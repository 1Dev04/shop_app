// NotificationPage — refactored with BLoC

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_notification/notification_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
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

// ============================================================================
// NotificationPage — entry point
// ============================================================================

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationBloc()..add(const NotificationLoadRequested()),
      child: const _NotificationView(),
    );
  }
}

// ============================================================================
// _NotificationView
// ============================================================================

class _NotificationView extends StatefulWidget {
  const _NotificationView();

  @override
  State<_NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<_NotificationView> {
  final PageController _bannerController = PageController();
  final PageController _contentTypeController = PageController();
  final PageController _messageController = PageController();
  final PageController _newsController = PageController();

  int _currentBannerIndex = 0;
  int _currentContentType = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    _contentTypeController.dispose();
    _messageController.dispose();
    _newsController.dispose();
    super.dispose();
  }

  void _showDetailPopup(BuildContext ctx, dynamic item) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(ctx).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => _NotificationDetailCard(item: item),
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

  List<NotificationItemMess> _messagesFromState(NotificationState state) {
    if (state is NotificationLoaded) return state.messages;
    if (state is NotificationDetailLoading) return state.messages;
    if (state is NotificationDetailLoaded) return state.messages;
    if (state is NotificationDetailFailure) return state.messages;
    if (state is NotificationBasketInProgress) return state.messages;
    if (state is NotificationBasketSuccess) return state.messages;
    if (state is NotificationBasketFailure) return state.messages;
    return [];
  }

  List<NotificationItemNews> _newsFromState(NotificationState state) {
    if (state is NotificationLoaded) return state.news;
    if (state is NotificationDetailLoading) return state.news;
    if (state is NotificationDetailLoaded) return state.news;
    if (state is NotificationDetailFailure) return state.news;
    if (state is NotificationBasketInProgress) return state.news;
    if (state is NotificationBasketSuccess) return state.news;
    if (state is NotificationBasketFailure) return state.news;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (ctx, state) {
        // เปิด popup เมื่อ detail โหลดเสร็จ
        if (state is NotificationDetailLoaded) {
          _showDetailPopup(ctx, state.itemDetail);
        }

        // detail ล้มเหลว
        if (state is NotificationDetailFailure) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }

        // basket สำเร็จ/ล้มเหลว
        if (state is NotificationBasketSuccess) {
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
        } else if (state is NotificationBasketFailure) {
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
        // ── Loading ────────────────────────────────────────────────────────
        if (state is NotificationInitial || state is NotificationLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // ── Failure (โหลดครั้งแรกล้มเหลว) ────────────────────────────────
        if (state is NotificationFailure) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => ctx
                        .read<NotificationBloc>()
                        .add(const NotificationLoadRequested()),
                    icon: const Icon(Icons.refresh),
                    label: Text(languageProvider.translate(
                        en: 'Retry', th: 'ลองอีกครั้ง')),
                  ),
                ],
              ),
            ),
          );
        }

        final messages = _messagesFromState(state);
        final news = _newsFromState(state);
        final isDetailLoading = state is NotificationDetailLoading;
        final isBasketLoading = state is NotificationBasketInProgress;

        return Scaffold(
          body: RefreshIndicator(
            onRefresh: () async {
              ctx
                  .read<NotificationBloc>()
                  .add(const NotificationRefreshRequested());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // Banner
                  _BannerCarousel(
                    controller: _bannerController,
                    currentIndex: _currentBannerIndex,
                    onPageChanged: (i) =>
                        setState(() => _currentBannerIndex = i),
                  ),
                  const SizedBox(height: 10),
                  _BannerIndicators(
                    count: NotificationData.bannerImages.length,
                    currentIndex: _currentBannerIndex,
                    onTap: (i) => _bannerController.animateToPage(
                      i,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ContentTypeTabs(
                    currentType: _currentContentType,
                    onTabChanged: (i) {
                      setState(() => _currentContentType = i);
                      _contentTypeController.animateToPage(
                        i,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  Divider(
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 2),
                  SizedBox(
                    height: 280,
                    child: PageView(
                      controller: _contentTypeController,
                      onPageChanged: (i) =>
                          setState(() => _currentContentType = i),
                      children: [
                        // Messages Tab
                        messages.isEmpty
                            ? Center(
                                child: Text(languageProvider.translate(
                                    en: 'No messages available',
                                    th: 'ไม่มีข้อความ')),
                              )
                            : _ContentList(
                                controller: _messageController,
                                items: messages,
                                isLoading: isDetailLoading || isBasketLoading,
                                onLearnMore: (id) => ctx
                                    .read<NotificationBloc>()
                                    .add(
                                        NotificationMessageDetailRequested(id)),
                                onAddToBasket: (uuid) => ctx
                                    .read<NotificationBloc>()
                                    .add(
                                        NotificationAddToBasketRequested(uuid)),
                                basketLoadingUuid:
                                    isBasketLoading ? state.uuid : null,
                              ),

                        // News Tab
                        news.isEmpty
                            ? Center(
                                child: Text(languageProvider.translate(
                                    en: 'No news available', th: 'ไม่มีข่าว')),
                              )
                            : _ContentList(
                                controller: _newsController,
                                items: news,
                                isLoading: isDetailLoading || isBasketLoading,
                                onLearnMore: (id) => ctx
                                    .read<NotificationBloc>()
                                    .add(NotificationNewsDetailRequested(id)),
                                onAddToBasket: (uuid) => ctx
                                    .read<NotificationBloc>()
                                    .add(
                                        NotificationAddToBasketRequested(uuid)),
                                basketLoadingUuid:
                                    isBasketLoading ? state.uuid : null,
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// _ContentList
// ============================================================================

class _ContentList extends StatelessWidget {
  final PageController controller;
  final List<dynamic> items;
  final bool isLoading;
  final Function(String) onLearnMore;
  final Function(String) onAddToBasket;
  final String? basketLoadingUuid;

  const _ContentList({
    required this.controller,
    required this.items,
    required this.isLoading,
    required this.onLearnMore,
    required this.onAddToBasket,
    this.basketLoadingUuid,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: items.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        final item = items[index];
        return _ContentCard(
          item: item,
          isLoading: isLoading,
          onLearnMore: onLearnMore,
          onAddToBasket: onAddToBasket,
          isBasketLoading: basketLoadingUuid == item.uuid,
        );
      },
    );
  }
}

// ============================================================================
// _ContentCard
// ============================================================================

class _ContentCard extends StatelessWidget {
  final dynamic item;
  final bool isLoading;
  final Function(String) onLearnMore;
  final Function(String) onAddToBasket;
  final bool isBasketLoading;

  const _ContentCard({
    required this.item,
    required this.isLoading,
    required this.onLearnMore,
    required this.onAddToBasket,
    required this.isBasketLoading,
  });

  @override
  Widget build(BuildContext context) {
    final price = _parseDouble(item.price);
    final discountPrice = item is NotificationItemMess
        ? _parseDouble((item as NotificationItemMess).discount_price)
        : 0.0;
    final hasDiscount = discountPrice > 0 && discountPrice < price;
    final isMessage = item is NotificationItemMess;
    final discountPercentRaw =
        isMessage ? (item as NotificationItemMess).discount_percent : '';
    final discountPercentClean = discountPercentRaw.replaceAll('%', '').trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.image_url ?? '',
              fit: BoxFit.cover,
              width: 180,
              height: 180,
              placeholder: (_, __) =>
                  const CircularProgressIndicator.adaptive(),
              errorWidget: (_, __, ___) => Container(
                width: 180,
                height: 180,
                color: Colors.grey.shade200,
                child: const Icon(Icons.error, size: 40),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              height: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isMessage
                        ? '${item.clothing_name} ลดพิเศษ!'
                        : item.clothing_name ?? '',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(item.create_at ?? '', context),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasDiscount && discountPercentClean.isNotEmpty) ...[
                        const SizedBox(width: 8),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  // ปุ่ม
                  Row(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'notif_cart_${item.id}',
                        onPressed: (isLoading || isBasketLoading)
                            ? null
                            : () {
                                if (FirebaseAuth.instance.currentUser?.email ==
                                    'guest678@gmail.com') {
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
                                onAddToBasket(item.uuid ?? '');
                              },
                        backgroundColor: isBasketLoading
                            ? Colors.grey
                            : Theme.of(context)
                                .floatingActionButtonTheme
                                .backgroundColor,
                        child: isBasketLoading
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => onLearnMore(item.id ?? ''),
                          child: const Icon(Icons.read_more_outlined, size: 30),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Detail Card (ยังคง StatefulWidget เพราะจัดการ fav/basket เป็น local)
// ============================================================================

class _NotificationDetailCard extends StatefulWidget {
  final dynamic item;
  const _NotificationDetailCard({required this.item});

  @override
  State<_NotificationDetailCard> createState() =>
      _NotificationDetailCardState();
}

class _NotificationDetailCardState extends State<_NotificationDetailCard> {
  bool _isFavourite = false;
  bool _isProcessing = false;
  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  String get _uuid => widget.item.uuid ?? '';
  String get _imageUrl => widget.item.image_url ?? '';
  Map<String, dynamic> get _imagesMap => _parseImagesMap(widget.item.images);

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
    if (_uuid.isEmpty) return;
    try {
      final isFav =
          await FavouriteApiService().checkFavourite(clothingUuid: _uuid);
      if (mounted) setState(() => _isFavourite = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    if (FirebaseAuth.instance.currentUser?.email == 'guest678@gmail.com') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: const Text('Members Only'),
          content: const Text('Please login to edit your profile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      if (_isFavourite) {
        await FavouriteApiService().removeFromFavourite(clothingUuid: _uuid);
        if (mounted) setState(() => _isFavourite = false);
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: languageProvider.translate(
                  en: 'Removed from favourites!', th: 'ลบออกจากรายการโปรดแล้ว'),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      } else {
        await FavouriteApiService().addToFavourite(clothingUuid: _uuid);
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
    if (FirebaseAuth.instance.currentUser?.email == 'guest678@gmail.com') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: const Text('Members Only'),
          content: const Text('Please login to edit your profile.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      return;
    }

    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      await BasketApiService().addToBasket(clothingUuid: _uuid);
      if (mounted) {
        Navigator.of(context).pop();
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.success(
            message: languageProvider.translate(
                en: 'Added to Basket successfully!',
                th: 'เพิ่มลงตะกร้าสำเร็จ!'),
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
    final price = _parseDouble(widget.item.price);
    final discountPrice = _parseDouble(
      widget.item is NotificationItemMess
          ? (widget.item as NotificationItemMess).discount_price
          : (widget.item as NotificationItemNews).discount_price,
    );
    final hasDiscount = discountPrice > 0 && discountPrice < price;
    final discountPercentRaw = widget.item is NotificationItemMess
        ? (widget.item as NotificationItemMess).discount_percent
        : (widget.item as NotificationItemNews).discount_percent;
    final discountPercentClean = discountPercentRaw.replaceAll('%', '').trim();

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
                                imageUrl: _imageUrl,
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
                                imageUrl: _imagesMap['image_clothing'] ?? '',
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
                              widget.item.clothing_name ?? '',
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Category', th: 'หมวดหมู่'),
                              value: widget.item.category ?? '',
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Size', th: 'ขนาด'),
                              value: widget.item.size_category ?? '',
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Gender', th: 'เพศ'),
                              value: formatGender(
                                  widget.item.gender ?? '', languageProvider),
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Stock', th: 'สต็อก'),
                              value: widget.item.stock ?? '',
                            ),
                            _DetailRow(
                              label: languageProvider.translate(
                                  en: 'Breed', th: 'สายพันธุ์'),
                              value: widget.item.breed ?? '',
                            ),
                            if ((widget.item.description ?? '').isNotEmpty)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Text(
                                    languageProvider.translate(
                                        en: 'Description', th: 'รายละเอียด'),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.item.description ?? '',
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
// Banner Carousel
// ============================================================================

class _BannerCarousel extends StatelessWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: controller,
        itemCount: NotificationData.bannerImages.length,
        onPageChanged: onPageChanged,
        itemBuilder: (_, index) => CachedNetworkImage(
          imageUrl: NotificationData.bannerImages[index],
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (_, __) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }
}

// ============================================================================
// Banner Indicators
// ============================================================================

class _BannerIndicators extends StatelessWidget {
  final int count;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BannerIndicators({
    required this.count,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => onTap(i),
            child: Icon(
              currentIndex == i ? Icons.circle : Icons.circle_outlined,
              size: 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Content Type Tabs
// ============================================================================

class _ContentTypeTabs extends StatelessWidget {
  final int currentType;
  final ValueChanged<int> onTabChanged;

  const _ContentTypeTabs(
      {required this.currentType, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabButton(
          label: lang.translate(en: 'Message', th: 'ข้อความ'),
          isSelected: currentType == 0,
          onTap: () => onTabChanged(0),
        ),
        _TabButton(
          label: lang.translate(en: 'News', th: 'ข่าว'),
          isSelected: currentType == 1,
          onTap: () => onTabChanged(1),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 50,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.surface
                  : Colors.transparent,
              width: 2.0,
            ),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.surface
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: isSelected ? 18 : 15,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Data Models
// ============================================================================

class NotificationItemMess {
  final String id;
  final String? uuid;
  final String image_url;
  final String images;
  final String clothing_name;
  final String category;
  final String size_category;
  final String description;
  final String price;
  final String discount_price;
  final String discount_percent;
  final String stock;
  final String gender;
  final String clothing_like;
  final String clothing_seller;
  final String breed;
  final String create_at;

  const NotificationItemMess({
    required this.id,
    this.uuid,
    required this.image_url,
    required this.images,
    required this.clothing_name,
    required this.category,
    required this.size_category,
    required this.description,
    required this.price,
    required this.discount_price,
    required this.discount_percent,
    required this.stock,
    required this.gender,
    required this.clothing_like,
    required this.clothing_seller,
    required this.breed,
    required this.create_at,
  });

  factory NotificationItemMess.fromJson(Map<String, dynamic> json) {
    return NotificationItemMess(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString(),
      image_url: json['image_url']?.toString() ?? '',
      images: json['images']?.toString() ?? '',
      clothing_name: json['clothing_name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      size_category: json['size_category']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      discount_price: json['discount_price']?.toString() ?? '',
      discount_percent: json['discount_percent']?.toString() ?? '',
      stock: json['stock']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      clothing_like: json['clothing_like']?.toString() ?? '',
      clothing_seller: json['clothing_seller']?.toString() ?? '',
      breed: json['breed']?.toString() ?? '',
      create_at: json['created_at']?.toString() ?? '',
    );
  }
}

class NotificationItemNews {
  final String id;
  final String? uuid;
  final String image_url;
  final String images;
  final String clothing_name;
  final String description;
  final String category;
  final String size_category;
  final String price;
  final String discount_price;
  final String discount_percent;
  final String gender;
  final String clothing_like;
  final String clothing_seller;
  final String stock;
  final String breed;
  final String create_at;

  const NotificationItemNews({
    required this.id,
    this.uuid,
    required this.image_url,
    required this.images,
    required this.clothing_name,
    required this.description,
    required this.category,
    required this.size_category,
    required this.price,
    required this.discount_price,
    required this.discount_percent,
    required this.stock,
    required this.gender,
    required this.clothing_like,
    required this.clothing_seller,
    required this.breed,
    required this.create_at,
  });

  factory NotificationItemNews.fromJson(Map<String, dynamic> json) {
    return NotificationItemNews(
      id: json['id']?.toString() ?? '',
      uuid: json['uuid']?.toString(),
      image_url: json['image_url']?.toString() ?? '',
      images: json['images']?.toString() ?? '',
      clothing_name: json['clothing_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      size_category: json['size_category']?.toString() ?? '',
      price: json['price']?.toString() ?? '',
      discount_price: json['discount_price']?.toString() ?? '',
      discount_percent: json['discount_percent']?.toString() ?? '',
      stock: json['stock']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      clothing_like: json['clothing_like']?.toString() ?? '',
      clothing_seller: json['clothing_seller']?.toString() ?? '',
      breed: json['breed']?.toString() ?? '',
      create_at: json['created_at']?.toString() ?? '',
    );
  }
}

class NotificationData {
  static final List<String> bannerImages = [
    "https://res.cloudinary.com/dag73dhpl/image/upload/v1769586709/Screenshot_2026-01-28_144831_d4yurr.png",
    "https://res.cloudinary.com/dag73dhpl/image/upload/v1769585619/Screenshot_2026-01-28_143025_qzfh7o.png",
    "https://res.cloudinary.com/dag73dhpl/image/upload/v1769585953/Screenshot_2026-01-28_143538_gtwma8.png",
    "https://res.cloudinary.com/dag73dhpl/image/upload/v1769586994/Screenshot_2026-01-28_145320_y6kvub.png",
    "https://res.cloudinary.com/dag73dhpl/image/upload/v1769587277/Screenshot_2026-01-28_145804_rtwpzv.png",
  ];
}

// ============================================================================
// Helpers
// ============================================================================

String _formatDate(String dateString, BuildContext context) {
  if (dateString.isEmpty) return '';
  final lang = Provider.of<LanguageProvider>(context, listen: false);
  try {
    DateTime dt;
    if (dateString.contains('T')) {
      dt = DateTime.parse(dateString);
    } else if (dateString.contains('-') && dateString.length >= 10) {
      dt = DateTime.parse(dateString.replaceAll(' ', 'T'));
    } else {
      return dateString;
    }
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) {
      return lang.translate(en: 'Just now', th: 'เมื่อสักครู่');
    } else if (diff.inMinutes < 60) {
      return lang.translate(
          en: '${diff.inMinutes} min ago', th: '${diff.inMinutes} นาทีที่แล้ว');
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      return lang.translate(
          en: '$h hour${h > 1 ? 's' : ''} ago', th: '$h ชั่วโมงที่แล้ว');
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      return lang.translate(
          en: '$d day${d > 1 ? 's' : ''} ago', th: '$d วันที่แล้ว');
    } else {
      return DateFormat('MMM dd, yyyy').format(dt);
    }
  } catch (_) {
    return dateString;
  }
}

String formatGender(String value, LanguageProvider lang) {
  switch (value) {
    case '0':
      return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
    case '1':
      return lang.translate(en: 'Male', th: 'เพศผู้');
    case '2':
      return lang.translate(en: 'Female', th: 'เพศเมีย');
    case '3':
      return lang.translate(en: 'Kitten', th: 'ลูกแมว');
    default:
      return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
  }
}
