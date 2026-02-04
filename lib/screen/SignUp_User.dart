import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/auth_page.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
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

class regisUser extends StatefulWidget {
  const regisUser({super.key});

  @override
  State<regisUser> createState() => _regisUserState();
}

class _regisUserState extends State<regisUser> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController postalController = TextEditingController();
  DateTime? selectedDate;
  String? selectedGender;
  bool subscribeNewsletter = false;
  bool acceptTerms = false;
  bool visiblePassCon = false;
  bool visiblePassCon1 = false;

  Future<void> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
        context: context, firstDate: DateTime(1900), lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void submitForm() {
    if (_formKey.currentState!.validate() && acceptTerms) {
      print("Name: ${nameController}");
      print("Gmail: ${emailController}");
      print("Phone: ${phoneController}");
      print("Postal Code: ${postalController}");
      print("Date: ${selectedDate}");
      print("Gender: ${selectedGender}");
      print("Subscribe to the newsletter: ${subscribeNewsletter}");
      print("Accepts Terms: ${acceptTerms}");
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.success(
          message: "Membership registration successful!",
        ),
      );
    } else {
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: "Please>> Fill in the information completely.",
        ),
      );
    }
  }

  void signUserUp() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator.adaptive(
            backgroundColor: Colors.white,
            valueColor:
                AlwaysStoppedAnimation<Color>(Color.fromARGB(75, 50, 50, 50)),
          ),
        );
      },
    );

    try {
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Password do not match")),
        );

        return;
      }

      var querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: emailController.text.trim())
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This email is already registered")),
        );
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      final user = userCredential.user;
      final idToken = await user!.getIdToken(true);

      final uri = Uri.parse('${getBaseUrl()}/api/auth/register');

      final response = await http.post(
        uri,
        headers: {
          "Authorization": "Bearer $idToken",
          "Content-Type": "application/json",
        },
      );
      if (response.statusCode != 200) {
        throw Exception("Backend register failed: ${response.body}");
      }

      if (!mounted) return;

      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'password': passwordController.text.trim(),
        'confirmPassword': confirmPasswordController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'postal': postalController.text.trim(),
        'gender': selectedGender ?? "",
        'birthdate': selectedDate?.toIso8601String() ?? "",
        'subscribeNewsletter': subscribeNewsletter,
        'acceptTerms': acceptTerms,
        'createdAt': FieldValue.serverTimestamp()
      });

      Navigator.pop(context);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => authPage()));
      print("Successfully Registered");
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);
      print("An error occurred ${e.message}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}')),
      );
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
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
        body: Container(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.arrow_back),
                      iconSize: 30,
                    )
                  ],
                ),
                Container(
                    width: double.infinity,
                    height: 80,
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create a new accout',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          GestureDetector(
                              onTap: () {
                                setState(() {});
                              },
                              child: Icon(Icons.lock)),
                        ],
                      ),
                    )),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            "You will receive a confirmation email to the email address you entered below. Please check your inbox.",
                            style: TextStyle(),
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                        SizedBox(
                          width: 40,
                        ),
                        Text(
                          "Please specify*",
                          style: TextStyle(
                              color: Color.fromARGB(255, 72, 169, 169)),
                        ),
                      ]),
                ),
                SizedBox(height: 10),
                Container(
                  margin: EdgeInsets.all(10),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          maxLength: 30,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                          ),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp nameRegex1 = RegExp(
                                r'^(Mr|Ms)\. [A-Z][a-z]+(?: [A-Z][a-z]+)*(\.?)$');
                            final RegExp nameRegex2 =
                                RegExp(r'^(?!.*\s{2,})(?:\S+\s?){1,3}$');

                            if (value == null || value.isEmpty) {
                              return "Please input username.";
                            } else if (value.length < 10 || value.length > 30) {
                              return "The username should be between 10-30 characters";
                            } else if (!nameRegex1.hasMatch(value)) {
                              return "Invalid username format: \nMr. Jake Smith / Ms. Emma Olivia";
                            } else if (!nameRegex2.hasMatch(value)) {
                              return "The username format ${value} is invalid.";
                            }

                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: emailController,
                          autofocus: true,
                          maxLength: 50,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                          ),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp emailRegExp1 = RegExp(
                                r'^(?=.*[a-zA-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                            final RegExp emailRegExp2 = RegExp(r'^\S+$');

                            if (value == null || value.isEmpty) {
                              return "Please input email.";
                            } else if (value.length < 15 || value.length > 50) {
                              return '''The email should be between 15-50 characters.''';
                            } else if (!emailRegExp1.hasMatch(value)) {
                              return 'Invalid email format: \nUser1@example.com, person1@example.co.th';
                            } else if (!emailRegExp2.hasMatch(value)) {
                              return 'The email format ${value} is invalid.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: passwordController,
                          obscureText: !visiblePassCon,
                          maxLength: 20,
                          decoration: InputDecoration(
                              labelText: 'Password',
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    visiblePassCon = !visiblePassCon;
                                  });
                                },
                                child: visiblePassCon
                                    ? Icon(Icons.visibility)
                                    : Icon(Icons.visibility_off),
                              )),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp passwordRegex1 = RegExp(
                                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                            final RegExp passwordRegex2 = RegExp(r'^\S+$');
                            if (value == null || value.isEmpty) {
                              return "Please input password.";
                            } else if (value.length < 5 || value.length > 20) {
                              return '''The password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                            } else if (!passwordRegex1.hasMatch(value)) {
                              return "Invalid password format: \nP@ssw0rd, P@ssw0rd";
                            } else if (!passwordRegex2.hasMatch(value)) {
                              return 'The password format ${value} is invalid.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: !visiblePassCon1,
                          maxLength: 20,
                          decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              suffixIcon: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    visiblePassCon1 = !visiblePassCon1;
                                  });
                                },
                                child: visiblePassCon1
                                    ? Icon(Icons.visibility)
                                    : Icon(Icons.visibility_off),
                              )),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp conpasswordRegex1 = RegExp(
                                r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                            final RegExp conpasswordRegex2 = RegExp(r'^\S+$');

                            if (value == null || value.isEmpty) {
                              return "Please input confirm password.";
                            } else if (value.length < 5 || value.length > 20) {
                              return '''The confirm password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                            } else if (!conpasswordRegex1.hasMatch(value)) {
                              return "Invalid confirm password format: \nP@ssw0rd, P@ssw0rd";
                            } else if (!conpasswordRegex2.hasMatch(value)) {
                              return 'The password format ${value} is invalid.';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: InputDecoration(
                            labelText: "Phone Number",
                          ),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp phoneRegex1 = RegExp(r'^[0-9]{10}$');
                            final RegExp phoneRegex2 =
                                RegExp(r'^(?!.*(\d)\1{2})\d{10}$');

                            if (value == null || value.isEmpty) {
                              return "Please input password";
                            } else if (value.length != 10) {
                              return "Please enter a 10-digit phone number.";
                            } else if (!phoneRegex1.hasMatch(value)) {
                              return "Invalid phone number format: \n0123456789, 0987654321";
                            } else if (!phoneRegex2.hasMatch(value)) {
                              return "The number format ${value} is invalid.";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        TextFormField(
                          controller: postalController,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          decoration: InputDecoration(labelText: "Postal Code"),
                          style: TextStyle(
                              color: themeProvider.themeMode == ThemeMode.dark
                                  ? Colors.white
                                  : Colors.black),
                          validator: (value) {
                            final RegExp postalRegex1 = RegExp(r'^[0-9]{5}$');
                            final RegExp postalRegex2 = RegExp(r'^\d{5}$');

                            if (value == null || value.isEmpty) {
                              return "Please input postal code";
                            } else if (value.length != 5) {
                              return "Please enter a 5-digit postal code.";
                            } else if (!postalRegex1.hasMatch(value)) {
                              return "Invalid postal code format: 01234, 12345";
                            } else if (!postalRegex2.hasMatch(value)) {
                              return "The postal code format ${value} is invalid.";
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 15),
                        ListTile(
                          title: Text(
                            selectedDate == null
                                ? "Select Brithday"
                                : "Date: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
                          ),
                          trailing: Icon(Icons.calendar_today),
                          onTap: () => selectDate(context),
                        ),
                        SizedBox(height: 15),
                        Text("Gender"),
                        Row(
                          children: [
                            Radio(
                              value: "Men",
                              groupValue: selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value.toString();
                                });
                              },
                            ),
                            Text("Men"),
                            Radio(
                              value: "Women",
                              groupValue: selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value.toString();
                                });
                              },
                            ),
                            Text("Women"),
                            Radio(
                              value: "Not selected",
                              groupValue: selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  selectedGender = value.toString();
                                });
                              },
                            ),
                            Text("Not selected"),
                          ],
                        ),
                        SizedBox(height: 15),
                        CheckboxListTile(
                          title: Text("Subscribe to the newsletter"),
                          value: subscribeNewsletter,
                          onChanged: (bool? value) {
                            setState(() {
                              subscribeNewsletter = value!;
                            });
                          },
                        ),
                        SizedBox(height: 15),
                        CheckboxListTile(
                          title: Text("Accept the member agreement"),
                          value: acceptTerms,
                          onChanged: (bool? value) {
                            setState(() {
                              acceptTerms = value!;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              signUserUp();
                              submitForm();
                            }
                          },
                          child: Text(
                            'Sign Up',
                          ),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
