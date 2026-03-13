// ----Control Button--------------------------------------------------------------------------

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:flutter_application_1/components/home_page.dart';
import 'package:flutter_application_1/components/menu_page.dart';
import 'package:flutter_application_1/components/notification_page.dart';
import 'package:flutter_application_1/components/search_page.dart';
import 'package:flutter_application_1/components/shop_page.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/basket_page.dart';
import 'package:flutter_application_1/screen/favorite_page.dart';
import 'package:flutter_application_1/screen/signin_user.dart';
import 'package:provider/provider.dart';
import '../screen/measure_size_cat.dart';

class MyControll extends StatefulWidget {
  const MyControll({super.key});

  @override
  State<MyControll> createState() => _MyControllState();
}

class _MyControllState extends State<MyControll> {
  var screenIndex = 1;
  int activeButton = 1;
  var screenPushIndex = 0;

  final mobileScreen = [
    SearchPage(),
    HomePage(),
    ShopPage(),
    NotificationPage(),
    MenuPage(),
  ];

  // ── Guest helper ──────────────────────────────────────────────────────────
  bool get _isGuest =>
      FirebaseAuth.instance.currentUser?.email == 'guest678@gmail.com';

  void _showGuestDialog(BuildContext context) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
          final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(languageProvider.translate(
          en: 'Members Only',
          th: 'สำหรับสมาชิกเท่านั้น',
        )),
        content: Text(languageProvider.translate(
          en: 'Please register or login to access this feature.',
          th: 'กรุณาสมัครสมาชิก หรือเข้าสู่ระบบเพื่อใช้งาน',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.translate(
              en: 'Cancel',
              th: 'ยกเลิก',
            )),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Login()),
              );
            },
            child: Text(languageProvider.translate(
              en: 'Login / Register',
              th: 'เข้าสู่ระบบ / สมัครสมาชิก',
            )),
          ),
        ],
      ),
    );
  }

  // ── Title helpers ─────────────────────────────────────────────────────────
  String setTitleEN() {
    if (screenIndex == 0) return "Search";
    if (screenIndex == 1) return "ABCat";
    if (screenIndex == 2) return "Shops";
    if (screenIndex == 3) return "Notification";
    if (screenIndex == 4) return "Menu";
    return "ABCat";
  }

  String setTitleTH() {
    if (screenIndex == 0) return "ค้นหา";
    if (screenIndex == 1) return "ABCat";
    if (screenIndex == 2) return "ร้านค้า";
    if (screenIndex == 3) return "การแจ้งเตือน";
    if (screenIndex == 4) return "เมนู";
    return "ABCat";
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      //------------------- AppBar -------------------
      appBar: AppBar(
        leading: SizedBox.shrink(),
        elevation: 0,
        title: Text(
          languageProvider.translate(en: setTitleEN(), th: setTitleTH()),
          style: TextStyle(
            fontFamily: 'Catfont',
            fontSize: 30,
            color: themeProvider.themeMode == ThemeMode.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
        backgroundColor: themeProvider.themeMode == ThemeMode.dark
            ? Colors.black
            : Colors.white,
        actions: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (screenIndex == 0) {
                  screenIndex = 1;
                  activeButton = 1;
                } else {
                  screenIndex = 0;
                  activeButton = 0;
                }
              });
            },
            child: Icon(
              screenIndex == 0 ? Icons.cancel : Icons.search,
              size: 30,
              color: AppBarTheme.of(context).iconTheme?.color,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              if (_isGuest) {
                _showGuestDialog(context);
                return;
              }
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => FavouritePage()));
            },
            icon: Icon(
              Icons.favorite_border_outlined,
              color: AppBarTheme.of(context).iconTheme?.color,
              size: 30,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: () {
              if (_isGuest) {
                _showGuestDialog(context);
                return;
              }
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => BasketPage()));
            },
            icon: Icon(
              Icons.add_shopping_cart_sharp,
              color: AppBarTheme.of(context).iconTheme?.color,
              size: 30,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      //------------------- body -------------------
      body: SafeArea(
        child: mobileScreen[screenIndex],
      ),

      //------------------- bottomNavigationBar -------------------
      bottomNavigationBar: Container(
        height: 80,
        width: double.infinity,
        decoration: BoxDecoration(
          color: themeProvider.themeMode == ThemeMode.dark
              ? Colors.black
              : Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Home
            GestureDetector(
              onTap: () => setState(() {
                screenIndex = 1;
                activeButton = 1;
              }),
              child: Icon(
                screenIndex == 1 ? Icons.home : Icons.home_outlined,
                size: 30,
                color: AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            // Shop
            GestureDetector(
              onTap: () => setState(() {
                screenIndex = 2;
                activeButton = 2;
              }),
              child: Icon(
                screenIndex == 2
                    ? Icons.shopping_bag
                    : Icons.shopping_bag_outlined,
                size: 30,
                color: AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            // Measure cat
            GestureDetector(
              onTap: () {
                if (_isGuest) {
                  _showGuestDialog(context);
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MeasureSizeCat()),
                ).then((_) {
                  if (mounted) setState(() {
                    screenIndex = 1;
                    activeButton = 1;
                  });
                });
              },
              child: Image.network(
                'https://res.cloudinary.com/dag73dhpl/image/upload/v1769662814/sizeCat_xil2jh.png',
                width: 40,
                height: 40,
                color: AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            // Notification
            GestureDetector(
              onTap: () => setState(() {
                screenIndex = 3;
                activeButton = 3;
              }),
              child: Icon(
                screenIndex == 3
                    ? Icons.notifications
                    : Icons.notifications_outlined,
                size: 30,
                color: AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            // Menu
            GestureDetector(
              onTap: () {
                if (_isGuest) {
                  _showGuestDialog(context);
                  return;
                }
                setState(() {
                  screenIndex = 4;
                  activeButton = 4;
                });
              },
              child: Icon(
                screenIndex == 4 ? Icons.menu_open : Icons.menu,
                size: 30,
                color: AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}