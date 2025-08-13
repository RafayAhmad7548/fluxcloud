import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxcloud/main.dart';
import 'package:fluxcloud/providers/sftp_state.dart';
import 'package:fluxcloud/sftp_worker.dart';

import 'widgets/operation_buttons.dart';

class SftpExplorer extends ConsumerWidget {
  const SftpExplorer({super.key, required this.sftpWorker});

  final SftpWorker sftpWorker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sftpState = ref.watch(sftpNotifierProvider(sftpWorker));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        title: Text('Explorer'),
        elevation: 2,
        actionsPadding: EdgeInsets.only(right: 20),
        leading: IconButton(
          onPressed: () {
            if (sftpState.path == '/') {
              // TODO: figure this out
              // Navigator.pop(context);
            }
            else {
              ref.read(sftpNotifierProvider(sftpWorker).notifier).goToPrevDir();
            }
          },
          icon: Icon(Icons.arrow_back)
        ),
        actions: [
          if (sftpState.uploadProgress != null)
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: sftpState.uploadProgress),
                duration: Duration(milliseconds: 300),
                builder: (context, value, _) => CircularProgressIndicator(strokeWidth: 3, value: value,)
              ),
              IconButton(
                onPressed: () {
                  // TODO: show upload details here
                },
                icon: Icon(Icons.upload)
              ),
            ]
          ),
          if (sftpState.downloadProgress != null)
          Stack(
            alignment: Alignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: sftpState.downloadProgress),
                duration: Duration(milliseconds: 300),
                builder: (context, value, _) => CircularProgressIndicator(strokeWidth: 3, value: value,)
              ),
              IconButton(
                onPressed: () {
                  // TODO: show donwload details here
                },
                icon: Icon(Icons.download)
              ),
            ]
          ),
        ],
      ),
      floatingActionButton: _buildFABs(context, ref),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, _) {
          if (sftpState.path != '/') {
            ref.read(sftpNotifierProvider(sftpWorker).notifier).goToPrevDir();
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
          child: sftpState.isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
            key: ValueKey(sftpState.path),
            itemCount: sftpState.dirContents.length,
            itemBuilder: (context, index) {
              final dirEntry = sftpState.dirContents[index];
              return ListTile(
                leading: Icon(dirEntry.attr.isDirectory ? Icons.folder : Icons.description),
                title: Text(dirEntry.filename),
                trailing: OperationButtons(sftpWorker: sftpWorker, dirEntries: [dirEntry],),
                onTap: () {
                  if (dirEntry.attr.isDirectory) {
                    ref.read(sftpNotifierProvider(sftpWorker).notifier).goToDir('${sftpState.path}${dirEntry.filename}/');
                  }
                },
              );
            }, 
          )
        ),
      )
    );
  }

  Widget _buildFABs(BuildContext context, WidgetRef ref) {
    final sftpState = ref.read(sftpNotifierProvider(sftpWorker));
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
                        await sftpWorker.mkdir('${sftpState.path}${nameController.text}');
                        ref.read(sftpNotifierProvider(sftpWorker).notifier).listDir();
                      }
                      catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
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
              await for (final progress in sftpWorker.uploadFiles(sftpState.path, filePaths)) {
                ref.read(sftpNotifierProvider(sftpWorker).notifier).setUploadProgress(progress);
                if (progress == 1) {
                  ref.read(sftpNotifierProvider(sftpWorker).notifier).listDir();
                }
              }
            }
            catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
              }
            }
            ref.read(sftpNotifierProvider(sftpWorker).notifier).setUploadProgress(null);
            ref.read(sftpNotifierProvider(sftpWorker).notifier).listDir();
          },
          child: Icon(Icons.upload),
        ),
      ],
    );
  }

}
