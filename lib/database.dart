import './model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseApp {
  static Database? _database;

  //------------- ฟังก์ชันสำหรับตรวจสอบว่ามีฐานข้อมูลอยู่แล้วหรือไม่ -------------
  Future<Database> initializedb() async {
    if (_database == null) _database = await createdb();
    return _database!;
  }

  //------------- ฟังก์ชันสำหรับสร้างฐานข้อมูลใหม่ กรณียังไม่มีฐานข้อมูล -------------
  Future<Database> createdb() async {
    final path = await getDatabasesPath();

    var database = await openDatabase(
      join(path, 'postDB.db'),
      version: 1,
      onCreate: ((db, version) async {
        await db.execute(
          '''CREATE TABLE post(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, 
        title TEXT, 
        description TEXT)''',
        );
      }),
    );
    return database;
  }

  //------------- ฟังก์ชันสำหรับเพิ่มข้อมูลในฐานข้อมูล -------------
  Future insertDB(PostModels data) async {
    var db = await initializedb();
    var result = await db.insert('post', data.toMap());
    return result;
  }

  //------------- ฟังก์ชันสำหรับแสดงข้อมูลทั้งหมด -------------
  Future<List<PostModels>> getAllData() async {
    var db = await initializedb();
    List<Map<String, dynamic>> result = await db.query('post');
    return List.generate(
      result.length,
      (index) => PostModels(
          id: result[index]['id'],
          title: result[index]['title'],
          description: result[index]['description']),
    );
  }

  //------------- ฟังก์ชันสำหรับลบข้อมูลตาม id ของข้อมูลที่เลือก -------------
   Future deleteData(PostModels data) async {
    var db = await initializedb();
    var result = db.delete(
      'post',
      where: 'id=?',
      whereArgs: [data.id],
    );
    return result;
  }

  //------------- ฟังก์ชันสำหรับแก้ไข/อัพเดทข้อมูลตาม id ของข้อมูลที่เลือก -------------
 Future updateData(PostModels data) async {
    var db = await initializedb();
    var result = db.update(
      'post',
      data.toMap(),
      where: 'id=?',
      whereArgs: [data.id],
    );
    return result;
  }
}
