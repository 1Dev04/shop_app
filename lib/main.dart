import 'package:flutter/material.dart';

//ติดตั้งแพคเกจ firebase_core จาก pub.dev
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/authPage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // เรียกใช้ Firebase ก่อนเริ่มแอป

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // เพิ่ม Provider
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: MyApp(),
      ),
    ),
  );
}

// ignore: must_be_immutable
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      home: Scaffold(
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
                    Color.fromARGB(75, 50, 50, 50)),
              ),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            SizedBox(height: 30),
            Text(
              'ABC_SHOP',
              style: TextStyle(
                fontSize: 50,
                fontFamily: 'Catfont',
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Welcome!',
              style: TextStyle(
                fontSize: 15,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    (MaterialPageRoute(builder: (context) => authPage())));
              },
              child: Text(
                "Get Started",
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            )
          ],
        )),
      ),
    );
  }
}
