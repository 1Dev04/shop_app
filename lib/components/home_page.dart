// lib/components/home_page.dart

import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/blocs/cat_home/home_bloc.dart';
import 'package:flutter_application_1/blocs/cat_item_detail/item_detail_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/signin_user.dart';
import 'package:flutter_application_1/screen/chat_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'dart:async';

// ── SnackBar helper ────────────────────────────────────────────────────────
void _showTopSnack(BuildContext context, String message,
    {required bool isError}) {
  showTopSnackBar(
    Overlay.of(context),
    isError
        ? CustomSnackBar.error(message: message)
        : CustomSnackBar.success(message: message),
    animationDuration: const Duration(milliseconds: 1000),
    reverseAnimationDuration: const Duration(milliseconds: 200),
    displayDuration: const Duration(milliseconds: 1000),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// HomePage
// ════════════════════════════════════════════════════════════════════════════

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc()..add(const HomeAdsLoadRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  final PageController _pageController = PageController(initialPage: 1000);
  int _currentPage = 0;
  Timer? _timer;
  bool _isUserInteracting = false;

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoScroll(int adsLength) {
    _timer?.cancel();
    if (adsLength == 0) return;
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_isUserInteracting && _pageController.hasClients) {
        _pageController.animateToPage(
          ((_pageController.page ?? 0) + 1).toInt(),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _showItemDetailPopup(
      BuildContext blocCtx, Map<String, dynamic> itemDetail) {
    showGeneralDialog(
      context: blocCtx,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(blocCtx).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return BlocProvider(
          create: (_) => ItemDetailBloc()
            ..add(ItemDetailFavCheckRequested(
                itemDetail['uuid']?.toString() ?? '')),
          child: ItemDetailsCard(itemDetails: itemDetail),
        );
      },
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

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return BlocConsumer<HomeBloc, HomeState>(
      listener: (ctx, state) {
        // ads โหลดเสร็จ → เริ่ม auto scroll + ผูก listener
        if (state is HomeLoaded && state.ads.isNotEmpty) {
          _pageController.addListener(() {
            if (state.ads.isEmpty) return;
            final page = (_pageController.page ?? 0).round() % state.ads.length;
            if (page != _currentPage && mounted) {
              setState(() => _currentPage = page);
            }
          });
          _startAutoScroll(state.ads.length);
        }

        // item detail โหลดเสร็จ → เปิด popup
        if (state is HomeItemDetailLoaded) {
          _showItemDetailPopup(ctx, state.itemDetail);
        }

        // item detail ล้มเหลว
        if (state is HomeItemDetailFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(
              content: Text('ไม่สามารถโหลดข้อมูลได้'),
              backgroundColor: Colors.red,
            ),
          );
        }

        // basket สำเร็จ/ล้มเหลว
        if (state is HomeBasketActionSuccess) {
          _showTopSnack(
            ctx,
            languageProvider.translate(
                en: 'Added to Basket successfully!',
                th: 'เพิ่มลงตะกร้าสำเร็จ!'),
            isError: false,
          );
        } else if (state is HomeBasketActionFailure) {
          _showTopSnack(
            ctx,
            languageProvider.translate(
                en: 'Failed to add to Basket', th: 'เพิ่มลงตะกร้าไม่สำเร็จ'),
            isError: true,
          );
        }
      },
      builder: (ctx, state) {
        // ── Loading ─────────────────────────────────────────────────────────
        if (state is HomeInitial || state is HomeLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Failure ─────────────────────────────────────────────────────────
        if (state is HomeFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        ctx.read<HomeBloc>().add(const HomeAdsLoadRequested()),
                    child: const Text('ลองใหม่'),
                  ),
                ],
              ),
            ),
          );
        }

        // ── ดึง ads จาก state ───────────────────────────────────────────────
        final ads = _adsFromState(state);
        final isDetailLoading = state is HomeItemDetailLoading;
        final isBasketLoading = state is HomeBasketActionInProgress;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        if (ads.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('ไม่มีข้อมูลโฆษณา')),
          );
        }

        return Scaffold(
          body: Stack(
            children: [
              GestureDetector(
                onPanDown: (_) {
                  _isUserInteracting = true;
                  _timer?.cancel();
                },
                onPanCancel: () {
                  _isUserInteracting = false;
                  _startAutoScroll(ads.length);
                },
                onPanEnd: (_) {
                  _isUserInteracting = false;
                  _startAutoScroll(ads.length);
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemCount: null,
                  onPageChanged: (index) {
                    if (ads.isEmpty) return;
                    setState(() => _currentPage = index % ads.length);
                  },
                  itemBuilder: (_, index) {
                    final item = ads[index % ads.length];
                    final discountPrice = _parseDouble(item['discount_price']);
                    final hasDiscount = discountPrice > 0;

                    final rawImages = item['images'];
                    final imagesMap = rawImages is String
                        ? Map<String, dynamic>.from(jsonDecode(rawImages))
                        : rawImages is Map
                            ? Map<String, dynamic>.from(rawImages)
                            : <String, dynamic>{};

                    return Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: item['image_url'] ?? '',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) =>
                              const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) =>
                              const Center(child: Icon(Icons.error)),
                        ),

                        // ชื่อสินค้า
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

                        // ราคา
                        Positioned(
                          bottom: 130,
                          left: 20,
                          right: 20,
                          child: Row(
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

                        // ปุ่มล่าง
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
                                    onPressed: (isBasketLoading ||
                                            isDetailLoading)
                                        ? null
                                        : () {
                                            if (FirebaseAuth.instance
                                                    .currentUser?.email ==
                                                'guest678@gmail.com') {
                                              // reuse _showGuestDialog หรือ showDialog inline
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor: isDark
                                                      ? Colors.grey[900]
                                                      : Colors.white,
                                                  title: const Text(
                                                      'Members Only'),
                                                  content: const Text(
                                                      'Please login to edit your profile.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            ctx.read<HomeBloc>().add(
                                                  HomeAddToBasketRequested(
                                                      item['uuid']
                                                              ?.toString() ??
                                                          ''),
                                                );
                                          },
                                    backgroundColor: Theme.of(context)
                                        .floatingActionButtonTheme
                                        .backgroundColor,
                                    child: isBasketLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : Icon(
                                            Icons.shopping_cart_outlined,
                                            size: 30,
                                            color: Theme.of(context)
                                                .floatingActionButtonTheme
                                                .foregroundColor,
                                          ),
                                  ),
                                  const SizedBox(width: 5),
                                  ElevatedButton(
                                    onPressed: (isDetailLoading ||
                                            isBasketLoading)
                                        ? null
                                        : () {
                                            final itemId = int.tryParse(
                                                    item['id']?.toString() ??
                                                        '0') ??
                                                0;
                                            ctx.read<HomeBloc>().add(
                                                HomeItemDetailRequested(
                                                    itemId));
                                          },
                                    child: Text(
                                      languageProvider.translate(
                                          en: 'Learn More', th: 'ดูเพิ่มเติม'),
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
                                  placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator()),
                                  errorWidget: (_, __, ___) =>
                                      const Icon(Icons.error),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Vertical page indicator
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(ads.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        width: 8,
                        height: isActive ? 24 : 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.deepOrange
                              : Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 10,
                child: SafeArea(
                  child: FloatingActionButton.small(
                    heroTag: 'home_fab',
                    onPressed: () {
                      if (FirebaseAuth.instance.currentUser?.email ==
                          'guest678@gmail.com') {
                        final languageProvider = Provider.of<LanguageProvider>(
                            context,
                            listen: false);
                        final isDark =
                            Theme.of(context).brightness == Brightness.dark;
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  backgroundColor:
                                      isDark ? Colors.grey[900] : Colors.white,
                                  title: Text(languageProvider.translate(
                                    en: 'Members Only',
                                    th: 'สำหรับสมาชิกเท่านั้น',
                                  )),
                                  content: Text(languageProvider.translate(
                                    en: 'Please register or login to access this feature.',
                                    th: 'กรุณาสมัครสมาชิก หรือเข้าสู่ระบบเพื่อใช้งาน',
                                  )),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(languageProvider.translate(
                                        en: 'Cancel',
                                        th: 'ยกเลิก',
                                      )),
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                              builder: (_) => const Login()),
                                        );
                                      },
                                      child: Text(languageProvider.translate(
                                        en: 'Login / Register',
                                        th: 'เข้าสู่ระบบ / สมัครสมาชิก',
                                      )),
                                    ),
                                  ],
                                ));
                      }
                      else {
                        Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ChatPage()));
                      }
                    },
                    backgroundColor: Colors.white.withOpacity(0.85),
                    child: const Icon(Icons.chat_bubble_outline,
                        color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _adsFromState(HomeState state) {
    if (state is HomeLoaded) return state.ads;
    if (state is HomeItemDetailLoading) return state.ads;
    if (state is HomeItemDetailLoaded) return state.ads;
    if (state is HomeItemDetailFailure) return state.ads;
    if (state is HomeBasketActionInProgress) return state.ads;
    if (state is HomeBasketActionSuccess) return state.ads;
    if (state is HomeBasketActionFailure) return state.ads;
    return [];
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ItemDetailsCard — ใช้ ItemDetailBloc
// ════════════════════════════════════════════════════════════════════════════

class ItemDetailsCard extends StatefulWidget {
  final Map<String, dynamic> itemDetails;

  const ItemDetailsCard({super.key, required this.itemDetails});

  @override
  State<ItemDetailsCard> createState() => _ItemDetailsCardState();
}

class _ItemDetailsCardState extends State<ItemDetailsCard> {
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final discountPrice = _parseDouble(widget.itemDetails['discount_price']);
    final hasDiscount = discountPrice > 0;
    final uuid = widget.itemDetails['uuid']?.toString() ?? '';

    final rawImages = widget.itemDetails['images'];
    final imagesMap = rawImages is String
        ? Map<String, dynamic>.from(jsonDecode(rawImages))
        : rawImages is Map
            ? Map<String, dynamic>.from(rawImages)
            : <String, dynamic>{};

    return BlocConsumer<ItemDetailBloc, ItemDetailState>(
      listener: (ctx, state) {
        if (state is ItemDetailFavToggleSuccess) {
          _showTopSnack(
            ctx,
            state.isFavourite
                ? languageProvider.translate(
                    en: 'Added to favourites successfully!',
                    th: 'เพิ่มลงรายการโปรดแล้ว!')
                : languageProvider.translate(
                    en: 'Removed from favourites!',
                    th: 'ลบออกจากรายการโปรดแล้ว'),
            isError: false,
          );
        } else if (state is ItemDetailBasketSuccess) {
          Navigator.of(ctx).pop();
          _showTopSnack(
            ctx,
            languageProvider.translate(
                en: 'Added to Basket successfully!',
                th: 'เพิ่มลงตะกร้าสำเร็จ!'),
            isError: false,
          );
        } else if (state is ItemDetailActionFailure) {
          final msg = state.message;
          final display = msg.startsWith('basket_failed:')
              ? languageProvider.translate(
                  en: 'Failed to add to Basket', th: 'เพิ่มลงตะกร้าไม่สำเร็จ')
              : languageProvider.translate(
                  en: 'Failed to update favourites',
                  th: 'อัปเดตรายการโปรดไม่สำเร็จ');
          _showTopSnack(ctx, display, isError: true);
        }
      },
      builder: (ctx, state) {
        final isFavourite = _isFavFromState(state);
        final isProcessing = state is ItemDetailActionInProgress;
        final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      // ── Image Slideshow ──────────────────────────────
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
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => const SizedBox(
                                      height: 300,
                                      child: Center(child: Icon(Icons.error)),
                                    ),
                                  ),
                                  CachedNetworkImage(
                                    imageUrl: imagesMap['image_clothing'] ?? '',
                                    width: double.infinity,
                                    height: 300,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const SizedBox(
                                      height: 300,
                                      child: Center(
                                          child: CircularProgressIndicator()),
                                    ),
                                    errorWidget: (_, __, ___) => const SizedBox(
                                      height: 300,
                                      child: Center(child: Icon(Icons.error)),
                                    ),
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
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
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
                              onTap: isProcessing
                                  ? null
                                  : () {
                                      if (FirebaseAuth
                                              .instance.currentUser?.email ==
                                          'guest678@gmail.com') {
                                        // reuse _showGuestDialog หรือ showDialog inline
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: isDark
                                                ? Colors.grey[900]
                                                : Colors.white,
                                            title: const Text('Members Only'),
                                            content: const Text(
                                                'Please login to edit your profile.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ),
                                        );
                                        return;
                                      }
                                      ctx.read<ItemDetailBloc>().add(
                                            ItemDetailFavToggleRequested(
                                              clothingUuid: uuid,
                                              currentlyFavourite: isFavourite,
                                            ),
                                          );
                                    },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isFavourite
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
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : Icon(
                                        isFavourite
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

                      // ── Content ──────────────────────────────────────
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
                                      fontWeight: FontWeight.bold),
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
                                  value:
                                      widget.itemDetails['size_category'] ?? '',
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Gender', th: 'เพศ'),
                                  value: formatGender(
                                      widget.itemDetails['gender'],
                                      languageProvider),
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Stock', th: 'สต็อก'),
                                  value:
                                      widget.itemDetails['stock']?.toString() ??
                                          '',
                                ),
                                _DetailRow(
                                  label: languageProvider.translate(
                                      en: 'Breed', th: 'สายพันธุ์'),
                                  value: widget.itemDetails['breed'] ?? '',
                                ),
                                if (widget.itemDetails['description'] != null)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('รายละเอียด',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.itemDetails['description'] ?? '',
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
                                        '฿${widget.itemDetails['price']?.toString() ?? ''}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.grey,
                                          decoration:
                                              TextDecoration.lineThrough,
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
                                        color: hasDiscount
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                                    if (hasDiscount) const SizedBox(width: 10),
                                    if (hasDiscount)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '-${widget.itemDetails['discount_percent']?.toString() ?? '0'}',
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
                                    onPressed: isProcessing
                                        ? null
                                        : () {
                                            if (FirebaseAuth.instance
                                                    .currentUser?.email ==
                                                'guest678@gmail.com') {
                                              // reuse _showGuestDialog หรือ showDialog inline
                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  backgroundColor: isDark
                                                      ? Colors.grey[900]
                                                      : Colors.white,
                                                  title: const Text(
                                                      'Members Only'),
                                                  content: const Text(
                                                      'Please login to edit your profile.'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              return;
                                            }
                                            ctx.read<ItemDetailBloc>().add(
                                                  ItemDetailAddToBasketRequested(
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

  bool _isFavFromState(ItemDetailState state) {
    if (state is ItemDetailLoaded) return state.isFavourite;
    if (state is ItemDetailActionInProgress) return state.isFavourite;
    if (state is ItemDetailFavToggleSuccess) return state.isFavourite;
    if (state is ItemDetailActionFailure) return state.isFavourite;
    if (state is ItemDetailBasketSuccess) return state.isFavourite;
    return false;
  }
}

// ── Detail Row (เหมือนเดิม) ────────────────────────────────────────────────
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
