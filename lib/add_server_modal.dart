import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
                    'Add Server',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 18),
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Host',
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'This value is required' : null
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
                    }
                  ),
                  TextFormField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'This value is required' : null
                  ),
                  TextFormField(
                    controller: _privateKeyFileController,
                    readOnly: true,
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.platform.pickFiles();
                      if (result != null) {
                        setState(() => _fileSelected = true);
                        _privateKeyFileController.text = result.files.single.name;
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
                    }
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _formKey.currentState?.validate();
                    },
                    child: Text('Submit')
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

