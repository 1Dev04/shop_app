import 'package:flutter/material.dart';
//ติดตั้งแพคเกจ firebase_auth จาก http://pub.dev
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screen/Home_Page.dart';
import 'package:flutter_application_1/screen/SignIn_User.dart';

class authPage extends StatelessWidget {
  const authPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          //authStateChanges ตรวจสอบว่าผู้ใช้ล็อกอินหรือยัง
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            //Logged in ถ้าล็อกอินแล้วไปที่ homePage
            if (snapshot.hasData ) {
              return MyHome();
            } else {
              //NOT logged in ถ้ายังไม่ล็อกอินไปที่ loginPage
              return Login();
            }
          }),
    );
  }
}
