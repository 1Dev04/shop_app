import 'package:flutter_application_1/model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseApp {
  // build parameter Database
  static Database? _database;

  Future<Database> initializeDB() async {
    if (_database == null) _database = await createDB();
    return _database!;
  }

  Future<Database> createDB() async {
    final path = await getDatabasesPath();

    var database = await openDatabase(
      join(path, 'postDB.db'),
      version: 1,
      onCreate: ((db, version) async {
        await db.execute(
          '''CREATE TABLE post(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        title TEXT,
        description TEXT
        )''',
        );
      }),
    );
    return database;
  }

  Future insertDB(PostModels model) async {
    var db = await initializeDB();
    var result = await db.insert('post', model.toMap());
    return result;
  }

  Future<List<PostModels>> getAllData() async {
  var db = await initializeDB();
    List<Map<String, dynamic>> result = await db.query('post');
    return List.generate(
      result.length,
      (index) => PostModels(
          id: result[index]['id'],
          title: result[index]['title'],
          description: result[index]['description']),
    );
  }
}