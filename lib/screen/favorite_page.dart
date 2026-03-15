// ----FavoritePage (Fixed with Firebase UID + Item Detail Popup)--------------------------------------------------------------------------

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_favourite/favourite_bloc.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// ── SnackBar helper (ใช้ร่วมกันทั้งไฟล์) ──────────────────────────────────
void _showTopSnack(
  BuildContext context, {
  required String message,
  required _SnackType type,
}) {
  final snackBar = switch (type) {
    _SnackType.success => CustomSnackBar.success(message: message),
    _SnackType.info => CustomSnackBar.info(message: message),
    _SnackType.error => CustomSnackBar.error(message: message),
  };
  showTopSnackBar(
    Overlay.of(context),
    snackBar,
    animationDuration: const Duration(milliseconds: 1000),
    reverseAnimationDuration: const Duration(milliseconds: 200),
    displayDuration: const Duration(milliseconds: 1000),
  );
}

enum _SnackType { success, info, error }

// ════════════════════════════════════════════════════════════════════════════
// FavouritePage
// ════════════════════════════════════════════════════════════════════════════

class FavouritePage extends StatelessWidget {
  const FavouritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FavouriteBloc()..add(const FavouriteLoadRequested()),
      child: const _FavouriteView(),
    );
  }
}

class _FavouriteView extends StatelessWidget {
  const _FavouriteView();

  void _showItemDetail(BuildContext blocCtx, FavouriteItem product) {
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
      context: blocCtx,
      barrierDismissible: true,
      barrierLabel:
          MaterialLocalizations.of(blocCtx).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: blocCtx.read<FavouriteBloc>()),
          ],
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(
                value: Provider.of<LanguageProvider>(blocCtx, listen: false),
              ),
            ],
            child: _FavItemDetailCard(itemDetails: itemDetails),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation.drive(
                Tween(begin: 0.0, end: 1.0)
                    .chain(CurveTween(curve: curve))),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<FavouriteBloc, FavouriteState>(
      listener: (ctx, state) {
        if (state is FavouriteActionSuccess) {
          switch (state.actionType) {
            case FavouriteActionType.remove:
              _showTopSnack(ctx,
                  message: languageProvider.translate(
                    en: 'Removed from favourites!',
                    th: 'ลบออกจากรายการโปรดแล้ว',
                  ),
                  type: _SnackType.info);
            case FavouriteActionType.addToBasket:
              Navigator.of(ctx).pop(); // ปิด detail card
              _showTopSnack(ctx,
                  message: languageProvider.translate(
                    en: 'Added to Basket successfully!',
                    th: 'เพิ่มลงตะกร้าสำเร็จ!',
                  ),
                  type: _SnackType.success);
          }
        } else if (state is FavouriteToggleSuccess) {
          _showTopSnack(ctx,
              message: state.isFavourite
                  ? languageProvider.translate(
                      en: 'Added to favourites successfully!',
                      th: 'เพิ่มลงรายการโปรดแล้ว!')
                  : languageProvider.translate(
                      en: 'Removed from favourites!',
                      th: 'ลบออกจากรายการโปรดแล้ว'),
              type: state.isFavourite ? _SnackType.success : _SnackType.info);
        } else if (state is FavouriteActionFailure) {
          final msg = state.message;
          final display = msg.startsWith('basket_failed:')
              ? languageProvider.translate(
                  en: 'Failed to add to Basket: ${msg.replaceFirst('basket_failed:', '')}',
                  th: 'เพิ่มลงตะกร้าไม่สำเร็จ')
              : msg.startsWith('toggle_failed:')
                  ? languageProvider.translate(
                      en: 'Failed to update favourites',
                      th: 'อัปเดตรายการโปรดไม่สำเร็จ')
                  : languageProvider.translate(
                      en: 'Failed to remove from favourites!',
                      th: 'ลบออกจากรายการโปรดไม่สำเร็จ');
          _showTopSnack(ctx, message: display, type: _SnackType.error);
        }
      },
      builder: (ctx, state) {
        // ดึง items จาก state ทุกแบบ
        final items = _itemsFromState(state);
        final isLoading =
            state is FavouriteInitial || state is FavouriteLoading;
        final failureMessage =
            state is FavouriteFailure ? state.message : null;
        final isProcessing = state is FavouriteActionInProgress;

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
                const Icon(Icons.favorite_rounded,
                    color: Colors.red, size: 22),
                const SizedBox(width: 8),
                Text(
                  languageProvider.translate(
                      en: 'Favourites', th: 'รายการโปรด'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (items.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            backgroundColor:
                isDark ? const Color(0xFF1A1A1A) : Colors.white,
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
          body: Stack(
            children: [
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (failureMessage != null)
                _buildErrorState(ctx, failureMessage, languageProvider)
              else if (items.isEmpty)
                _buildEmptyState(ctx, languageProvider, isDark)
              else
                _buildFavoriteList(ctx, items, isDark, languageProvider),
              // overlay ขณะ action
              if (isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<FavouriteItem> _itemsFromState(FavouriteState state) {
    if (state is FavouriteLoaded) return state.items;
    if (state is FavouriteActionInProgress) return state.items;
    if (state is FavouriteActionSuccess) return state.items;
    if (state is FavouriteActionFailure) return state.items;
    if (state is FavouriteToggleSuccess) return state.items;
    return [];
  }

  Widget _buildErrorState(BuildContext context, String error,
      LanguageProvider languageProvider) {
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
            onPressed: () => context
                .read<FavouriteBloc>()
                .add(const FavouriteLoadRequested()),
            child: Text(
                languageProvider.translate(en: 'Retry', th: 'ลองใหม่')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context,
      LanguageProvider languageProvider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded,
              size: 80,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
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
    return RefreshIndicator(
      onRefresh: () async =>
          context.read<FavouriteBloc>().add(const FavouriteLoadRequested()),
      color: Colors.red,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: favorites.length,
        itemBuilder: (context, index) {
          final product = favorites[index];
          final hasDiscount = product.discountPrice != null &&
              product.discountPrice! > 0 &&
              product.discountPrice! < product.price;

          return GestureDetector(
            onTap: () => _showItemDetail(context, product),
            child: Card(
              elevation: 2,
              color: isDark ? Colors.grey[900] : Colors.white,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
                              child: CircularProgressIndicator(
                                  strokeWidth: 2)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child:
                              const Icon(Icons.shopping_bag, size: 30),
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
                              color:
                                  isDark ? Colors.white : Colors.black,
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
                                    decoration:
                                        TextDecoration.lineThrough,
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
                                      : (isDark
                                          ? Colors.white
                                          : Colors.black),
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
                      icon: const Icon(Icons.delete,
                          color: Colors.red, size: 24),
                      onPressed: () async {
                        final confirmed = await _showDeleteConfirmation(
                          context,
                          product,
                          languageProvider,
                        );
                        if (confirmed == true) {
                          context.read<FavouriteBloc>().add(
                                FavouriteRemoveRequested(
                                    product.clothingUuid),
                              );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
            en: 'Remove from Favorites?',
            th: 'ลบออกจากรายการโปรด?')),
        content: Text(languageProvider.translate(
            en: 'Do you want to remove "${product.clothingName}" from favorites?',
            th: 'คุณต้องการลบ "${product.clothingName}" ออกจากรายการโปรดหรือไม่?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(languageProvider.translate(
                en: 'Cancel', th: 'ยกเลิก')),
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

  const _FavItemDetailCard({required this.itemDetails});

  @override
  State<_FavItemDetailCard> createState() => _FavItemDetailCardState();
}

class _FavItemDetailCardState extends State<_FavItemDetailCard> {
  // isFavourite เริ่มต้น true เสมอ (เปิดจากหน้า Favourite)
  bool _isFavourite = true;

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
    final imagesMap = _parseImagesMap(widget.itemDetails['images']);
    final uuid = widget.itemDetails['uuid']?.toString() ?? '';

    return BlocConsumer<FavouriteBloc, FavouriteState>(
      // อัปเดต _isFavourite ตาม toggle result
      listener: (ctx, state) {
        if (state is FavouriteToggleSuccess) {
          setState(() => _isFavourite = state.isFavourite);
        }
      },
      builder: (ctx, state) {
        final isProcessing = state is FavouriteActionInProgress;

        return Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                      // ── รูป Slideshow + ปุ่มหัวใจ + จุด indicator ──────
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
                                  setState(
                                      () => _currentImagePage = index);
                                },
                                children: [
                                  CachedNetworkImage(
                                    imageUrl:
                                        widget.itemDetails['image_url'] ??
                                            '',
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child:
                                              CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child: Icon(Icons.error)),
                                    ),
                                  ),
                                  CachedNetworkImage(
                                    imageUrl:
                                        imagesMap['image_clothing'] ?? '',
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child:
                                              CircularProgressIndicator()),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child: Icon(Icons.error)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // จุด Page Indicator
                          Positioned(
                            bottom: 12,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children:
                                  List.generate(2, (index) {
                                return AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 4),
                                  width: _currentImagePage == index
                                      ? 20
                                      : 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: _currentImagePage == index
                                        ? Colors.deepOrange
                                        : Colors.black.withOpacity(0.5),
                                    borderRadius:
                                        BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                          ),

                          // ปุ่มหัวใจ
                          Positioned(
                            top: 16,
                            right: 16,
                            child: GestureDetector(
                              onTap: isProcessing
                                  ? null
                                  : () {
                                      ctx.read<FavouriteBloc>().add(
                                            FavouriteToggleRequested(
                                              clothingUuid: uuid,
                                              currentlyFavourite:
                                                  _isFavourite,
                                            ),
                                          );
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _isFavourite
                                      ? Colors.red.withOpacity(0.8)
                                      : Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: isProcessing
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<
                                                  Color>(Colors.white),
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
                                  widget.itemDetails['clothing_name']
                                          ?.toString() ??
                                      '',
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Category', th: 'หมวดหมู่'),
                                  value: widget.itemDetails['category']
                                          ?.toString() ??
                                      '',
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Size', th: 'ขนาด'),
                                  value: widget
                                          .itemDetails['size_category']
                                          ?.toString() ??
                                      '',
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Gender', th: 'เพศ'),
                                  value: _formatGender(
                                      widget.itemDetails['gender'],
                                      languageProvider),
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Stock', th: 'สต็อก'),
                                  value: widget.itemDetails['stock']
                                          ?.toString() ??
                                      '',
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Breed', th: 'สายพันธุ์'),
                                  value: widget.itemDetails['breed']
                                          ?.toString() ??
                                      '',
                                ),
                                if (widget.itemDetails['description'] !=
                                        null &&
                                    widget.itemDetails['description']
                                        .toString()
                                        .isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        languageProvider.translate(
                                            en: 'Description',
                                            th: 'รายละเอียด'),
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.itemDetails['description']
                                            .toString(),
                                        style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700]),
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
                                            decoration: TextDecoration
                                                .lineThrough,
                                            decorationThickness: 2),
                                      ),
                                    if (hasDiscount)
                                      const SizedBox(width: 10),
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
                                    if (hasDiscount &&
                                        discountPercent != null)
                                      const SizedBox(width: 10),
                                    if (hasDiscount &&
                                        discountPercent != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(6)),
                                        child: Text(
                                          '-$discountPercent%',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.w900),
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
                                    onPressed: isProcessing
                                        ? null
                                        : () {
                                            ctx
                                                .read<FavouriteBloc>()
                                                .add(
                                                  FavouriteAddToBasketRequested(
                                                      uuid),
                                                );
                                          },
                                    icon: const Icon(
                                        Icons.add_shopping_cart_sharp),
                                    label: Text(
                                      languageProvider.translate(
                                          en: 'Add to Cart',
                                          th: 'เพิ่มลงตะกร้า'),
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 16),
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
      },
    );
  }
}

// ============================================================================
// Detail Row Widget (เหมือนเดิม)
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