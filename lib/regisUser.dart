import 'package:flutter/material.dart';

class regisUser extends StatefulWidget {
  const regisUser({super.key});

  @override
  State<regisUser> createState() => _regisUserState();
}

class _regisUserState extends State<regisUser> {
  final _formKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text('Create accout', style: TextStyle(color: Colors.black)),
        ),
        actions: [
          TextButton.icon(
              onPressed: () {},
              icon: Icon(Icons.person, color: Colors.black),
              label: Text("acccout", style: TextStyle(color: Colors.black)))
        ],
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
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.all(10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        autofocus: true,
                        decoration: const InputDecoration(
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
                      SizedBox(height: 15),
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Password',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'กรุณากรอกรหัสผ่าน';
                          return null;
                        },
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Confirm Password',
                        ),
                        validator: (value) {
                          if (value!.isEmpty) return 'กรุณากรอกรหัสยืนยัน';
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {}
                        },
                        child: Text(
                          'Sign Up',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromRGBO(0, 0, 0, 1)),
                      ),
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
