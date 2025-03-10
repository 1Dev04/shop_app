import 'package:flutter_application_1/data/database.dart';
import 'package:flutter_application_1/models/model.dart';
import 'package:flutter/material.dart';

class UpdateForm extends StatefulWidget {
  @override
  State<UpdateForm> createState() => _UpdateFormState();
}

class _UpdateFormState extends State<UpdateForm> {
  DatabaseApp db = DatabaseApp();
  @override
  Widget build(BuildContext context) {
    final data = ModalRoute.of(context)!.settings.arguments as PostModels;

    final titleController = TextEditingController(text: data.title);
    final descriptionController = TextEditingController(text: data.description);

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
                  'Edit Post',
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
                    Map input = {
                      'id': data.id,
                      'title': titleController.text,
                      'description': descriptionController.text
                    };
                    update(input);
                    Navigator.pop(context);
                  },
                  child: Text('Edit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void update(Map input) async {
    PostModels arg = PostModels(
        id: input['id'],
        title: input['title'],
        description: input['description']);
    await db.updateData(arg);
  }
}
