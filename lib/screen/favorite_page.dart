// ----FavoritePage (Fixed with Firebase UID + Item Detail Popup)--------------------------------------------------------------------------

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// ✅ Safe parse images ทุกกรณี
Map<String, dynamic> _parseImagesMap(dynamic rawImages) {
  if (rawImages is String && rawImages.isNotEmpty) {
    try {
      return Map<String, dynamic>.from(jsonDecode(rawImages));
    } catch (_) {
      return {};
    }
  } else if (rawImages is Map) {
    return Map<String, dynamic>.from(rawImages);
  }
  return {};
}

class FavouritePage extends StatefulWidget {
  const FavouritePage({super.key});

  @override
  State<FavouritePage> createState() => _FavouritePageState();
}

class _FavouritePageState extends State<FavouritePage> {
  final FavouriteApiService _favouriteApi = FavouriteApiService();

  List<FavouriteItem> _favourites = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  Future<void> _loadFavourites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _favouriteApi.getFavourites();
      if (mounted) {
        setState(() {
          _favourites = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load favourites: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _showItemDetail(FavouriteItem product) {
    final itemDetails = <String, dynamic>{
      'uuid': product.clothingUuid,
      'clothing_uuid': product.clothingUuid,
      'clothing_name': product.clothingName,
      'image_url': product.imageUrl,
      'images': product.images,
      'price': product.price,
      'discount_price': product.discountPrice,
      'stock': product.stock,
      'category': product.category,
      'size_category': product.sizeCategory,
      'gender': product.gender,
      'breed': product.breed,
      'description': product.description,
    };

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: Provider.of<LanguageProvider>(context, listen: false),
            ),
          ],
          child: _FavItemDetailCard(
            itemDetails: itemDetails,
            onRemoved: () {
              _loadFavourites();
            },
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
              opacity: animation.drive(
                  Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve))),
              child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              languageProvider.translate(en: 'Favourites', th: 'รายการโปรด'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            if (_favourites.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_favourites.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.07),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState(context, _error!, languageProvider)
              : _favourites.isEmpty
                  ? _buildEmptyState(context, languageProvider, isDark)
                  : _buildFavoriteList(
                      context, _favourites, isDark, languageProvider),
    );
  }

  Widget _buildErrorState(
      BuildContext context, String error, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.red),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadFavourites,
            child: Text(languageProvider.translate(en: 'Retry', th: 'ลองใหม่')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, LanguageProvider languageProvider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded,
              size: 80, color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 20),
          Text(
            languageProvider.translate(
                en: "No favorites", th: "ไม่มีรายการโปรด"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              languageProvider.translate(
                  en: "Add products to your favorites list to check prices and stock availability.",
                  th: "เพิ่มสินค้าลงในรายการโปรดของคุณเพื่อตรวจสอบราคาและสถานะสต็อก"),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[500] : Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteList(
    BuildContext context,
    List<FavouriteItem> favorites,
    bool isDark,
    LanguageProvider languageProvider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final product = favorites[index];
        final hasDiscount = product.discountPrice != null &&
            product.discountPrice! > 0 &&
            product.discountPrice! < product.price;

        return GestureDetector(
          onTap: () => _showItemDetail(product),
          child: Card(
            elevation: 2,
            color: isDark ? Colors.grey[900] : Colors.white,
            margin: const EdgeInsets.only(bottom: 12),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // รูปภาพ
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.shopping_bag, size: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ชื่อ + ราคา
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.clothingName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (hasDiscount)
                              Text(
                                '฿${product.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                            if (hasDiscount) const SizedBox(width: 6),
                            Text(
                              hasDiscount
                                  ? '฿${product.discountPrice!.toStringAsFixed(0)}'
                                  : '฿${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount
                                    ? Colors.red
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.touch_app_outlined,
                                size: 12,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400]),
                            const SizedBox(width: 4),
                            Text(
                              languageProvider.translate(
                                en: 'Tap for details',
                                th: 'แตะเพื่อดูรายละเอียด',
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? Colors.grey[500]
                                    : Colors.grey[400],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ปุ่มลบ
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 24),
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirmation(
                        context,
                        product,
                        languageProvider,
                      );
                      if (confirmed == true) {
                        try {
                          await _favouriteApi.removeFromFavourite(
                            clothingUuid: product.clothingUuid,
                          );
                          await _loadFavourites();
                          if (mounted) {
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.info(
                                message: languageProvider.translate(
                                  en: 'Removed from favourites!',
                                  th: 'ลบออกจากรายการโปรดแล้ว',
                                ),
                              ),
                              animationDuration: const Duration(
                                  milliseconds: 1000), // เร็วแค่ไหนตอน popup
                              reverseAnimationDuration: const Duration(
                                  milliseconds: 200), // เร็วแค่ไหนตอนหาย
                              displayDuration: const Duration(
                                  milliseconds: 1000), // แสดงนานแค่ไหน
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.info(
                                message: languageProvider.translate(
                                  en: 'Failed to remove from favourites!',
                                  th: 'ลบออกจากรายการโปรดไม่สำเร็จ',
                                ),
                              ),
                              animationDuration: const Duration(
                                  milliseconds: 1000), // เร็วแค่ไหนตอน popup
                              reverseAnimationDuration: const Duration(
                                  milliseconds: 200), // เร็วแค่ไหนตอนหาย
                              displayDuration: const Duration(
                                  milliseconds: 1000), // แสดงนานแค่ไหน
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    FavouriteItem product,
    LanguageProvider languageProvider,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.black : Colors.white,
        title: Text(languageProvider.translate(
            en: 'Remove from Favorites?', th: 'ลบออกจากรายการโปรด?')),
        content: Text(languageProvider.translate(
            en: 'Do you want to remove "${product.clothingName}" from favorites?',
            th: 'คุณต้องการลบ "${product.clothingName}" ออกจากรายการโปรดหรือไม่?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(languageProvider.translate(en: 'Cancel', th: 'ยกเลิก')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              languageProvider.translate(en: 'Remove', th: 'ลบ'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Item Detail Card สำหรับ FavouritePage
// ============================================================================

class _FavItemDetailCard extends StatefulWidget {
  final Map<String, dynamic> itemDetails;
  final VoidCallback? onRemoved;

  const _FavItemDetailCard({
    required this.itemDetails,
    this.onRemoved,
  });

  @override
  State<_FavItemDetailCard> createState() => _FavItemDetailCardState();
}

class _FavItemDetailCardState extends State<_FavItemDetailCard> {
  bool _isFavourite = true;
  bool _isProcessing = false;

  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _toggleFavourite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final uuid = widget.itemDetails['uuid']?.toString() ?? '';

    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      if (_isFavourite) {
        await FavouriteApiService().removeFromFavourite(clothingUuid: uuid);
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
          widget.onRemoved?.call();
        }
      } else {
        await FavouriteApiService().addToFavourite(clothingUuid: uuid);
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

  String _formatGender(dynamic gender, LanguageProvider lang) {
    final g =
        gender is int ? gender : int.tryParse(gender?.toString() ?? '') ?? 0;
    switch (g) {
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

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final discountPrice = _parseDouble(widget.itemDetails['discount_price']);
    final price = _parseDouble(widget.itemDetails['price']);
    final hasDiscount = discountPrice > 0 && discountPrice < price;
    final discountPercent = widget.itemDetails['discount_percent'];

    // ✅ Safe parse images
    final imagesMap = _parseImagesMap(widget.itemDetails['images']);

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
                maxHeight: MediaQuery.of(context).size.height * 0.80,
                maxWidth: 400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ รูป Slideshow + ปุ่มหัวใจ
                  // ✅ รูป Slideshow + ปุ่มหัวใจ + จุด indicator
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20)),
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
                                  child: Center(
                                      child: CircularProgressIndicator()),
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
                                  child: Center(
                                      child: CircularProgressIndicator()),
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
                              widget.itemDetails['clothing_name']?.toString() ??
                                  '',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Category', th: 'หมวดหมู่'),
                              value:
                                  widget.itemDetails['category']?.toString() ??
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
                              value: _formatGender(widget.itemDetails['gender'],
                                  languageProvider),
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
                                    widget.itemDetails['description']
                                        .toString(),
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[700]),
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
                                        decorationThickness: 2),
                                  ),
                                if (hasDiscount) const SizedBox(width: 10),
                                Text(
                                  hasDiscount
                                      ? '฿${discountPrice.toStringAsFixed(0)}'
                                      : '฿${price.toStringAsFixed(0)}',
                                  style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: hasDiscount
                                          ? Colors.red
                                          : Colors.black),
                                ),
                                if (hasDiscount && discountPercent != null)
                                  const SizedBox(width: 10),
                                if (hasDiscount && discountPercent != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      '-$discountPercent%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900),
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
                                onPressed: () async {
                                  final uuid =
                                      widget.itemDetails['uuid']?.toString() ??
                                          '';
                                  try {
                                    await BasketApiService()
                                        .addToBasket(clothingUuid: uuid);
                                    if (context.mounted) {
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
                                            const Duration(milliseconds: 1000),
                                        reverseAnimationDuration:
                                            const Duration(milliseconds: 200),
                                        displayDuration:
                                            const Duration(milliseconds: 1000),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      showTopSnackBar(
                                        Overlay.of(context),
                                        CustomSnackBar.error(
                                          message: languageProvider.translate(
                                            en: 'Failed to add to Basket: $e',
                                            th: 'เพิ่มลงตะกร้าไม่สำเร็จ: $e',
                                          ),
                                        ),
                                        animationDuration:
                                            const Duration(milliseconds: 1000),
                                        reverseAnimationDuration:
                                            const Duration(milliseconds: 200),
                                        displayDuration:
                                            const Duration(milliseconds: 1000),
                                      );
                                    }
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

// ============================================================================
// Detail Row Widget
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
            child: Text('$label:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );
  }
}
