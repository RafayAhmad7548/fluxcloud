import 'package:dartssh2/dartssh2.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

class SftpExplorer extends StatefulWidget {
  const SftpExplorer({super.key, required this.sftpClient, this.path = '/'});

  final SftpClient sftpClient;
  final String path;

  @override
  State<SftpExplorer> createState() => _SftpExplorerState();
}

class _SftpExplorerState extends State<SftpExplorer> {

  bool _isLoading = true;
  late List<SftpName> _dirContents;
  
  SftpFileWriter? _loader;
  String _loadingFileName = '';
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _listDir();
  }

  Future<void> _listDir() async {
    setState(() => _isLoading = true);
    _dirContents =  await widget.sftpClient.listdir(widget.path);
    setState(() => _isLoading = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explorer'),
      ),
      bottomNavigationBar: _buildLoadingWidget(context), 
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
                              try {
                                await widget.sftpClient.rename('${widget.path}${dirEntry.filename}', '${widget.path}${newNameController.text}');
                                _listDir();
                              }
                              on SftpStatusError catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, e.message));
                                }
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                              }

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
                              if (dirEntry.attr.isDirectory) {
                                Future<void> removeRecursively (String path) async {
                                  final dirContents = await widget.sftpClient.listdir(path);
                                  for (SftpName entry in dirContents) {
                                    final fullPath = '$path${entry.filename}';
                                    if (entry.attr.isDirectory) {
                                      await removeRecursively('$fullPath/');
                                      await widget.sftpClient.rmdir('$fullPath/');
                                    }
                                    else {
                                      await widget.sftpClient.remove(fullPath);
                                    }
                                  }
                                  await widget.sftpClient.rmdir(path);
                                }
                                await removeRecursively('${widget.path}${dirEntry.filename}/');
                              }
                              else {
                                await widget.sftpClient.remove('${widget.path}${dirEntry.filename}');
                              }
                              _listDir();
                              if (context.mounted) {
                                Navigator.pop(context);
                              }
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
                    sftpClient: widget.sftpClient,
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
                      try {
                        await widget.sftpClient.mkdir('${widget.path}${nameController.text}');
                        _listDir();
                      }
                      on SftpStatusError catch (e) {
                        if (context.mounted) {
                          if (e.code == 4) {
                            ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'Folder Already Exists'));
                          }
                          else {
                            ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'Error: ${e.message}'));
                          }
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
            // TODO: upload hangingig on android
            final List<XFile> files = await openFiles();
            try {
              for (XFile file in files) {
                final remoteFile = await widget.sftpClient.open('${widget.path}${file.name}', mode: SftpFileOpenMode.create | SftpFileOpenMode.write | SftpFileOpenMode.exclusive);
                final fileSize = await file.length();
                final uploader = remoteFile.write(
                  file.openRead().cast(),
                  onProgress: (progress) => setState(() => _progress = progress/fileSize)
                );
                setState(() {
                  _loader = uploader;
                  _loadingFileName = file.name;
                });
                await uploader.done;
              }
              setState(() => _loader = null);
              _listDir();
            }
            on SftpStatusError catch (e) {
              if (context.mounted) {
                if (e.code == 4) {
                  ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'File Already Exists'));
                }
                else {
                  ScaffoldMessenger.of(context).showSnackBar(_buildErrorSnackBar(context, 'Error: ${e.message}'));
                }
              }
            }
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

  Widget _buildLoadingWidget(BuildContext context) {
    return _loader != null ? Container(
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
                    _loader!.abort();
                    widget.sftpClient.remove('${widget.path}$_loadingFileName');
                  },
                  child: Text('Cancel')
                ),
              ],
            ),
            LinearProgressIndicator(value: _progress,)
          ],
        ),
      ),
    ) : SizedBox();
  }
}
