// NotificationPage

import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
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
    // ลบ " THB", "%", whitespace ออก ก่อน parse
    final cleaned = value.replaceAll('THB', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

// ============================================================================
// API Configuration
// ============================================================================

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  static const Duration apiTimeout = Duration(seconds: 30);

  static Uri getMessagesUri() =>
      Uri.parse('$baseUrl/api/notifications/messages');
  static Uri getNewsUri() => Uri.parse('$baseUrl/api/notifications/news');
  static Uri getMessageDetailUri(String id) =>
      Uri.parse('$baseUrl/api/notifications/messages/$id');
  static Uri getNewsDetailUri(String id) =>
      Uri.parse('$baseUrl/api/notifications/news/$id');
}

// ============================================================================
// Main Notification Page
// ============================================================================

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  PageController? _bannerController;
  PageController? _contentTypeController;
  PageController? _messageController;
  PageController? _newsController;

  int _currentBannerIndex = 0;
  int _currentContentType = 0; // 0: Messages, 1: News

  List<NotificationItemMess> _messages = [];
  List<NotificationItemNews> _news = [];

  bool _isLoadingMessages = true;
  bool _isLoadingNews = true;
  bool _isRefreshing = false;

  String? _messagesError;
  String? _newsError;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadInitialData();
  }

  void _initializeControllers() {
    _bannerController = PageController();
    _contentTypeController = PageController();
    _messageController = PageController();
    _newsController = PageController();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchMessages(),
      _fetchNews(),
    ]);
  }

  @override
  void dispose() {
    _bannerController?.dispose();
    _contentTypeController?.dispose();
    _messageController?.dispose();
    _newsController?.dispose();
    super.dispose();
  }

  // ============================================================================
  // API Calls
  // ============================================================================

  Future<void> _fetchMessages() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMessages = true;
      _messagesError = null;
    });

    try {
      final response = await http
          .get(ApiConfig.getMessagesUri())
          .timeout(ApiConfig.apiTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _messages =
              data.map((json) => NotificationItemMess.fromJson(json)).toList();
          _isLoadingMessages = false;
        });
      } else {
        setState(() {
          _messagesError = 'Failed to load messages (${response.statusCode})';
          _isLoadingMessages = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messagesError = _getErrorMessage(e);
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _fetchNews() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      final response =
          await http.get(ApiConfig.getNewsUri()).timeout(ApiConfig.apiTimeout);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _news =
              data.map((json) => NotificationItemNews.fromJson(json)).toList();
          _isLoadingNews = false;
        });
      } else {
        setState(() {
          _newsError = 'Failed to load news (${response.statusCode})';
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _newsError = _getErrorMessage(e);
        _isLoadingNews = false;
      });
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);

    await Future.wait([
      _fetchMessages(),
      _fetchNews(),
    ]);

    if (mounted) {
      setState(() => _isRefreshing = false);
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Request timeout. Please check your connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'No internet connection';
    } else {
      return 'Error: ${error.toString()}';
    }
  }

  // ============================================================================
  // Detail Fetch & Popup
  // ============================================================================

  Future<void> _showMessageDetail(String id) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    // Loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http
          .get(ApiConfig.getMessageDetailUri(id))
          .timeout(ApiConfig.apiTimeout);

      if (!mounted) return;
      Navigator.of(context).pop(); // ปิด loading

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = NotificationItemMess.fromJson(data);
        _showDetailPopup(context, item);
      } else {
        _showError(languageProvider.translate(
          en: 'Failed to load message details',
          th: 'ไม่สามารถโหลดรายละเอียดข้อความได้',
        ));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError(languageProvider.translate(
        en: 'Error loading details',
        th: 'เกิดข้อผิดพลาดในการโหลดรายละเอียด',
      ));
    }
  }

  Future<void> _showNewsDetail(String id) async {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http
          .get(ApiConfig.getNewsDetailUri(id))
          .timeout(ApiConfig.apiTimeout);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final item = NotificationItemNews.fromJson(data);
        _showDetailPopup(context, item);
      } else {
        _showError(languageProvider.translate(
          en: 'Failed to load news details',
          th: 'ไม่สามารถโหลดรายละเอียดข่าวได้',
        ));
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      _showError(languageProvider.translate(
        en: 'Error loading details',
        th: 'เกิดข้อผิดพลาดในการโหลดรายละเอียด',
      ));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================================
  // Navigation
  // ============================================================================

  void _navigateToBanner(int index) {
    _bannerController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToContentType(int index) {
    _contentTypeController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // ============================================================================
  // Build UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _BannerCarousel(
              controller: _bannerController!,
              currentIndex: _currentBannerIndex,
              onPageChanged: (index) =>
                  setState(() => _currentBannerIndex = index),
            ),
            const SizedBox(height: 10),
            _BannerIndicators(
              count: NotificationData.bannerImages.length,
              currentIndex: _currentBannerIndex,
              onTap: _navigateToBanner,
            ),
            const SizedBox(height: 20),
            _ContentTypeTabs(
              currentType: _currentContentType,
              onTabChanged: _navigateToContentType,
            ),
            Divider(color: Theme.of(context).colorScheme.onSurface, height: 2),
            SizedBox(
              height: 280,
              child: PageView(
                controller: _contentTypeController,
                onPageChanged: (index) =>
                    setState(() => _currentContentType = index),
                children: [
                  _buildMessagesTab(),
                  _buildNewsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoadingMessages) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messagesError != null) {
      return _ErrorView(message: _messagesError!, onRetry: _fetchMessages);
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(languageProvider.translate(
          en: 'No messages available',
          th: 'ไม่มีข้อความ',
        )),
      );
    }

    return _ContentList(
      controller: _messageController!,
      items: _messages,
      onLearnMore: _showMessageDetail,
    );
  }

  Widget _buildNewsTab() {
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoadingNews) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_newsError != null) {
      return _ErrorView(message: _newsError!, onRetry: _fetchNews);
    }
    if (_news.isEmpty) {
      return Center(
        child: Text(languageProvider.translate(
          en: 'No news available',
          th: 'ไม่มีข่าว',
        )),
      );
    }

    return _ContentList(
      controller: _newsController!,
      items: _news,
      onLearnMore: _showNewsDetail,
    );
  }
}

// ============================================================================
// Error View
// ============================================================================

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text(
                languageProvider.translate(en: 'Retry', th: 'ลองอีกครั้ง')),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Detail Popup — แบบเดียวกับ HomePage ItemDetailsCard
// ============================================================================

void _showDetailPopup(BuildContext context, dynamic item) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _NotificationDetailCard(item: item);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, -1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOut;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
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
}

// ============================================================================
// Notification Detail Card — คล้าย HomePage ItemDetailsCard
// ============================================================================

class _NotificationDetailCard extends StatelessWidget {
  final dynamic item; // NotificationItemMess หรือ NotificationItemNews

  const _NotificationDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    // เทียบราคาเป็น double เหมือน HomePage
    final price = _parseDouble(item.price);
    final discountPrice = _parseDouble(item.discount_price);
    final hasDiscount = discountPrice > 0 && discountPrice < price;

    // discount_percent จาก API อาจมี "%" อยู่แล้ว ให้ clean
    final discountPercentRaw = item is NotificationItemMess
        ? (item as NotificationItemMess).discount_percent
        : '';
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
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: item.image_url,
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
                        item.clothing_name,
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
                        value: item.category,
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Size', th: 'ขนาด'),
                        value: item.size_category,
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Gender', th: 'เพศ'),
                        value: formatGender(item.gender, languageProvider),
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Stock', th: 'สต็อก'),
                        value: item.stock,
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Breed', th: 'สายพันธุ์'),
                        value: item.breed,
                      ),

                      // รายละเอียด
                      if (item.description.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
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
                              item.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // ราคา — เทียบเป็น double เหมือน HomePage
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ราคาเดิม (ขีดฆ่า)
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

                          // ราคาหลัง discount หรือราคาปกติ
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

                          // Badge % ลด
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

                      // ปุ่ม Add to Cart — แบบเดียวกับ HomePage
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
        itemBuilder: (context, index) {
          return Container(
            color: Theme.of(context).textTheme.bodyLarge?.color,
            child: CachedNetworkImage(
              imageUrl: NotificationData.bannerImages[index],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const Center(child: Icon(Icons.error)),
            ),
          );
        },
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
      children: List.generate(count, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: GestureDetector(
            onTap: () => onTap(index),
            child: Icon(
              currentIndex == index ? Icons.circle : Icons.circle_outlined,
              size: 15,
            ),
          ),
        );
      }),
    );
  }
}

// ============================================================================
// Content Type Tabs
// ============================================================================

class _ContentTypeTabs extends StatelessWidget {
  final int currentType;
  final ValueChanged<int> onTabChanged;

  const _ContentTypeTabs({
    required this.currentType,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TabButton(
          label: languageProvider.translate(en: "Message", th: "ข้อความ"),
          isSelected: currentType == 0,
          onTap: () => onTabChanged(0),
        ),
        _TabButton(
          label: languageProvider.translate(en: "News", th: "ข่าว"),
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

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
// Content List
// ============================================================================

class _ContentList extends StatelessWidget {
  final PageController controller;
  final List<dynamic> items;
  final Function(String) onLearnMore;

  const _ContentList({
    required this.controller,
    required this.items,
    required this.onLearnMore,
  });

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: controller,
      itemCount: items.length,
      scrollDirection: Axis.vertical,
      itemBuilder: (context, index) {
        return _ContentCard(
          item: items[index],
          onLearnMore: onLearnMore,
        );
      },
    );
  }
}

// ============================================================================
// Content Card
// ============================================================================

class _ContentCard extends StatelessWidget {
  final dynamic item;
  final Function(String) onLearnMore;

  const _ContentCard({required this.item, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          _ContentImage(imageUrl: item.image_url),
          const SizedBox(width: 10),
          Expanded(
            child: _ContentDetails(item: item, onLearnMore: onLearnMore),
          ),
        ],
      ),
    );
  }
}

class _ContentImage extends StatelessWidget {
  final String imageUrl;

  const _ContentImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 180,
        height: 180,
        placeholder: (context, url) => const CircularProgressIndicator.adaptive(
          backgroundColor: Colors.white,
          valueColor:
              AlwaysStoppedAnimation<Color>(Color.fromARGB(75, 50, 50, 50)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 180,
          height: 180,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error, size: 40),
        ),
      ),
    );
  }
}

class _ContentDetails extends StatelessWidget {
  final dynamic item;
  final Function(String) onLearnMore;

  const _ContentDetails({required this.item, required this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    // เทียบราคาเป็น double เหมือน HomePage
    final price = _parseDouble(item.price);
   final discountPrice = item is NotificationItemMess 
    ? _parseDouble((item as NotificationItemMess).discount_price)
    : 0.0;
    final hasDiscount = discountPrice > 0 && discountPrice < price;

    final isMessage = item is NotificationItemMess;

    // clean discount_percent
    final discountPercentRaw =
        isMessage ? (item as NotificationItemMess).discount_percent : '';
    final discountPercentClean = discountPercentRaw.replaceAll('%', '').trim();

    return Container(
      padding: const EdgeInsets.all(8),
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            isMessage ? '${item.clothing_name} ลดพิเศษ!' : item.clothing_name,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 8),

          // Date + Discount badge
          Row(
            children: [
              Text(
                _formatDate(item.create_at, context),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (hasDiscount && discountPercentClean.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

          // Action buttons
          _ActionButtons(
            itemId: item.id,
            onLearnMore: onLearnMore,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Action Buttons (Card)
// ============================================================================

class _ActionButtons extends StatefulWidget {
  final String itemId;
  final Function(String) onLearnMore;

  const _ActionButtons({
    required this.itemId,
    required this.onLearnMore,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _isAddingToCart = false;

  Future<void> _handleAddToCart() async {
    setState(() => _isAddingToCart = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isAddingToCart = false);

    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);

    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(
        message: languageProvider.translate(
          en: 'Added to cart!',
          th: 'เพิ่มลงตะกร้าแล้ว!',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FloatingActionButton.small(
          onPressed: _isAddingToCart ? null : _handleAddToCart,
          backgroundColor: _isAddingToCart
              ? Colors.grey
              : Theme.of(context).floatingActionButtonTheme.backgroundColor,
          child: _isAddingToCart
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
        ElevatedButton(
          onPressed: () => widget.onLearnMore(widget.itemId),
          child: Text(
            languageProvider.translate(
              en: 'Learn More',
              th: 'ดูเพิ่มเติม',
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Data Models
// ============================================================================

class NotificationItemMess {
  final String id;
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
  final String image_url;
  final String images;
  final String clothing_name;
  final String description;
  final String category;
  final String size_category;
  final String price;
  final String discount_price;  // เพิ่มบรรทัดนี้
  final String discount_percent; // เพิ่มบรรทัดนี้
  final String gender;
  final String clothing_like;
  final String clothing_seller;
  final String stock;
  final String breed;
  final String create_at;

  const NotificationItemNews({
    required this.id,
    required this.image_url,
    required this.images,
    required this.clothing_name,
    required this.description,
    required this.category,
    required this.size_category,
    required this.price,
    required this.discount_price,  // เพิ่มบรรทัดนี้
    required this.discount_percent, // เพิ่มบรรทัดนี้
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
// Helper Functions
// ============================================================================

String _formatDate(String dateString, BuildContext context) {
  if (dateString.isEmpty) return '';

  final languageProvider =
      Provider.of<LanguageProvider>(context, listen: false);

  try {
    DateTime dateTime;

    if (dateString.contains('T')) {
      dateTime = DateTime.parse(dateString);
    } else if (dateString.contains('-') && dateString.length >= 10) {
      dateTime = DateTime.parse(dateString.replaceAll(' ', 'T'));
    } else {
      return dateString;
    }

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return languageProvider.translate(en: 'Just now', th: 'เมื่อสักครู่');
    } else if (difference.inMinutes < 60) {
      return languageProvider.translate(
        en: '${difference.inMinutes} min ago',
        th: '${difference.inMinutes} นาทีที่แล้ว',
      );
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return languageProvider.translate(
        en: '$hours hour${hours > 1 ? 's' : ''} ago',
        th: '$hours ชั่วโมงที่แล้ว',
      );
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return languageProvider.translate(
        en: '$days day${days > 1 ? 's' : ''} ago',
        th: '$days วันที่แล้ว',
      );
    } else {
      return DateFormat('MMM dd, yyyy').format(dateTime);
    }
  } catch (e) {
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
