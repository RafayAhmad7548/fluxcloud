import 'dart:convert';

class Connection {
  String? host;
  int? port;
  String? username;
  String? privateKeyFilePath;
  String? password;

  Connection();

  Connection.fromJson(Map<String, dynamic> json) {
    host = json['host'];
    port = json['port'];
    username = json['username'];
    privateKeyFilePath = json['privateKeyFilePath)'];
    password = json['password'];
  }

  String get toJson => jsonEncode({
    'host': host,
    'port': port,
    'username': username,
    'privateKeyFilePath': privateKeyFilePath,
    'password': password
  });


  bool assertComplete() {
    assert(host != null);
    assert(port != null);
    assert(username != null);
    assert(privateKeyFilePath != null || password != null);
    return true;
  }
}
