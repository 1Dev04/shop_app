import 'package:flutter/material.dart';
import 'dart:async';
import './addForm.dart';
import './login.dart';

//import 'package:flutter_application_1/landPage.dart';

void main() {
  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var screenIndex = 2;
  int activeButton = 2;

  var screenPushIndex = 0;

  final mobileScreen = [
    SearchPage(),
    FavoritePage(),
    HomePage(),
    ShopPage(),
    NotificationPage(),
    ProfilePage()
  ];

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
            style: TextStyle(color: Colors.white),
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
                  setState(() {
                    screenPushIndex = 1;
                  });

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
                },
                child: Icon(
                  screenIndex == 3
                      ? Icons.shopping_cart_rounded
                      : Icons.shopping_cart_outlined,
                  size: 25,
                  color: activeButton == 3 ? Colors.white : Colors.white60,
                ),
              ),
              FloatingActionButton(
                onPressed: () {
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100)),
                backgroundColor: Color.fromARGB(156, 81, 81, 81),
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
            children: [],
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
      "image": "assets/images/Gen1.jpg",
      "title": "V-neck T-shirt",
      "description": "เสื้อยืด สีดำ คอวี ผ้าคอตตอน 100% นุ่มสบาย",
      "price": "180THB",
    },
    {
      "image": "assets/images/Gen2.jpg",
      "title": "Round neck T-shirt",
      "description": "เสื้อยืด สีขาว คอกลม ผ้าคอตตอน 100% นุ่มสบาย",
      "price": "150THB",
    },
    {
      "image": "assets/images/Gen3.jpg",
      "title": "Hoodie Jacket",
      "description": "เสื้อแจ็คเก็ตฮู้ดดี้ สีเทา ผ้าเนื้อหนา ทนทาน",
      "price": "300THB",
    },
    {
      "image": "assets/images/Gen4.jpg",
      "title": "Sleeveless Top",
      "description": "เสื้อแขนกุด ผ้าเนื้อบางเบา ระบายอากาศดี",
      "price": "120THB",
    },
    {
      "image": "assets/images/Gen5.jpg",
      "title": "Polo Shirt",
      "description": "เสื้อโปโล สีฟ้า ผ้าคอตตอน ระบายความร้อนได้ดี",
      "price": "250THB",
    },
  ];

  Timer? timer;
  bool isUserInteracting = false;

  @override
  void initState() {
    super.initState(); // ใช้งาน คลาส แม่
    startAutoScroll(); // AutoSlide
  }

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
                  Image.asset(
                    item['image']!,
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
  final PageController _pageControlPageMess = PageController(initialPage: 0);

  int actionPageNotificate1 = 0;
  int actionPageTwo = 0;

  void _goToPageNotificate1(int pageIndexNotificate1) {
    _pageControlNotificate1.animateToPage(
      pageIndexNotificate1,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToPageNotificate2(int pageIndexNotificate2) {
    _pageControlPageMess.animateToPage(
      pageIndexNotificate2,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  final List<Map<String, String>> imagesNoti = [
    {"imagesNoti": "assets/imagesNoti/imgN1.png"},
    {"imagesNoti": "assets/imagesNoti/imgN2.png"},
    {"imagesNoti": "assets/imagesNoti/imgN3.png"},
    {"imagesNoti": "assets/imagesNoti/imgN4.png"},
    {"imagesNoti": "assets/imagesNoti/imgN5.png"}
  ];

  final List<Map<String, String>> messageSet = [
    {"messageImg": "assets/messageImg/imgN5.png"},
    {"messageImg": "assets/messageImg/imgN6.png"},
    {"messageImg": "assets/messageImg/imgN7.png"},
  ];

  final List<Map<String, String>> newsSet = [
    {"newsImg": "assets/imagesNoti/imgN1.png"},
    {"newsImg": "assets/imagesNoti/imgN2.png"},
    {"newsImg": "assets/imagesNoti/imgN3.png"},
    {"newsImg": "assets/imagesNoti/imgN4.png"},
    {"newsImg": "assets/imagesNoti/imgN5.png"}
  ];

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
              physics: BouncingScrollPhysics(), // ปิดการเลื่อนของ PageView
              onPageChanged: (index) {
                setState(() {
                  actionPageNotificate1 = index;
                });
              },
              itemBuilder: (context, index) {
                final item1 = imagesNoti[index % imagesNoti.length];
                return Stack(
                  children: [
                    Image.asset(
                      item1['imagesNoti']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 120,
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
          SizedBox(height: 10),
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
            height: 300,
            child: PageView(
              controller: _pageControlPageMess,
              scrollDirection: Axis.horizontal,
              onPageChanged: (indexS) {
                setState(() {
                  actionPageTwo = indexS;
                });
              },
              children: [
                Container(
                  decoration: BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
                  child: Column(
                    children: [
                      Container(
                          padding: EdgeInsets.all(15),
                          decoration:
                              BoxDecoration(color: Color.fromARGB(5, 0, 0, 0)),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/messageImg/imgN5.png',
                                fit: BoxFit.cover,
                                width: 100,
                                height: 120,
                              ),
                              SizedBox(
                                height: 20,
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                width: 230,
                                height: 120,
                                decoration: BoxDecoration(
                                    color: Color.fromARGB(0, 0, 0, 0)),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "เสื้อแมวสุดคิ้วท์ ลดพิเศษ!",
                                      style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "ใส่สบาย น่ารัก ต้องมีติดตู้!",
                                      style: TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal),
                                    ),
                                    Text("5/02/2025",
                                        style: TextStyle(
                                            color: Colors.black54,
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal)),
                                  ],
                                ),
                              )
                            ],
                          )),
                      Divider(color: Colors.black12, height: 1),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(color: Color.fromARGB(0, 0, 0, 0)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            child: Image.asset(
                              'assets/messageImg/imgN7.png',
                              fit: BoxFit.cover,
                              width: 100,
                              height: 120,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                )
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
                        children: [Icon(Icons.badge_outlined), Text('Profile')],
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
