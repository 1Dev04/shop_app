// ----ShopPage--------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/profile_user.dart';
import 'package:http/http.dart' as http;


import 'package:provider/provider.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final PageController _pageControlShop1 = PageController(initialPage: 0);
  final PageController _pageControlShop2 = PageController(initialPage: 0);

  
  List<Map<String, dynamic>> dataShoplike = [];
  List<Map<String, dynamic>> dataShopSeller = [];
  bool isLoadingLike = true;
  bool isLoadingSeller = true;
  String errorMessageLike = '';
  String errorMessageSeller = '';

 
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
