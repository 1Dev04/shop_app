/*

import 'package:flutter/material.dart';
import 'package:flutter_application_1/apiService.dart';
import 'package:flutter_application_1/model2.dart';

class cartScreen extends StatefulWidget {
  const cartScreen({super.key});

  @override
  State<cartScreen> createState() => _cartScreenState();
}

class _cartScreenState extends State<cartScreen> {
  CartAPI api = CartAPI();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: FutureBuilder(
          future: api.getCart(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                  
                  itemBuilder: (context, index) {
                    Carts carts = snapshot.data[index];
                   
                    return Card(
                      color: const Color.fromARGB(66, 255, 47, 47),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [

                            Text("ID: " + carts.id.toString()),
                            Text("UserID: " + carts.userId.toString()),
                            Text("date: " + carts.date.toString()),
                            Text("__v: " + carts.iV.toString()),
                            
                        ],
                      ),
                    );
                  });
            } else {
              return CircularProgressIndicator();
            }
          }),
    );
  }
}
*/