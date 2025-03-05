import 'package:flutter/material.dart';
import 'package:flutter_application_1/authPage.dart';

import './regisUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';

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
    showDialog(
        context: context,
        barrierDismissible: false, //Barrier Close
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator.adaptive(
              backgroundColor: Colors.white,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color.fromARGB(75, 50, 50, 50)),
            ),
          );
        });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Close Dialog before change page
      if (mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Login successful! 🎉")));
      //Home page
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => authPage()));
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context);

      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else {
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

  /*
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
  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(255, 255, 255, 0.937),
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
                            icon: Icon(Icons.cancel_outlined), iconSize: 30,)
                      ],
                    ),
                    Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          color: Color.fromARGB(15, 0, 0, 0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Login",
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold),
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
                                                  const end = Offset(0.0, 0.0);
                                                  const curve =
                                                      Curves.easeInOut;
                                                  var tween = Tween(
                                                          begin: begin,
                                                          end: end)
                                                      .chain(CurveTween(
                                                          curve: curve));
                                                  return SlideTransition(
                                                    position:
                                                        animation.drive(tween),
                                                    child: child,
                                                  );
                                                })).then((_) {});
                                      },
                                      child: Text(
                                        "Create a new user account",
                                        style: TextStyle(
                                            color: Colors.black,
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
                          labelText: 'E-mail',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please input password.";
                          } else if (value.length < 15) {
                            return '''The password should be between 15-50 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                          } else if (value.length > 50) {
                            return "Password more than 50 characters";
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
                        maxLength: 8,
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
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please input password.";
                          } else if (value.length < 3) {
                            return '''The password should be between 3-8 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                          } else if (value.length > 8) {
                            return "Password more than 8 characters";
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          signUserIn();
                        }
                      },
                      child: Text('Confirm'),
                    ),
                    /*
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
                            backgroundColor: Color.fromRGBO(25, 0, 0, 0.2),
                            child:
                                Icon(Icons.g_mobiledata, color: Colors.white),
                          ),
                        ),
                        SizedBox(width: 10),
                       
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
                        
                      ],
                    ),
                    */
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "Forgot password",
                            style: TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(15),
                      color: Color.fromARGB(15, 0, 0, 0),
                      child: Center(
                        child: Text(
                          "Create a new user account",
                          style: TextStyle(
                              fontSize: 25, fontWeight: FontWeight.bold),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        Navigator.push(
                            context,
                            PageRouteBuilder(
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
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
                        child: Divider(color: Colors.black26, height: 2)),
                    SizedBox(height: 5),
                    Container(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text("All rights reserved.",
                                style: TextStyle(color: Colors.black54)),
                            Icon(
                              Icons.copyright_rounded,
                              color: Colors.black54,
                            ),
                            Text("ABC_Shop (Thailand)",
                                style: TextStyle(color: Colors.black54))
                          ],
                        )),
                  ],
                ))),
      ),
    );
  }
}
