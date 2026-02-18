import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class BasketPage extends StatefulWidget {
  const BasketPage({super.key});

  @override
  State<BasketPage> createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  // ✅ ลบ _userId ออก — ใช้ Firebase UID ผ่าน service โดยตรง

  final BasketApiService _basketApi = BasketApiService();

  List<BasketItem> _basketItems = [];
  BasketSummary? _summary;
  bool _isLoading = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadBasket();
  }

  // ============================================================================
  // Load Basket
  // ============================================================================

  Future<void> _loadBasket() async {
    setState(() => _isLoading = true);

    try {
      // ✅ ไม่ต้องส่ง userId
      final result = await _basketApi.getBasket();
      setState(() {
        _basketItems = result['items'];
        _summary = result['summary'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Failed to load basket: $e',
          ),
        );
      }
    }
  }

  // ============================================================================
  // Update Quantity
  // ============================================================================

  Future<void> _updateQuantity(String clothingUuid, int newQuantity) async {
    try {
      // ✅ ไม่ต้องส่ง userId
      await _basketApi.updateQuantity(
        clothingUuid: clothingUuid,
        quantity: newQuantity,
      );

      await _loadBasket();

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: 'Quantity updated',
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Failed to update: $e',
          ),
        );
      }
    }
  }

  // ============================================================================
  // Remove Item
  // ============================================================================

  Future<void> _removeItem(String clothingUuid) async {
    setState(() => _isDeleting = true);

    try {
      // ✅ ไม่ต้องส่ง userId
      await _basketApi.removeFromBasket(
        clothingUuid: clothingUuid,
      );

      await _loadBasket();

      setState(() => _isDeleting = false);

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: 'Item removed from basket',
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Failed to remove: $e',
          ),
        );
      }
    }
  }

  // ============================================================================
  // Clear Basket
  // ============================================================================

  Future<void> _clearBasket() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('Clear Basket?'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeleting = true);

    try {
      // ✅ ไม่ต้องส่ง userId
      await _basketApi.clearBasket();

      await _loadBasket();

      setState(() => _isDeleting = false);

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          const CustomSnackBar.success(
            message: 'Basket cleared',
          ),
        );
      }
    } catch (e) {
      setState(() => _isDeleting = false);
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: 'Failed to clear basket: $e',
          ),
        );
      }
    }
  }

  // ============================================================================
  // Build UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          languageProvider.translate(en: 'BASKET', th: 'ตะกร้า'),
          style: TextStyle(
            fontFamily: "catFont",
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
        actions: [
          if (_basketItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _isDeleting ? null : _clearBasket,
              tooltip: languageProvider.translate(
                en: 'Clear All',
                th: 'ล้างทั้งหมด',
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _basketItems.isEmpty
              ? _buildEmptyState(isDark, languageProvider)
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _basketItems.length,
                        itemBuilder: (context, index) {
                          final item = _basketItems[index];
                          return _BasketItemCard(
                            item: item,
                            onQuantityChanged: (newQuantity) {
                              _updateQuantity(item.clothingUuid, newQuantity);
                            },
                            onRemove: () {
                              _removeItem(item.clothingUuid);
                            },
                            isDeleting: _isDeleting,
                            languageProvider: languageProvider,
                          );
                        },
                      ),
                    ),
                    if (_summary != null)
                      _buildSummarySection(isDark, languageProvider),
                  ],
                ),
    );
  }

  // ============================================================================
  // Empty State
  // ============================================================================

  Widget _buildEmptyState(bool isDark, LanguageProvider languageProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 100,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 20),
          Text(
            languageProvider.translate(
              en: 'Your basket is empty',
              th: 'ตะกร้าของคุณว่างอยู่',
            ),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            languageProvider.translate(
              en: 'Start shopping to add items!',
              th: 'เริ่มช้อปปิ้งเพื่อเพิ่มสินค้า!',
            ),
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // Summary Section
  // ============================================================================

  Widget _buildSummarySection(bool isDark, LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate(
                    en: 'Total Items:',
                    th: 'จำนวนสินค้า:',
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${_summary!.totalItems}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate(
                    en: 'Total Quantity:',
                    th: 'จำนวนชิ้นทั้งหมด:',
                  ),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${_summary!.totalQuantity}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate(
                    en: 'Total Price:',
                    th: 'ราคารวม:',
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '฿${_summary!.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.greenAccent : Colors.green[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.info(
                      message: languageProvider.translate(
                        en: 'Checkout feature coming soon!',
                        th: 'ฟีเจอร์ชำระเงินเร็วๆ นี้!',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  languageProvider.translate(
                    en: 'Proceed to Checkout',
                    th: 'ดำเนินการชำระเงิน',
                  ),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Basket Item Card Widget
// ============================================================================

class _BasketItemCard extends StatelessWidget {
  final BasketItem item;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final bool isDeleting;
  final LanguageProvider languageProvider;

  const _BasketItemCard({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.isDeleting,
    required this.languageProvider,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discountPrice != null &&
        item.discountPrice! > 0 &&
        item.discountPrice! < item.price;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[900] : Colors.white,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 100,
                height: 120,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.error),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clothingName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sizeCategory} • ${_formatGender(item.gender)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (hasDiscount)
                        Text(
                          '฿${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 14,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 6),
                      Text(
                        hasDiscount
                            ? '฿${item.discountPrice!.toStringAsFixed(0)}'
                            : '฿${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: hasDiscount ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 28,
                        onPressed: isDeleting
                            ? null
                            : () {
                                if (item.quantity > 1) {
                                  onQuantityChanged(item.quantity - 1);
                                }
                              },
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 28,
                        onPressed: isDeleting
                            ? null
                            : () {
                                if (item.quantity < item.stock &&
                                    item.quantity < 8) {
                                  onQuantityChanged(item.quantity + 1);
                                } else if (item.quantity >= 8) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDark ? Colors.black : Colors.white,
                                      title: Text('จำกัดจำนวน'),
                                      content: Text(
                                          'สามารถซื้อสินค้าได้สูงสุด 8 ชิ้นต่อรายการ'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('โอเค'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 28,
                        onPressed: isDeleting ? null : onRemove,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  Text(
                    '${languageProvider.translate(en: "Subtotal", th: "รวม")}: ฿${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.greenAccent : Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatGender(int gender) {
    switch (gender) {
      case 0:
        return languageProvider.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
      case 1:
        return languageProvider.translate(en: 'Male', th: 'เพศผู้');
      case 2:
        return languageProvider.translate(en: 'Female', th: 'เพศเมีย');
      case 3:
        return languageProvider.translate(en: 'Kitten', th: 'ลูกแมว');
      default:
        return languageProvider.translate(en: 'Unknown', th: 'ไม่ระบุ');
    }
  }
}
