import 'package:flutter/material.dart';

import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:provider/provider.dart';

class Settingpage extends StatefulWidget {
  const Settingpage({super.key});

  @override
  State<Settingpage> createState() => _SettingpageState();
}

class _SettingpageState extends State<Settingpage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setting",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),

        centerTitle: true,
        //iconTheme: const IconThemeData(),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Theme mode',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Switch(
                    padding: EdgeInsets.symmetric(horizontal: 10), // Pad
                    activeColor: Color.fromRGBO(18, 195, 9, 1), // สีตอนเปิด

                    value: themeProvider.themeMode == ThemeMode.dark,
                    onChanged: (value) {
                      themeProvider.toggleTheme(value);
                    },
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
