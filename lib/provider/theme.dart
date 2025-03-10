import 'package:flutter/material.dart';

class AppThemes {
  // (Light Theme)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Color.fromARGB(15, 0, 0, 0),
    scaffoldBackgroundColor: Color.fromARGB(15, 0, 0, 0),
    colorScheme: ColorScheme.light(
      primary: Colors.black,      // สีหลัก
      onPrimary: Colors.white,   // สีของข้อความบน primary
      secondary: Colors.orange,  // สีรอง
      onSecondary: Colors.white, 
     
      surface: Colors.white,
      onSurface: Colors.black,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
  );

  // (Dark Theme)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color.fromARGB(21, 255, 255, 255),
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      onPrimary: Colors.white,
      secondary: Colors.deepPurple,
      onSecondary: Colors.white,
 
      surface: Colors.black,
      onSurface: Colors.white,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
  );
}