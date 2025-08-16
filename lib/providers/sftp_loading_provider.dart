import 'package:flutter/material.dart';

class SftpLoadingProvider extends ChangeNotifier {

  double? _uploadProgress;
  double? _downloadProgress;
  
  double? _copyProgress;
  List<String>? _toBeMovedOrCopied;
  bool _isCopy = false;


  double? get copyProgress => _copyProgress;
  double? get uploadProgress => _uploadProgress;
  double? get downloadProgress => _downloadProgress;

  List<String>? get toBeMovedOrCopied => _toBeMovedOrCopied;
  bool get isCopy => _isCopy;

  void setUploadProgress(double? progress) {
    _uploadProgress = progress;
    notifyListeners();
  }

  void setDownloadProgress(double? progress) {
    _downloadProgress = progress;
    notifyListeners();
  }

  void setCopyProgress(double? progress) {
    _copyProgress = progress;
    notifyListeners();
  }

  void setCopyOrMoveFiles(List<String>? files, bool isCopy) {
    _toBeMovedOrCopied = files;
    _isCopy = isCopy;
    notifyListeners();
  }
}
