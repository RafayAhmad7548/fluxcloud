import 'package:dartssh2/dartssh2.dart';
import 'package:fluxcloud/sftp_worker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sftp_state.g.dart';

class SftpState {
  final String path;
  final bool isLoading;
  final List<SftpName> dirContents;

  final double? uploadProgress;
  final double? downloadProgress;

  SftpState({
    required this.path,
    required this.isLoading,
    required this.dirContents,
    required this.uploadProgress,
    required this.downloadProgress
  });

  SftpState copyWith({
    String? path,
    bool? isLoading,
    List<SftpName>? dirContents,
    double? uploadProgress,
    double? downloadProgress,
  }) => SftpState(
    path: path ?? this.path,
    isLoading: isLoading ?? this.isLoading,
    dirContents: dirContents ?? this.dirContents,
    uploadProgress: uploadProgress ?? this.uploadProgress,
    downloadProgress: downloadProgress ?? this.downloadProgress
  );

}

@riverpod
class SftpNotifier extends _$SftpNotifier {

  @override
  SftpState build(SftpWorker sftpWorker) {
    Future.microtask(listDir);
    return SftpState(path: '/', isLoading: false, dirContents: [], uploadProgress: null, downloadProgress: null);
  } 


  Future<void> listDir() async {
    state = state.copyWith(isLoading: true);
    final dirContents =  await sftpWorker.listdir(state.path);
    state = state.copyWith(isLoading: false, dirContents: dirContents);
  }

  void goToDir(String path) {
    state = state.copyWith(path: path);
    listDir();
  }

  void goToPrevDir() {
    String path = state.path.substring(0, state.path.length - 1);
    path = path.substring(0, path.lastIndexOf('/')+1);
    state = state.copyWith(path: path);
    listDir();
  }

  void setUploadProgress(double? progress) {
    state = state.copyWith(uploadProgress: progress);
  }

  void setDownloadProgress(double? progress) {
    state = state.copyWith(downloadProgress: progress);
  }

}
