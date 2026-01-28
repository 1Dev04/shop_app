import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/documents/faq.dart';
import 'package:flutter_application_1/documents/learn_user.dart';
import 'package:flutter_application_1/documents/terms_of_use.dart';
import 'package:flutter_application_1/documents/privacy_policy.dart';
import 'package:flutter_application_1/menuprofile/history.dart';
import 'package:flutter_application_1/menuprofile/myorder.dart';
import 'package:flutter_application_1/provider/Favorite_Provider.dart';
import 'package:flutter_application_1/provider/Language_Provider.dart';
import 'package:flutter_application_1/provider/theme.dart';
import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:flutter_application_1/screen/%E0%B8%BABasket.dart';
// import 'package:flutter_application_1/screen/View_Account.dart';

import 'package:flutter_application_1/screen/Profile_User.dart';
import 'package:flutter_application_1/screen/Setting_Page.dart';

// import 'package:flutter_application_1/login.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'Measue_SizeCat.dart';

class MyHome extends StatefulWidget {
  const MyHome({super.key});

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
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
    if (screenIndex == 0) return "Search";
    if (screenIndex == 1) return "Favorites";
    if (screenIndex == 2) return "ABC shop";
    if (screenIndex == 3) return "Shops";
    if (screenIndex == 4) return "Notification";
    if (screenIndex == 5) return "Menu";
    
    return "ABC Shop"; 
  }

  //Set Header Title TH
  String setTitleTH() {
    if (screenIndex == 0) return "ค้นหา";
    if (screenIndex == 1) return "รายการโปรด";
    if (screenIndex == 2) return "ร้าน ABC";
    if (screenIndex == 3) return "ร้านค้า";
    if (screenIndex == 4) return "การแจ้งเตือน";
    if (screenIndex == 5) return "เมนู";

    return "ร้าน ABC"; // ✅ แก้เป็นค่า Default
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
        //------------------- AppBar -------------------
        appBar: AppBar(
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
          child: IndexedStack(
            index: screenIndex,
            children: mobileScreen, 
          ),
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
                  /*
                  setState(() {
                    screenPushIndex = 1;
                  });
                  */
                  setState(() {
                    screenIndex = 3;
                    activeButton = 3;
                  });
                  /*
Navigator.push(
                      context,
                      PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  Login(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin =
                                Offset(0.0, 1.0); //Slide from right to left
                            const end = Offset(0.0, 0.0);
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));
                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          })).then((_) {
                          
                    setState(() {
                      screenIndex = 2;
                      activeButton = 2;
                    });
                  });
                  */
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class CatItem {
  final String imageUrl;
  final String name;

  CatItem({required this.imageUrl, required this.name});
}

final List<CatItem> femaleCats = [
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288948/F1-removebg-preview_b0vnu5.png",
    name: "Princess Paws",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288947/F2-removebg-preview_upsxlj.png",
    name: "Floral Feline",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288946/F3-removebg-preview_nl7eks.png",
    name: "Elegant Diva",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F4-removebg-preview_ncl6mt.png",
    name: "Pastel Kitty",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F5-removebg-preview_mynzc3.png",
    name: "Royal Queen",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F6-removebg-preview_p0x3j4.png",
    name: "Fairy Tale Cat",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F7-removebg-preview_hrobn2.png",
    name: "Sweet Lolita",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F8-removebg-preview_yipil7.png",
    name: "Chic & Trendy",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F9-removebg-preview_glqkuw.png",
    name: "Romantic Lace",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F10-removebg-preview_ka2hjm.png",
    name: "Tutu & Frills",
  ),
];

final List<CatItem> maleCats = [
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290117/M1-removebg-preview_dy7jvt.png",
    name: "Gentleman Paws",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M2-removebg-preview_fhbtuj.png",
    name: "Sporty Cat",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M3-removebg-preview_w7onjr.png",
    name: "Cool Street Style",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M4-removebg-preview_eu2eum.png",
    name: "Dapper Kitty",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M5-removebg-preview_ptzi7o.png",
    name: "Retro Vibes",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M6-removebg-preview_wwab4z.png",
    name: "Rockstar Meow",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M7-removebg-preview_kq2mpl.png",
    name: "Minimalist Chic",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M8-removebg-preview_i94h7h.png",
    name: "Bad Boy Cat",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M9-removebg-preview_yulrpr.png",
    name: "Sailor & Navy",
  ),
  CatItem(
    imageUrl:
        "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M10-removebg-preview_zrc7cm.png",
    name: "Adventure Outfit",
  ),
];

class _SearchPageState extends State<SearchPage> {
  final fromKey = GlobalKey<FormState>();
  final PageController _pageControlSearch = PageController(initialPage: 0);

  int actionPageSearch = 0;

  void _goToPageSearch(int pageIndexSearch) {
    _pageControlSearch.animateToPage(
      pageIndexSearch,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Container(
              color: Theme.of(context).snackBarTheme.backgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(0);
                      setState(() {
                        actionPageSearch = 0;
                      });
                    },
                    child: actionPageSearch == 0
                        ? Text(
                            languageProvider.translate(
                                en: "FEMALE", th: "ตัวเมีย"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "FEMALE", th: "ตัวเมีย"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(1);
                      setState(() {
                        actionPageSearch = 1;
                      });
                    },
                    child: actionPageSearch == 1
                        ? Text(
                            languageProvider.translate(
                                en: "MALE", th: "ตัวผู้"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color, // สีของเส้นใต้
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "MALE", th: "ตัวผู้"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                  GestureDetector(
                    onTap: () {
                      _goToPageSearch(2);
                      setState(() {
                        actionPageSearch = 2;
                      });
                    },
                    child: actionPageSearch == 2
                        ? Text(
                            languageProvider.translate(
                                en: "KITTEN", th: "ลูกแมว"),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1, // ความหนาของเส้นใต้
                              decorationColor: Theme.of(context)
                                  .snackBarTheme
                                  .contentTextStyle
                                  ?.color, // สีของเส้นใต้
                              fontSize: 18,
                              height: 3,
                            ),
                          )
                        : Text(
                            languageProvider.translate(
                                en: "KITTEN", th: "ลูกแมว"),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 15,
                              height: 3,
                            )),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(
            height: 20,
          ),
          Expanded(
              child: PageView(
            controller: _pageControlSearch,
            scrollDirection: Axis.horizontal,
            onPageChanged: (indexS) {
              setState(() {
                actionPageSearch = indexS;
              });
            },
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288948/F1-removebg-preview_b0vnu5.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Princess Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288947/F2-removebg-preview_upsxlj.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Floral Feline',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288946/F3-removebg-preview_nl7eks.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Elegant Diva',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F4-removebg-preview_ncl6mt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Pastel Kitty',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F5-removebg-preview_mynzc3.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Royal Queen',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289084/F6-removebg-preview_p0x3j4.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Fairy Tale Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F7-removebg-preview_hrobn2.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sweet Lolita',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289083/F8-removebg-preview_yipil7.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Chic & Trendy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Female 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F9-removebg-preview_glqkuw.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Romantic Lace',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Female 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740289082/F10-removebg-preview_ka2hjm.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Tutu & Frills',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290117/M1-removebg-preview_dy7jvt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Gentleman Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M2-removebg-preview_fhbtuj.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sporty Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M3-removebg-preview_w7onjr.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Cool Street Style',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M4-removebg-preview_eu2eum.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Dapper Kitty',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M5-removebg-preview_ptzi7o.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Retro Vibes',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M6-removebg-preview_wwab4z.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Rockstar Meow',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M7-removebg-preview_kq2mpl.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Minimalist Chic',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290116/M8-removebg-preview_i94h7h.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Bad Boy Cat',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Male 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M9-removebg-preview_yulrpr.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Sailor & Navy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Male 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/M10-removebg-preview_zrc7cm.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Adventure Outfit',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    //Section 1
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K1-removebg-preview_sha0wo.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Baby Meow',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 2
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K2-removebg-preview_ijiu0l.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Fluffy Bunny',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K3-removebg-preview_p8ysrz.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Candy Cutie',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 4
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290115/K4-removebg-preview_mxeobw.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Little Sailor',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 3
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K5-removebg-preview_h7u4gt.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Tiny Teddy',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 6
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K6-removebg-preview_u4upj9.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Playful Paws',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 4
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K7-removebg-preview_ynkt7n.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Rainbow Kitten',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 8
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K8-removebg-preview_mxeqvn.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Mini Prince & Princess',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    //Section 9
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        //Kittin 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K9-removebg-preview_nbydc8.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Dreamy Cloud',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        //Kittin 10
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 180,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740290114/K10-removebg-preview_xmzj5i.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(75, 50, 50, 50)),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Icon(Icons.error),
                                ),
                                Container(
                                  width: 100,
                                  child: Text(
                                    'Cozy Pajamas',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontSize: 14,
                                    ),
                                    maxLines: 2,
                                    // overflow: TextOverflow.ellipsis, // ...
                                    softWrap: true, // new line
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
              ),
            ],
          )) // ส่วนขยาย ภายใน
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        padding: EdgeInsets.all(5),
        child: Form(
            key: fromKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                    labelText: languageProvider.translate(
                        en: 'Search for products', th: 'ค้นหาสินค้า'),
                    prefixIcon: Icon(Icons.search),
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ],
            )),
      ),
    );
  }
}

class FavoritePage extends StatelessWidget {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SafeArea(
      child: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          final favorites = favoriteProvider.favorites;
          final isDark = Theme.of(context).brightness == Brightness.dark;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color.fromARGB(120, 88, 88, 88)
                      : Colors.grey[200],
                ),
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      languageProvider.translate(
                          en: "Item: ${favorites.length} List",
                          th: "รายการ: ${favorites.length} รายการ"),
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: favorites.isEmpty
                    ? _buildEmptyState(context)
                    : _buildFavoriteList(context, favorites, isDark),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            languageProvider.translate(en: "Setting", th: "การตั้งค่า"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              languageProvider.translate(
                  en: "Add products to your favorites list to check prices and stock availability.",
                  th: "เพิ่มสินค้าลงในรายการโปรดของคุณเพื่อตรวจสอบราคาและสถานะสต็อก"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteList(
    BuildContext context,
    List<ProductRecommendation> favorites,
    bool isDark,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final product = favorites[index];
        return Card(
          elevation: 2,
          color: isDark ? Colors.grey[900] : Colors.white,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // ส่วนบน: รูป + ชื่อ + ราคา + ปุ่มลบ
                Row(
                  children: [
                    // รูปภาพ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.shopping_bag, size: 30),
                          );
                        },
                      ),
                    ),

                    SizedBox(width: 12),

                    // ชื่อสินค้า + ราคา
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Price: ${product.price}',
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ปุ่มลบ
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 24),
                      onPressed: () {
                        context
                            .read<FavoriteProvider>()
                            .removeFavorite(product.id);
                      },
                      tooltip: 'Remove from favorites',
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // ส่วนล่าง: ปุ่ม Buy และ More
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Coming Soon!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Buy',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening details...'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.grey[400],
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'More',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1000);
  List<Map<String, dynamic>> images = [];

  Timer? timer;
  bool isUserInteracting = false;
  bool isLoading = true;
  String? errorMessage;

  // ฟังก์ชันสำหรับหา Base URL ที่ถูกต้องตาม Platform
  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // สำหรับ Android Emulator
    } else {
      return 'http://localhost:8000';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchAdvertisements();
  }

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ดึงข้อมูลจาก API
  Future<void> fetchAdvertisements() async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/home-advertiment';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        List<Map<String, dynamic>> parsedImages = [];

        if (data is List) {
          parsedImages = data.map<Map<String, dynamic>>((item) {
            final rawImages = item['images'];

            return {
              ...item,
              // 🔥 แปลง images จาก String → Map
              'images': rawImages is String ? jsonDecode(rawImages) : rawImages,
            };
          }).toList();
        } else if (data is Map && data.containsKey('data')) {
          parsedImages = List<Map<String, dynamic>>.from(
            data['data'].map<Map<String, dynamic>>((item) {
              final rawImages = item['images'];

              return {
                ...item,
                'images':
                    rawImages is String ? jsonDecode(rawImages) : rawImages,
              };
            }),
          );
        }

        setState(() {
          images = parsedImages;
          isLoading = false;
        });

        if (images.isNotEmpty) {
          startAutoScroll();
        }
      } else {
        setState(() {
          errorMessage = 'ไม่สามารถโหลดข้อมูลได้ (${response.statusCode})';
          isLoading = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessage = 'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend';
        isLoading = false;
      });
    } on TimeoutException {
      setState(() {
        errorMessage = 'หมดเวลาการเชื่อมต่อ';
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'เกิดข้อผิดพลาด: $e';
        isLoading = false;
      });
    }
  }

  void startAutoScroll() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isUserInteracting && images.isNotEmpty) {
        if (_pageController.hasClients) {
          final nextPage = (_pageController.page ?? 0) + 1;
          _pageController.animateToPage(
            nextPage.toInt(),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void stopAutoScroll() {
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // แสดง Loading
    if (isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // แสดง Error
    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchAdvertisements();
                },
                child: Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    // แสดงข้อมูลว่าง
    if (images.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text('ไม่มีข้อมูลโฆษณา'),
        ),
      );
    }

    // แสดงข้อมูลปกติ
    return Scaffold(
      body: GestureDetector(
        onPanDown: (_) {
          isUserInteracting = true;
          stopAutoScroll();
        },
        onPanCancel: () {
          isUserInteracting = false;
          startAutoScroll();
        },
        onPanEnd: (_) {
          isUserInteracting = false;
          startAutoScroll();
        },
        child: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: images.length * 1000, // infinite scroll
          itemBuilder: (context, index) {
            final item = images[index % images.length];
            return Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.error),
                  ),
                ),
                Positioned(
                  bottom: 250,
                  left: 20,
                  child: Text(
                    item['clothing_name'] ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 160,
                  left: 20,
                  right: 20,
                  child: Text(
                    item['description'] ?? '',
                    style: TextStyle(
                      color: const Color.fromARGB(238, 255, 255, 255),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    maxLines: 3,
                    softWrap: true,
                  ),
                ),
                Positioned(
                  bottom: 110,
                  left: 20,
                  right: 0,
                  child: Text(
                    item['price']?.toString() ?? '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 20,
                          color: Colors.black.withOpacity(0.7),
                          offset: Offset(2, 2),
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // ตะกร้าสินค้า
                        },
                        icon: Icon(Icons.shopping_cart_outlined),
                        label: Text('Buy Now'),
                      ),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: item['images']['image_clothing'] ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final PageController _pageControlNotificate1 = PageController(initialPage: 0);
  final PageController _pageControlNotificate2 = PageController(initialPage: 0);

  final PageController _pageControlPageMess = PageController(initialPage: 0);
  final PageController _pageControlPageNew = PageController(initialPage: 0);

  int actionPageNotificate1 = 0;
  int actionPageTwo = 0;
  int actionMessage = 0;
  int actionNews = 0;

  void _goToPageNotificate1(int pageIndexNotificate1) {
    _pageControlNotificate1.animateToPage(
      pageIndexNotificate1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPageNotificate2(int pageIndexNotificate2) {
    _pageControlNotificate2.animateToPage(
      pageIndexNotificate2,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  final List<Map<String, String>> imagesNoti = [
    {
      "TextNoti": "Free for VIP Member\nABC_SHOP",
    },
    {
      "TextNoti": "EASY E-RECEIPT\nABC_SHOP",
    },
    {
      "TextNoti": "CREDIT CARD PROMOTION\nABC_SHOP",
    },
    {
      "TextNoti": "STORES_WEEKLY\nABC_SHOP",
    },
    {
      "TextNoti": "GIFT CARD BALANCE CHECK\nABC_SHOP",
    },
  ];

  final List<Map<String, String>> messageSet = [
    {
      "messageImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303108/imgM1_nasssc.png",
      "messageText1": "เสื้อแมวสุดคิ้วท์ ลดพิเศษ!",
      "messageText2": "ใส่สบาย น่ารัก ต้องมีติดตู้!",
      "messageText3": "5/02/2025",
    },
    {
      "messageImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303108/imgM2_skzohs.png",
      "messageText1": "เสื้อแมวชุดเดท ลดพิเศษ!",
      "messageText2": "ใส่สบาย ดูดี ต้องมีติดตู้!",
      "messageText3": "5/02/2025",
    },
    {
      "messageImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303109/imgM3_gsjpdm.png",
      "messageText1": "เสื้อแมว Halloween ลดพิเศษ!",
      "messageText2": "ใส่สบาย เฟี้ยว ต้องมีติดตู้!",
      "messageText3": "5/02/2025",
    },
    {
      "messageImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303108/imgM4_f7vjl0.png",
      "messageText1": "เสื้อแมว Hoodie ลดพิเศษ!",
      "messageText2": "ใส่สบาย มีสไตล์ ต้องมีติดตู้!",
      "messageText3": "5/02/2025",
    },
    {
      "messageImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303109/imgM5_ifttmv.png",
      "messageText1": "เสื้อแมว Cyber ลดพิเศษ!",
      "messageText2": "ใส่สบาย เท่ ต้องมีติดตู้!",
      "messageText3": "5/02/2025",
    },
  ];

  final List<Map<String, String>> newsSet = [
    {
      "newsImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303110/imgNew1_oykobh.png",
      "newsText1": "เสื้อแมวสุดน่ารัก 199฿!",
      "newsText2": "ให้เจ้าเหมียวดูดี ใส่สบาย ในราคาสุดคุ้ม",
      "newsText3": "5/02/2025",
    },
    {
      "newsImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303109/imgNew2_e3l8dx.png",
      "newsText1": "เสื้อแมวสุดน่ารัก 299฿!",
      "newsText2": "ดีไซน์สุดคูล ใส่สบาย",
      "newsText3": "7/02/2025",
    },
    {
      "newsImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303110/imgNew3_uplaeh.png",
      "newsText1": "เสื้อแมวสุดคิ้วท์ราคาเบาๆ 399฿!",
      "newsText2": "ดีไซน์น่ารัก เหมาะกับทุกสายพันธุ์",
      "newsText3": "7/02/2025",
    },
    {
      "newsImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303110/imgNew4_ras0uw.png",
      "newsText1": "เสื้อแมวสุดน่ารัก! 499฿",
      "newsText2": "สวมใส่สบาย ดีไซน์เก๋ เหมาะกับทุกสายพันธุ์",
      "newsText3": "7/02/2025",
    },
    {
      "newsImg":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303110/imgNew5_wd3nra.png",
      "newsText1": "เสื้อแมวสุด หรูหรา 599฿!",
      "newsText2": "ดีไซน์สุดไฮโซ ใส่สบาย",
      "newsText3": "7/02/2025",
    },
  ];

  //List file "Image [ notification, message, news]"
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.wait(imagesNoti.map((item1) {
      final imageN = item1["imagesNoti"];
      if (imageN != null && imageN.isNotEmpty) {
        return precacheImage(AssetImage(imageN), context);
      } else {
        // not imagePath return Future
        return Future.value();
      }
    }).toList());
    Future.wait(messageSet.map((item2) {
      final imageMes = item2["messageSet"];
      if (imageMes != null && imageMes.isNotEmpty) {
        return precacheImage(AssetImage(imageMes), context);
      } else {
        // not imagePath return Future
        return Future.value();
      }
    }).toList());
    Future.wait(newsSet.map((item3) {
      final imageNew = item3["newsImg"];
      if (imageNew != null && imageNew.isNotEmpty) {
        return precacheImage(AssetImage(imageNew), context);
      } else {
        // not imagePath return Future
        return Future.value();
      }
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 135, // กำหนดความสูงของ PageView
            child: PageView.builder(
              controller: _pageControlNotificate1,
              itemCount: imagesNoti.length,
              scrollDirection: Axis.horizontal,
              // ปิดการเลื่อนของ PageView
              onPageChanged: (index) {
                setState(() {
                  actionPageNotificate1 = index;
                });
              },
              itemBuilder: (context, index) {
                final item1 = imagesNoti[index % imagesNoti.length];
                return Stack(
                  children: [
                    Container(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      child: Center(
                        child: Text(
                          item1['TextNoti']!,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 20,
                                  //color: Colors.black45,
                                  offset: Offset(2, 2),
                                ),
                              ]),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                  onTap: () {
                    _goToPageNotificate1(0);
                    setState(() {
                      actionPageNotificate1 = 0;
                    });
                  },
                  child: actionPageNotificate1 == 0
                      ? Icon(Icons.circle, size: 15)
                      : Icon(Icons.circle_outlined, size: 15)),
              SizedBox(width: 4),
              GestureDetector(
                  onTap: () {
                    _goToPageNotificate1(1);
                    setState(() {
                      actionPageNotificate1 = 1;
                    });
                  },
                  child: actionPageNotificate1 == 1
                      ? Icon(Icons.circle, size: 15)
                      : Icon(Icons.circle_outlined, size: 15)),
              SizedBox(width: 4),
              GestureDetector(
                  onTap: () {
                    _goToPageNotificate1(2);
                    setState(() {
                      actionPageNotificate1 = 2;
                    });
                  },
                  child: actionPageNotificate1 == 2
                      ? Icon(Icons.circle, size: 15)
                      : Icon(Icons.circle_outlined, size: 15)),
              SizedBox(width: 4),
              GestureDetector(
                  onTap: () {
                    _goToPageNotificate1(3);
                    setState(() {
                      actionPageNotificate1 = 3;
                    });
                  },
                  child: actionPageNotificate1 == 3
                      ? Icon(Icons.circle, size: 15)
                      : Icon(Icons.circle_outlined, size: 15)),
              SizedBox(width: 4),
              GestureDetector(
                  onTap: () {
                    _goToPageNotificate1(4);
                    setState(() {
                      actionPageNotificate1 = 4;
                    });
                  },
                  child: actionPageNotificate1 == 4
                      ? Icon(Icons.circle, size: 15)
                      : Icon(Icons.circle_outlined, size: 15))
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  _goToPageNotificate2(0);
                  setState(() {
                    actionPageTwo = 0;
                  });
                },
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: actionPageTwo == 0
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2.0)
                              : BorderSide(
                                  color: Color.fromARGB(0, 0, 0, 0),
                                  width: 2.0))),
                  child: Center(
                    child: Text(
                      languageProvider.translate(en: "Message", th: "ข้อความ"),
                      style: TextStyle(
                          color: actionPageTwo == 0
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: actionPageTwo == 0 ? 18 : 15),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  _goToPageNotificate2(1);
                  setState(() {
                    actionPageTwo = 1;
                  });
                },
                child: Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: actionPageTwo == 1
                              ? BorderSide(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2.0)
                              : BorderSide(
                                  color: Color.fromARGB(0, 0, 0, 0),
                                  width: 2.0))),
                  child: Center(
                    child: Text(
                      languageProvider.translate(en: "News", th: "ข่าว"),
                      style: TextStyle(
                          color: actionPageTwo == 1
                              ? Theme.of(context).colorScheme.surface
                              : Theme.of(context).colorScheme.onSurface,
                          fontSize: actionPageTwo == 1 ? 18 : 15),
                    ),
                  ),
                ),
              )
            ],
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface, height: 2),
          SizedBox(
            height: 450,
            child: PageView(
              controller: _pageControlNotificate2,
              scrollDirection: Axis.horizontal,
              onPageChanged: (indexS) {
                setState(() {
                  actionPageTwo = indexS;
                });
              },
              children: [
                Container(
                  decoration: BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
                  child: SizedBox(
                    child: PageView.builder(
                      controller: _pageControlPageMess,
                      itemCount: messageSet.length,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          actionMessage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final item2 = messageSet[index % messageSet.length];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CachedNetworkImage(
                                imageUrl: item2["messageImg"]!,
                                fit: BoxFit.cover,
                                width: 180,
                                height: 180,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(75, 50, 50, 50)),
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  height: 200,
                                  decoration: BoxDecoration(
                                      color: Color.fromARGB(0, 0, 0, 0)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item2["messageText1"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item2["messageText2"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 3,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item2["messageText3"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              //Divider(color: Colors.black12, height: 1),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  //decoration: BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
                  child: SizedBox(
                    child: PageView.builder(
                      controller: _pageControlPageNew,
                      itemCount: newsSet.length,
                      scrollDirection: Axis.vertical,
                      onPageChanged: (index) {
                        setState(() {
                          actionNews = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final item3 = newsSet[index % newsSet.length];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CachedNetworkImage(
                                imageUrl: item3["newsImg"]!,
                                fit: BoxFit.cover,
                                width: 180,
                                height: 180,
                                placeholder: (context, url) =>
                                    CircularProgressIndicator.adaptive(
                                  backgroundColor: Colors.white,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(75, 50, 50, 50)),
                                ),
                                errorWidget: (context, url, error) =>
                                    Icon(Icons.error),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(5),
                                  height: 200,
                                  //decoration: BoxDecoration(color: Color.fromARGB(0, 28, 22, 22)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item3["newsText1"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item3["newsText2"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 3,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item3["newsText3"]!,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 12,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              //Divider(color: Colors.black12, height: 1),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<MenuPage> {
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
                              MaterialPageRoute(builder: (context) => const MyOrderPage()), 
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
                              MaterialPageRoute(builder: (context) => const HistoryPage()), 
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
              Column(
                children: [
                  GestureDetector( 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HowToUsePage()), 
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
                                  en: "Learn how to use it", 
                                  th: "เรียนรู้วิธีใช้งาน"
                              ),
                              style: TextStyle(fontSize: 18)
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  GestureDetector( 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FAQPage()), 
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
                                  th: "คำถามที่พบบ่อย"
                              ),
                              style: TextStyle(fontSize: 18)
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  GestureDetector( 
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TermsOfUsePage()), 
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
                                  th: "ข้อกำหนดการใช้งาน"
                              ),
                              style: TextStyle(fontSize: 18)
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.rotationY(-180),
                              child: Icon(Icons.arrow_back_ios_new_outlined, size: 20),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1),
                  GestureDetector(  
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
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
                                th: "นโยบายความเป็นส่วนตัว"
                              ),
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
                  Divider(height: 1),
                ],
              ),
              SizedBox(height: 15),
              Center(
                  child: Text(
                      languageProvider.translate(
                          en: "Version: 4.0 | By 1DEV",
                          th: "เวอร์ชัน: 4.0 | โดย 1DEV"),
                      style: TextStyle(fontSize: 15)))
            ],
          ),
        )
      ],
    );
  }
}

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final PageController _pageControlShop1 = PageController(initialPage: 0);
  final PageController _pageControlShop2 = PageController(initialPage: 0);

  // ✅ แก้ไข: เพิ่ม List สำหรับเก็บข้อมูลจาก API
  List<Map<String, dynamic>> dataShoplike = [];
  List<Map<String, dynamic>> dataShopSeller = [];
  bool isLoadingLike = true;
  bool isLoadingSeller = true;
  String errorMessageLike = '';
  String errorMessageSeller = '';

  // ฟังก์ชันสำหรับหา Base URL ที่ถูกต้องตาม Platform
  String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchShoplike();
    fetchShopseller();
  }

  // ✅ gender
  String getGenderText(dynamic gender) {
    final genderCode =
        gender is int ? gender : int.tryParse(gender?.toString() ?? '');

    switch (genderCode) {
      case 0:
        return 'Unisex';
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      case 3:
        return 'Kitten';
      default:
        return 'N/A';
    }
  }

  // ✅ แก้ไข: ดึงข้อมูล "You might like"
  Future<void> fetchShoplike() async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/clothing-shop/like';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> parsedImages = [];

        if (data is List) {
          parsedImages = data.map<Map<String, dynamic>>((item) {
            final rawImages = item['images'];
            return {
              ...item,
              'images': rawImages is String ? jsonDecode(rawImages) : rawImages,
            };
          }).toList();
        } else if (data is Map && data.containsKey('data')) {
          parsedImages = List<Map<String, dynamic>>.from(
            data['data'].map<Map<String, dynamic>>((item) {
              final rawImages = item['images'];
              return {
                ...item,
                'images':
                    rawImages is String ? jsonDecode(rawImages) : rawImages,
              };
            }),
          );
        }

        setState(() {
          dataShoplike = parsedImages;
          isLoadingLike = false;
        });
      } else {
        setState(() {
          errorMessageLike = 'ไม่สามารถโหลดข้อมูลได้ (${response.statusCode})';
          isLoadingLike = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessageLike = 'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend';
        isLoadingLike = false;
      });
    } on TimeoutException {
      setState(() {
        errorMessageLike = 'หมดเวลาการเชื่อมต่อ';
        isLoadingLike = false;
      });
    } catch (e) {
      setState(() {
        errorMessageLike = 'เกิดข้อผิดพลาด: $e';
        isLoadingLike = false;
      });
    }
  }

  // ✅ แก้ไข: ดึงข้อมูล "Best Seller"
  Future<void> fetchShopseller() async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/clothing-shop/seller';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> parsedImages = [];

        if (data is List) {
          parsedImages = data.map<Map<String, dynamic>>((item) {
            final rawImages = item['images'];
            return {
              ...item,
              'images': rawImages is String ? jsonDecode(rawImages) : rawImages,
            };
          }).toList();
        } else if (data is Map && data.containsKey('data')) {
          parsedImages = List<Map<String, dynamic>>.from(
            data['data'].map<Map<String, dynamic>>((item) {
              final rawImages = item['images'];
              return {
                ...item,
                'images':
                    rawImages is String ? jsonDecode(rawImages) : rawImages,
              };
            }),
          );
        }

        setState(() {
          dataShopSeller = parsedImages;
          isLoadingSeller = false;
        });
      } else {
        setState(() {
          errorMessageSeller =
              'ไม่สามารถโหลดข้อมูลได้ (${response.statusCode})';
          isLoadingSeller = false;
        });
      }
    } on SocketException {
      setState(() {
        errorMessageSeller = 'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend';
        isLoadingSeller = false;
      });
    } on TimeoutException {
      setState(() {
        errorMessageSeller = 'หมดเวลาการเชื่อมต่อ';
        isLoadingSeller = false;
      });
    } catch (e) {
      setState(() {
        errorMessageSeller = 'เกิดข้อผิดพลาด: $e';
        isLoadingSeller = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1741695217/cat3_xvd0mu.png",
                  width: 50,
                  height: 50,
                  placeholder: (context, url) =>
                      CircularProgressIndicator.adaptive(
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(75, 50, 50, 50)),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => Profile()));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 30),
                      Text(
                        languageProvider.translate(
                            en: "Profile", th: "โปรไฟล์"),
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface, height: 1),
          SizedBox(height: 10),

          // ✅ Section: You might like
          Container(
            child: Column(
              children: [
                Center(
                  child: Text(
                    languageProvider.translate(
                        en: "You might like this", th: "คุณอาจจะชอบสิ่งนี้"),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // ✅ แสดง Loading, Error หรือข้อมูล
                isLoadingLike
                    ? SizedBox(
                        height: 490,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : errorMessageLike.isNotEmpty
                        ? SizedBox(
                            height: 490,
                            child: Center(child: Text(errorMessageLike)),
                          )
                        : dataShoplike.isEmpty
                            ? SizedBox(
                                height: 490,
                                child: Center(child: Text('ไม่มีข้อมูล')),
                              )
                            : SizedBox(
                                height: 490,
                                child: PageView.builder(
                                  controller: _pageControlShop1,
                                  itemCount: dataShoplike.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final item = dataShoplike[index];
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl:
                                                item["image_url"]?.toString() ??
                                                    '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 350,
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator
                                                    .adaptive(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                getGenderText(item['gender']),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              Text(
                                                item['size_category']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item['clothing_name']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              Text(
                                                'Items: ${item['stock']}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${item['price']?.toString() ?? '0'} ฿',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              FloatingActionButton.small(
                                                onPressed: () {
                                                  // Add to cart logic
                                                },
                                                child: Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 30,
                                                  color: Theme.of(context)
                                                      .floatingActionButtonTheme
                                                      .foregroundColor,
                                                ),
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .floatingActionButtonTheme
                                                    .backgroundColor,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ],
            ),
          ),

          // ✅ Section: Best Seller
          Container(
            child: Column(
              children: [
                Center(
                  child: Text(
                    languageProvider.translate(
                        en: "Best Seller", th: "สินค้าขายดี"),
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                isLoadingSeller
                    ? SizedBox(
                        height: 490,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : errorMessageSeller.isNotEmpty
                        ? SizedBox(
                            height: 490,
                            child: Center(child: Text(errorMessageSeller)),
                          )
                        : dataShopSeller.isEmpty
                            ? SizedBox(
                                height: 490,
                                child: Center(child: Text('ไม่มีข้อมูล')),
                              )
                            : SizedBox(
                                height: 490,
                                child: PageView.builder(
                                  controller: _pageControlShop2,
                                  itemCount: dataShopSeller.length,
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, index) {
                                    final item = dataShopSeller[index];
                                    return Container(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: Column(
                                        children: [
                                          CachedNetworkImage(
                                            imageUrl:
                                                item["image_url"]?.toString() ??
                                                    '',
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 350,
                                            placeholder: (context, url) =>
                                                CircularProgressIndicator
                                                    .adaptive(),
                                            errorWidget:
                                                (context, url, error) =>
                                                    Icon(Icons.error),
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                getGenderText(item['gender']),
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              Text(
                                                item['size_category']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item['clothing_name']
                                                        ?.toString() ??
                                                    'N/A',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                ),
                                              ),
                                              Text(
                                                'Items: ${item['stock']}',
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                '${item['price']?.toString() ?? '0'} ฿',
                                                style: TextStyle(
                                                  fontSize: 20,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              FloatingActionButton.small(
                                                onPressed: () {
                                                  // Add to cart logic
                                                },
                                                child: Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 30,
                                                  color: Theme.of(context)
                                                      .floatingActionButtonTheme
                                                      .foregroundColor,
                                                ),
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .floatingActionButtonTheme
                                                    .backgroundColor,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
