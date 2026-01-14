import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:flutter_application_1/screen/Auth_Page.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class editProfilePage extends StatefulWidget {
  const editProfilePage({super.key});

  @override
  State<editProfilePage> createState() => _editProfilePageState();
}

class _editProfilePageState extends State<editProfilePage> {
  final _formKey = GlobalKey<FormState>();

  bool visiblePassCon = false;
  bool visiblePassCon1 = false;
  bool visiblePassCon2 = false;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController newEmailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController conNewPasswordController =
      TextEditingController();
  final TextEditingController postalController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController birthdateController = TextEditingController();

  String? selectedGender;
  bool subscribeNewsletter = false;
  bool acceptTerms = false;
  DateTime? selectedBirthdate;

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
        nameController.text = userDoc['name'] ?? '';
        emailController.text = user.email ?? ''; // ✅ ดึงจาก Authentication
        postalController.text = userDoc['postal'] ?? '';
        phoneController.text = userDoc['phone'] ?? '';
        selectedGender = userDoc['gender'] ?? '';
        subscribeNewsletter = userDoc['subscribeNewsletter'] ?? false;
        acceptTerms = userDoc['acceptTerms'] ?? false;

        // ✅ จัดการ birthdate ให้ถูกต้อง
        if (userDoc['birthdate'] != null) {
          if (userDoc['birthdate'] is Timestamp) {
            selectedBirthdate = (userDoc['birthdate'] as Timestamp).toDate();
            birthdateController.text = selectedBirthdate!.toIso8601String();
          } else if (userDoc['birthdate'] is String) {
            selectedBirthdate = DateTime.parse(userDoc['birthdate']);
            birthdateController.text = selectedBirthdate!.toIso8601String();
          }
        }
      });
    }
  }
}

  void _showSuccessMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(message: message),
      displayDuration: Duration(seconds: 2),
    );
  }

  void _showInfoMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(message: message),
      displayDuration: Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
      displayDuration: Duration(seconds: 3),
    );
  }

  // ✅ ฟังก์ชันเลือกวันเกิด
  Future<void> selectBirthdate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedBirthdate ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedBirthdate) {
      setState(() {
        selectedBirthdate = picked;
        // ✅ แก้ให้แสดง format ที่ถูกต้องพร้อม timestamp
        birthdateController.text =
            picked.toIso8601String(); // "2025-03-03T00:00:00.000"
      });
    }
  }

  // ✅ ฟังก์ชันแก้ไขโปรไฟล์ (ลบข้อมูลเก่าแล้วเพิ่มข้อมูลใหม่)
  Future<void> editUserProfile({
  required String name,
  required String email,
  required String postal,
  required String phone,
  required String birthdate,
  required String? selectedGender,
  required bool subscribeNewsletter,
  required bool acceptTerms,
  String? newEmail,
  String? currentPassword,
  String? newPassword,
}) async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception("User not logged in");

  String uid = user.uid;
  String finalEmail = user.email ?? email; // ✅ ดึงอีเมลจาก Authentication

  try {
    // ✅ 1. ดึงข้อมูลเก่าจาก Firestore
    DocumentSnapshot oldData =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (!oldData.exists) {
      throw Exception("User data not found in Firestore");
    }

    print("✅ Old data found: ${oldData.data()}");

    // ✅ 2. หากมีการเปลี่ยนอีเมล ต้องยืนยันตัวตนก่อน
    if (newEmail != null && newEmail.isNotEmpty && newEmail != user.email) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception(
            "Please enter your current password to verify your identity.");
      }
      await reauthenticateUser(user.email!, currentPassword);
      
      // ✅ อัพเดทอีเมลใน Firebase Authentication
      await user.verifyBeforeUpdateEmail(newEmail);
      finalEmail = newEmail; // ✅ เก็บอีเมลใหม่
      
      _showInfoMessage("Please check your new email to verify the change.");
    }

    // ✅ 3. หากมีการเปลี่ยนรหัสผ่าน
    if (newPassword != null && newPassword.isNotEmpty) {
      if (currentPassword == null || currentPassword.isEmpty) {
        throw Exception(
            "Please enter your current password to change password.");
      }
      await reauthenticateUser(user.email!, currentPassword);
      
      // ✅ อัพเดทรหัสผ่านใน Firebase Authentication
      await user.updatePassword(newPassword);
    }

    // ✅ 4. อัพเดทข้อมูลใน Firestore (ใช้ update แทน delete + set)
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'acceptTerms': acceptTerms,
        'birthdate': birthdate,
        'confirmPassword': newPassword ?? oldData['confirmPassword'] ?? '',
        'createdAt': oldData['createdAt'] ?? FieldValue.serverTimestamp(),
        'email': newEmail?.isNotEmpty == true ? newEmail : email,
        'gender': selectedGender ?? '',
        'name': name.trim(),
        'password': newPassword ?? oldData['password'] ?? '',
        'phone': phone.trim(),
        'postal': postal.trim(),
        'subscribeNewsletter': subscribeNewsletter,
        'uid': uid,
      });

    print("✅ Data updated in Firestore");
    print("✅ Email in Firestore: $finalEmail");
    print("✅ Email in Authentication: ${user.email}");

    _showSuccessMessage("Profile updated successfully 🎉");
  } on FirebaseAuthException catch (e) {
    _showError("Firebase Auth Error: ${e.message} ❌");
    rethrow;
  } catch (e) {
    _showError("Error: $e ❌");
    rethrow;
  }
}

  // ✅ ฟังก์ชันยืนยันตัวตนใหม่ด้วยอีเมลและรหัสผ่าน
  Future<void> reauthenticateUser(String email, String password) async {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        AuthCredential credential =
            EmailAuthProvider.credential(email: email, password: password);

        await FirebaseAuth.instance.currentUser!
            .reauthenticateWithCredential(credential);

        print("✅ Reauthentication successful");
      } else {
        throw FirebaseAuthException(
            code: 'no-user', message: 'No user is logged in');
      }
    } on FirebaseAuthException catch (e) {
      print('❌ Reauthentication failed: ${e.message}');

      _showError(
          "Authentication failed: ${e.message}. Please check your password.");
      rethrow;
    } catch (e) {
      print('❌ Error: $e');
      rethrow;
    }
  }

  // ✅ ฟังก์ชันส่งข้อมูลที่แก้ไขแล้วไปยัง Firebase
  void submitEdit() async {
    // ตรวจสอบว่ารหัสผ่านใหม่และยืนยันรหัสผ่านตรงกันหรือไม่
    if (newPasswordController.text.isNotEmpty &&
        conNewPasswordController.text.isNotEmpty) {
      if (newPasswordController.text != conNewPasswordController.text) {
        _showInfoMessage("New password and confirm password do not match! ❌");
        return;
      }
    }

    try {
      await editUserProfile(
        name: nameController.text,
        email: emailController.text,
        postal: postalController.text,
        phone: phoneController.text,
        birthdate: birthdateController.text,
        selectedGender: selectedGender,
        subscribeNewsletter: subscribeNewsletter,
        acceptTerms: acceptTerms,
        newEmail:
            newEmailController.text.isNotEmpty ? newEmailController.text : null,
        currentPassword:
            passwordController.text.isNotEmpty ? passwordController.text : null,
        newPassword: newPasswordController.text.isNotEmpty
            ? newPasswordController.text
            : null,
      );

      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => authPage()));
    } catch (e) {
      print("❌ Error in submitEdit: $e");
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

                  // Username
                  TextFormField(
                    controller: nameController,
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
                      if (value == null || value.isEmpty) {
                        return "Please input username.";
                      } else if (value.length < 10 || value.length > 30) {
                        return "The username should be between 10-30 characters";
                      } else if (!editNameRegex1.hasMatch(value)) {
                        return "Invalid username format: \nMr. Jake Smith / Ms. Emma Olivia";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Current Email
                  TextFormField(
                    controller: emailController,
                    enabled: false,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'Current Email',
                    ),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white70
                            : Colors.black54),
                  ),
                  SizedBox(height: 15),

                  // New Email
                  TextFormField(
                    controller: newEmailController,
                    maxLength: 50,
                    decoration: InputDecoration(
                      labelText: 'New Email (Optional)',
                    ),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: InputDecoration(labelText: "Phone Number"),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    validator: (value) {
                      final RegExp phoneRegex = RegExp(r'^0[0-9]{9}$');
                      if (value == null || value.isEmpty) {
                        return "Please input phone number";
                      } else if (!phoneRegex.hasMatch(value)) {
                        return "Invalid phone format: 0890489858";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Birthdate
                  TextFormField(
                    controller: birthdateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: "Birthdate",
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    onTap: selectBirthdate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Please select birthdate";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Postal Code
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
                      final RegExp postalRegex = RegExp(r'^[0-9]{5}$');
                      if (value == null || value.isEmpty) {
                        return "Please input postal code";
                      } else if (!postalRegex.hasMatch(value)) {
                        return "Invalid postal code format: 10270";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Gender
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

                  // Current Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: !visiblePassCon,
                    maxLength: 20,
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
                      if ((newEmailController.text.isNotEmpty ||
                              newPasswordController.text.isNotEmpty) &&
                          (value == null || value.isEmpty)) {
                        return "Please enter current password to make changes.";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // New Password
                  TextFormField(
                    controller: newPasswordController,
                    obscureText: !visiblePassCon1,
                    maxLength: 20,
                    decoration: InputDecoration(
                        labelText: 'New Password (Optional)',
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
                      if (value == null || value.isEmpty) {
                        return null;
                      }
                      final RegExp passwordRegex = RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                      if (!passwordRegex.hasMatch(value)) {
                        return "Password must contain uppercase, lowercase, number, and special character";
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Confirm New Password
                  TextFormField(
                    controller: conNewPasswordController,
                    obscureText: !visiblePassCon2,
                    maxLength: 20,
                    decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        suffixIcon: GestureDetector(
                          onTap: () {
                            setState(() {
                              visiblePassCon2 = !visiblePassCon2;
                            });
                          },
                          child: visiblePassCon2
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off),
                        )),
                    style: TextStyle(
                        color: themeProvider.themeMode == ThemeMode.dark
                            ? Colors.white
                            : Colors.black),
                    validator: (value) {
                      if (newPasswordController.text.isNotEmpty) {
                        if (value == null || value.isEmpty) {
                          return "Please confirm your new password.";
                        }
                        if (value != newPasswordController.text) {
                          return "Passwords do not match!";
                        }
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),

                  // Subscribe Newsletter
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

                  // Accept Terms
                  CheckboxListTile(
                    title: Text("Accept terms and conditions"),
                    value: acceptTerms,
                    onChanged: (bool? value) {
                      setState(() {
                        acceptTerms = value!;
                      });
                    },
                  ),
                  SizedBox(height: 15),

                  // Confirm Button
                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (!acceptTerms) {
                          _showInfoMessage(
                              "Please accept terms and conditions");

                          return;
                        }
                        submitEdit();
                      }
                    },
                    child: Text(
                      'Confirm',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
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
