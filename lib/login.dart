import 'package:flutter/material.dart';
import 'package:flutter_application_1/home.dart';
import './regisUser.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool visibleP = false;

  void signUserIn() async {
    showDialog(
        context: context,
        barrierDismissible: false, //Barrier Close
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      //Dialog Successfully
     
      print("Login Successfully!");

      //Next Page
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomePage()));
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      
      if (e.code == 'user-not-found') {
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        print('Wrong password provided for that user.');
      } else {
        print('Error: ${e.message}');
      }
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
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
                            icon: Icon(Icons.cancel_outlined))
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
                                "Please specify*",
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
                        autofocus: true,
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please input email.';
                          } else if (value.length > 30) {
                            return 'Email more than 30 characters.';
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
                        decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.password),
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
                            return '''The password should be between 8-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                          } else if (value.length > 20) {
                            return "Password more than 20 characters";
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
