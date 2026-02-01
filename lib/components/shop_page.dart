// ----ShopPage--------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/all_products.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// ============================================================================
// Helper: parse any dynamic → double safely
// ============================================================================

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll('THB', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

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

  String getGenderText(dynamic gender, LanguageProvider lang) {
    final genderCode =
        gender is int ? gender : int.tryParse(gender?.toString() ?? '');

    switch (genderCode) {
      case 0:
        return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
      case 1:
        return lang.translate(en: 'Male', th: 'เพศผู้');
      case 2:
        return lang.translate(en: 'Female', th: 'เพศเมีย');
      case 3:
        return lang.translate(en: 'Kitten', th: 'ลูกแมว');
      default:
        return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
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

  // ============================================================================
  // Fetch Item Detail & Show Popup
  // ============================================================================

  Future<Map<String, dynamic>?> fetchItemDetails(int itemId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/home-advertiment/$itemId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data.containsKey('data')) {
          return data['data'];
        }
        return data;
      } else {
        return null;
      }
    } catch (e) {
      print('❌ Error fetching item details: $e');
      return null;
    }
  }

  void showItemDetailsPopup(int itemId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final itemDetails = await fetchItemDetails(itemId);
    Navigator.of(context).pop(); // ปิด loading

    if (itemDetails != null) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel:
            MaterialLocalizations.of(context).modalBarrierDismissLabel,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) {
          return _ShopItemDetailsCard(itemDetails: itemDetails);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );
          var offsetAnimation = animation.drive(tween);
          var fadeAnimation = animation.drive(
            Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ไม่สามารถโหลดข้อมูลได้'),
          backgroundColor: Colors.red,
        ),
      );
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
            padding: const EdgeInsets.all(15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CachedNetworkImage(
                  imageUrl:
                      "https://res.cloudinary.com/dag73dhpl/image/upload/v1741695217/cat3_xvd0mu.png",
                  width: 50,
                  height: 50,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator.adaptive(
                    backgroundColor: Colors.white,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(75, 50, 50, 50)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => AllProducts()));
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopify_sharp, size: 30),
                      Text(
                        languageProvider.translate(
                            en: "All Products", th: "สินค้าทั้งหมด"),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface, height: 1),
          const SizedBox(height: 10),

          // ============================================================================
          // You might like this Section
          // ============================================================================
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
                    ? const SizedBox(
                        height: 490,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : errorMessageLike.isNotEmpty
                        ? SizedBox(
                            height: 490,
                            child: Center(child: Text(errorMessageLike)),
                          )
                        : dataShoplike.isEmpty
                            ? const SizedBox(
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
                                    final price = _parseDouble(item['price']);
                                    final discountPrice =
                                        _parseDouble(item['discount_price']);
                                    final hasDiscount = discountPrice > 0 &&
                                        discountPrice < price;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: Column(
                                        children: [
                                          // 🔥 รูปภาพ — กดได้
                                          GestureDetector(
                                            onTap: () {
                                              final itemId = int.tryParse(
                                                      item['id']?.toString() ??
                                                          '0') ??
                                                  0;
                                              showItemDetailsPopup(itemId);
                                            },
                                            child: CachedNetworkImage(
                                              imageUrl: item["image_url"]
                                                      ?.toString() ??
                                                  '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 350,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator
                                                      .adaptive(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Gender + Size
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                getGenderText(item['gender'],
                                                    languageProvider),
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
                                          const SizedBox(height: 10),

                                          // Clothing Name + Stock
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['clothing_name']
                                                          ?.toString() ??
                                                      'N/A',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                          const SizedBox(height: 10),

                                          // Price + Cart button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // ราคา
                                              Row(
                                                children: [
                                                  if (hasDiscount)
                                                    Text(
                                                      '฿${price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  if (hasDiscount)
                                                    const SizedBox(width: 8),
                                                  Text(
                                                    hasDiscount
                                                        ? '฿${discountPrice.toStringAsFixed(0)}'
                                                        : '฿${price.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: hasDiscount
                                                          ? Colors.red
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  // แสดง % ส่วนลด
                                                  if (hasDiscount)
                                                    SizedBox(width: 10),
                                                  if (hasDiscount)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        '-${item['discount_percent']?.toString() ?? '0'}%',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              // Cart button
                                              FloatingActionButton.small(
                                                onPressed: () {
                                                  showTopSnackBar(
                                                    Overlay.of(context),
                                                    CustomSnackBar.success(
                                                      message: languageProvider
                                                          .translate(
                                                        en: 'Added to cart!',
                                                        th: 'เพิ่มลงตะกร้าแล้ว!',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .floatingActionButtonTheme
                                                    .backgroundColor,
                                                child: Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 30,
                                                  color: Theme.of(context)
                                                      .floatingActionButtonTheme
                                                      .foregroundColor,
                                                ),
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

          // ============================================================================
          // Best Seller Section
          // ============================================================================
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
                    ? const SizedBox(
                        height: 490,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : errorMessageSeller.isNotEmpty
                        ? SizedBox(
                            height: 490,
                            child: Center(child: Text(errorMessageSeller)),
                          )
                        : dataShopSeller.isEmpty
                            ? const SizedBox(
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
                                    final price = _parseDouble(item['price']);
                                    final discountPrice =
                                        _parseDouble(item['discount_price']);
                                    final hasDiscount = discountPrice > 0 &&
                                        discountPrice < price;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      child: Column(
                                        children: [
                                          // 🔥 รูปภาพ — กดได้
                                          GestureDetector(
                                            onTap: () {
                                              final itemId = int.tryParse(
                                                      item['id']?.toString() ??
                                                          '0') ??
                                                  0;
                                              showItemDetailsPopup(itemId);
                                            },
                                            child: CachedNetworkImage(
                                              imageUrl: item["image_url"]
                                                      ?.toString() ??
                                                  '',
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: 350,
                                              placeholder: (context, url) =>
                                                  const CircularProgressIndicator
                                                      .adaptive(),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(Icons.error),
                                            ),
                                          ),
                                          const SizedBox(height: 10),

                                          // Gender + Size
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                getGenderText(item['gender'],
                                                    languageProvider),
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
                                          const SizedBox(height: 10),

                                          // Clothing Name + Stock
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['clothing_name']
                                                          ?.toString() ??
                                                      'N/A',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
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
                                          const SizedBox(height: 10),

                                          // Price + Cart button
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              // ราคา
                                              Row(
                                                children: [
                                                  if (hasDiscount)
                                                    Text(
                                                      '฿${price.toStringAsFixed(0)}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  if (hasDiscount)
                                                    const SizedBox(width: 8),
                                                  Text(
                                                    hasDiscount
                                                        ? '฿${discountPrice.toStringAsFixed(0)}'
                                                        : '฿${price.toStringAsFixed(0)}',
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: hasDiscount
                                                          ? Colors.red
                                                          : Theme.of(context)
                                                              .colorScheme
                                                              .primary,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  // แสดง % ส่วนลด
                                                  if (hasDiscount)
                                                    SizedBox(width: 10),
                                                  if (hasDiscount)
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 4,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                      ),
                                                      child: Text(
                                                        '-${item['discount_percent']?.toString() ?? '0'}%',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w900,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),

                                              // Cart button
                                              FloatingActionButton.small(
                                                onPressed: () {
                                                  showTopSnackBar(
                                                    Overlay.of(context),
                                                    CustomSnackBar.success(
                                                      message: languageProvider
                                                          .translate(
                                                        en: 'Added to cart!',
                                                        th: 'เพิ่มลงตะกร้าแล้ว!',
                                                      ),
                                                    ),
                                                  );
                                                },
                                                backgroundColor: Theme.of(
                                                        context)
                                                    .floatingActionButtonTheme
                                                    .backgroundColor,
                                                child: Icon(
                                                  Icons.shopping_cart_outlined,
                                                  size: 30,
                                                  color: Theme.of(context)
                                                      .floatingActionButtonTheme
                                                      .foregroundColor,
                                                ),
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

// ============================================================================
// Shop Item Details Card — คล้าย HomePage ItemDetailsCard
// ============================================================================

class _ShopItemDetailsCard extends StatelessWidget {
  final Map<String, dynamic> itemDetails;

  const _ShopItemDetailsCard({required this.itemDetails});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    final price = _parseDouble(itemDetails['price']);
    final discountPrice = _parseDouble(itemDetails['discount_price']);
    final hasDiscount = discountPrice > 0 && discountPrice < price;

    final discountPercentRaw =
        itemDetails['discount_percent']?.toString() ?? '';
    final discountPercentClean = discountPercentRaw.replaceAll('%', '').trim();

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
                // รูปภาพสินค้า
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: itemDetails['image_url'] ?? '',
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อสินค้า
                      Text(
                        itemDetails['clothing_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Detail rows
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Category', th: 'หมวดหมู่'),
                        value: itemDetails['category']?.toString() ?? '',
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Size', th: 'ขนาด'),
                        value: itemDetails['size_category']?.toString() ?? '',
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Gender', th: 'เพศ'),
                        value: _formatGender(
                            itemDetails['gender'], languageProvider),
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Stock', th: 'สต็อก'),
                        value: itemDetails['stock']?.toString() ?? '',
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Breed', th: 'สายพันธุ์'),
                        value: itemDetails['breed']?.toString() ?? '',
                      ),

                      // รายละเอียด
                      if (itemDetails['description'] != null &&
                          itemDetails['description'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.translate(
                                  en: 'Description', th: 'รายละเอียด'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              itemDetails['description'] ?? '',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // ราคา
                      Row(
                        children: [
                          if (hasDiscount)
                            Text(
                              '฿${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2,
                              ),
                            ),
                          if (hasDiscount) const SizedBox(width: 10),
                          Text(
                            hasDiscount
                                ? '฿${discountPrice.toStringAsFixed(0)}'
                                : '฿${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? Colors.red : Colors.black,
                            ),
                          ),
                          if (hasDiscount) const SizedBox(width: 10),
                          if (hasDiscount && discountPercentClean.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-$discountPercentClean%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ปุ่ม Add to Cart
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.success(
                                message: languageProvider.translate(
                                  en: 'Added to cart successfully!',
                                  th: 'เพิ่มลงตะกร้าสำเร็จ!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart_sharp),
                          label: Text(
                            languageProvider.translate(
                                en: 'Add to Cart', th: 'เพิ่มลงตะกร้า'),
                            style: const TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.black,
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

// ============================================================================
// Detail Row
// ============================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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

// ============================================================================
// Helper: format gender
// ============================================================================

String _formatGender(dynamic value, LanguageProvider lang) {
  final genderCode =
      value is int ? value : int.tryParse(value?.toString() ?? '');

  switch (genderCode) {
    case 0:
      return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
    case 1:
      return lang.translate(en: 'Male', th: 'เพศผู้');
    case 2:
      return lang.translate(en: 'Female', th: 'เพศเมีย');
    case 3:
      return lang.translate(en: 'Kitten', th: 'ลูกแมว');
    default:
      return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
  }
}
