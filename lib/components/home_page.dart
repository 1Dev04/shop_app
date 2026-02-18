// ----HomePage (Fixed with Firebase UID + Working Favourite)--------------------------------------------------------------------------

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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

  String getBaseUrl() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');

    if (env == 'prod') {
      return 'https://catshop-backend-9pzq.onrender.com';
    }

    if (env == 'prod-v2') {
      return 'https://catshop-backend-v2.onrender.com';
    }

    if (kIsWeb) {
      return 'http://localhost:10000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:10000';
    }

    return 'http://localhost:10000';
  }

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
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

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
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        Map<String, dynamic>? item;

        if (data is Map && data.containsKey('data')) {
          item = Map<String, dynamic>.from(data['data']);
        } else if (data is Map) {
          item = Map<String, dynamic>.from(data);
        }

        // ✅ Parse images ให้เป็น Map เสมอ
        if (item != null) {
          final rawImages = item['images'];
          if (rawImages is String) {
            item['images'] = jsonDecode(rawImages);
          } else if (rawImages == null) {
            item['images'] = <String, dynamic>{};
          }
        }

        return item;
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
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final itemDetails = await fetchItemDetails(itemId);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  fetchAdvertisements();
                },
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }

    if (images.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('ไม่มีข้อมูลโฆษณา')),
      );
    }

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
          itemCount: null,
          itemBuilder: (context, index) {
            final item = images[index % images.length];
            final discountPrice = parseDouble(item['discount_price']);
            final hasDiscount = discountPrice > 0;

            // ✅ Safe parse images
            final rawImages = item['images'];
            final Map<String, dynamic> imagesMap = rawImages is String
                ? Map<String, dynamic>.from(jsonDecode(rawImages))
                : rawImages is Map
                    ? Map<String, dynamic>.from(rawImages)
                    : {};

            return Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: item['image_url'] ?? '',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) =>
                      const Center(child: Icon(Icons.error)),
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
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 130,
                  left: 20,
                  right: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                                offset: const Offset(2, 2),
                              )
                            ],
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 10),
                      Text(
                        hasDiscount
                            ? '฿${discountPrice.toStringAsFixed(0)}'
                            : '฿${item['price']?.toString() ?? ''}',
                        style: TextStyle(
                          color: hasDiscount
                              ? const Color.fromARGB(255, 255, 244, 125)
                              : Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 20,
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(2, 2),
                            )
                          ],
                        ),
                      ),
                      if (hasDiscount) const SizedBox(width: 10),
                      if (hasDiscount)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '-${item['discount_percent']?.toString() ?? '0'}%',
                            style: const TextStyle(
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
                        children: [
                          FloatingActionButton.small(
                            onPressed: () async {
                              try {
                                await BasketApiService().addToBasket(
                                  clothingUuid: item['uuid'],
                                );
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.success(
                                    message: languageProvider.translate(
                                      en: 'Added to cart!',
                                      th: 'เพิ่มลงตะกร้าแล้ว!',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                showTopSnackBar(
                                  Overlay.of(context),
                                  CustomSnackBar.error(
                                      message: 'เกิดข้อผิดพลาด'),
                                );
                              }
                            },
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
                          const SizedBox(width: 5),
                          ElevatedButton(
                            onPressed: () {
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
                          imageUrl: imagesMap['image_clothing'] ?? '',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error),
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

// ============================================================================
// Item Details Card with Firebase UID
// ============================================================================

class ItemDetailsCard extends StatefulWidget {
  final Map<String, dynamic> itemDetails;

  const ItemDetailsCard({
    super.key,
    required this.itemDetails,
  });

  @override
  State<ItemDetailsCard> createState() => _ItemDetailsCardState();
}

class _ItemDetailsCardState extends State<ItemDetailsCard> {
  bool _isFavourite = false;
  bool _isProcessing = false;

  double parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void initState() {
    super.initState();
    _checkFavouriteStatus();
  }

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
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Removed from favourites',
                th: 'ลบออกจากรายการโปรดแล้ว',
              ),
            ),
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
                en: 'Added to favourites!',
                th: 'เพิ่มลงรายการโปรดแล้ว!',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(message: 'เกิดข้อผิดพลาด: $e'),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final discountPrice = parseDouble(widget.itemDetails['discount_price']);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hasDiscount = discountPrice > 0;

    // ✅ Safe parse images ทุกกรณี
    final rawImages = widget.itemDetails['images'];
    final Map<String, dynamic> imagesMap = rawImages is String
        ? Map<String, dynamic>.from(jsonDecode(rawImages))
        : rawImages is Map
            ? Map<String, dynamic>.from(rawImages)
            : {};

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                  // ✅ รูป Slideshow + ปุ่มหัวใจ
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(20)),
                        child: SizedBox(
                          height: 300,
                          child: PageView(
                            children: [
                              // รูปหลัก
                              CachedNetworkImage(
                                imageUrl: widget.itemDetails['image_url'] ?? '',
                                width: double.infinity,
                                height: 300,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const SizedBox(
                                  height: 300,
                                  child: Center(child: CircularProgressIndicator()),
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
                                  child: Center(child: CircularProgressIndicator()),
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

                  // ✅ Content ที่เลื่อนได้
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
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Category', th: 'หมวดหมู่'),
                              value: widget.itemDetails['category'] ?? '',
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Size', th: 'ขนาด'),
                              value: widget.itemDetails['size_category'] ?? '',
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Gender', th: 'เพศ'),
                              value: formatGender(
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
                              value: widget.itemDetails['breed'] ?? '',
                            ),
                            if (widget.itemDetails['description'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'รายละเอียด',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.itemDetails['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            Row(
                              children: [
                                if (hasDiscount)
                                  Text(
                                    '฿${widget.itemDetails['price']?.toString() ?? ''}',
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
                                      : '฿${widget.itemDetails['price']?.toString() ?? ''}',
                                  style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        hasDiscount ? Colors.red : Colors.black,
                                  ),
                                ),
                                if (hasDiscount) const SizedBox(width: 10),
                                if (hasDiscount)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${widget.itemDetails['discount_percent']?.toString() ?? '0'}%',
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
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await BasketApiService().addToBasket(
                                      clothingUuid: widget.itemDetails['uuid'],
                                    );
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
                                  } catch (e) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.error(
                                          message: 'เกิดข้อผิดพลาด'),
                                    );
                                  }
                                },
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
      ),
    );
  }
}

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

String formatGender(dynamic value, LanguageProvider lang) {
  final intValue = int.tryParse(value?.toString() ?? '0') ?? 0;
  switch (intValue) {
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