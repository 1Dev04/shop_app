import 'package:flutter/material.dart';


import 'package:flutter_application_1/provider/Theme_Provider.dart';
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

        // iconTheme: const IconThemeData(),
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
                        'Dark mode',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 10), //  Padding ครอบ Switch
                      child: Switch(
                        value: themeProvider.themeMode == ThemeMode.dark,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                        activeThumbColor: Color.fromRGBO(18, 195, 9, 1), // ON
                        activeTrackColor: Color.fromRGBO(
                            18, 195, 9, 0.5), // background color toggle (ON)
                        inactiveThumbColor: Colors.grey, // OFF
                        inactiveTrackColor:
                            Colors.grey.shade400, // background color toggle (OFF)
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      
    );
  }
}
