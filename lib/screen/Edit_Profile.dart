import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:flutter_application_1/screen/Auth_Page.dart';
import 'package:provider/provider.dart';

class editProfilePage extends StatefulWidget {
  const editProfilePage({super.key});

  @override
  State<editProfilePage> createState() => _editProfilePageState();
}

class _editProfilePageState extends State<editProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool visiblePassCon = false;
  bool visiblePassCon1 = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();

  final TextEditingController postalController = TextEditingController();
  String? selectedGender;
  bool subscribeNewsletter = false;

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

// ✅ โหลดข้อมูลโปรไฟล์ผู้ใช้จาก Firestore
  void loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          nameController.text = userDoc['name'];
          emailController.text = userDoc['email'];
          passwordController.text = ''; // Do not load the password field
          postalController.text = userDoc['postal'];
          selectedGender = userDoc['gender'];
          subscribeNewsletter = userDoc['subscribeNewsletter'];
        });
      }
    }
  }

// ✅ ฟังก์ชันแก้ไขโปรไฟล์
  Future<void> editUserProfile({
    required String name,
    required String postal,
    required String? selectedGender,
    required bool subscribeNewsletter,
    String? newEmail,
    String? currentPassword,
    String? newPassword,
  }) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("User not logged in");

    String uid = user.uid;

    try {
      // ✅ หากมีการเปลี่ยนอีเมลหรือรหัสผ่าน ต้องทำการยืนยันตัวตนใหม่
      if (newEmail?.isNotEmpty ?? false) {
        if (newEmail != user.email) {
          // หากจะเปลี่ยนอีเมล ต้องใส่รหัสผ่านเดิมเพื่อยืนยันตัวตน
          if (currentPassword == null || currentPassword.isEmpty) {
            throw Exception(
                "Please enter your current password to verify your identity.");
          }
          await reauthenticateUser(user.email!, currentPassword);
          await user.verifyBeforeUpdateEmail(newEmail!);
          // Update email in Firestore
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'email': newEmail,
          });
        }
      }

      // ✅ หากมีการเปลี่ยนรหัสผ่าน
      if (newPassword?.isNotEmpty ?? false) {
        await user.updatePassword(newPassword!);
      }

      // ✅ อัปเดตข้อมูลโปรไฟล์ใน Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': name.trim(),
        'postal': postal.trim(),
        'gender': selectedGender ?? '',
        'subscribeNewsletter': subscribeNewsletter,
        'updatedAt': FieldValue.serverTimestamp(),
        if (newPassword?.isNotEmpty ?? false) 'password': newPassword,
      });

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Update profile successful! 🎉")));
    } on FirebaseAuthException catch (e) {
      throw ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error from Firebase Auth: ${e.message} ❌")));
    } catch (e) {
      throw SnackBar(content: Text("Error: ${e} ❌"));
    }
  }

// ฟังก์ชันยืนยันตัวตนใหม่ด้วยอีเมลและรหัสผ่าน
  Future<void> reauthenticateUser(String email, String password) async {
    AuthCredential credential =
        EmailAuthProvider.credential(email: email, password: password);
    await FirebaseAuth.instance.currentUser
        ?.reauthenticateWithCredential(credential);
  }

// ฟังก์ชันส่งข้อมูลที่แก้ไขแล้วไปยัง Firebase
  void submitEdit() async {
    
    try {
      await editUserProfile(
        name: nameController.text,
        postal: postalController.text,
        selectedGender: selectedGender,
        subscribeNewsletter: subscribeNewsletter,
        newEmail:
            newEmailController.text.isNotEmpty ? newEmailController.text : null,
        currentPassword:
            passwordController.text.isNotEmpty ? passwordController.text : null,
        newPassword: newPasswordController.text.isNotEmpty
            ? newPasswordController.text
            : null,
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => authPage()));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update Profile Successful! 🎉")),
      );
    } catch (e) {
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
        body: SingleChildScrollView(
          child: Container(
            margin: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 30),
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
                  Center(
                    child: Text("Edit Profile",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20)),
                  ),
                  SizedBox(height: 30),
                  TextFormField(
                    controller: emailController,
                    autofocus: true,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Current Email',
                    ),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    validator: (value) {
                      final RegExp editEmailLoginRegex1 = RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                      final RegExp editEmailLoginRegex2 = RegExp(r'^\S+$');

                      if (value!.isEmpty) {
                        return "Please input email.";
                      } else if (value.length < 15) {
                        return '''The email should be between 15-50 characters''';
                      } else if (value.length > 50) {
                        return "Password more than 50 characters";
                      } else if (!editEmailLoginRegex1.hasMatch(value)) {
                        return 'Invalid email format: \nUser1@example.com, Person1@example.co.th';
                      } else if (!editEmailLoginRegex2.hasMatch(value)) {
                        return 'The email format ${value} is invalid.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: newEmailController,
                    autofocus: true,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'New Email',
                    ),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    validator: (value) {
                      final RegExp editNewEmailLoginRegex1 = RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!\.]{8,20}$');
                      final RegExp editNewEmailLoginRegex2 = RegExp(r'^\S+$');

                      if (value!.isEmpty) {
                        return "Please input new email.";
                      } else if (value.length < 15) {
                        return '''The new email should be between 15-50 characters''';
                      } else if (value.length > 50) {
                        return "Password more than 50 characters";
                      } else if (!editNewEmailLoginRegex1.hasMatch(value)) {
                        return 'Invalid new email format: \nUser1@example.com, Person1@example.co.th';
                      } else if (!editNewEmailLoginRegex2.hasMatch(value)) {
                        return 'The new email format ${value} is invalid.';
                      }
                      return null;
                    },
                  ),

                  SizedBox(height: 15),
                  TextFormField(
                    controller: passwordController,
                    obscureText: !visiblePassCon,
                    maxLength: 10,
                    decoration: InputDecoration(
                        labelText: 'Current Password',
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
                      final RegExp editPasswordRegex1 = RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                      final RegExp editPasswordRegex2 = RegExp(r'^\S+$');

                      if (value == null || value.isEmpty) {
                        return "Please input confirm password.";
                      } else if (value.length < 5 || value.length > 20) {
                        return '''The confirm password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                      } else if (!editPasswordRegex1.hasMatch(value)) {
                        return "Invalid confirm password format: \nP@ssw0rd, P@ssw0rd";
                      } else if (!editPasswordRegex2.hasMatch(value)) {
                        return "The confirm password format ${value} is invalid.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !visiblePassCon1,
                    maxLength: 10,
                    decoration: InputDecoration(
                        labelText: 'New Password',
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
                      final RegExp editConPasswordRegex1 = RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                      final RegExp editConPasswordRegex2 = RegExp(r'^\S+$');
                      if (value == null || value.isEmpty) {
                        return "Please input confirm password.";
                      } else if (value.length < 5 || value.length > 20) {
                        return '''The confirm password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                      } else if (!editConPasswordRegex1.hasMatch(value)) {
                        return "Invalid confirm password format: \nP@ssw0rd, P@ssw0rd";
                      } else if (!editConPasswordRegex2.hasMatch(value)) {
                        return "The confirm password format ${value} is invalid.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
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
                      final RegExp editNameRegex1 = RegExp(
                          r'^(Mr|Ms)\. [A-Z][a-z]+(?: [A-Z][a-z]+)*(\.?)$');
                      final RegExp editNameRegex2 =
                          RegExp(r'^(?!.*\s{2,})(?:\S+\s?){1,3}$');
                      if (value == null || value.isEmpty) {
                        return "Please input username.";
                      } else if (value.length < 10 || value.length > 30) {
                        return "The username should be between 10-30 characters";
                      } else if (!editNameRegex1.hasMatch(value)) {
                        return "Invalid username format: \nMr. Jake Smith / Ms. Emma Olivia";
                      } else if (!editNameRegex2.hasMatch(value)) {
                        return "The username format ${value} is invalid.";
                      }

                      return null;
                    },
                  ),
                  SizedBox(
                    height: 15,
                  ),
                  // รหัสไปรษณีย์ (กรอกตัวเลข 5 ตัว)
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
                      final RegExp editPostalRegex1 = RegExp(r'^[0-9]{5}$');
                      final RegExp editPostalRegex2 = RegExp(r'^\d{5}$');
                      if (value == null || value.isEmpty) {
                        return "Please input postal code";
                      } else if (value.length != 5) {
                        return "Please enter a 5-digit postal code.";
                      } else if (!editPostalRegex1.hasMatch(value)) {
                        return "Invalid postal code format: 01234, 12345";
                      } else if (!editPostalRegex2.hasMatch(value)) {
                        return "The postal code format ${value} is invalid.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  // เพศ
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
                  // ยืนยันการสมัครรับจดหมายข่าว
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
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        submitEdit(); // เรียกฟังก์ชันอัปเดตข้อมูล
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
