import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:flutter_application_1/screen/SignUp_User.dart';
import 'package:flutter_application_1/screen/Auth_Page.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
      // Sign out the user before sign in (to ensure a fresh session)
      await FirebaseAuth.instance.signOut();

      // Sign in with updated email and password
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Close Dialog before changing page
      if (mounted) Navigator.pop(context);

      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "Login successful!",
        ),
      );
      // Navigate to Home page
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => authPage()));
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);

      // Handle different error codes with a switch statement
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found for that email.';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided for that user.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  //---------- ฟังก์ชันสำหรับล็อกอินด้วย google account ----------
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

    // Obtain the auth details from the request
    final GoogleSignInAuthentication? googleAuth =
        await googleUser?.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    // Once signed in, return the UserCredential
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
                                                    const begin = Offset(1.0,
                                                        0.0); //Slide from right to left
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
                                        child: Text(
                                          "Create a new user account",
                                          style: TextStyle(
                                              color: themeProvider.themeMode ==
                                                      ThemeMode.dark
                                                  ? Color.fromRGBO(0, 0, 0, 0)
                                                  : Color.fromRGBO(
                                                      255, 255, 255, 1),
                                              fontWeight: FontWeight.bold),
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
                          /*
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color.fromRGBO(25, 0, 0, 0.2),
                            child: Icon(Icons.facebook, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Color.fromRGBO(25, 0, 0, 0.2),
                            child: Icon(Icons.apple, color: Colors.white),
                          ),
                          */
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
                                    const begin = Offset(
                                        1.0, 0.0); //Slide from right to left
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
