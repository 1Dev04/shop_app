// ----Control Button--------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_application_1/components/home_page.dart';
import 'package:flutter_application_1/components/favorite_page.dart';
import 'package:flutter_application_1/components/menu_page.dart';
import 'package:flutter_application_1/components/notification_page.dart';
import 'package:flutter_application_1/components/search_page.dart';
import 'package:flutter_application_1/components/shop_page.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:flutter_application_1/screen/%E0%B8%BABasket.dart';
import 'package:provider/provider.dart';
import '../screen/Measue_SizeCat.dart';

class MyControll extends StatefulWidget {
  const MyControll({super.key});

  @override
  State<MyControll> createState() => _MyControllState();
}

class _MyControllState extends State<MyControll> {
  //Change Screen
  var screenIndex = 2;
  //Active Button
  int activeButton = 2;
  //Push Screen
  var screenPushIndex = 0;

  //Page Screen
  final mobileScreen = [
    SearchPage(),
    FavoritePage(),
    HomePage(),
    ShopPage(),
    NotificationPage(),
    MenuPage(),
  ];

  //Set Header Title EN
  String setTitleEN() {
    if (screenIndex == 0) {
      return "Search";
    } else if (screenIndex == 1) {
      return "Favorites";
    } else if (screenIndex == 2) {
      return "ABC shop";
    } else if (screenIndex == 3) {
      return "Shops";
    } else if (screenIndex == 4) {
      return "Notification";
    } else if (screenIndex == 5) {
      return "Menu";
    }

    return setTitleEN();
  }

  //Set Header Title TH
  String setTitleTH() {
    if (screenIndex == 0) {
      return "ค้นหา";
    } else if (screenIndex == 1) {
      return "รายการโปรด";
    } else if (screenIndex == 2) {
      return "ร้าน ABC";
    } else if (screenIndex == 3) {
      return "ร้านค้า";
    } else if (screenIndex == 4) {
      return "การแจ้งเตือน";
    } else if (screenIndex == 5) {
      return "เมนู";
    }

    return setTitleTH();
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
                  screenIndex = 0;
                  activeButton = 0;
                });
              },
              child: Icon(
                screenIndex == 0 ? Icons.cancel_outlined : Icons.search,
                size: 30,
                color: activeButton == 0
                    ? AppBarTheme.of(context).iconTheme?.color
                    : AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  screenIndex = 1;
                  activeButton = 1;
                });
              },
              child: Icon(
                screenIndex == 1
                    ? Icons.favorite
                    : Icons.favorite_border_outlined,
                size: 30,
                color: activeButton == 1
                    ? AppBarTheme.of(context).iconTheme?.color
                    : AppBarTheme.of(context).iconTheme?.color,
              ),
            ),
            SizedBox(
              width: 10,
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => Basket()));
                },
                icon: Icon(
                  Icons.add_shopping_cart_sharp,
                  color: AppBarTheme.of(context).iconTheme?.color,
                  size: 30,
                )),
            SizedBox(width: 10)
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
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    screenIndex = 2;
                    activeButton = 2;
                  });
                },
                child: Icon(
                  screenIndex == 2 ? Icons.home : Icons.home_outlined,
                  size: 30,
                  color: activeButton == 2
                      ? AppBarTheme.of(context).iconTheme?.color
                      : AppBarTheme.of(context).iconTheme?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                 
                  setState(() {
                    screenIndex = 3;
                    activeButton = 3;
                  });
                },
                child: Icon(
                  screenIndex == 3
                      ? Icons.shopping_bag
                      : Icons.shopping_bag_outlined,
                  size: 30,
                  color: activeButton == 3
                      ? AppBarTheme.of(context).iconTheme?.color
                      : AppBarTheme.of(context).iconTheme?.color,
                ),
              ),
              GestureDetector(
                  onTap: () {
                    setState(() {
                      screenPushIndex = 2;
                    });

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => MeasureSizeCat())).then((_) {
                      setState(() {
                        screenIndex = 2;
                        activeButton = 2;
                      });
                    });
                  },
                  child: Image.asset(
                    'assets/icons/sizeCat.png',
                    width: 40,
                    height: 40,
                    color: AppBarTheme.of(context)
                        .iconTheme
                        ?.color, // ถ้าเป็นรูปสีเดียว
                  )),
              GestureDetector(
                onTap: () {
                  setState(() {
                    screenIndex = 4;
                    activeButton = 4;
                  });
                },
                child: Icon(
                  screenIndex == 4
                      ? Icons.notifications
                      : Icons.notifications_outlined,
                  size: 30,
                  color: activeButton == 4
                      ? AppBarTheme.of(context).iconTheme?.color
                      : AppBarTheme.of(context).iconTheme?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    screenIndex = 5;
                    activeButton = 5;
                  });
                },
                child: Icon(
                  screenIndex == 5 ? Icons.menu_open : Icons.menu,
                  size: 30,
                  color: activeButton == 5
                      ? AppBarTheme.of(context).iconTheme?.color
                      : AppBarTheme.of(context).iconTheme?.color,
                ),
              ),
            ],
          ),
        ),
    );
  }
}




