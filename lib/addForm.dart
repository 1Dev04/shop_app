import 'package:flutter/material.dart';
import 'package:flutter_application_1/database.dart';
import 'package:flutter_application_1/model.dart';

class addForm extends StatefulWidget {
  const addForm({super.key});

  @override
  State<addForm> createState() => _addFormState();
}

class _addFormState extends State<addForm> {
  DatabaseApp db = DatabaseApp();

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromRGBO(99, 136, 137, 1),
        title: Center(
          child: Text(
            'Example',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Form(
            child: Column(
              children: [
                Text(
                  'New Post',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: titleController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Add a title',
                    icon: Icon(Icons.title),
                  ),
                ),
                SizedBox(height: 10),
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Start a new Post',
                    icon: Icon(Icons.description),
                  ),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Map data = {
                      'title': titleController.text,
                      'description': descriptionController.text,
                    };
                    insertDB(data);
                  },
                  child: Text('Post'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void insertDB(Map input) async {
    PostModels data =
        PostModels(title: input['title'], description: input['description']);
    await db.insertDB(data);
  }
}
