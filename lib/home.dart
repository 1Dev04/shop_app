import 'package:flutter/material.dart';
import 'package:flutter_application_1/profile.dart';

// import 'package:flutter_application_1/login.dart';
import 'package:flutter_application_1/viewAccount.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'dart:async';
import './addForm.dart';

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
    ProfilePage(),
  ];

  //Set Header Title
  String setTitle() {
    if (screenIndex == 0) {
      return "Search";
    } else if (screenIndex == 1) {
      return "Favorites";
    } else if (screenIndex == 2) {
      return "ABC_shop";
    } else if (screenIndex == 3) {
      return "Shops";
    } else if (screenIndex == 4) {
      return "Notification";
    } else if (screenIndex == 5) {
      return "Profile";
    }

    return setTitle();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        //------------------- AppBar -------------------
        appBar: AppBar(
          title: Text(
            setTitle(),
            style: TextStyle(
                color: Colors.white, fontFamily: 'Catfont', fontSize: 30),
          ),
          backgroundColor: Color.fromRGBO(0, 0, 0, 0.938),
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
                size: 25,
                color: activeButton == 0 ? Colors.white : Colors.white60,
              ),
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
                size: 25,
                color: activeButton == 1 ? Colors.white : Colors.white60,
              ),
            ),
            IconButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => ViewAccount()));
                },
                icon: Icon(Icons.add_chart_outlined, color: Colors.white)),
            SizedBox(width: 15)
          ],
        ),
        //------------------- body -------------------
        body: SafeArea(
          child: mobileScreen[screenIndex],
        ),

        //------------------- bottomNavigationBar -------------------
        bottomNavigationBar: Container(
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            color: Color.fromRGBO(0, 0, 0, 0.938),
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
                  size: 25,
                  color: activeButton == 2 ? Colors.white : Colors.white60,
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
                      ? Icons.shopping_cart_rounded
                      : Icons.shopping_cart_outlined,
                  size: 25,
                  color: activeButton == 3 ? Colors.white : Colors.white60,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    screenPushIndex = 2;
                  });

                  Navigator.push(context,
                          MaterialPageRoute(builder: (context) => addForm()))
                      .then((_) {
                    setState(() {
                      screenIndex = 2;
                      activeButton = 2;
                    });
                  });
                },
                child: Icon(Icons.add, color: Colors.white),
              ),
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
                  size: 25,
                  color: activeButton == 4 ? Colors.white : Colors.white60,
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
                  screenIndex == 5 ? Icons.person : Icons.person_outline,
                  size: 25,
                  color: activeButton == 5 ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
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
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
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
                          "FEMALE",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1, // ความหนาของเส้นใต้
                            decorationColor:
                                Color.fromARGB(255, 0, 0, 0), // สีของเส้นใต้
                            height: 3,
                          ),
                        )
                      : Text("FEMALE",
                          style: TextStyle(
                            color: Color.fromARGB(255, 40, 40, 40),
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
                          "MALE",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1, // ความหนาของเส้นใต้
                            decorationColor:
                                Color.fromARGB(255, 0, 0, 0), // สีของเส้นใต้
                            height: 3,
                          ),
                        )
                      : Text("MALE",
                          style: TextStyle(
                            color: Color.fromARGB(255, 40, 40, 40),
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
                          "KITTEN",
                          style: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationThickness: 1, // ความหนาของเส้นใต้
                            decorationColor:
                                Color.fromARGB(255, 0, 0, 0), // สีของเส้นใต้
                            height: 3,
                          ),
                        )
                      : Text("KITTEN",
                          style: TextStyle(
                            color: Color.fromARGB(255, 40, 40, 40),
                            height: 3,
                          )),
                ),
              ],
            ),
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Female 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288948/F1-removebg-preview_b0vnu5.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
                                borderRadius: BorderRadius.circular(5)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1740288947/F2-removebg-preview_upsxlj.png",
                                  width: 50,
                                  height: 50,
                                  placeholder: (context, url) =>
                                      CircularProgressIndicator.adaptive(
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Female 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Female 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Female 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Female 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Male 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Male 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Male 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Male 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Male 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Kittin 1
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Kittin 3
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Kittin 5
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Kittin 7
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //Kittin 9
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5),
                          child: Container(
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                            width: 170,
                            height: 70,
                            decoration: BoxDecoration(
                                color: Color.fromARGB(5, 0, 0, 0),
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
                                    backgroundColor: Colors.white,
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
                                      color: Color.fromRGBO(0, 0, 0, 1),
                                      fontSize: 12,
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
                    labelText: 'What are you looking for',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 400,
            height: 50,
            decoration: BoxDecoration(color: Color.fromARGB(15, 0, 0, 0)),
            padding: EdgeInsets.all(10),
            child: Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Text(
                "0 list",
                style: TextStyle(fontSize: 15),
              )
            ]),
          ),
        ),
        Container(
          color: const Color.fromARGB(0, 0, 0, 0),
          width: 400,
          height: 410,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.pets_rounded, size: 80),
              SizedBox(height: 20),
              Text(
                "0 items in your favorites",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 5),
              Text(
                "Add products to your favorites list to check prices and stock availability.",
                style: TextStyle(fontSize: 10, color: Colors.black54),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(initialPage: 1000);
  final List<Map<String, String>> images = [
    {
      "image":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303107/Gen1_myeyh2.jpg",
      "title": "V-neck T-shirt",
      "description": "เสื้อแมวยืด สีดำ คอวี ผ้าคอตตอน 100% นุ่มสบาย",
      "price": "180THB",
    },
    {
      "image":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303106/Gen2_djp2gr.jpg",
      "title": "Round neck T-shirt",
      "description": "เสื้อแมวยืด สีขาว คอกลม ผ้าคอตตอน 100% นุ่มสบาย",
      "price": "150THB",
    },
    {
      "image":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303107/Gen3_ixstbu.jpg",
      "title": "Hoodie Jacket",
      "description": "เสื้อแมวแจ็คเก็ตฮู้ดดี้ สีเทา ผ้าเนื้อหนา ทนทาน",
      "price": "300THB",
    },
    {
      "image":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303107/Gen4_w7drxe.jpg",
      "title": "Sleeveless Top",
      "description": "เสื้อแมวแขนกุด ผ้าเนื้อบางเบา ระบายอากาศดี",
      "price": "120THB",
    },
    {
      "image":
          "https://res.cloudinary.com/dag73dhpl/image/upload/v1740303107/Gen5_zr8dij.jpg",
      "title": "Polo Shirt",
      "description": "เสื้อแมวโปโล สีฟ้า ผ้าคอตตอน ระบายความร้อนได้ดี",
      "price": "250THB",
    },
  ];

  Timer? timer;
  bool isUserInteracting = false;

  @override
  void dispose() {
    timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void startAutoScroll() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!isUserInteracting) {
        if (_pageController.hasClients) {
          final nextPage = (_pageController.page ?? 0) + 1;
          _pageController.animateToPage(
            nextPage.toInt() % images.length,
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

  //List file "images"
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    Future.wait(images.map((item) {
      final imagePath = item["image"];
      if (imagePath != null && imagePath.isNotEmpty) {
        return precacheImage(AssetImage(imagePath), context);
      } else {
        // not imagePath return Future
        return Future.value();
      }
    }).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanDown: (_) {
          // user: action | auto: break
          isUserInteracting = true;
          stopAutoScroll();
        },
        onPanCancel: () {
          // user: break | auto: action
          isUserInteracting = false;
          startAutoScroll();
        },
        onPanEnd: (_) {
          // user: dont touch | auto: action
          isUserInteracting = false;
          startAutoScroll();
        },
        child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemBuilder: (context, index) {
              final item = images[index % images.length];
              return Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: item['image']!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  Positioned(
                    bottom: 200,
                    left: 20,
                    child: Text(
                      item['title']!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black38,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 140,
                    left: 20,
                    right: 20,
                    child: Text(
                      item['description']!,
                      style: TextStyle(
                        color: Color.fromRGBO(255, 255, 255, 1),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black87,
                            offset: Offset(2, 2),
                          ),
                        ],
                      ),
                      maxLines: 3,
                      // overflow: TextOverflow.ellipsis, // ...
                      softWrap: true, // new line
                    ),
                  ),
                  Positioned(
                    bottom: 90,
                    left: 20,
                    right: 20,
                    child: Text(
                      item['price']!,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 5,
                              color: Colors.black38,
                              offset: Offset(2, 2),
                            )
                          ]),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 30,
                    child: FloatingActionButton.small(
                      onPressed: () {
                        Navigator();
                      },
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.black,
                      ),
                      backgroundColor: Color.fromARGB(194, 255, 250, 250),
                    ),
                  )
                ],
              );
            }),
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
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 120, // กำหนดความสูงของ PageView
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
                      color: Colors.white,
                      child: Center(
                        child: Text(
                          item1['TextNoti']!,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  blurRadius: 5,
                                  color: Colors.black45,
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
                  height: 40,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: actionPageTwo == 0
                              ? BorderSide(color: Colors.black, width: 2.0)
                              : BorderSide(
                                  color: Color.fromARGB(0, 0, 0, 0),
                                  width: 2.0))),
                  child: Center(
                    child: Text(
                      "Message",
                      style: TextStyle(
                          color: actionPageTwo == 0
                              ? Colors.black
                              : Colors.black38),
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
                  height: 40,
                  decoration: BoxDecoration(
                      border: Border(
                          bottom: actionPageTwo == 1
                              ? BorderSide(color: Colors.black, width: 2.0)
                              : BorderSide(
                                  color: Color.fromARGB(0, 0, 0, 0),
                                  width: 2.0))),
                  child: Center(
                    child: Text(
                      "News",
                      style: TextStyle(
                          color: actionPageTwo == 1
                              ? Colors.black
                              : Colors.black38),
                    ),
                  ),
                ),
              )
            ],
          ),
          Divider(color: Colors.black12, height: 2),
          SizedBox(
            height: 250,
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
                  padding: EdgeInsets.all(1),
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
                                width: 150,
                                height: 150,
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
                                  height: 120,
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
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item2["messageText2"]!,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 3,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item2["messageText3"]!,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
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
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
                  child: SizedBox(
                    height: 100,
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
                                width: 150,
                                height: 150,
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
                                  height: 120,
                                  decoration: BoxDecoration(
                                      color: Color.fromARGB(0, 0, 0, 0)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item3["newsText1"]!,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 2,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item3["newsText2"]!,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        maxLines: 3,
                                        softWrap: true,
                                      ),
                                      Text(
                                        item3["newsText3"]!,
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 10,
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

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => Profile()));
                    },
                    child: Container(
                      padding: EdgeInsets.all(5),
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(15, 0, 0, 0),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.badge_outlined),
                          Text('Profile'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(15, 0, 0, 0),
                          borderRadius: BorderRadius.circular(5)),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.archive_outlined),
                            Text('My Orders')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(5),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(15, 0, 0, 0),
                          borderRadius: BorderRadius.circular(5)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined),
                          Text('Order List')
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(15, 0, 0, 0),
                          borderRadius: BorderRadius.circular(5)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.confirmation_num_outlined),
                          Text('Coupon')
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(15, 0, 0, 0),
                          borderRadius: BorderRadius.circular(5)),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt_outlined),
                            Text('Survey Branch')
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(10),
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                          color: Color.fromARGB(15, 0, 0, 0),
                          borderRadius: BorderRadius.circular(5)),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined),
                          Text('Setting')
                        ],
                      ),
                    ),
                  )
                ],
              ),
              SizedBox(height: 10),
              Column(
                children: [
                  Container(
                    width: 400,
                    height: 50,
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
                          child: Text('Find branch locations'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  10), //padding = ระยะขอบ //horizontal = ซ้ายและขวา
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(-180), // rotate
                            child: Icon(Icons.arrow_back_ios_new_outlined,
                                size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.black12, height: 1),
                  Container(
                    width: 400,
                    height: 50,
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
                          child: Text('Learn how to use it'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  10), //padding = ระยะขอบ //horizontal = ซ้ายและขวา
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(-180), // rotate
                            child: Icon(Icons.arrow_back_ios_new_outlined,
                                size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.black12, height: 1),
                  Container(
                    width: 400,
                    height: 50,
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
                          child: Text('Frequently asked questions'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  10), //padding = ระยะขอบ //horizontal = ซ้ายและขวา
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(-180), // rotate
                            child: Icon(Icons.arrow_back_ios_new_outlined,
                                size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.black12, height: 1),
                  Container(
                    width: 400,
                    height: 50,
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
                          child: Text('Terms of Use'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  10), //padding = ระยะขอบ //horizontal = ซ้ายและขวา
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(-180), // rotate
                            child: Icon(Icons.arrow_back_ios_new_outlined,
                                size: 20),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.black12, height: 1),
                  Container(
                    width: 400,
                    height: 50,
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
                          child: Text('Privacy Policy'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                                  10), //padding = ระยะขอบ //horizontal = ซ้ายและขวา
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.rotationY(-180), // rotate
                            child: Icon(
                              Icons.arrow_back_ios_new_outlined,
                              size: 20,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  Divider(color: Colors.black12, height: 1),
                ],
              ),
              SizedBox(height: 10),
              Center(
                  child: Text("Version: 1.0 | By 1DEV",
                      style: TextStyle(color: Colors.black54)))
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
  bool lightIsOn = false;
  bool homeIsOn = false;
  bool heartIsOn = false;
  Color homeDefaultColor = Colors.black;

  IconData iconDefault = Icons.favorite_border_outlined;
  Color heartDefaultColor = Colors.black;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(15), //เว้นระยะรอบวัตถุ 15 pixel
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                lightIsOn = !lightIsOn;
              });
            },
            child: Icon((Icons.lightbulb),
                // ignore: dead_code
                size: 50,
                color: lightIsOn ? Colors.yellow : Colors.black),
          ),
          GestureDetector(
            onDoubleTap: () {
              setState(() {
                homeIsOn = !homeIsOn;
                homeDefaultColor = homeIsOn ? Colors.blue : Colors.black;
              });
            },
            onTap: () {
              setState(() {
                homeIsOn = !homeIsOn;
                homeDefaultColor = homeIsOn ? Colors.green : Colors.black;
              });
            },
            child: Icon(
              (Icons.home),
              size: 50,
              color: homeDefaultColor,
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                heartIsOn = !heartIsOn;
                iconDefault =
                    heartIsOn ? Icons.favorite : Icons.favorite_border_outlined;
                heartDefaultColor = heartIsOn ? Colors.red : Colors.black;
              });
            },
            child: Icon(
              iconDefault,
              size: 50,
              color: heartDefaultColor,
            ),
          ),
        ],
      ),
    );
  }
}
