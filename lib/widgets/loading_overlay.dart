import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class LoadingOverlay extends StatefulWidget{
  const LoadingOverlay({
    super.key, required this.sftpClient, required this.path, required this.files,
  });

  final SftpClient sftpClient;
  final String path;
  final List<XFile> files;

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay> {

  Future<void> uploadFiles() async {
    for (final file in widget.files) {
      final fileSize = await file.length();
      final remoteFile = await widget.sftpClient.open(
        '${widget.path}${file.name}',
        mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.exclusive
      );
      _loader = remoteFile.write(
        file.openRead(),
        onProgress: (progress) => setState(() => _progress = progress/fileSize)
      );
      await _loader?.done;
    }
  }
  
  @override
  void initState() {
    super.initState();
    uploadFiles();
    _loadingFileName = widget.files[0].name;
  }
  
  SftpFileWriter? _loader;

  late String _loadingFileName;
  double _progress = 0;

  @override
  build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            spacing: 10,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                spacing: 10,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Uploading file: $_loadingFileName', style: TextStyle(fontSize: 16),),
                  TextButton(
                    onPressed: () {
                      if (_loader != null) {
                        _loader!.abort();
                        widget.sftpClient.remove('${widget.path}$_loadingFileName');
                      }
                    },
                    child: Text('Cancel')
                  ),
                ],
              ),
              LinearProgressIndicator(value: _progress,)
            ],
          ),
        ),
      ),
    );
  }
}

