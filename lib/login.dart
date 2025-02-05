import 'package:flutter/material.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final fromKey = GlobalKey<FormState>();
  final gmailController = TextEditingController();
  final passwordController = TextEditingController();
  bool visibleP = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login"),
        centerTitle: true,
      ),
      backgroundColor: Color.fromRGBO(255, 255, 255, 0.937),
      body: SafeArea(
        child: SingleChildScrollView(
            child: Form(
                key: fromKey,
                child: Column(
                  children: [
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
                                onTap: () {
                                  setState(() {});
                                },
                                child: Text(
                                  "Create a new user account",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
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
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: TextFormField(
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
                    SizedBox(height: 10),
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
                          } else if (value.length < 8) {
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
                          SizedBox(height: 10),
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
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        if (fromKey.currentState!.validate()) {
                          print(gmailController.text);
                        }
                      },
                      child: Text('Confirm'),
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
                      onPressed: () {},
                      child: Text('Confirm'),
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
