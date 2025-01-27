import 'package:flutter/material.dart';

class LandPage extends StatelessWidget {
  final String getUsername;
  final String getPassword;
  final bool getCheck;

  const LandPage(
   {super.key, required this.getUsername, required this.getPassword, required this.getCheck});

  

  @override
  Widget build(BuildContext context) {
   
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Text('Landing Page'),

            Text(getUsername),
            Text(getPassword),
            Text(getCheck.toString())
          ],
        ),
      ),
    );
  }
}
