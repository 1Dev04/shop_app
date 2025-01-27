import 'package:flutter/material.dart';
import 'dart:async';
import './addForm.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        //------------------- AppBar -------------------
        appBar: AppBar(
          title: Text('ABC_Shop', style: TextStyle(color: Colors.white)),
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
                    screenIndex = 3;
                    activeButton = 3;
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
                    screenPushIndex = 1;
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
                          "WOMEN",
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
                      : Text("WOMEN",
                          style: TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              height: 3,)
                          ),               
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
                          "MEN",
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
                      : Text("MEN",
                          style: TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              height: 3,)
                          ),      
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
                          "KIDS",
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
                      : Text("KIDS",
                          style: TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              height: 3,)
                          ),      
                ),
                GestureDetector(
                  onTap: () {
                    _goToPageSearch(3);
                    setState(() {
                      actionPageSearch = 3;
                    });
                  },
                  child: actionPageSearch == 3
                      ? Text(
                          "BABY",
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
                      : Text("BABY",
                          style: TextStyle(
                              color: Color.fromARGB(255, 40, 40, 40),
                              height: 3,)
                          ),      
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
              Center(child: Text("WOMEN PAGE", style: TextStyle(fontSize: 24))),
              Center(child: Text("MEN PAGE", style: TextStyle(fontSize: 24))),
              Center(child: Text("KIDS PAGE", style: TextStyle(fontSize: 24))),
              Center(child: Text("BABY PAGE", style: TextStyle(fontSize: 24))),
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
    return Text("Favorite");
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
  @override
  Widget build(BuildContext context) {
    return Text("Notification");
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
      children: [Text("Profile Page")],
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
