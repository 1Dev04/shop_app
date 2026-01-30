import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'firebase_options.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/provider/favorite_provider.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/auth_page.dart';
import 'package:provider/provider.dart';

import 'package:camera/camera.dart';

List<CameraDescription>? _availableCameras;

Future<void> initializeCameras() async {
  try {
    _availableCameras = await availableCameras();
    print('✅ Cameras initialized: ${_availableCameras?.length ?? 0}');
  } catch (e) {
    print('❌ Camera initialization error: $e');
    _availableCameras = [];
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeCameras();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: MyApp(), 
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return MaterialApp(
      
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: WelcomeScreen(), 
    );
  }
}


class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.themeMode == ThemeMode.dark
          ? Colors.black
          : Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CachedNetworkImage(
              imageUrl:
                  "https://res.cloudinary.com/dag73dhpl/image/upload/v1741695217/cat3_xvd0mu.png",
              width: 200,
              height: 200,
              placeholder: (context, url) => CircularProgressIndicator.adaptive(
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Color.fromARGB(75, 50, 50, 50),
                ),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            SizedBox(height: 30),
            Text(
              'ABC SHOP',
              style: TextStyle(
                fontSize: 50,
                fontFamily: 'Catfont',
              ),
            ),
            SizedBox(height: 10),
            Text(
              languageProvider.translate(
                en: 'Welcome!',
                th: 'ยินดีต้อนรับ!',
              ),
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => authPage()),
                );
              },
              child: Text(
                languageProvider.translate(
                  en: "Get Started",
                  th: "เริ่มต้น",
                ),
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}