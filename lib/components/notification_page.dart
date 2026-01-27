// ----NotificationPage--------------------------------------------------------------------------

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:provider/provider.dart';

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
