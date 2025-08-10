import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fluxcloud/sftp_worker.dart';

import 'widgets/operation_buttons.dart';

class SftpExplorer extends StatefulWidget {
  const SftpExplorer({super.key, required this.sftpWorker});

  final SftpWorker sftpWorker;

  @override
  State<SftpExplorer> createState() => _SftpExplorerState();
}

class _SftpExplorerState extends State<SftpExplorer> {

  String path = '/';

  bool _isLoading = true;
  late List<SftpName> _dirContents;

  double? _progress;
  
  @override
  void initState() {
    super.initState();
    _listDir();
  }

  Future<void> _listDir() async {
    setState(() => _isLoading = true);
    try {
      _dirContents =  await widget.sftpWorker.listdir(path);
    }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, e.toString()));
      }
    }
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: Text('Explorer'),
        elevation: 2,
        actionsPadding: EdgeInsets.only(right: 20),
        leading: IconButton(
          onPressed: () {
            if (path == '/') {
              // TODO: figure this out
              // Navigator.pop(context);
            }
            else {
              path = path.substring(0, path.length - 1);
              path = path.substring(0, path.lastIndexOf('/')+1);
              _listDir();
            }
          },
          icon: Icon(Icons.arrow_back)
        ),
        actions: [
          if (_progress != null)
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: _progress),
                duration: Duration(milliseconds: 300),
                builder: (context, value, _) => CircularProgressIndicator(strokeWidth: 3, value: value,)
              ),
              IconButton(
                onPressed: () {
                  // TODO: show donwload details here
                },
                icon: Icon(Icons.upload)
              ),
            ]
          ),
        ],
      ),
      floatingActionButton: _buildFABs(context),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, _) {
          if (path != '/') {
            path = path.substring(0, path.length - 1);
            path = path.substring(0, path.lastIndexOf('/')+1);
            _listDir();
          }
        },
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.fastOutSlowIn
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.92,
                  end: 1
                ).animate(curved),
                child: child,
              ),
            );
          },
          child: _isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
            key: ValueKey(path),
            itemCount: _dirContents.length,
            itemBuilder: (context, index) {
              final dirEntry = _dirContents[index];
              return ListTile(
                leading: Icon(dirEntry.attr.isDirectory ? Icons.folder : Icons.description),
                title: Text(dirEntry.filename),
                trailing: OperationButtons(sftpWorker: widget.sftpWorker, path: path, dirEntries: [dirEntry], listDir: _listDir,),
                onTap: () {
                  if (dirEntry.attr.isDirectory) {
                    path = '$path${dirEntry.filename}/';
                    _listDir();
                  }
                },
              );
            }, 
          )
        ),
      )
    );
  }

  Widget _buildFABs(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        FloatingActionButton(
          heroTag: 'create-new-folder',
          onPressed: () {
            final nameController = TextEditingController();
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Create new folder'),
                content: TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Enter folder name'
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                  TextButton(
                    onPressed: () async {
                      try {
                        await widget.sftpWorker.mkdir('$path${nameController.text}');
                        _listDir();
                      }
                      catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, e.toString()));
                        }
                      }
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: Text('Ok')
                  ),
                ],
              )
            );
          },
          child: Icon(Icons.create_new_folder),
        ),
        FloatingActionButton(
          heroTag: 'upload-file',
          onPressed: () async {
            final List<String> filePaths;
            if (Platform.isAndroid | Platform.isIOS) {
              final res = await FilePicker.platform.pickFiles(allowMultiple: true);
              filePaths = (res?.paths ?? []).whereType<String>().toList();
            }
            else {
              final files = await openFiles();
              filePaths = files.map((file) => file.path).toList();
            }
            try {
              await for (final progress in widget.sftpWorker.uploadFiles(path, filePaths)) {
                setState(() => _progress = progress);
              }
            }
            catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, e.toString()));
              }
            }
            setState(() => _progress = null);
            _listDir();
          },
          child: Icon(Icons.upload),
        ),
      ],
    );
  }

  SnackBar _buildErrorSnackBar(BuildContext context, String error) {
    return SnackBar(
      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
      behavior: SnackBarBehavior.floating,
      content: Row(
        spacing: 10,
        children: [
          Icon(Icons.error, color: Colors.red,),
          Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),),
        ],
      )
    );
  }
}
