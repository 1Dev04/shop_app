import 'package:flutter/material.dart';
import 'package:flutter_application_1/data/database.dart';
import 'package:flutter_application_1/models/model.dart';
import 'package:flutter_application_1/screen/Update_Form.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class ViewAccount extends StatefulWidget {
  const ViewAccount({super.key});

  @override
  State<ViewAccount> createState() => _ViewAccount();
}

class _ViewAccount extends State<ViewAccount> {
  DatabaseApp db = DatabaseApp();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feedback", style: TextStyle(fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      body: FutureBuilder<List<PostModels>>(
          //------ ดึงข้อมูลทั้งหมดจากฐานข้อมูล ------
          future: db.getAllData(),
          builder: (context, snapshot) {
            //-------- ตรวจสอบว่ามีข้อมูลใน db.getAlldata หรือไม่ --------
            //-------- ถ้ามีข้อมูลให้ดึงข้อมูลมาแสดงใน ListView.builder
            //-------- ถ้าไม่มีข้อมูลให้ไปที่คำสั่ง else
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: ((context, index) {
                  PostModels topic = snapshot.data![index];
                  return Slidable(
                    endActionPane:
                        ActionPane(motion: DrawerMotion(), children: [
                      SlidableAction(
                        onPressed: (context) {
                          Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => UpdateForm(),
                                      settings:
                                          RouteSettings(arguments: topic)))
                              .then((value) {
                            //setState หน้าใหม่หลังจากกลับมาจากหน้า updataForm
                            setState(() {
                              db.getAllData();
                            });
                          });
                        },
                        icon: Icons.edit,
                        backgroundColor: Color.fromARGB(255, 165, 165, 165),
                        foregroundColor: Colors.white,
                        label: 'Edit',
                      ),
                      SlidableAction(
                        onPressed: (context) {
                          deleteDialog(topic);
                        },
                        icon: Icons.delete,
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        label: 'Delete',
                      )
                    ]),
                    child: ListTile(
                      title: Text('${topic.title}'),
                      subtitle: Container(
                          alignment: Alignment.topLeft,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('${topic.description}'),
                            ],
                          )),
                      /*trailing: Container(
                        width: 70,
                        child: Row(
                          children: [
                            //-------- Icon ดินสอ สำหรับแก้ไขข้อมูล --------
                            Expanded(
                                child: IconButton(
                                    onPressed: () {
                                      Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      UpdateForm(),
                                                  settings: RouteSettings(
                                                      arguments: topic)))
                                          .then((value) {
                                        //setState หน้าใหม่หลังจากกลับมาจากหน้า updataForm
                                        setState(() {
                                          db.getAllData();
                                        });
                                      });
                                    },
                                    icon: Icon(Icons.edit))),
                            //-------- Icon ถังขยะ สำหรับลบข้อมูล --------
                            Expanded(
                              child: IconButton(
                                  onPressed: () {
                                    //เรียกใช้เมธอด deleteDialog
                                    deleteDialog(topic);
                                  },
                                  icon: Icon(Icons.delete, color: Colors.red)),
                            ),
                          ],
                        ),
                      ),*/
                      trailing: Container(
                        child: Icon(Icons.arrow_back_ios_new_outlined),
                      ),
                    ),
                  );
                }),
              );
              //-------- ถ้าไม่มีข้อมูลในฐานข้อมูลให้แสดงคำว่า 'No data' --------
            } else {
              return Center(child: Text('No data'));
            }
          }),
    );
  }

  //-------- Delete Dialog ------
  deleteDialog(PostModels data) async {
    return showDialog(
        
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            title: Text('คุณแน่ใจว่าต้องการลบข้อมูล?'),
            actions: [
              TextButton(
                  onPressed: () {
                    db.deleteData(data);
                    setState(() {
                      db.getAllData();
                    });
                    Navigator.pop(context);
                  },
                  child: Container(
                      height: 30,
                      width: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Center(
                        child: Text(
                          'ลบ',
                          style: TextStyle(color: Colors.white),
                        ),
                      ))),
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('ยกเลิก')),
            ],
          );
        });
  }
}
