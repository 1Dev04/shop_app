import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
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
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageProvider.translate(en: "Setting", th: "การตั้งค่า"),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
        ),
        centerTitle: true,
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
                      languageProvider.translate(
                          en: 'Theme Dark', th: 'ธีมมืด'),
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Switch(
                      value: themeProvider.themeMode == ThemeMode.dark,
                      onChanged: (value) {
                        themeProvider.toggleTheme(value);
                      },
                      activeThumbColor: Color.fromRGBO(18, 195, 9, 1),
                      activeTrackColor: Color.fromRGBO(18, 195, 9, 0.5),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

     
            Container(
              width: double.infinity,
              height: 70,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      languageProvider.translate(en: 'Language', th: 'ภาษา'),
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: GestureDetector(
                      onTap: () {
                        languageProvider.toggleLanguage();
                      },
                      child: Container(
                        width: 70,
                        height: 45,
                        decoration: BoxDecoration(
                        
                          color: languageProvider.isEnglish
                              ? Color.fromARGB(
                                  255, 222, 231, 255) 
                              : Color.fromARGB(
                                  255, 255, 215, 216),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            languageProvider.isEnglish ? '🇬🇧' : '🇹🇭',
                            style: TextStyle(fontSize: 28),
                          ),
                        ),
                      ),
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
