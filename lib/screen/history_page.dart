// lib/pages/history_page.dart
// หน้า History รวม 2 Tab:
//   - Tab 1: Order History (mock data เดิม)
//   - Tab 2: Cat Analysis History (ใช้ CatHistoryBloc)

import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/language_provider.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/api/service_cat_api.dart';
import 'package:flutter_application_1/blocs/cat_history/history_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Mock Orders ────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _orders = [
    {
      "id": "ORD-2567-001",
      "date": "28 Jan 2024, 10:30 AM",
      "status": "Shipping",
      "items": "Cat Hoodie (Blue) x 1",
      "total": "฿350",
      "image": Icons.checkroom,
    },
    {
      "id": "ORD-2567-002",
      "date": "15 Jan 2024, 14:20 PM",
      "status": "Completed",
      "items": "Cute Bowtie (Red) x 2",
      "total": "฿120",
      "image": Icons.pets,
    },
    {
      "id": "ORD-2566-099",
      "date": "20 Dec 2023, 09:15 AM",
      "status": "Cancelled",
      "items": "Summer Shirt (S) x 1",
      "total": "฿200",
      "image": Icons.shopping_bag,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }



  // ── Delete Confirm ─────────────────────────────────────────────────────────
  Future<void> _deleteCat(BuildContext context, CatRecord cat) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบข้อมูลแมว "${cat.breed}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child:
                const Text('ลบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    if (!context.mounted) return;
    context.read<CatHistoryBloc>().add(CatHistoryDeleteRequested(cat));
  }

  Future<void> _detailCat(BuildContext context, CatRecord cat) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle bar ──────────────────────────────────────────
               const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: isDark ? Colors.white : Colors.black87,
                        size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 32), // balance spacing
                ],
              ),
              const SizedBox(height: 16),
              // ── Image + Title ────────────────────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: cat.imageCat != null
                      ? Image.network(cat.imageCat!,
                          width: 90,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _placeholderIcon(isDark))
                      : _placeholderIcon(isDark),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.breed?.isNotEmpty == true
                            ? cat.breed!
                            : cat.catColor,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(cat.catColor,
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade500)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('Size ${cat.sizeCategory}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ]),

              const SizedBox(height: 24),
              _sectionTitle('ข้อมูลพื้นฐาน', isDark),
              const SizedBox(height: 10),

              // ── Basic Info Grid ──────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _detailTile(Icons.cake_outlined, 'อายุ',
                      cat.age != null ? '${cat.age} ปี' : '-', isDark),
                  _detailTile(cat.gender == 1 ? Icons.male : Icons.female,
                      'เพศ', _genderText(cat.gender), isDark),
                  _detailTile(
                      Icons.monitor_weight_outlined,
                      'น้ำหนัก',
                      cat.weight != null
                          ? '${cat.weight!.toStringAsFixed(1)} kg'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.straighten,
                      'BMI',
                      cat.bmi != null ? cat.bmi!.toStringAsFixed(1) : '-',
                      isDark),
                ],
              ),

              const SizedBox(height: 20),
              _sectionTitle('การวัดขนาด', isDark),
              const SizedBox(height: 10),

              // ── Measurements ─────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _detailTile(
                      Icons.radio_button_unchecked,
                      'รอบอก',
                      cat.chestCm != null
                          ? '${cat.chestCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.radio_button_unchecked,
                      'รอบคอ',
                      cat.neckCm != null
                          ? '${cat.neckCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.straighten,
                      'ยาวตัว',
                      cat.bodyLengthCm != null
                          ? '${cat.bodyLengthCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.straighten,
                      'ยาวหลัง',
                      cat.backLengthCm != null
                          ? '${cat.backLengthCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.radio_button_unchecked,
                      'รอบเอว',
                      cat.waistCm != null
                          ? '${cat.waistCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                  _detailTile(
                      Icons.straighten,
                      'ยาวขา',
                      cat.legLengthCm != null
                          ? '${cat.legLengthCm!.toStringAsFixed(1)} cm'
                          : '-',
                      isDark),
                ],
              ),

              const SizedBox(height: 20),
              _sectionTitle('สุขภาพ', isDark),
              const SizedBox(height: 10),

              // ── Body Condition ────────────────────────────────────────
              if (cat.bodyCondition != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _conditionColor(cat.bodyCondition).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          _conditionColor(cat.bodyCondition).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.favorite,
                            size: 16,
                            color: _conditionColor(cat.bodyCondition)),
                        const SizedBox(width: 6),
                        Text('BCS ${cat.bodyConditionScore ?? "-"}/9',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _conditionColor(cat.bodyCondition),
                            )),
                      ]),
                      const SizedBox(height: 6),
                      Text(
                        cat.bodyConditionDescription ?? cat.bodyCondition!,
                        style: TextStyle(
                          fontSize: 13,
                          color: _conditionColor(cat.bodyCondition),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              _sectionTitle('ข้อมูลเพิ่มเติม', isDark),
              const SizedBox(height: 10),

              // ── Meta Info ─────────────────────────────────────────────
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _detailTile(Icons.accessibility_new, 'ท่าทาง',
                      cat.posture ?? '-', isDark),
                  _detailTile(Icons.verified, 'คุณภาพภาพ',
                      cat.qualityFlag ?? '-', isDark),
                  _detailTile(
                      Icons.bar_chart,
                      'ความแม่นยำ',
                      cat.confidence != null
                          ? '${(cat.confidence! * 100).toStringAsFixed(0)}%'
                          : '-',
                      isDark),
                  _detailTile(Icons.category, 'ช่วงวัย', cat.ageCategory ?? '-',
                      isDark),
                ],
              ),

              const SizedBox(height: 16),

              // ── Date ─────────────────────────────────────────────────
              Row(children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
                const SizedBox(width: 6),
                Text(
                  cat.detectedAt != null
                      ? _formatDate(cat.detectedAt!)
                      : 'ไม่ทราบวันที่',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

// ── Detail helper widgets ──────────────────────────────────────────────────
  Widget _placeholderIcon(bool isDark) {
    return Container(
      width: 90,
      height: 100,
      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Icon(Icons.pets, size: 36, color: Colors.grey.shade400),
    );
  }

  Widget _sectionTitle(String title, bool isDark) {
    return Text(title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black54,
        ));
  }

  Widget _detailTile(IconData icon, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(icon, size: 14, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text(value,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _genderText(int g) {
    switch (g) {
      case 1:
        return '♂ ผู้';
      case 2:
        return '♀ เมีย';
      default:
        return '? ไม่ทราบ';
    }
  }

  Color _conditionColor(String? c) {
    switch (c) {
      case 'ideal':
        return Colors.green;
      case 'overweight':
        return Colors.red;
      case 'underweight':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dt) =>
      '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => CatHistoryBloc()..add(const CatHistoryLoadRequested()),
      child: Builder(builder: (blocCtx) {
        return Scaffold(
          backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
          appBar: AppBar(
            centerTitle: true,
            backgroundColor: isDark ? Colors.black : Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new,
                  color: isDark ? Colors.white : Colors.black87, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'History',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor:
                      isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  unselectedLabelStyle: const TextStyle(fontSize: 13),
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 16),
                          SizedBox(width: 6),
                          Text('Orders'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.pets, size: 16),
                          SizedBox(width: 6),
                          Text('Analysis Cat'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // ── Tab 1: Orders (ไม่เปลี่ยนแปลง) ──────────────────────────
              _buildOrdersTab(isDark),
              // ── Tab 2: Cat Analysis (BLoC) ────────────────────────────────
              _buildCatTab(blocCtx, isDark),
            ],
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — ORDERS (เหมือนเดิมทุกอย่าง)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _orders.length,
      itemBuilder: (context, index) => _buildOrderCard(_orders[index], isDark),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    Color statusColor;
    String btnText;
    Color btnColor;

    switch (order['status']) {
      case 'Shipping':
        statusColor = Colors.orange;
        btnText = 'Track Order';
        btnColor = Colors.black87;
        break;
      case 'Completed':
        statusColor = Colors.green;
        btnText = 'Rate & Review';
        btnColor = Colors.blue;
        break;
      case 'Cancelled':
        statusColor = Colors.red;
        btnText = 'Buy Again';
        btnColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
        btnText = 'View Details';
        btnColor = Colors.black;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(order['date'],
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(order['status'],
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ]),
          const Divider(height: 25),
          Row(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(order['image'], color: Colors.grey[400], size: 30),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order['items'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 5),
                    Text('Order ID: ${order['id']}',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ]),
            ),
          ]),
          const SizedBox(height: 15),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Payment',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(order['total'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ]),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              child: Text(btnText,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ]),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — CAT ANALYSIS (BLoC)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCatTab(BuildContext blocCtx, bool isDark) {
    return BlocConsumer<CatHistoryBloc, CatHistoryState>(
      // ── Listener: แสดง SnackBar ──────────────────────────────────────────
      listener: (ctx, state) {
        if (state is CatHistoryActionSuccess) {
          final languageProvider =
              Provider.of<LanguageProvider>(ctx, listen: false);
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Saved successfully!',
                th: 'บันทึกสำเร็จแล้ว!',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        } else if (state is CatHistoryActionFailure) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.error(
              message: state.message,
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      },
      // ── Builder: UI ────────────────────────────────────────────────────────
      builder: (ctx, state) {
        // Loading ครั้งแรก
        if (state is CatHistoryInitial || state is CatHistoryLoading) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CircularProgressIndicator(color: Colors.black),
              SizedBox(height: 16),
              Text('กำลังโหลดข้อมูล...', style: TextStyle(color: Colors.grey)),
            ]),
          );
        }

        // โหลดล้มเหลว
        if (state is CatHistoryFailure) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(state.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red, fontSize: 15)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => ctx
                      .read<CatHistoryBloc>()
                      .add(const CatHistoryLoadRequested()),
                  icon: const Icon(Icons.refresh),
                  label: const Text('ลองใหม่'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
              ]),
            ),
          );
        }

        // ดึง cats จาก state ที่มี list (Loaded / ActionInProgress / ActionSuccess / ActionFailure)
        final cats = _catsFromState(state);
        final isProcessing = state is CatHistoryActionInProgress;

        if (cats.isEmpty) {
          return Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('ยังไม่มีประวัติการวัดขนาดแมว',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
              const SizedBox(height: 8),
              Text('ถ่ายรูปแมวแล้ววิเคราะห์ได้เลย!',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
            ]),
          );
        }

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async => ctx
                  .read<CatHistoryBloc>()
                  .add(const CatHistoryLoadRequested()),
              color: isDark ? Colors.black : Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: cats.length,
                itemBuilder: (_, index) =>
                    _buildCatCard(ctx, cats[index], isDark),
              ),
            ),
            // overlay ขณะ delete/update
            if (isProcessing)
              Container(
                color: Colors.black.withOpacity(0.15),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              ),
          ],
        );
      },
    );
  }

  List<CatRecord> _catsFromState(CatHistoryState state) {
    if (state is CatHistoryLoaded) return state.cats;
    if (state is CatHistoryActionInProgress) return state.cats;
    if (state is CatHistoryActionSuccess) return state.cats;
    if (state is CatHistoryActionFailure) return state.cats;
    return [];
  }

  Widget _buildCatCard(BuildContext blocCtx, CatRecord cat, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 90,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                border: Border.all(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: cat.imageCat != null
                    ? Image.network(cat.imageCat!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.pets,
                            size: 36, color: Colors.grey.shade400))
                    : Icon(Icons.pets, size: 36, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                            cat.breed?.isNotEmpty == true
                                ? cat.breed!
                                : cat.catColor,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(cat.sizeCategory,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    _infoChip(Icons.color_lens_outlined, cat.catColor, isDark),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (cat.age != null) ...[
                        _infoChip(Icons.cake_outlined, '${cat.age} ปี', isDark),
                        const SizedBox(width: 8),
                      ],
                      _infoChip(
                        cat.gender == 1
                            ? Icons.male
                            : cat.gender == 2
                                ? Icons.female
                                : Icons.poll_outlined,
                        _genderText(cat.gender),
                        isDark,
                      ),
                    ]),
                    const SizedBox(height: 4),
                    if (cat.weight != null)
                      _infoChip(Icons.monitor_weight_outlined,
                          '${cat.weight!.toStringAsFixed(1)} kg', isDark),
                  ]),
            ),
          ]),
        ),

        // ── Body Condition ───────────────────────────────────────────────
        if (cat.bodyCondition != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _conditionColor(cat.bodyCondition).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _conditionColor(cat.bodyCondition).withOpacity(0.3),
                ),
              ),
              child: Row(children: [
                Icon(Icons.favorite_border,
                    size: 16, color: _conditionColor(cat.bodyCondition)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.bodyConditionDescription ?? cat.bodyCondition!,
                    style: TextStyle(
                        fontSize: 12,
                        color: _conditionColor(cat.bodyCondition)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cat.bodyConditionScore != null)
                  Text('BCS ${cat.bodyConditionScore}/9',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _conditionColor(cat.bodyCondition))),
              ]),
            ),
          ),

        // ── Measurements ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (cat.chestCm != null)
                _measureChip(
                    'รอบอก', '${cat.chestCm!.toStringAsFixed(1)} cm', isDark),
              if (cat.neckCm != null)
                _measureChip(
                    'รอบคอ', '${cat.neckCm!.toStringAsFixed(1)} cm', isDark),
              if (cat.bodyLengthCm != null)
                _measureChip('ยาวตัว',
                    '${cat.bodyLengthCm!.toStringAsFixed(1)} cm', isDark),
              if (cat.bmi != null)
                _measureChip('BMI', cat.bmi!.toStringAsFixed(1), isDark),
            ],
          ),
        ),

        // ── Footer: วันที่ + ปุ่ม ─────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
          child: Row(children: [
            Icon(Icons.access_time, size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                cat.detectedAt != null
                    ? _formatDate(cat.detectedAt!)
                    : 'ไม่ทราบวันที่',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
           
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _deleteCat(blocCtx, cat),
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade500, size: 22),
              tooltip: 'ลบ',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _detailCat(blocCtx, cat),
              icon: Icon(Icons.density_medium_sharp,
                  color: const Color.fromARGB(255, 9, 9, 9), size: 22),
              tooltip: 'รายระเอียด',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Chip Widgets ───────────────────────────────────────────────────────────
  Widget _infoChip(IconData icon, String text, bool isDark) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: Colors.grey.shade500),
      const SizedBox(width: 4),
      Text(text,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade600)),
    ]);
  }

  Widget _measureChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700)),
    );
  }
}
