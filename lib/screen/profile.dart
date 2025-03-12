import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screen/editProfile.dart';
import 'package:flutter_application_1/screen/login.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';

class Profile extends StatefulWidget {
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? user = FirebaseAuth.instance.currentUser;
  String _name = "";
  String _email = "";
  String _phone = "";
  String _postal = "";
  String _birthdate = "";
  String _gender = "";
  String _newsletter = "";
  String _memberAgreement = "";

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void showLogAlertExit(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Are you sure you want to log out?"),
            
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await signOut();

                  if (mounted) {
                    Navigator.of(context).pop();
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => Login()),
                    );
                  }
                },
                child: const Text(
                  "Confirm",
                ),
              ),
            ],
          );
        });
  }

  String formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'No date';
    DateTime parsedDate = DateTime.parse(isoDate);
    return DateFormat('dd/MM/yyyy').format(parsedDate);
  }

  @override
  void initState() {
    super.initState();
    fetchUser(); // เรียกข้อมูลผู้ใช้เมื่อหน้าโปรไฟล์ถูกสร้างขึ้น
  }

  void fetchUser() async {
    String uid = FirebaseAuth.instance.currentUser!.uid;
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists) {
      var data = userDoc.data() as Map<String, dynamic>;
      setState(() {
        _name = data['name'] ?? 'No name';
        _email = data['email'] ?? 'No email';
        _phone = data['phone'] ?? 'No phone';
        _postal = data['postal'] ?? 'No postal code';
        _birthdate = data['birthdate'] ?? 'No date';
        _gender = data['gender'] ?? 'No gender';
        _newsletter = data['subscribeNewsletter'] != null
            ? (data['subscribeNewsletter'] ? 'Subscribed' : 'Not subscribed')
            : 'No data';
        _memberAgreement = data['acceptTerms'] != null
            ? (data['acceptTerms'] ? 'Accepted' : 'Not accepted')
            : 'No data';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28)),
        centerTitle: true,

        // iconTheme: const IconThemeData(),
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(10),
          width: double.infinity,
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => editProfilePage(),
                                ),
                              );
                            },
                            child: Column(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: 30,
                                ),
                                Text(
                                  'Edit',
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ))
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 100,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? CachedNetworkImage(
                            imageUrl:
                                "https://res.cloudinary.com/dag73dhpl/image/upload/v1741695217/cat3_xvd0mu.png",
                            width: 180,
                            height: 180,
                            placeholder: (context, url) =>
                                CircularProgressIndicator.adaptive(
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.fromARGB(75, 50, 50, 50)),
                            ),
                            errorWidget: (context, url, error) =>
                                Icon(Icons.error),
                          )
                        : null,
                  ),
                  SizedBox(height: 20),
                  Text("Name: $_name", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Email: $_email", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Phone: $_phone", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Postal Code: $_postal", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Date: ${formatDate(_birthdate)}",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Gender: $_gender", style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("The newsletter: $_newsletter",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 15),
                  Text("Member agreement: $_memberAgreement",
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => showLogAlertExit(context),
                    child: Text(
                      "Logout",
                      style: TextStyle(fontSize: 16 ,),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
