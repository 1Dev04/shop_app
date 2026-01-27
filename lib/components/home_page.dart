// ----HomePage--------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

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
                  bottom: 170,
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
                // Positioned(
                //   bottom: 160,
                //   left: 20,
                //   right: 20,
                //   child: Text(
                //     item['description'] ?? '',
                //     style: TextStyle(
                //       color: const Color.fromARGB(238, 255, 255, 255),
                //       fontSize: 18,
                //       fontWeight: FontWeight.bold,
                //       shadows: [
                //         Shadow(
                //           blurRadius: 20,
                //           color: Colors.black.withOpacity(0.7),
                //           offset: Offset(2, 2),
                //         ),
                //       ],
                //     ),
                //     maxLines: 3,
                //     softWrap: true,
                //   ),
                // ),
                Positioned(
                  bottom: 130,
                  left: 20,
                  right: 0,
                  child: Text(
                    item['price']?.toString() ?? '',
                    style: TextStyle(
                      color: Colors.white,
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
                ),
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
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
