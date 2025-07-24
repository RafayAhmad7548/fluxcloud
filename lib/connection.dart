import 'dart:convert';

class Connection {
  String? host;
  int? port;
  String? username;
  String? privateKey;
  String? password;
  bool? isEncryptionEnabled;
  bool? isDefault;

  Connection() : isEncryptionEnabled = true, isDefault = false;

  Connection.fromJson(Map<String, dynamic> json) {
    host = json['host'];
    port = json['port'];
    username = json['username'];
    privateKey = json['privateKeyFilePath'];
    password = json['password'];
    isEncryptionEnabled = json['isEncryptionEnabled'];
    isDefault = json['isDefault'];
  }

  String get toJson => jsonEncode({
    'host': host,
    'port': port,
    'username': username,
    'privateKeyFilePath': privateKey,
    'password': password,
    'isEncryptionEnabled': isEncryptionEnabled,
    'isDefault': isDefault
  });


  bool assertComplete() {
    assert(host != null);
    assert(port != null);
    assert(username != null);
    assert(privateKey != null || password != null);
    assert(isEncryptionEnabled != null);
    assert(isDefault != null);
    return true;
  }
}
