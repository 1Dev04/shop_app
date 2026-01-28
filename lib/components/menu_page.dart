// ----MenuPage--------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/history_page.dart';
import 'package:flutter_application_1/components/my_order_page.dart';
import 'package:flutter_application_1/documents/faq.dart';
import 'package:flutter_application_1/documents/terms_of_use.dart';
import 'package:flutter_application_1/documents/privacy_policy.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/profile_user.dart';
import 'package:flutter_application_1/screen/setting_page.dart';
import 'package:provider/provider.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Container(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Profile()));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.badge_outlined,
                                  size: 30,
                                ),
                                Text(
                                  languageProvider.translate(
                                      en: "Profiles", th: "โปรไฟล์"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const MyOrderPage()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.archive_outlined, size: 30),
                                Text(
                                  languageProvider.translate(
                                      en: "My Orders", th: "ค้าของฉัน"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HistoryPage()),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 30),
                                Text(
                                  languageProvider.translate(
                                      en: "Order List", th: "รายการค้า"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 14,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.confirmation_num_outlined, size: 30),
                                Text(
                                  languageProvider.translate(
                                      en: "Coupon", th: "คูปอง"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.list_alt_outlined, size: 30),
                                Text(
                                  languageProvider.translate(
                                      en: "Survey B.", th: "แบบสอบถาม"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => Settingpage()));
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5, vertical: 5),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.settings_outlined, size: 30),
                                Text(
                                  languageProvider.translate(
                                      en: "Setting", th: "การตั้งค่า"),
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              // ✅ แก้ไขส่วนนี้ - เปลี่ยนจาก Row เป็น Column
              Column(
                children: [
                  // FAQ
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const FAQPage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(15, 0, 0, 0),
                        border: Border(
                          bottom: BorderSide(color: Colors.black12, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                                languageProvider.translate(
                                    en: "Frequently asked questions",
                                    th: "คำถามที่พบบ่อย"),
                                style: TextStyle(fontSize: 18)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(Icons.arrow_back_ios_new_outlined,
                                  size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  // Terms of Use
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const TermsOfUsePage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(15, 0, 0, 0),
                        border: Border(
                          bottom: BorderSide(color: Colors.black12, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                                languageProvider.translate(
                                    en: "Terms of Use",
                                    th: "ข้อกำหนดการใช้งาน"),
                                style: TextStyle(fontSize: 18)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(Icons.arrow_back_ios_new_outlined,
                                  size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  // Privacy Policy
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PrivacyPolicyPage()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(15, 0, 0, 0),
                        border: Border(
                          bottom: BorderSide(color: Colors.black12, width: 1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              languageProvider.translate(
                                  en: "Privacy Policy",
                                  th: "นโยบายความเป็นส่วนตัว"),
                              style: TextStyle(fontSize: 18),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(
                                Icons.arrow_back_ios_new_outlined,
                                size: 20,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Center(
                  child: Text(
                      languageProvider.translate(
                          en: "Version: 4.0 | By 1DEV co.,ltd.",
                          th: "เวอร์ชัน: 4.0 | โดย 1DEV co.,ltd."),
                      style: TextStyle(fontSize: 15)))
            ],
          ),
        )
      ],
    );
  }
}