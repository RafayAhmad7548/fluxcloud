import 'package:dartssh2/dartssh2.dart';
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


  @override
  void initState() {
    super.initState();
    _listDir();
  }

  void _listDir() async {
    _dirContents =  await widget.sftpClient.listdir(widget.path);
    setState(() {
      _isLoading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Explorer'),
      ),
      body: _isLoading ? Center(child: CircularProgressIndicator()) : ListView.builder(
        itemCount: _dirContents.length,
        itemBuilder: (context, index) {
          final dirEntry = _dirContents[index];
          return ListTile(
            leading: Icon(dirEntry.attr.isDirectory ? Icons.folder : Icons.description),
            title: Text(dirEntry.filename),
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
}
