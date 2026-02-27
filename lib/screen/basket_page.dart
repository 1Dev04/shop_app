import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_basket/basket_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// ── SnackBar helper ────────────────────────────────────────────────────────
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
// BasketPage
// ════════════════════════════════════════════════════════════════════════════

class BasketPage extends StatelessWidget {
  const BasketPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BasketBloc()..add(const BasketLoadRequested()),
      child: const _BasketView(),
    );
  }
}

class _BasketView extends StatelessWidget {
  const _BasketView();

  // ── Confirm Clear Dialog ──────────────────────────────────────────────────
  Future<bool?> _confirmClear(BuildContext context, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: const Text('Clear Basket?'),
        content: const Text('Are you sure you want to remove all items?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return BlocConsumer<BasketBloc, BasketState>(
      listener: (ctx, state) {
        if (state is BasketFailure) {
          final raw = state.message;
          final msg = raw.startsWith('load_failed:')
              ? languageProvider.translate(
                  en: 'Failed to load Basket: ${raw.replaceFirst('load_failed:', '')}',
                  th: 'โหลดตะกร้าไม่สำเร็จ: ${raw.replaceFirst('load_failed:', '')}')
              : raw;
          _showTopSnack(ctx, message: msg, type: _SnackType.error);
        } else if (state is BasketActionSuccess) {
          final msg = switch (state.actionType) {
            BasketActionType.updateQuantity => languageProvider.translate(
                en: 'Quantity updated successfully!',
                th: 'ปรับปรุงจำนวนสินค้าสำเร็จ!'),
            BasketActionType.removeItem => languageProvider.translate(
                en: 'Item removed from Basket!',
                th: 'ลบสินค้าออกจากตะกร้าแล้ว!'),
            BasketActionType.clearBasket => languageProvider.translate(
                en: 'Basket cleared successfully!',
                th: 'ล้างตะกร้าสำเร็จ!'),
          };
          _showTopSnack(ctx, message: msg, type: _SnackType.success);
        } else if (state is BasketActionFailure) {
          final raw = state.message;
          final display = raw.startsWith('quantity_failed:')
              ? languageProvider.translate(
                  en: 'Failed to update quantity: ${raw.replaceFirst('quantity_failed:', '')}',
                  th: 'ปรับปรุงจำนวนสินค้าไม่สำเร็จ')
              : raw.startsWith('remove_failed:')
                  ? languageProvider.translate(
                      en: 'Failed to remove item: ${raw.replaceFirst('remove_failed:', '')}',
                      th: 'ลบสินค้าออกจากตะกร้าไม่สำเร็จ')
                  : languageProvider.translate(
                      en: 'Failed to clear Basket: ${raw.replaceFirst('clear_failed:', '')}',
                      th: 'ล้างตะกร้าไม่สำเร็จ');
          _showTopSnack(ctx, message: display, type: _SnackType.error);
        }
      },
      builder: (ctx, state) {
        final items = _itemsFromState(state);
        final summary = _summaryFromState(state);
        final isLoading =
            state is BasketInitial || state is BasketLoading;
        final isProcessing = state is BasketActionInProgress;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: isDark ? Colors.white : Colors.black87, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
              if (items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final confirmed =
                              await _confirmClear(ctx, isDark);
                          if (confirmed == true) {
                            ctx
                                .read<BasketBloc>()
                                .add(const BasketClearRequested());
                          }
                        },
                  tooltip: languageProvider.translate(
                    en: 'Clear All',
                    th: 'ล้างทั้งหมด',
                  ),
                ),
            ],
          ),
          body: Stack(
            children: [
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (items.isEmpty)
                _buildEmptyState(isDark, languageProvider)
              else
                Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async => ctx
                            .read<BasketBloc>()
                            .add(const BasketLoadRequested()),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _BasketItemCard(
                              item: item,
                              isProcessing: isProcessing,
                              languageProvider: languageProvider,
                              onQuantityChanged: (newQty) {
                                ctx.read<BasketBloc>().add(
                                      BasketQuantityUpdateRequested(
                                        clothingUuid: item.clothingUuid,
                                        newQuantity: newQty,
                                      ),
                                    );
                              },
                              onRemove: () {
                                ctx.read<BasketBloc>().add(
                                      BasketItemRemoveRequested(
                                          item.clothingUuid),
                                    );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    if (summary != null)
                      _buildSummarySection(
                          ctx, isDark, languageProvider, summary),
                  ],
                ),
              // overlay ขณะ action
              if (isProcessing)
                Container(
                  color: Colors.black.withOpacity(0.15),
                  child: const Center(
                    child: CircularProgressIndicator(color: Colors.blue),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<BasketItem> _itemsFromState(BasketState state) {
    if (state is BasketLoaded) return state.items;
    if (state is BasketActionInProgress) return state.items;
    if (state is BasketActionSuccess) return state.items;
    if (state is BasketActionFailure) return state.items;
    return [];
  }

  BasketSummary? _summaryFromState(BasketState state) {
    if (state is BasketLoaded) return state.summary;
    if (state is BasketActionInProgress) return state.summary;
    if (state is BasketActionSuccess) return state.summary;
    if (state is BasketActionFailure) return state.summary;
    return null;
  }

  // ── Empty State (เหมือนเดิม) ───────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark, LanguageProvider languageProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets_rounded,
              size: 100,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
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

  // ── Summary Section (เหมือนเดิม) ──────────────────────────────────────────
  Widget _buildSummarySection(
    BuildContext context,
    bool isDark,
    LanguageProvider languageProvider,
    BasketSummary summary,
  ) {
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
                      en: 'Total Items:', th: 'จำนวนสินค้า:'),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${summary.totalItems}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate(
                      en: 'Total Quantity:', th: 'จำนวนชิ้นทั้งหมด:'),
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  '${summary.totalQuantity}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  languageProvider.translate(
                      en: 'Total Price:', th: 'ราคารวม:'),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  '฿${summary.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark ? Colors.greenAccent : Colors.green[700],
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
                  _showTopSnack(
                    context,
                    message: languageProvider.translate(
                      en: 'Checkout feature coming soon!',
                      th: 'ฟีเจอร์ชำระเงินเร็วๆ นี้!',
                    ),
                    type: _SnackType.info,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? Colors.blue[700] : Colors.blue,
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
                      fontSize: 18, fontWeight: FontWeight.bold),
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
// Basket Item Card Widget (เหมือนเดิมทุกอย่าง เปลี่ยน isDeleting → isProcessing)
// ============================================================================

class _BasketItemCard extends StatelessWidget {
  final BasketItem item;
  final bool isProcessing;
  final LanguageProvider languageProvider;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _BasketItemCard({
    required this.item,
    required this.isProcessing,
    required this.languageProvider,
    required this.onQuantityChanged,
    required this.onRemove,
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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.sizeCategory} • ${_formatGender(item.gender)}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
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
                      // ปุ่ม -
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 28,
                        onPressed: isProcessing
                            ? null
                            : () {
                                if (item.quantity > 1) {
                                  onQuantityChanged(item.quantity - 1);
                                }
                              },
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      // แสดงจำนวน
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantity}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      // ปุ่ม +
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 28,
                        onPressed: isProcessing
                            ? null
                            : () {
                                if (item.quantity < item.stock &&
                                    item.quantity < 8) {
                                  onQuantityChanged(item.quantity + 1);
                                } else if (item.quantity >= 8) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      title: const Text('จำกัดจำนวน'),
                                      content: const Text(
                                          'สามารถซื้อสินค้าได้สูงสุด 8 ชิ้นต่อรายการ'),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('โอเค'),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                              },
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const Spacer(),
                      // ปุ่มลบ
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        iconSize: 28,
                        onPressed: isProcessing ? null : onRemove,
                        color: Colors.red,
                      ),
                    ],
                  ),
                  Text(
                    '${languageProvider.translate(en: "Subtotal", th: "รวม")}: ฿${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.greenAccent : Colors.green[700],
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