// ----HomePage (Fixed)--------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:provider/provider.dart';

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
    } else if (Platform.isIOS) {
      return 'http://localhost:8000'; // สำหรับ iOS Simulator
    } else {
      return 'http://localhost:8000';
    }
  }

  // ฟังก์ชันแปลงค่าเป็น double (รองรับทั้ง String และ number)
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
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

  // ดึงข้อมูลรายละเอียดสินค้า
  Future<Map<String, dynamic>?> fetchItemDetails(int itemId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/home-advertiment/$itemId';

      print('🔍 Fetching details from: $url'); // Debug

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📡 Response status: ${response.statusCode}'); // Debug
      print('📦 Response body: ${response.body}'); // Debug

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // 🔥 ตรวจสอบว่าข้อมูลอยู่ใน key 'data' หรือไม่
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        }

        return data;
      } else {
        print('❌ Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching item details: $e');
      return null;
    }
  }

  // แสดง Popup รายละเอียดสินค้า
  void showItemDetailsPopup(int itemId) async {
    // แสดง loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    final itemDetails = await fetchItemDetails(itemId);

    // ปิด loading dialog
    Navigator.of(context).pop();

    if (itemDetails != null) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return ItemDetailsCard(itemDetails: itemDetails);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          // Slide from top + Fade animation
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          var offsetAnimation = animation.drive(tween);
          var fadeAnimation = animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            ),
          );

          return SlideTransition(
            position: offsetAnimation,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: child,
            ),
          );
        },
      );
    } else {
      // แสดง error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ไม่สามารถโหลดข้อมูลได้'),
          backgroundColor: Colors.red,
        ),
      );
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
    final languageProvider = Provider.of<LanguageProvider>(context);

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

            // 🔥 แก้ไข: แปลง discount_price เป็น double ก่อนเปรียบเทียบ
            final discountPrice = parseDouble(item['discount_price']);
            final hasDiscount = discountPrice > 0;

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
                  bottom: 170,
                  left: 20,
                  width: 300,
                  child: Text(
                    item['clothing_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
                
                // ส่วนแสดงราคา
                Positioned(
                  bottom: 130,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ราคาปกติ (ถ้ามีส่วนลดจะขีดฆ่า)
                      if (hasDiscount)
                        Text(
                          '฿${item['price']?.toString() ?? ''}',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 20,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.white70,
                            decorationThickness: 2,
                            shadows: [
                              Shadow(
                                blurRadius: 20,
                                color: Colors.black.withOpacity(0.7),
                                offset: Offset(2, 2),
                              )
                            ],
                          ),
                        ),

                      // ราคาหลังหักส่วนลด
                      if (hasDiscount) SizedBox(width: 10),
                      Text(
                        hasDiscount
                            ? '฿${discountPrice.toStringAsFixed(0)}'
                            : '฿${item['price']?.toString() ?? ''}',
                        style: TextStyle(
                          color: hasDiscount ? Colors.yellow : Colors.white,
                          fontSize: 25,
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

                      // แสดง % ส่วนลด
                      if (hasDiscount) SizedBox(width: 10),
                      if (hasDiscount)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${item['discount_percent']?.toString() ?? '0'}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          FloatingActionButton.small(
                            onPressed: () {},
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 30,
                              color: Theme.of(context)
                                  .floatingActionButtonTheme
                                  .foregroundColor,
                            ),
                            backgroundColor: Theme.of(context)
                                .floatingActionButtonTheme
                                .backgroundColor,
                          ),
                          SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () {
                              // 🔥 แปลง id เป็น int
                              final itemId =
                                  int.tryParse(item['id']?.toString() ?? '0') ??
                                      0;
                              showItemDetailsPopup(itemId);
                            },
                            child: Text(
                              languageProvider.translate(
                                en: 'Learn More',
                                th: 'ดูเพิ่มเติม',
                              ),
                            ),
                          ),
                        ],
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

// Widget สำหรับแสดง Popup รายละเอียดสินค้า
class ItemDetailsCard extends StatelessWidget {
  final Map<String, dynamic> itemDetails;

  const ItemDetailsCard({
    super.key,
    required this.itemDetails,
  });

  // ฟังก์ชันแปลงค่าเป็น double
  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 แก้ไข: แปลง discount_price เป็น double ก่อนเปรียบเทียบ
    final discountPrice = parseDouble(itemDetails['discount_price']);
    final languageProvider = Provider.of<LanguageProvider>(context);

    final hasDiscount = discountPrice > 0;

    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  // Positioned(
                  //   top: 6,
                  //   right: 6,
                  //   child: GestureDetector(
                  //     onTap: () {

                  //     },
                  //     child: Container(
                  //       padding: EdgeInsets.all(6),
                  //       decoration: BoxDecoration(
                  //         color: Colors.black.withOpacity(0.1),
                  //         shape: BoxShape.circle,
                  //       ),
                  //       child: Icon(
                  //         Icons.favorite,
                  //         color:  Colors.white,
                  //         size: 18,
                  //       ),
                  //     ),
                  //   ),
                  // ),
                // รูปภาพสินค้า
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: itemDetails['image_url'] ?? '',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      child: Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อสินค้า
                      Text(
                        itemDetails['clothing_name'] ?? '',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                

                      
                      SizedBox(height: 5),


                      // รายละเอียดสินค้า
                      if (itemDetails['description'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'รายละเอียด',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              itemDetails['description'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 16),
                          ],
                        ),

                        _DetailRow(
                          label: languageProvider.translate(
                              en: 'Category',
                              th: 'หมวดหมู่',
                            ),
                            value: itemDetails['category'],
                        ),
                         _DetailRow(
                          label: languageProvider.translate(
                              en: 'Size',
                              th: 'ขนาด',
                            ),
                            value: itemDetails['size_category'],
                        ),


                      // ราคา
                      Row(
                        children: [
                          if (hasDiscount)
                            Text(
                              '฿${itemDetails['price']?.toString() ?? ''}',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2,
                              ),
                            ),
                          if (hasDiscount) SizedBox(width: 10),
                          Text(
                            hasDiscount
                                ? '฿${discountPrice.toStringAsFixed(0)}'
                                : '฿${itemDetails['price']?.toString() ?? ''}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? Colors.red : Colors.black,
                            ),
                          ),
                          if (hasDiscount) SizedBox(width: 10),
                          if (hasDiscount)
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${itemDetails['discount_percent']?.toString() ?? '0'}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // ปุ่มปิด
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.black,
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => {},
                            icon: Icon(Icons.add_shopping_cart_sharp),
                            label: Text(
                              languageProvider.translate(
                                en: 'Add to Cart',
                                th: 'เพิ่มลงตะกร้า',
                              ),
                              style: TextStyle(
                                fontSize: 16
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}