import 'package:flutter/material.dart';

class AppThemes {
  // (Light Theme)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: Colors.black12, // button Menu
    scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255), //backgound body
    colorScheme: ColorScheme.light(
      primary: Colors.black, // icon  footer
      onPrimary: Colors.white, // floatNavigation
      secondary: Colors.black87,
      onSecondary: Colors.white, // Text button change
      surface: Colors.black, // background Button and BarHeader
      onSurface: Colors.grey, // Text BarHeader
      error: Colors.red,
      onError: Colors.red,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black12), // background Nottification
      bodyMedium: TextStyle(color: Colors.black), // Main Text
      titleLarge: TextStyle(
          color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    appBarTheme: AppBarTheme(
      // Header AppBar
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 4,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.red),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Color.fromARGB(255, 72, 169, 169),
        side: BorderSide(color: Colors.deepOrange),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
    ),
    iconTheme: IconThemeData(color: Colors.black, size: 24), // icon footer
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.transparent,
      labelStyle: TextStyle(color: Colors.black),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.black)),
    ),

    cardTheme: CardTheme(
      color: Colors.deepOrangeAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: TextStyle(color: Colors.black),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.white,
      thickness: 1,
    ),
  );

  // (Dark Theme)
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color.fromARGB(21, 255, 255, 255),
    scaffoldBackgroundColor: Colors.grey[900],
    colorScheme: ColorScheme.dark(
      primary: Colors.white, // icon  footer
      onPrimary: Colors.black, // floatNavigation
      secondary: Colors.white70,
      onSecondary: Colors.black, // Text button change
      surface: Colors.white, // background Button and BarHeader
      onSurface: Colors.grey, // Text BarHeader
      error: Colors.red,
      onError: Colors.red,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white38), // background Nottification
      bodyMedium: TextStyle(color: Colors.white), // Main Text
      titleLarge: TextStyle(
          color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
    ),
    appBarTheme: AppBarTheme(
      // Header AppBar
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      elevation: 4,
      centerTitle: false,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
          fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Colors.red),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.amberAccent,
        side: BorderSide(color: Colors.deepOrange),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white, size: 24), // icon footer
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
       fillColor: Colors.transparent,
      labelStyle: TextStyle(color: Colors.white),
      
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white)),
    ),

    cardTheme: CardTheme(
      color: Colors.deepOrangeAccent,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.black,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    dividerTheme: DividerThemeData(
      color: Colors.black,
      thickness: 1,
    ),
    
  );
}
