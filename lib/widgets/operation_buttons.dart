import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/material.dart';

class OperationButtons extends StatelessWidget {
  const OperationButtons({
    super.key,
    required this.dirEntry,
  });

  final SftpName dirEntry;

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
                      //   await widget.sftpWorker.rename('${path}${dirEntry.filename}', '${widget.path}${newNameController.text}');
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
                      //   await removeRecursively('${path}${dirEntry.filename}/');
                      // }
                      // else {
                      //   await widget.sftpWorker.remove('${path}${dirEntry.filename}');
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
    );
  }
}

