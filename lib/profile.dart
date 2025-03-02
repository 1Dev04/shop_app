import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/login.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Profile extends StatefulWidget {
 
  
  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  User? user = FirebaseAuth.instance.currentUser;

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }

  void showLogAlertExit(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Message"),
            content: const Text("Are you sure you want to log out?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
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
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Colors.black, // ✅ ใช้สีดำตรงๆ
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 20),
                CircleAvatar(
                  radius: 100,
                  backgroundImage: user?.photoURL != null
                      ? NetworkImage(user!.photoURL!)
                      : null,
                  child: user?.photoURL == null
                      ? const Icon(Icons.person, size: 50)
                      : null,
                ),
                SizedBox(height: 20),
                Text(
                  user?.displayName ?? "No username", // ✅ แก้คำผิด
                  style: const TextStyle(fontSize: 20),
                ),
                SizedBox(height: 5),
                Text(
                  user?.email ?? "No email",
                  style: const TextStyle(fontSize: 15),
                ),
                SizedBox(height: 10),
                Text("Phone: None", style: TextStyle(fontSize: 15)),
                 SizedBox(height: 10),
                Text("Zip: None", style: TextStyle(fontSize: 15)),
                 SizedBox(height: 10),
                 Text("Date: None", style: TextStyle(fontSize: 15)),
                 SizedBox(height: 10),
                 Text("Gender: None", style: TextStyle(fontSize: 15)),
                 SizedBox(height: 10),
                 Text("The newsletter: None",
                    style: TextStyle(fontSize: 15)),
                 SizedBox(height: 10),
                 Text("Member agreement: None",
                    style: TextStyle(fontSize: 15)),
                 SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => showLogAlertExit(context),
                  child:  Text("Logout"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
