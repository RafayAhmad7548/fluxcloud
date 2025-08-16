import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:fluxcloud/main.dart';
import 'package:fluxcloud/providers/sftp_loading_provider.dart';
import 'package:fluxcloud/providers/sftp_provider.dart';
import 'package:fluxcloud/widgets/operation_buttons.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';


class SftpExplorer extends StatelessWidget {
  const SftpExplorer({super.key});

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
            if (context.read<SftpProvider>().path == '/') {
              // TODO: figure this out
              // Navigator.pop(context);
            }
            else {
              context.read<SftpProvider>().goToPrevDir();
            }
          },
          icon: Icon(Icons.arrow_back)
        ),
        actions: _buildLoadingButtons,
      ),
      floatingActionButton: _buildFABs(context),
      bottomNavigationBar: _buildCopyMoveButton(context),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, _) {
          if (context.read<SftpProvider>().path != '/') {
            context.read<SftpProvider>().goToPrevDir();
          }
        },
        child: Consumer<SftpProvider>(
          builder: (_, sftpProvider, __) => AnimatedSwitcher(
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
            child: sftpProvider.isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
              key: ValueKey(sftpProvider.path),
              itemCount: sftpProvider.dirContents.length,
              itemBuilder: (context, index) {
                final dirEntry = sftpProvider.dirContents[index];
                return ListTile(
                  leading: Icon(dirEntry.attr.isDirectory ? Icons.folder : Icons.description),
                  title: Text(dirEntry.filename),
                  trailing: OperationButtons(dirEntries: [dirEntry],),
                  onTap: () {
                    if (dirEntry.attr.isDirectory) {
                      sftpProvider.goToDir('${sftpProvider.path}${dirEntry.filename}/');
                    }
                  },
                );
              }, 
            )
          ),
        ),
      )
    );
  }

  Widget _buildFABs(BuildContext context) {
    final sftpProvider = context.read<SftpProvider>();
    final sftpLoadingProvider = context.read<SftpLoadingProvider>();
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
                        await sftpProvider.sftpWorker.mkdir('${sftpProvider.path}${nameController.text}');
                        sftpProvider.listDir();
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
            for (final filePath in filePaths) {
              try {
                await for (final progress in sftpProvider.sftpWorker.uploadFile(sftpProvider.path, filePath)) {
                  sftpLoadingProvider.setUploadProgress(progress);
                }
                await sftpProvider.listDir();
              }
              catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
                }
              }
            }
            sftpLoadingProvider.setUploadProgress(null);
            sftpProvider.listDir();
          },
          child: Icon(Icons.upload),
        ),
      ],
    );
  }

  Widget _buildCopyMoveButton(BuildContext context) {
    return Selector<SftpLoadingProvider, (List<String>?, bool)>(
      selector: (_, sftpLoadingProvider) => (sftpLoadingProvider.toBeMovedOrCopied, sftpLoadingProvider.isCopy),
      builder: (_, data, __) {
        final (toBeMovedOrCopied, isCopy) = data;
        if (toBeMovedOrCopied == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            spacing: 10,
            children: [
              Expanded(child: ElevatedButton(
                onPressed: () async {
                  final sftpProvider = context.read<SftpProvider>();
                  final sftpLoadingProvider = context.read<SftpLoadingProvider>();
                  for (final filePath in toBeMovedOrCopied) {
                    try {
                      final fileName = basename(filePath);
                      if (isCopy) {
                        await for (final progress in sftpProvider.sftpWorker.copy(filePath, '${sftpProvider.path}$fileName')) {
                          sftpLoadingProvider.setCopyProgress(progress);
                        }
                      }
                      else {
                        await sftpProvider.sftpWorker.rename(filePath, '${sftpProvider.path}$fileName');
                      }
                    }
                    catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(buildErrorSnackBar(context, e.toString()));
                      }
                    }
                  }
                  // TODO: figure out where to put this line
                  sftpLoadingProvider.setCopyOrMoveFiles(null, isCopy);
                  sftpLoadingProvider.setCopyProgress(null);
                  sftpProvider.listDir();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(isCopy ? 'Copy Here' : 'Move Here'),
                ),
              )),
              IconButton(
                onPressed: () {
                  context.read<SftpLoadingProvider>().setCopyOrMoveFiles(null, isCopy);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer
                ),
                icon: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close),
                ),
              )
            ],
          ),
        );
      }
    );
  }

  List<Widget> get _buildLoadingButtons => [
    Selector<SftpLoadingProvider, double?>(
      selector: (_, sftpLoadingProvider) => sftpLoadingProvider.uploadProgress,
      builder: (_, uploadProgress, __) => _buildLoader(uploadProgress, Icons.upload)
    ),
    Selector<SftpLoadingProvider, double?>(
      selector: (_, sftpLoadingProvider) => sftpLoadingProvider.downloadProgress,
      builder: (_, downloadProgress, __) => _buildLoader(downloadProgress, Icons.download)
    ),
    Selector<SftpLoadingProvider, double?>(
      selector: (_, sftpLoadingProvider) => sftpLoadingProvider.copyProgress,
      builder: (_, copyProgress, __) => _buildLoader(copyProgress, Icons.copy)
    ),
  ];

  Widget _buildLoader(double? progress, IconData icon) {
    return progress != null ? Stack(
      alignment: Alignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: Duration(milliseconds: 300),
          builder: (context, value, _) => CircularProgressIndicator(strokeWidth: 3, value: value,)
        ),
        IconButton(
          onPressed: () {
            // TODO: show details here
          },
          icon: Icon(icon)
        ),
      ]
    ) : const SizedBox.shrink();
  }

}
