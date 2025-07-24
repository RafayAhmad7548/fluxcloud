import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluxcloud/connection.dart';

class AddServerModal extends StatefulWidget {
  const AddServerModal({
    super.key, required this.updateConnectionList, this.initialState,
  });

  final Function updateConnectionList;
  final Connection? initialState;

  @override
  State<AddServerModal> createState() => _AddServerModalState();
}

class _AddServerModalState extends State<AddServerModal> {

  final GlobalKey<FormState> _formKey = GlobalKey();
  
  final TextEditingController _privateKeyFileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _fileSelected = false;
  bool _showPassword = false;
  bool _showPrivateKey = false;
  bool _isPrivateKeyValid = false;

  final Connection _connection = Connection();


  @override
    void initState() {
      super.initState();
      if (widget.initialState != null) {
        _connection.isEncryptionEnabled = widget.initialState?.isEncryptionEnabled;
        _connection.isDefault = widget.initialState?.isDefault;
        _privateKeyFileController.text = widget.initialState?.privateKey ?? '';
        _passwordController.text = widget.initialState?.password ?? '';
      }
    }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.only(left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 16,
                children: [
                  Text(
                    widget.initialState == null ? 'Add Connection' : 'Edit Connection',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 18),
                  ),
                  TextFormField(
                    initialValue: widget.initialState?.host,
                    decoration: InputDecoration(
                      labelText: 'Host',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This value is required';
                      }
                      if (!RegExp(r'^(([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,})|(\d{1,3}(\.\d{1,3}){3})$').hasMatch(value)) {
                        return 'Please enter a valid host';
                      }
                      return null;
                    },
                    onSaved: (value) => _connection.host = value,
                  ),
                  TextFormField(
                    initialValue: widget.initialState?.port.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Port',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'This value is required';
                      }
                      if (int.tryParse(value) == null || int.parse(value) < 0 || int.parse(value) > 65535) {
                        return 'Please enter a valid port';
                      }
                      return null;
                    },
                    onSaved: (value) => _connection.port = int.parse(value!),
                  ),
                  TextFormField(
                    initialValue: widget.initialState?.username,
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'This value is required' : null,
                    onSaved: (value) => _connection.username = value,
                  ),
                  TextFormField(
                    controller: _privateKeyFileController,
                    obscureText: !_showPrivateKey,
                    readOnly: true,
                    onTap: () async {
                      final XFile? file = await openFile();
                      if (file != null) {
                        const knownHeaders = [
                          '-----BEGIN OPENSSH PRIVATE KEY-----',
                          '-----BEGIN RSA PRIVATE KEY-----',
                          '-----BEGIN DSA PRIVATE KEY-----',
                          '-----BEGIN EC PRIVATE KEY-----',
                          '-----BEGIN PRIVATE KEY-----',
                        ];
                        try {
                          final privateKey = utf8.decode(await file.readAsBytes());
                          if (knownHeaders.any((h) => privateKey.startsWith(h))) {
                            setState(() {
                              _fileSelected = true;
                              _showPrivateKey = false;
                              _privateKeyFileController.text = privateKey;
                            });
                            _isPrivateKeyValid = true;
                            _connection.privateKey = privateKey;
                          }
                          else {
                            _isPrivateKeyValid = false;
                          }
                        }
                        catch (e) {
                          print('bonga');
                          setState(() {
                            _fileSelected = true;
                            _showPrivateKey = true;
                            _privateKeyFileController.text = 'Invalid private key file';
                          });
                          _isPrivateKeyValid = false;
                        }
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Private Key File',
                      suffixIcon: _fileSelected ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _showPrivateKey = !_showPrivateKey),
                            icon: _showPrivateKey ? Icon(Icons.visibility) : Icon(Icons.visibility_off)
                          ),
                          IconButton(
                            onPressed: () => setState(() { 
                              _fileSelected = false;
                              _privateKeyFileController.clear();
                            }),
                            icon: Icon(Icons.remove)
                          ),
                        ],
                      ) : null
                    ),
                    validator: (value) {
                      if (_privateKeyFileController.text.isEmpty && _passwordController.text.isEmpty) {
                        return 'At least provide one of these';
                      }
                      if (!_isPrivateKeyValid) {
                        return 'Invalid private key file';
                      }
                      return null;
                    }
                  ),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => _showPassword = !_showPassword),
                        icon: _showPassword ? Icon(Icons.visibility) : Icon(Icons.visibility_off)
                      )
                    ),
                    validator: (value) {
                      if (_privateKeyFileController.text.isEmpty && _passwordController.text.isEmpty) {
                        return 'At least provide one of these';
                      }
                      return null;
                    },
                    onSaved: (value) => _connection.password = value,
                  ),
                  CheckboxListTile(
                    title: Text('Enable Encryption'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                    value: _connection.isEncryptionEnabled ?? true,
                    onChanged: (value) => setState(() => _connection.isEncryptionEnabled = value),
                  ),
                  CheckboxListTile(
                    title: Text('Set as Default Connection'),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(10)),
                    value: _connection.isDefault ?? false,
                    onChanged: (value) => setState(() => _connection.isDefault = value),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() == true) {
                        _formKey.currentState?.save();
                        assert(_connection.assertComplete());
                        final storage = FlutterSecureStorage();
                        await storage.write(key: _connection.host!, value: _connection.toJson);
                        widget.updateConnectionList();
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text(widget.initialState == null ? 'Add Connection' : 'Save')
                  )
                ],
              )
            ),
          ),
        ),
      ),
    );
  }
}

