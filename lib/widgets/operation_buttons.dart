import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';
import 'package:fluxcloud/main.dart';
import 'package:fluxcloud/sftp_worker.dart';
import 'package:path_provider/path_provider.dart';

class OperationButtons extends StatelessWidget {
  const OperationButtons({
    super.key,
    required this.sftpWorker, required this.path, required this.dirEntries, required this.listDir, required this.setDownloadProgress,
  });

  final SftpWorker sftpWorker;
  final String path;
  final List<SftpName> dirEntries;
  final Function listDir;
  final Function(double? progress) setDownloadProgress;

  @override
  Widget build(BuildContext context) {
    return Row(
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
        if (dirEntries.length == 1)
        IconButton(
          onPressed: () {
            final dirEntry = dirEntries[0];
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
                        await sftpWorker.rename('$path${dirEntry.filename}', '$path${newNameController.text}');
                        listDir();
                      }
                      on SftpStatusError catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.message));
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
              builder: (context) {
                String warningText = 'This action cannot be undone';
                if (dirEntries.length == 1 && dirEntries[0].attr.isDirectory) {
                  warningText = 'The contents of this folder will be deleted as well\n$warningText';
                }
                else if (dirEntries.length > 1) {
                  warningText = 'All selected files will be deleted\n$warningText';
                }
                return AlertDialog(
                  title: Text('Delete Permanently?'),
                  content: Text(warningText),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
                    TextButton(
                      onPressed: () async {
                        for (final dirEntry in dirEntries) {
                          try {
                            await sftpWorker.remove(dirEntry, path);
                          }
                          catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
                            }
                          }
                          listDir();
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        }
                      },
                      child: Text('Yes')
                    ),
                  ],
                );
              }
            );
          },
          icon: Icon(Icons.delete)
        ),
        IconButton(
          onPressed: () async {
            final downloadsDir = await getDownloadsDirectory();
            if (downloadsDir == null) return;
            try {
              await for (final progress in sftpWorker.downloadFiles(dirEntries, path, downloadsDir.path)) {
                setDownloadProgress(progress);
              }
              setDownloadProgress(null);
            }
            catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
              }
            }
          },
          icon: Icon(Icons.download)
        )
      ],
    );
  }
}

