import 'package:flutter/material.dart';

class authPage extends StatelessWidget {
  const authPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Firebase Auth', style: TextStyle(color: Colors.white)),
        ),
        actions: [Icon(Icons.help, color: Colors.white)],
        backgroundColor: Color.fromRGBO(40, 84, 48, 1),
      ),
    );
  }
}
