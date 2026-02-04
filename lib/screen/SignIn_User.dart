import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/signup_user.dart';
import 'package:flutter_application_1/screen/auth_page.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000'; // สำหรับ Android Emulator
  } else if (Platform.isIOS) {
    return 'http://localhost:8000'; // สำหรับ iOS Simulator
  } else {
    return 'http://localhost:8000';
  }
}

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool visibleP = false;

  void signUserIn() async {
    try {

     await FirebaseAuth.instance.signOut();

    UserCredential userCredential =
        await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );

    final user = userCredential.user;
    final idToken = await user!.getIdToken(true);
    
    final uri = Uri.parse('${getBaseUrl()}/api/auth/login');
    
    final response = await http.post(
      uri,
      headers: {
        "Authorization": "Bearer $idToken",
        "Content-Type": "application/json",
      },
    );
    if (response.statusCode != 200) {
      throw Exception("Backend login failed: ${response.body}");
    }

      if (!mounted) return;

      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "Login successful!",
        ),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => authPage()),
        );
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided.';
          break;
        default:
          errorMessage = e.message ?? 'Login failed';
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

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
            ? Color.fromRGBO(0, 0, 0, 0.933)
            : Color.fromRGBO(255, 255, 255, 0.933),
        body: SafeArea(
          child: SingleChildScrollView(
              child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.cancel_outlined),
                            iconSize: 30,
                          )
                        ],
                      ),
                      Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            color: themeProvider.themeMode == ThemeMode.dark
                                ? Color.fromRGBO(255, 255, 255, 0.929)
                                : Color.fromRGBO(0, 0, 0, 0.929),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.themeMode ==
                                            ThemeMode.dark
                                        ? Color.fromRGBO(0, 0, 0, 1)
                                        : Color.fromRGBO(255, 255, 255, 1),
                                  ),
                                ),
                                GestureDetector(
                                    child: TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              PageRouteBuilder(
                                                  pageBuilder: (context,
                                                          animation,
                                                          secondaryAnimation) =>
                                                      regisUser(),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    const begin =
                                                        Offset(1.0, 0.0);
                                                    const end =
                                                        Offset(0.0, 0.0);
                                                    const curve =
                                                        Curves.easeInOut;
                                                    var tween = Tween(
                                                            begin: begin,
                                                            end: end)
                                                        .chain(CurveTween(
                                                            curve: curve));
                                                    return SlideTransition(
                                                      position: animation
                                                          .drive(tween),
                                                      child: child,
                                                    );
                                                  })).then((_) {});
                                        },
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          minimumSize: const Size(180, 40),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          "Create a new user account",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: themeProvider.themeMode ==
                                                    ThemeMode.dark
                                                ? Colors.white
                                                : Colors.black,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ))),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 1,
                          ),
                          Container(
                            padding: EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Login by email and password"),
                                Icon(Icons.announcement_sharp)
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 1,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Please Specify*",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 72, 169, 169)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: emailController,
                          autofocus: true,
                          maxLength: 50,
                          decoration: InputDecoration(
                            labelText: 'Email',
                          ),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp emailLoginRegex1 = RegExp(
                                r'^(?=.*[a-zA-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                            final RegExp emailLoginRegex2 = RegExp(r'^\S+$');

                            if (value!.isEmpty) {
                              return "Please input email.";
                            } else if (value.length < 15 || value.length > 50) {
                              return '''The email should be between 15-50 characters''';
                            } else if (!emailLoginRegex1.hasMatch(value)) {
                              return 'Invalid email format: \nUser1@example.com, person1@example.co.th';
                            } else if (!emailLoginRegex2.hasMatch(value)) {
                              return 'The email format ${value} is invalid.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: TextFormField(
                          controller: passwordController,
                          obscureText: !visibleP,
                          maxLength: 20,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    visibleP = !visibleP;
                                  });
                                },
                                child: visibleP
                                    ? Icon(Icons.visibility)
                                    : Icon(Icons.visibility_off),
                              )),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp passwordLoginRegex1 = RegExp(
                                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                            final RegExp passwordLoginRegex2 = RegExp(r'^\S+$');

                            if (value == null || value.isEmpty) {
                              return "Please input password.";
                            } else if (value.length < 5 || value.length > 20) {
                              return '''The password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                            } else if (!passwordLoginRegex1.hasMatch(value)) {
                              return "Invalid password format: \nP@ssw0rd, P@ssw0rd";
                            } else if (!passwordLoginRegex2.hasMatch(value)) {
                              return 'The password format ${value} is invalid.';
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                child: GestureDetector(
                                  onTap: () {},
                                  child: Text(
                                    "Terms of Use",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 5),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: GestureDetector(
                                onTap: () {},
                                child: Text(
                                  "Privacy Policy",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            signUserIn();
                          }
                        },
                        child: Text('Confirm'),
                      ),
                      SizedBox(height: 10),
                      Center(
                        child: Text('Or continue with'),
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              signInWithGoogle();
                            },
                            child: CircleAvatar(
                              radius: 20,
                              child: Icon(Icons.g_mobiledata),
                            ),
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                      SizedBox(height: 10),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Forgot password",
                              style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(15),
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Color.fromRGBO(255, 255, 255, 0.929)
                            : Color.fromRGBO(0, 0, 0, 0.929),
                        child: Center(
                          child: Text(
                            "Create a new user account",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Color.fromRGBO(0, 0, 0, 1)
                                  : Color.fromRGBO(255, 255, 255, 1),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                            "Create an account for convenient use and faster payment."),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              PageRouteBuilder(
                                  pageBuilder: (context, animation,
                                          secondaryAnimation) =>
                                      regisUser(),
                                  transitionsBuilder: (context, animation,
                                      secondaryAnimation, child) {
                                    const begin = Offset(1.0, 0.0);
                                    const end = Offset(0.0, 0.0);
                                    const curve = Curves.easeInOut;
                                    var tween = Tween(begin: begin, end: end)
                                        .chain(CurveTween(curve: curve));
                                    return SlideTransition(
                                      position: animation.drive(tween),
                                      child: child,
                                    );
                                  })).then((_) {});
                        },
                        child: Text('Create'),
                      ),
                      SizedBox(height: 20),
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Divider(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Color.fromRGBO(255, 255, 255, 0.929)
                                  : Color.fromRGBO(0, 0, 0, 0.929),
                              height: 2)),
                      SizedBox(height: 5),
                      Container(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("All rights reserved."),
                              Icon(
                                Icons.copyright_rounded,
                              ),
                              Text(
                                "ABC_Shop (Thailand)",
                              )
                            ],
                          )),
                    ],
                  ))),
        ),
      ),
    );
  }
}
