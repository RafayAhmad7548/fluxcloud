import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluxcloud/connection.dart';
import 'package:fluxcloud/providers/sftp_loading_provider.dart';
import 'package:fluxcloud/providers/sftp_provider.dart';
import 'package:fluxcloud/sftp_explorer.dart';
import 'package:fluxcloud/sftp_worker.dart';
import 'package:fluxcloud/widgets/add_server_modal.dart';
import 'package:provider/provider.dart';


class SftpConnectionList extends StatefulWidget {
  const SftpConnectionList({
    super.key,
  });

  @override
  State<SftpConnectionList> createState() => _SftpConnectionListState();
}

class _SftpConnectionListState extends State<SftpConnectionList> {

  late List<Connection> _connections;
  bool _isConnectionsInit = false;

  @override
  void initState() {
    super.initState();
    _getConnections();
  }

  Future<void> _getConnections() async {
    final storage = FlutterSecureStorage();
    final secureMap = await storage.readAll();
    setState(() {
      _connections = secureMap.values.map((json) => Connection.fromJson(jsonDecode(json))).toList();
      _isConnectionsInit = true;
    });
  }

  String _getAuthString(int index) {
    String result = 'Auth: ';
    final hasKey = _connections[index].privateKey?.isNotEmpty ?? false;
    final hasPass = _connections[index].password?.isNotEmpty ?? false;

    if (hasKey) result += 'Private Key';
    if (hasKey && hasPass) result += ', ';
    if (hasPass) result += 'Password';

    return result;
  }

  void _showBottomSheet(BuildContext context, Connection? initialState) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context, 
      showDragHandle: true,
      builder: (context) => AddServerModal(updateConnectionList: _getConnections, initialState: initialState,)
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () => _showBottomSheet(context, null)
      ),
      body: _isConnectionsInit ? RefreshIndicator(
        onRefresh: () => _getConnections(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView.builder(
            itemCount: _connections.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  Material(
                    color: Theme.of(context).colorScheme.onSecondary,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      onTap: () async {
                        final sftpWorker = await SftpWorker.spawn(_connections[index]);
                        if (context.mounted) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => MultiProvider(
                            providers: [
                              ChangeNotifierProvider<SftpProvider>(create: (_) => SftpProvider(sftpWorker)),
                              ChangeNotifierProvider<SftpLoadingProvider>(create: (_) => SftpLoadingProvider()),
                            ],
                            child: SftpExplorer())
                          ));
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _connections[index].host!,
                                  style: TextStyle(fontSize: 20),
                                ),
                                Text('Port: ${_connections[index].port}'),
                                Text('Username: ${_connections[index].username}'),
                                Text(_getAuthString(index)),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Encryption: '),
                                    Icon(
                                      _connections[index].isEncryptionEnabled! ? Icons.check : Icons.close,
                                      size: 18
                                    )
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Default: '),
                                    Icon(
                                      _connections[index].isDefault! ? Icons.check : Icons.close,
                                      size: 18
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Expanded(child: SizedBox()),
                            IconButton(
                              onPressed: () => _showBottomSheet(context, _connections[index]),
                              icon: Icon(Icons.edit)
                            ),
                            IconButton(
                              onPressed: () {
                                final storage = FlutterSecureStorage();
                                storage.delete(key: _connections[index].host!);
                                _getConnections();
                              }, 
                              icon: Icon(Icons.delete)
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10,)
                ],
              );
            }
          ),
        ),
      ) : Center(child: CircularProgressIndicator())
    );
  }

}

