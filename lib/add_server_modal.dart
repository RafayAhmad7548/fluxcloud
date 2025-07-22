import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluxcloud/user.dart';

class AddServerModal extends StatefulWidget {
  const AddServerModal({
    super.key,
  });

  @override
  State<AddServerModal> createState() => _AddServerModalState();
}

class _AddServerModalState extends State<AddServerModal> {

  final GlobalKey<FormState> _formKey = GlobalKey();
  
  final TextEditingController _privateKeyFileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _fileSelected = false;
  bool _showPassword = false;

  final Connection _connection = Connection();

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
                    'Add Connection',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 18),
                  ),
                  TextFormField(
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
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'This value is required' : null,
                    onSaved: (value) => _connection.username = value,
                  ),
                  TextFormField(
                    controller: _privateKeyFileController,
                    readOnly: true,
                    onTap: () async {
                      final XFile? result = await openFile();
                      if (result != null) {
                        setState(() => _fileSelected = true);
                        _privateKeyFileController.text = result.name;
                        _connection.privateKeyFilePath = result.path;
                      }
                    },
                    decoration: InputDecoration(
                      labelText: 'Private Key File',
                      suffixIcon: _fileSelected ? IconButton(
                        onPressed: () => setState(() { 
                          _fileSelected = false;
                          _privateKeyFileController.clear();
                        }),
                        icon: Icon(Icons.remove)
                      ) : null
                    ),
                    validator: (value) {
                      // TODO: validate the file to see if it is valid private key
                      if (_privateKeyFileController.text.isEmpty && _passwordController.text.isEmpty) {
                        return 'At least provide one of these';
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
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState?.validate() == true) {
                        _formKey.currentState?.save();
                        assert(_connection.assertComplete());
                        final storage = FlutterSecureStorage();
                        await storage.write(key: _connection.host!, value: _connection.toJson);
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      }
                    },
                    child: Text('Add Connection')
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

