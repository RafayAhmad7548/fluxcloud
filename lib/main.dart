import 'package:flutter/material.dart';
import 'package:fluxcloud/sftp_connection_list.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.light
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark
      ),
      themeMode: ThemeMode.system,
      color: Color(0x002EC1EB),
      home: SftpConnectionList()
    );
  }
}

SnackBar buildErrorSnackBar(BuildContext context, String error) {
  return SnackBar(
    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
    behavior: SnackBarBehavior.floating,
    content: Row(
      spacing: 10,
      children: [
        Icon(Icons.error, color: Colors.red,),
        Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),),
      ],
    )
  );
}
