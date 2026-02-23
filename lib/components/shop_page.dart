// ----ShopPage--------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';

import 'package:flutter_application_1/provider/language_provider.dart';

import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// ============================================================================
// Helper
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
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');

    if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
    if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
    if (kIsWeb) return 'http://localhost:10000';
    if (Platform.isAndroid) return 'http://10.0.2.2:10000';
    return 'http://localhost:10000';
  }

  @override
  void initState() {
    super.initState();
    fetchShoplike();
    fetchShopseller();
  }

  @override
  void dispose() {
    _pageControlShop1.dispose();
    _pageControlShop2.dispose();
    super.dispose();
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/clothing-shop/like'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        List<Map<String, dynamic>> parsedImages = [];

        if (data is List) {
          parsedImages = data.map<Map<String, dynamic>>((item) {
            final rawImages = item['images'];
            return {
              ...item,
              'images': rawImages is String ? jsonDecode(rawImages) : rawImages
            };
          }).toList();
        } else if (data is Map && data.containsKey('data')) {
          parsedImages = List<Map<String, dynamic>>.from(
            data['data'].map<Map<String, dynamic>>((item) {
              final rawImages = item['images'];
              return {
                ...item,
                'images':
                    rawImages is String ? jsonDecode(rawImages) : rawImages
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
      final response = await http.get(
        Uri.parse('$baseUrl/api/clothing-shop/seller'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        List<Map<String, dynamic>> parsedImages = [];

        if (data is List) {
          parsedImages = data.map<Map<String, dynamic>>((item) {
            final rawImages = item['images'];
            return {
              ...item,
              'images': rawImages is String ? jsonDecode(rawImages) : rawImages
            };
          }).toList();
        } else if (data is Map && data.containsKey('data')) {
          parsedImages = List<Map<String, dynamic>>.from(
            data['data'].map<Map<String, dynamic>>((item) {
              final rawImages = item['images'];
              return {
                ...item,
                'images':
                    rawImages is String ? jsonDecode(rawImages) : rawImages
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
  // ✅ Add to Basket — Firebase UID (ไม่ส่ง userId)
  // ============================================================================

  Future<void> _addToBasket(Map<String, dynamic> item) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      await BasketApiService().addToBasket(
        clothingUuid: item['uuid'],
      );

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: languageProvider.translate(
              en: 'Added to Basket successfully!',
              th: 'เพิ่มลงตะกร้าสำเร็จ!',
            ),
          ),
          animationDuration:
              const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
          reverseAnimationDuration:
              const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
          displayDuration: const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to Basket: $e',
              th: 'เพิ่มลงตะกร้าไม่สำเร็จ: $e',
            ),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    }
  }

  // ============================================================================
  // Fetch Item Detail & Show Popup
  // ============================================================================

  Future<Map<String, dynamic>?> fetchItemDetails(int itemId) async {
    try {
      final baseUrl = getBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/api/home-advertiment/$itemId'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        if (data is Map && data.containsKey('data')) return data['data'];
        return data;
      }
      return null;
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
    if (!mounted) return;
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
          return _ShopItemDetailsCard(itemDetails: itemDetails);
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, -1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(
              opacity: animation.drive(
                  Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve))),
              child: child,
            ),
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('ไม่สามารถโหลดข้อมูลได้'),
            backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================================
  // Build UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                // GestureDetector(
                //   onTap: () {
                //     Navigator.push(context,
                //         MaterialPageRoute(builder: (context) => AllProducts()));
                //   },
                //   child: Column(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     crossAxisAlignment: CrossAxisAlignment.center,
                //     children: [
                //       const Icon(Icons.shopify_sharp, size: 30),
                //       Text(
                //         languageProvider.translate(en: "All Products", th: "สินค้าทั้งหมด"),
                //         style: const TextStyle(fontSize: 16),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
          Divider(color: Theme.of(context).colorScheme.onSurface, height: 1),
          const SizedBox(height: 10),

          // ============================================================================
          // You might like this Section
          // ============================================================================
          _buildSection(
            title: languageProvider.translate(
                en: "You might like this", th: "คุณอาจจะชอบสิ่งนี้"),
            isLoading: isLoadingLike,
            errorMessage: errorMessageLike,
            data: dataShoplike,
            controller: _pageControlShop1,
            languageProvider: languageProvider,
          ),

          // ============================================================================
          // Best Seller Section
          // ============================================================================
          _buildSection(
            title: languageProvider.translate(
                en: "Best Seller", th: "สินค้าขายดี"),
            isLoading: isLoadingSeller,
            errorMessage: errorMessageSeller,
            data: dataShopSeller,
            controller: _pageControlShop2,
            languageProvider: languageProvider,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required bool isLoading,
    required String errorMessage,
    required List<Map<String, dynamic>> data,
    required PageController controller,
    required LanguageProvider languageProvider,
  }) {
    return Column(
      children: [
        Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        isLoading
            ? const SizedBox(
                height: 490, child: Center(child: CircularProgressIndicator()))
            : errorMessage.isNotEmpty
                ? SizedBox(
                    height: 490, child: Center(child: Text(errorMessage)))
                : data.isEmpty
                    ? const SizedBox(
                        height: 490, child: Center(child: Text('ไม่มีข้อมูล')))
                    : SizedBox(
                        height: 490,
                        child: PageView.builder(
                          controller: controller,
                          itemCount: data.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final item = data[index];
                            final price = _parseDouble(item['price']);
                            final discountPrice =
                                _parseDouble(item['discount_price']);
                            final hasDiscount =
                                discountPrice > 0 && discountPrice < price;

                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 10),
                              child: Column(
                                children: [
                                  // รูปภาพ — กดดู detail
                                  GestureDetector(
                                    onTap: () {
                                      final itemId = int.tryParse(
                                              item['id']?.toString() ?? '0') ??
                                          0;
                                      showItemDetailsPopup(itemId);
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          item["image_url"]?.toString() ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: 350,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator
                                              .adaptive(),
                                      errorWidget: (context, url, error) =>
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
                                        getGenderText(
                                            item['gender'], languageProvider),
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Text(
                                        item['size_category']?.toString() ??
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
                                          item['clothing_name']?.toString() ??
                                              'N/A',
                                          style: TextStyle(
                                            fontSize: 15,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
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
                                      Row(
                                        children: [
                                          if (hasDiscount)
                                            Text(
                                              '฿${price.toStringAsFixed(0)}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                decoration:
                                                    TextDecoration.lineThrough,
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
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          if (hasDiscount)
                                            const SizedBox(width: 10),
                                          if (hasDiscount)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                '-${item['discount_percent']?.toString() ?? '0'}%',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      // ✅ Cart button — เรียก API จริง
                                      FloatingActionButton.small(
                                        heroTag:
                                            'shop_cart_${item['uuid']}_${index}',
                                        onPressed: () => _addToBasket(item),
                                        backgroundColor: Theme.of(context)
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
    );
  }
}

// ============================================================================
// ✅ Shop Item Details Card — WITH Favourite & Basket (Firebase UID)
// ============================================================================

class _ShopItemDetailsCard extends StatefulWidget {
  final Map<String, dynamic> itemDetails;

  const _ShopItemDetailsCard({required this.itemDetails});

  @override
  State<_ShopItemDetailsCard> createState() => _ShopItemDetailsCardState();
}

class _ShopItemDetailsCardState extends State<_ShopItemDetailsCard> {
  bool _isFavourite = false;
  bool _isProcessing = false;

  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  double _pd(dynamic v) => _parseDouble(v);

  @override
  void initState() {
    super.initState();
    _checkFavouriteStatus();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // ✅ เช็ค Favourite — ไม่ส่ง userId
  Future<void> _checkFavouriteStatus() async {
    try {
      final isFav = await FavouriteApiService().checkFavourite(
        clothingUuid: widget.itemDetails['uuid'],
      );
      if (mounted) setState(() => _isFavourite = isFav);
    } catch (e) {
      print('❌ Error checking favourite: $e');
    }
  }

  // ✅ Toggle Favourite — ไม่ส่ง userId
  Future<void> _toggleFavourite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      if (_isFavourite) {
        await FavouriteApiService().removeFromFavourite(
          clothingUuid: widget.itemDetails['uuid'],
        );
        if (mounted) {
          setState(() => _isFavourite = false);
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: languageProvider.translate(
                en: 'Removed from favourites!',
                th: 'ลบออกจากรายการโปรดแล้ว',
              ),
            ),
            animationDuration:
                const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
            reverseAnimationDuration:
                const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
            displayDuration:
                const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
          );
        }
      } else {
        await FavouriteApiService().addToFavourite(
          clothingUuid: widget.itemDetails['uuid'],
        );
        if (mounted) {
          setState(() => _isFavourite = true);
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Added to favourites successfully!',
                th: 'เพิ่มลงรายการโปรดแล้ว!',
              ),
            ),
            animationDuration:
                const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
            reverseAnimationDuration:
                const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
            displayDuration:
                const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to favourites: $e',
              th: 'เพิ่มลงรายการโปรดไม่สำเร็จ: $e',
            ),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ✅ Add to Basket — ไม่ส่ง userId
  Future<void> _addToBasket() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      await BasketApiService().addToBasket(
        clothingUuid: widget.itemDetails['uuid'],
      );

      if (mounted) {
        Navigator.of(context).pop();
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: languageProvider.translate(
              en: 'Added to Basket successfully!',
              th: 'เพิ่มลงตะกร้าสำเร็จ!',
            ),
          ),
          animationDuration:
              const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
          reverseAnimationDuration:
              const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
          displayDuration: const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to Basket: $e',
              th: 'เพิ่มลงตะกร้าไม่สำเร็จ: $e',
            ),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final price = _pd(widget.itemDetails['price']);
    final discountPrice = _pd(widget.itemDetails['discount_price']);
    final hasDiscount = discountPrice > 0 && discountPrice < price;
    final discountPercentClean =
        (widget.itemDetails['discount_percent']?.toString() ?? '')
            .replaceAll('%', '')
            .trim();

    // ✅ Safe parse images ทุกกรณี
    final rawImages = widget.itemDetails['images'];
    final Map<String, dynamic> imagesMap = rawImages is String
        ? Map<String, dynamic>.from(jsonDecode(rawImages))
        : rawImages is Map
            ? Map<String, dynamic>.from(rawImages)
            : {};

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 10,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // รูปภาพ + ปุ่มหัวใจ
                // ✅ รูป Slideshow + ปุ่มหัวใจ + จุด indicator
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _imagePageController,
                          onPageChanged: (index) {
                            setState(() => _currentImagePage = index);
                          },
                          children: [
                            // รูปหลัก
                            CachedNetworkImage(
                              imageUrl: widget.itemDetails['image_url'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                height: 300,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                height: 300,
                                child: Center(child: Icon(Icons.error)),
                              ),
                            ),
                            // รูปเสื้อผ้า
                            CachedNetworkImage(
                              imageUrl: imagesMap['image_clothing'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                height: 300,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                height: 300,
                                child: Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ จุด Page Indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(2, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImagePage == index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImagePage == index
                                  ? Colors.deepOrange
                                  : const Color.fromARGB(255, 0, 0, 0)
                                      .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                    // ✅ ปุ่มหัวใจ
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _isProcessing ? null : _toggleFavourite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isFavourite
                                ? Colors.red.withOpacity(0.8)
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(
                                  _isFavourite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Content ที่เลื่อนได้
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.itemDetails['clothing_name'] ?? '',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Category', th: 'หมวดหมู่'),
                            value: widget.itemDetails['category']?.toString() ??
                                '',
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Size', th: 'ขนาด'),
                            value: widget.itemDetails['size_category']
                                    ?.toString() ??
                                '',
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Gender', th: 'เพศ'),
                            value: _formatGender(
                                widget.itemDetails['gender'], languageProvider),
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Stock', th: 'สต็อก'),
                            value:
                                widget.itemDetails['stock']?.toString() ?? '',
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Breed', th: 'สายพันธุ์'),
                            value:
                                widget.itemDetails['breed']?.toString() ?? '',
                          ),
                          if (widget.itemDetails['description'] != null &&
                              widget.itemDetails['description']
                                  .toString()
                                  .isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.translate(
                                      en: 'Description', th: 'รายละเอียด'),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.itemDetails['description'] ?? '',
                                  style: TextStyle(
                                      fontSize: 16, color: Colors.grey[700]),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
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
                                  color:
                                      hasDiscount ? Colors.red : Colors.black,
                                ),
                              ),
                              if (hasDiscount) const SizedBox(width: 10),
                              if (hasDiscount &&
                                  discountPercentClean.isNotEmpty)
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
                          // ✅ ปุ่ม Add to Cart — เรียก API จริง
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: _addToBasket,
                              icon: const Icon(Icons.add_shopping_cart_sharp),
                              label: Text(
                                languageProvider.translate(
                                    en: 'Add to Cart', th: 'เพิ่มลงตะกร้า'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  fontSize: 14, color: Theme.of(context).colorScheme.secondary),
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
