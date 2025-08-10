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

class MkDir extends SftpCommand {
  final String path;

  MkDir(this.path);
}

class Remove extends SftpCommand {
  final SftpName dirEntry;
  final String path;

  Remove(this.dirEntry, this.path);
}

class Rename extends SftpCommand {
  final String oldpath;
  final String newpath;

  Rename(this.oldpath, this.newpath);
}


class SftpWorker {

  final ReceivePort _responses;
  final SendPort _commands;
  final Map<int, dynamic> _activeRequests = {};
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
      final (int id, SftpCommand command) = message;
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
              bool timeout = true;
              await remoteFile.write(
                file.openRead().cast(),
                onProgress: (progress) {
                  if (timeout) {
                    timeout = false;
                    sendPort.send((id, progress/fileSize));
                    Future.delayed(Duration(seconds: 2), () => timeout = true);
                  }
                }
              );
            }
            on SftpStatusError catch (e) {
              sendPort.send((id, RemoteError(e.message, '')));
            }
            sendPort.send((id, 1.0));
          }
        case MkDir(:final path):
          try {
            await sftpClient.mkdir(path);
            sendPort.send((id, 0));
          }
          on SftpStatusError catch (e) {
            sendPort.send((id, RemoteError(e.message, '')));
          }
        case Remove(:final dirEntry, :final path):
          try {
            if (dirEntry.attr.isDirectory) {
              Future<void> removeRecursively (String path) async {
                final dirContents = await sftpClient.listdir(path);
                for (SftpName entry in dirContents) {
                  final fullPath = '$path${entry.filename}';
                  if (entry.attr.isDirectory) {
                    await removeRecursively('$fullPath/');
                    await sftpClient.rmdir('$fullPath/');
                  }
                  else {
                    await sftpClient.remove(fullPath);
                  }
                }
                await sftpClient.rmdir(path);
              }
              await removeRecursively('$path${dirEntry.filename}/');
            }
            else {
              await sftpClient.remove('$path${dirEntry.filename}');
            }
            sendPort.send((id, 0));
          }
          on SftpStatusError catch (e) {
            sendPort.send((id, RemoteError(e.message, '')));
          }
        case Rename(:final oldpath, :final newpath):
          try {
            await sftpClient.rename(oldpath, newpath);
            sendPort.send((id, 0));
          }
          on SftpStatusError catch (e) {
            sendPort.send((id, RemoteError(e.message, '')));
          }
      }
    });
  }

  void _sftpResponseHandler(dynamic message) {
    final (int id, Object response) = message;

    if (_activeRequests[id] is Completer) {
      final completer = _activeRequests.remove(id)!;

      if (response is RemoteError) {
        completer.completeError(response);
      }
      else {
        completer.complete(response);
      }
    }
    else if (_activeRequests[id] is StreamController) {
      final controller = _activeRequests[id] as StreamController;
      if (response is RemoteError) {
        controller.addError(response);
      }
      else {
        controller.add(response);
        if (response == 1) {
          controller.close();
          _activeRequests.remove(id);
        }
      }
    }
  }

  
  Future<List<SftpName>> listdir(String path) async {
    final completer = Completer.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, ListDir(path)));
    return await completer.future as List<SftpName>;
  }

  
  Stream<double> uploadFiles(String path, List<String> filePaths) {
    final controller = StreamController<double>();
    final id = _idCounter++;
    _activeRequests[id] = controller;
    _commands.send((id, UploadFiles(path, filePaths)));
    return controller.stream;
  }

  Future<void> mkdir(String path) async {
    final completer = Completer.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, MkDir(path)));
    await completer.future;
  }

  Future<void> remove(SftpName dirEntry, String path) async {
    final completer = Completer.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, Remove(dirEntry, path)));
    await completer.future;
  }

  Future<void> rename(String oldpath, String newpath) async {
    final completer = Completer.sync();
    final id = _idCounter++;
    _activeRequests[id] = completer;
    _commands.send((id, Rename(oldpath, newpath)));
    await completer.future;
  }

}
