import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart';

import 'connection.dart';

sealed class SftpCommand {}
class ListDir extends SftpCommand {
  final String path;

  ListDir(this.path);
}
class UploadFiles extends SftpCommand {
  final String path;
  final List<String> fileNames;

  UploadFiles(this.path, this.fileNames);
}

class SftpWorker {

  final ReceivePort _responses;
  final SendPort _commands;
  final Map<int, Completer<Object>> _activeRequests = {};
  int _idCounter = 0;

  SftpWorker._(this._responses, this._commands) {
    _responses.listen(_sftpResponseHandler);
  }
  
  static Future<SftpWorker> spawn(Connection connection) async {
    final initPort = RawReceivePort();
    final workerReady = Completer<(ReceivePort, SendPort)>.sync();
    initPort.handler = (message) {
      final commandPort = message as SendPort;
      workerReady.complete((
        ReceivePort.fromRawReceivePort(initPort),
        commandPort
      ));
    };

    try {
      Isolate.spawn(_startSftpIsolate, (initPort.sendPort, connection));
    } on Object {
      initPort.close();
      rethrow;
    }

    final (receivePort, sendPort) = await workerReady.future;

    return SftpWorker._(receivePort, sendPort);
  }

  static void _startSftpIsolate((SendPort, Connection) args) async {
    final sendPort = args.$1;
    final receivePort = ReceivePort();
    
    // TODO: error handling
    final connection = args.$2;
    final client = SSHClient(
      await SSHSocket.connect(connection.host!, connection.port!),
      username: connection.username!,
      onPasswordRequest: () => connection.password,
      identities: [
        if (connection.privateKey != null)
        ...SSHKeyPair.fromPem(connection.privateKey!)
      ]
    );
    final sftpClient = await client.sftp();

    sendPort.send(receivePort.sendPort);
  
    _sftpCmdHandler(sendPort, receivePort, sftpClient);
  }


  static void _sftpCmdHandler(SendPort sendPort, ReceivePort receivePort, SftpClient sftpClient) {
    receivePort.listen((message) async {
      final (int id, dynamic command) = message;
      switch (command) {
        case ListDir(:final path):
          try {
            final files = await sftpClient.listdir(path);
            sendPort.send((id, files));
          }
          on SftpStatusError catch (e) {
            sendPort.send((id, RemoteError(e.message, '')));
          }
        case UploadFiles(:final path, fileNames:final filePaths):
          for (var filePath in filePaths) {
            try {
              final file = File(filePath);
              final fileSize = await file.length();
              final remoteFile = await sftpClient.open(
                '$path${basename(filePath)}',
                mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.exclusive
              );
              await remoteFile.write(
                file.openRead().cast(),
                onProgress: (progress) {
                  print(progress/fileSize);
                }
              );
            }
            on SftpStatusError catch (e) {
              sendPort.send((id, RemoteError(e.message, '')));
            }
          }
          sendPort.send((id, 0));
      }
    });
  }

  void _sftpResponseHandler(dynamic message) {
    final (int id, Object response) = message;
    final completer = _activeRequests.remove(id)!;

    if (response is RemoteError) {
      completer.completeError(response);
    }
    else {
      completer.complete(response);
    }
  }

  
  Future<List<SftpName>> listdir(String path) async {
    final completer = Completer<Object>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, ListDir(path)));
    return await completer.future as List<SftpName>;
  }

  
  Future<void> uploadFiles(String path, List<String> filePaths) async {
    final completer = Completer<Object>.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, UploadFiles(path, filePaths)));
    await completer.future;
  }


}
