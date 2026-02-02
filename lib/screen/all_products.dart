import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/database.dart';


class AllProducts extends StatefulWidget {
  const AllProducts({super.key});

  @override
  State<AllProducts> createState() => _AllProductsState();
}

class _AllProductsState extends State<AllProducts> {
  DatabaseApp db = DatabaseApp();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            "All Products",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        body: SafeArea(child: Column(


        )));
  }
}
