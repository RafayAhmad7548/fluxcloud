import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:fluxcloud/sftp_worker.dart';

class SftpProvider extends ChangeNotifier {
  final SftpWorker _sftpWorker;

  String _path = '/';
  bool _isLoading = false;
  late List<SftpName> _dirContents;

  double? _uploadProgress;
  double? _downloadProgress;
  
  List<String>? _toBeMovedOrCopied;
  bool _isCopy = false;

  SftpProvider(this._sftpWorker) {
    listDir();
  }

  SftpWorker get sftpWorker => _sftpWorker;

  String get path => _path;
  bool get isLoading => _isLoading;
  List<SftpName> get dirContents  => _dirContents;

  double? get uploadProgress => _uploadProgress;
  double? get downloadProgress => _downloadProgress;

  List<String>? get toBeMovedOrCopied => _toBeMovedOrCopied;
  bool get isCopy => _isCopy;
  
  Future<void> listDir() async {
    _isLoading = true;
    notifyListeners();
    _dirContents =  await _sftpWorker.listdir(_path);
    _isLoading = false;
    notifyListeners();
  }

  void goToPrevDir() {
    _path = _path.substring(0, _path.length - 1);
    _path = _path.substring(0, _path.lastIndexOf('/')+1);
    listDir();
  }

  void goToDir(String path) {
    _path = path;
    listDir();
  }

  void setUploadProgress(double? progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void setDownloadProgress(double? progress) {
    _downloadProgress = progress;
    notifyListeners();
  }

  void setCopyOrMoveFiles(List<String>? files, bool isCopy) {
    _toBeMovedOrCopied = files;
    _isCopy = isCopy;
    notifyListeners();
  }

}
