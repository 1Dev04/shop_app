import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class editProfilePage extends StatefulWidget {
  const editProfilePage({super.key});

  @override
  State<editProfilePage> createState() => _editProfilePageState();
}

class _editProfilePageState extends State<editProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController postalController = TextEditingController();
  String? selectedGender;
  bool subscribeNewsletter = false;
  bool visiblePassCon = false;
  bool visiblePassCon1 = false;

  void submitEdit() {
    if (_formKey.currentState!.validate()) {
      print("Name: ${nameController}");
      print("Gmail: ${emailController}");
      print("Phone: ${phoneController}");
      print("Postal Code: ${postalController}");
      print("Gender: ${selectedGender}");
      print("Subscribe to the newsletter: ${subscribeNewsletter}");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Edit profile successful! 🎉")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please>> Fill in the information completely.")));
    }
  }

  void editUserProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      showDialog(
          context: context,
          barrierDismissible: false, //Barrier Close
          builder: (context) {
            return const Center(
              child: CircularProgressIndicator.adaptive(
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(
                    Color.fromARGB(75, 50, 50, 50)),
              ),
            );
          });

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (context.mounted) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
        return;
      }

      String uid = user.uid;
      String newEmail = emailController.text.trim();

      if (newEmail.isNotEmpty && newEmail != user.email) {
        try {
          await user.verifyBeforeUpdateEmail(newEmail);
          if (context.mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    "Verification email sent! Please confirm before updating.")),
          );
          return;
        } catch (e) {
          if (context.mounted) Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Email verification failed: $e")),
          );
          return;
        }
      }

      if (passwordController.text.trim().isNotEmpty &&
          passwordController.text.trim() ==
              confirmPasswordController.text.trim()) {
        await user.updatePassword(passwordController.text.trim());
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'name': nameController.text.trim(),
        'phone': phoneController.text.trim(),
        'postal': postalController.text.trim(),
        'gender': selectedGender ?? '',
        'subscribeNewsletter': subscribeNewsletter,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      DocumentSnapshot updatedUser =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      setState(() {
        nameController.text = updatedUser['name'];
        phoneController.text = updatedUser['phone'];
        postalController.text = updatedUser['postal'];
        selectedGender = updatedUser['gender'];
        subscribeNewsletter = updatedUser['subscribeNewsletter'];
      });

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile updated successfully 🎉")));
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Firebase Auth Error: ${e.message}")),
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Profile",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Color.fromRGBO(0, 0, 0, 0.938),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: emailController,
                  autofocus: true,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                  validator: (value) {
                    final RegExp editEmailRegExp1 = RegExp(
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*!])[A-Za-z\d@#$%^&*!]{8,20}$');
                    final RegExp editEmailRegExp2 = RegExp(r'^\S+$');

                    if (value == null || value.isEmpty) {
                      return "Please input email.";
                    } else if (value.length < 15 || value.length > 50) {
                      return '''The email should be between 15-50 characters.''';
                    } else if (!editEmailRegExp1.hasMatch(value)) {
                      return 'Invalid email format: \nUser1@example.com, Person1@example.co.th';
                    } else if (!editEmailRegExp2.hasMatch(value)) {
                      return 'The email format ${value} is invalid.';
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
                SizedBox(height: 15),
                TextFormField(
                  controller: passwordController,
                  obscureText: !visiblePassCon,
                  maxLength: 10,
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
                  validator: (value) {
                    final RegExp editPasswordRegex1 = RegExp(
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                    final RegExp editPasswordRegex2 = RegExp(r'^\S+$');

                    if (value == null || value.isEmpty) {
                      return "Please input confirm password.";
                    } else if (value.length < 5 || value.length > 20) {
                      return '''The confirm password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                    } else if (!editPasswordRegex1.hasMatch(value)) {
                      return "Invalid confirm password format: \nP@ssw0rd!, P@ssw0rd";
                    } else if (!editPasswordRegex2.hasMatch(value)) {
                      return "The confirm password format ${value} is invalid.";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: !visiblePassCon1,
                  maxLength: 10,
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
                  validator: (value) {
                    final RegExp editConPasswordRegex1 = RegExp(
                        r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@#$%^&*])[A-Za-z\d@#$%^&*]{8,20}$');
                    final RegExp editConPasswordRegex2 = RegExp(r'^\S+$');
                    if (value == null || value.isEmpty) {
                      return "Please input confirm password.";
                    } else if (value.length < 5 || value.length > 20) {
                      return '''The confirm password should be between 5-20 characters \n and must contain both letters and numbers. \n Symbols allowed: !"#%'()*+,-./:;<=>?@[]^_`{}|~''';
                    } else if (!editConPasswordRegex1.hasMatch(value)) {
                      return "Invalid confirm password format: \nP@ssw0rd!, P@ssw0rd";
                    } else if (!editConPasswordRegex2.hasMatch(value)) {
                      return "The confirm password format ${value} is invalid.";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                // เบอร์โทร (กรอกตัวเลข 10 ตัว)
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: InputDecoration(
                    labelText: "Phone Number",
                  ),
                  validator: (value) {
                    final RegExp editPhoneRegex1 = RegExp(r'^[0-9]{10}$');
                    final RegExp editPhoneRegex2 =
                        RegExp(r'^(?!.*(\d)\1{2})\d{10}$');

                    if (value == null || value.isEmpty) {
                      return "Please input password";
                    } else if (value.length != 10) {
                      return "Please enter a 10-digit phone number.";
                    } else if (!editPhoneRegex1.hasMatch(value)) {
                      return "Invalid phone number format: 0123456789, 0987654321";
                    } else if (!editPhoneRegex2.hasMatch(value)) {
                      return "The number format ${value} is invalid.";
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                // รหัสไปรษณีย์ (กรอกตัวเลข 5 ตัว)
                TextFormField(
                  controller: postalController,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  decoration: InputDecoration(labelText: "Postal Code"),
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
                      editUserProfile();
                      submitEdit();
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
    );
  }
}
