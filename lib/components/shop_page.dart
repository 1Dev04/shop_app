// ShopPage — refactored with BLoC

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_shop/shop_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// ============================================================================
// ShopPage — entry point
// ============================================================================

class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ShopBloc()..add(const ShopLoadRequested()),
      child: const _ShopView(),
    );
  }
}

// ============================================================================
// _ShopView
// ============================================================================

class _ShopView extends StatefulWidget {
  const _ShopView();

  @override
  State<_ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<_ShopView> {
  final PageController _pageControlShop1 = PageController(initialPage: 0);
  final PageController _pageControlShop2 = PageController(initialPage: 0);

  @override
  void dispose() {
    _pageControlShop1.dispose();
    _pageControlShop2.dispose();
    super.dispose();
  }

  void _showItemDetailPopup(BuildContext ctx, Map<String, dynamic> itemDetail) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(ctx).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) =>
          _ShopItemDetailsCard(itemDetails: itemDetail),
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _likeFromState(ShopState state) {
    if (state is ShopLoaded) return state.likeItems;
    if (state is ShopItemDetailLoading) return state.likeItems;
    if (state is ShopItemDetailLoaded) return state.likeItems;
    if (state is ShopItemDetailFailure) return state.likeItems;
    if (state is ShopBasketInProgress) return state.likeItems;
    if (state is ShopBasketSuccess) return state.likeItems;
    if (state is ShopBasketFailure) return state.likeItems;
    return [];
  }

  List<Map<String, dynamic>> _sellerFromState(ShopState state) {
    if (state is ShopLoaded) return state.sellerItems;
    if (state is ShopItemDetailLoading) return state.sellerItems;
    if (state is ShopItemDetailLoaded) return state.sellerItems;
    if (state is ShopItemDetailFailure) return state.sellerItems;
    if (state is ShopBasketInProgress) return state.sellerItems;
    if (state is ShopBasketSuccess) return state.sellerItems;
    if (state is ShopBasketFailure) return state.sellerItems;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return BlocConsumer<ShopBloc, ShopState>(
      listener: (ctx, state) {
        // เปิด popup เมื่อ detail โหลดเสร็จ
        if (state is ShopItemDetailLoaded) {
          _showItemDetailPopup(ctx, state.itemDetail);
        }

        // detail ล้มเหลว
        if (state is ShopItemDetailFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถโหลดข้อมูลได้'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // basket success/failure
        if (state is ShopBasketSuccess) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Added to Basket successfully!',
                th: 'เพิ่มลงตะกร้าสำเร็จ!',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        } else if (state is ShopBasketFailure) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.error(
              message: languageProvider.translate(
                en: 'Failed to add to Basket',
                th: 'เพิ่มลงตะกร้าไม่สำเร็จ',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      },
      builder: (ctx, state) {
        // ── Loading ──────────────────────────────────────────────────────────
        if (state is ShopInitial || state is ShopLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final likeItems = _likeFromState(state);
        final sellerItems = _sellerFromState(state);
        final isDetailLoading = state is ShopItemDetailLoading;
        final isBasketLoading = state is ShopBasketInProgress;
        final basketUuid =
            state is ShopBasketInProgress ? state.uuid : null;

        // ── Failure (สำหรับทั้งคู่) ─────────────────────────────────────────
        if (state is ShopFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  if (state.likeError.isNotEmpty) Text(state.likeError),
                  if (state.sellerError.isNotEmpty) Text(state.sellerError),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ctx
                        .read<ShopBloc>()
                        .add(const ShopLoadRequested()),
                    icon: const Icon(Icons.refresh),
                    label: Text(languageProvider.translate(
                        en: 'Retry', th: 'ลองอีกครั้ง')),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          body: SingleChildScrollView(
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
                        placeholder: (_, __) =>
                            const CircularProgressIndicator.adaptive(
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color.fromARGB(75, 50, 50, 50)),
                        ),
                        errorWidget: (_, __, ___) =>
                            const Icon(Icons.error),
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: Theme.of(context).colorScheme.onSurface, height: 1),
                const SizedBox(height: 10),

                // You might like this
                _buildSection(
                  ctx: ctx,
                  title: languageProvider.translate(
                      en: 'You might like this', th: 'คุณอาจจะชอบสิ่งนี้'),
                  data: likeItems,
                  controller: _pageControlShop1,
                  languageProvider: languageProvider,
                  isDetailLoading: isDetailLoading,
                  isBasketLoading: isBasketLoading,
                  basketUuid: basketUuid,
                ),

                // Best Seller
                _buildSection(
                  ctx: ctx,
                  title: languageProvider.translate(
                      en: 'Best Seller', th: 'สินค้าขายดี'),
                  data: sellerItems,
                  controller: _pageControlShop2,
                  languageProvider: languageProvider,
                  isDetailLoading: isDetailLoading,
                  isBasketLoading: isBasketLoading,
                  basketUuid: basketUuid,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required BuildContext ctx,
    required String title,
    required List<Map<String, dynamic>> data,
    required PageController controller,
    required LanguageProvider languageProvider,
    required bool isDetailLoading,
    required bool isBasketLoading,
    required String? basketUuid,
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
        data.isEmpty
            ? const SizedBox(
                height: 490, child: Center(child: Text('ไม่มีข้อมูล')))
            : SizedBox(
                height: 490,
                child: PageView.builder(
                  controller: controller,
                  itemCount: data.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (_, index) {
                    final item = data[index];
                    final price = _parseDouble(item['price']);
                    final discountPrice = _parseDouble(item['discount_price']);
                    final hasDiscount =
                        discountPrice > 0 && discountPrice < price;
                    final itemUuid = item['uuid']?.toString() ?? '';
                    final thisIsLoading =
                        isBasketLoading && basketUuid == itemUuid;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 10),
                      child: Column(
                        children: [
                          // รูปภาพ — กดดู detail
                          GestureDetector(
                            onTap: isDetailLoading
                                ? null
                                : () {
                                    final itemId = int.tryParse(
                                            item['id']?.toString() ?? '0') ??
                                        0;
                                    ctx.read<ShopBloc>().add(
                                        ShopItemDetailRequested(itemId));
                                  },
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                CachedNetworkImage(
                                  imageUrl:
                                      item['image_url']?.toString() ?? '',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 350,
                                  placeholder: (_, __) =>
                                      const CircularProgressIndicator.adaptive(),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.error),
                                ),
                                if (isDetailLoading)
                                  const CircularProgressIndicator(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Gender + Size
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getGenderText(
                                    item['gender'], languageProvider),
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                item['size_category']?.toString() ?? 'N/A',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Name + Stock
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item['clothing_name']?.toString() ?? 'N/A',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Price + Cart button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  if (hasDiscount) ...[
                                    Text(
                                      '฿${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        decoration:
                                            TextDecoration.lineThrough,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
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
                                  if (hasDiscount) ...[
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 4, vertical: 2),
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
                                ],
                              ),
                              FloatingActionButton.small(
                                heroTag:
                                    'shop_cart_${itemUuid}_$index',
                                onPressed: (thisIsLoading || isDetailLoading)
                                    ? null
                                    : () => ctx.read<ShopBloc>().add(
                                        ShopAddToBasketRequested(itemUuid)),
                                backgroundColor: thisIsLoading
                                    ? Colors.grey
                                    : Theme.of(context)
                                        .floatingActionButtonTheme
                                        .backgroundColor,
                                child: thisIsLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Icon(
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

  String _getGenderText(dynamic gender, LanguageProvider lang) {
    final code =
        gender is int ? gender : int.tryParse(gender?.toString() ?? '');
    switch (code) {
      case 0: return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
      case 1: return lang.translate(en: 'Male', th: 'เพศผู้');
      case 2: return lang.translate(en: 'Female', th: 'เพศเมีย');
      case 3: return lang.translate(en: 'Kitten', th: 'ลูกแมว');
      default: return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
    }
  }
}

// ============================================================================
// _ShopItemDetailsCard (StatefulWidget — fav/basket local)
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

  Future<void> _checkFavouriteStatus() async {
    try {
      final isFav = await FavouriteApiService().checkFavourite(
        clothingUuid: widget.itemDetails['uuid'],
      );
      if (mounted) setState(() => _isFavourite = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      if (_isFavourite) {
        await FavouriteApiService()
            .removeFromFavourite(clothingUuid: widget.itemDetails['uuid']);
        if (mounted) setState(() => _isFavourite = false);
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: languageProvider.translate(
                  en: 'Removed from favourites!',
                  th: 'ลบออกจากรายการโปรดแล้ว'),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      } else {
        await FavouriteApiService()
            .addToFavourite(clothingUuid: widget.itemDetails['uuid']);
        if (mounted) setState(() => _isFavourite = true);
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: languageProvider.translate(
                  en: 'Added to favourites successfully!',
                  th: 'เพิ่มลงรายการโปรดแล้ว!'),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
                en: 'Failed to update favourites',
                th: 'อัปเดตรายการโปรดไม่สำเร็จ'),
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

  Future<void> _addToBasket() async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      await BasketApiService()
          .addToBasket(clothingUuid: widget.itemDetails['uuid']);
      if (mounted) {
        Navigator.of(context).pop();
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: languageProvider.translate(
                en: 'Added to Basket successfully!', th: 'เพิ่มลงตะกร้าสำเร็จ!'),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
                en: 'Failed to add to Basket', th: 'เพิ่มลงตะกร้าไม่สำเร็จ'),
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _imagePageController,
                          onPageChanged: (i) =>
                              setState(() => _currentImagePage = i),
                          children: [
                            CachedNetworkImage(
                              imageUrl:
                                  widget.itemDetails['image_url'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                  height: 300,
                                  child: Center(
                                      child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error))),
                            ),
                            CachedNetworkImage(
                              imageUrl: imagesMap['image_clothing'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                  height: 300,
                                  child: Center(
                                      child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error))),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Page indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(2, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImagePage == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImagePage == i
                                  ? Colors.deepOrange
                                  : Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
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
                            value: widget.itemDetails['category']
                                    ?.toString() ??
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
                          if ((widget.itemDetails['description']?.toString() ??
                                  '')
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
                              if (hasDiscount) ...[
                                Text(
                                  '฿${price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                    decoration: TextDecoration.lineThrough,
                                    decorationThickness: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                              ],
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
                              if (hasDiscount &&
                                  discountPercentClean.isNotEmpty) ...[
                                const SizedBox(width: 10),
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
                            ],
                          ),
                          const SizedBox(height: 10),
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

// ============================================================================
// Helpers
// ============================================================================

String _formatGender(dynamic value, LanguageProvider lang) {
  final code =
      value is int ? value : int.tryParse(value?.toString() ?? '');
  switch (code) {
    case 0: return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
    case 1: return lang.translate(en: 'Male', th: 'เพศผู้');
    case 2: return lang.translate(en: 'Female', th: 'เพศเมีย');
    case 3: return lang.translate(en: 'Kitten', th: 'ลูกแมว');
    default: return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
  }
}