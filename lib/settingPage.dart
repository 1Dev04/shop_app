import 'package:flutter/material.dart';

class Settingpage extends StatefulWidget {
  const Settingpage({super.key});

  @override
  State<Settingpage> createState() => _SettingpageState();
}

class _SettingpageState extends State<Settingpage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.938), // ✅ ใช้สีดำตรงๆ
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}