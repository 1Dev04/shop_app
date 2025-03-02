import 'package:flutter/material.dart';

//ติดตั้งแพคเกจ firebase_core จาก pub.dev
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/authPage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyApp(),
  ));
}

/*
void showAlert(BuildContext context) {
  showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Message",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text("You must be logged in to login."),
              SizedBox(height: 20),
              Column(
                
                children: [
                  ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => authPage()));
                      },
                      child: Text("Meow In", style: TextStyle(
                        color: Colors.black,
                        fontSize: 15
                      ),)),
                      
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => authPage()));
                      },
                      child: Text("Join Us",style: TextStyle(
                        color:  Color.fromARGB(255, 0, 0, 0),
                        fontSize: 10,
                        
                        )
                        
                        ))
                ],
              )
            ],
          ),
        );
      });
}
*/

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedNetworkImage(
            imageUrl:
                "https://res.cloudinary.com/dag73dhpl/image/upload/v1740759438/animalshelter_ncqile.png",
            width: 150,
            height: 150,
            placeholder: (context, url) => CircularProgressIndicator.adaptive(
              backgroundColor: Colors.white,
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color.fromARGB(75, 50, 50, 50)),
            ),
            errorWidget: (context, url, error) => Icon(Icons.error),
          ),
          SizedBox(height: 30),
          Text(
            'ABC_SHOP',
            style: TextStyle(fontSize: 40, fontFamily: 'Catfont'),
          ),
          SizedBox(height: 10),
          Text(
            'Welcome!',
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 10),
          TextButton(
            onPressed: () {
              //showAlert(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => authPage()));
            },
            child: Text('Continue', style: TextStyle(color: Colors.black)),
            style: TextButton.styleFrom(
              backgroundColor: Color.fromARGB(51, 0, 0, 0),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
