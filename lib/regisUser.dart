import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/authPage.dart';



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
  final TextEditingController zipController = TextEditingController();
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
      print("Zip Code: ${zipController}");
      print("Date: ${selectedDate}");
      print("Gender: ${selectedGender}");
      print("Subscribe to the newsletter: ${subscribeNewsletter}");
      print("Accepts Terms: ${acceptTerms}");

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Membership registration successful! 🎉")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Please>> Fill in the information completely.")));
    }
  }

  void signUserUp() async {
    showDialog(
        context: context,
        barrierDismissible: false, // barrier close
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
      // Check if the passwords match
      if (passwordController.text.trim() !=
          confirmPasswordController.text.trim()) {
        Navigator.pop(context); // ปิด Dialog
        print('Password do not match');
        return;
      }

      // Register
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      // Get user id
      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'name': nameController.text.trim(),
        'password': passwordController.text.trim(),
        'confirmPassword': confirmPasswordController.text.trim(),
        'email': emailController.text.trim(),
        'phone': phoneController.text.trim(),
        'zip': zipController.text.trim(),
        'gender': selectedGender ?? "",
        'birthdate': selectedDate?.toIso8601String() ?? "",
        'subscribeNewsletter': subscribeNewsletter,
        'acceptTerms': acceptTerms,
        'createdAt': FieldValue.serverTimestamp()
      });

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => authPage()));
      print("Successfully Registered");
    } on FirebaseAuthException catch (e) {
      print("An error occurred ${e.message}");
    } catch (e) {
      Navigator.pop(context);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
          Text('Create accout', style: TextStyle(color: Colors.black)),
          centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                  color: const Color.fromARGB(15, 0, 0, 0),
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
                padding: EdgeInsets.symmetric(
                    horizontal: 10), // เพิ่ม padding แทน Positioned
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          "You will receive a confirmation email to the email address you entered below. Please check your inbox.",
                          style: TextStyle(color: Colors.black38),
                          maxLines: 5,
                          overflow:
                              TextOverflow.ellipsis, // ตัดข้อความถ้ายาวเกิน
                          softWrap: true,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                      ),
                      Text(
                        "Please specify*",
                        style:
                            TextStyle(color: Color.fromARGB(255, 72, 169, 169)),
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
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please input password.";
                          } else if (value.length < 10) {
                            return '''The password should be between 10-30 characters''';
                          } else if (value.length > 30) {
                            return "Password more than 30 characters";
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
                          labelText: 'E-mail',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return "Please input password.";
                          } else if (value.length < 15) {
                            return '''The password should be between 15-50 characters.''';
                          } else if (value.length > 50) {
                            return "Password more than 50 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !visiblePassCon,
                        maxLength: 8,
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
                      SizedBox(height: 15),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !visiblePassCon1,
                        maxLength: 8,
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
                          if (value == null ||
                              value.isEmpty ||
                              value.length != 10) {
                            return "Please enter a 10-digit postal code.";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      // รหัสไปรษณีย์ (กรอกตัวเลข 5 ตัว)
                      TextFormField(
                        controller: zipController,
                        keyboardType: TextInputType.number,
                        maxLength: 5,
                        decoration: InputDecoration(labelText: "Zip Password"),
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length != 5) {
                            return "Please enter a 5-digit postal code.";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      // วันเกิด (เลือกจากปฏิทิน)
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
                      // ข้อตกลงของสมาชิก (ต้องติ๊กก่อนกดสมัคร)
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
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(0, 0, 0, 1)),
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
    );
  }
}
