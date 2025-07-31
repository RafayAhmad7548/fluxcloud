import 'dart:io';

import 'package:dartssh2/dartssh2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fluxcloud/sftp_worker.dart';

class SftpExplorer extends StatefulWidget {
  const SftpExplorer({super.key, required this.sftpWorker, this.path = '/'});

  final SftpWorker sftpWorker;
  final String path;

  @override
  State<SftpExplorer> createState() => _SftpExplorerState();
}

class _SftpExplorerState extends State<SftpExplorer> {

  bool _isLoading = true;
  late List<SftpName> _dirContents;
  
  @override
  void initState() {
    super.initState();
    _listDir();
  }

  Future<void> _listDir() async {
    setState(() => _isLoading = true);
    try {
      _dirContents =  await widget.sftpWorker.listdir(widget.path);
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
        title: Text('Explorer'),
      ),
      floatingActionButton: _buildFABs(context),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _dirContents.length,
        itemBuilder: (context, index) {
          final dirEntry = _dirContents[index];
          return ListTile(
            leading: Icon(dirEntry.attr.isDirectory ? Icons.folder : Icons.description),
            title: Text(dirEntry.filename),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () {

                  },
                  icon: Icon(Icons.drive_file_move)
                ),
                IconButton(
                  onPressed: () {

                  },
                  icon: Icon(Icons.copy)
                ),
                IconButton(
                  onPressed: () {
                    final newNameController = TextEditingController(text: dirEntry.filename);
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Rename'),
                        content: TextField(
                          controller: newNameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: 'Enter new name'
                          ),
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              // try {
                              //   await widget.sftpWorker.rename('${widget.path}${dirEntry.filename}', '${widget.path}${newNameController.text}');
                              //   _listDir();
                              // }
                              // on SftpStatusError catch (e) {
                              //   if (context.mounted) {
                              //     ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, e.message));
                              //   }
                              // }
                              // if (context.mounted) {
                              //   Navigator.pop(context);
                              // }
                              //
                            },
                            child: Text('Rename')
                          ),

                        ],
                      )
                    );
                  },
                  icon: Icon(Icons.drive_file_rename_outline)
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete Permanently?'),
                        content: Text(dirEntry.attr.isDirectory ? 'The contents of this folder will be deleted as well\nThis action cannot be undone' : 'This action cannot be undone'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                          TextButton(
                            onPressed: () async {
                              // if (dirEntry.attr.isDirectory) {
                              //   Future<void> removeRecursively (String path) async {
                              //     final dirContents = await widget.sftpWorker.listdir(path);
                              //     for (SftpName entry in dirContents) {
                              //       final fullPath = '$path${entry.filename}';
                              //       if (entry.attr.isDirectory) {
                              //         await removeRecursively('$fullPath/');
                              //         await widget.sftpWorker.rmdir('$fullPath/');
                              //       }
                              //       else {
                              //         await widget.sftpWorker.remove(fullPath);
                              //       }
                              //     }
                              //     await widget.sftpWorker.rmdir(path);
                              //   }
                              //   await removeRecursively('${widget.path}${dirEntry.filename}/');
                              // }
                              // else {
                              //   await widget.sftpWorker.remove('${widget.path}${dirEntry.filename}');
                              // }
                              // _listDir();
                              // if (context.mounted) {
                              //   Navigator.pop(context);
                              // }
                            },
                            child: Text('Yes')
                          ),
                        ],
                      )
                    );
                  },
                  icon: Icon(Icons.delete)
                ),
              ],
            ),
            onTap: () {
              if (dirEntry.attr.isDirectory) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => SftpExplorer(
                    sftpWorker: widget.sftpWorker,
                    path: '${widget.path}${dirEntry.filename}/',
                  )
                ));
              }
            },
          );
        }, 
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
                      // try {
                      //   await widget.sftpWorker.mkdir('${widget.path}${nameController.text}');
                      //   _listDir();
                      // }
                      // on SftpStatusError catch (e) {
                      //   if (context.mounted) {
                      //     if (e.code == 4) {
                      //       ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'Folder Already Exists'));
                      //     }
                      //     else {
                      //       ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'Error: ${e.message}'));
                      //     }
                      //   }
                      // }
                      // if (context.mounted) {
                      //   Navigator.pop(context);
                      // }
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
            await widget.sftpWorker.uploadFiles(widget.path, filePaths);
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
