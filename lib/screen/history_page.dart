// lib/pages/history_page.dart
// หน้า History รวม 2 Tab:
//   - Tab 1: Order History (mock data เดิม)
//   - Tab 2: Cat Analysis History (ดึงจาก Backend)

import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_cat_api.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CatApiService _catApi = CatApiService();

  // ── Cat Analysis State ─────────────────────────────────────────────────────
  List<CatRecord> _cats = [];
  bool _isLoadingCats = true;
  String? _catError;

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
    _loadCats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Load Cat History ───────────────────────────────────────────────────────
  Future<void> _loadCats() async {
    setState(() {
      _isLoadingCats = true;
      _catError = null;
    });
    try {
      final cats = await _catApi.getUserCats();
      if (mounted) setState(() => _cats = cats);
    } catch (e) {
      if (mounted)
        setState(() => _catError = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoadingCats = false);
    }
  }

  // ── Delete Cat ─────────────────────────────────────────────────────────────
  Future<void> _deleteCat(CatRecord cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบ'),
        content: Text('ต้องการลบข้อมูลแมว "${cat.catColor}" ใช่หรือไม่?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await _catApi.deleteCat(cat.id);
      setState(() => _cats.removeWhere((c) => c.id == cat.id));
      _showSuccess('ลบข้อมูลแมวแล้ว');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Edit Cat ───────────────────────────────────────────────────────────────
  Future<void> _editCat(CatRecord cat) async {
    final colorCtrl = TextEditingController(text: cat.catColor);
    final breedCtrl = TextEditingController(text: cat.breed ?? '');
    final ageCtrl = TextEditingController(text: cat.age?.toString() ?? '');
    final weightCtrl =
        TextEditingController(text: cat.weight?.toString() ?? '');
    String selectedSize = cat.sizeCategory;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx2, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const Text('✏️ แก้ไขข้อมูลแมว',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(
                  labelText: 'สีแมว / Cat Color',
                  prefixIcon: Icon(Icons.color_lens_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: breedCtrl,
                decoration: const InputDecoration(
                  labelText: 'พันธุ์ / Breed',
                  prefixIcon: Icon(Icons.pets),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'อายุ (ปี)',
                      prefixIcon: Icon(Icons.cake_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: weightCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'น้ำหนัก (kg)',
                      prefixIcon: Icon(Icons.monitor_weight_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              const Text('ขนาด / Size',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                  final selected = selectedSize == size;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedSize = size),
                    child: Container(
                      width: 52,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.orange
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Text(size,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: selected
                                ? Colors.white
                                : Colors.black87,
                          )),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('บันทึก',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;

    try {
      final updateData = <String, dynamic>{
        'cat_color': colorCtrl.text.trim().isEmpty
            ? cat.catColor
            : colorCtrl.text.trim(),
        'size_category': selectedSize,
        if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
        if (ageCtrl.text.trim().isNotEmpty)
          'age': int.tryParse(ageCtrl.text.trim()),
        if (weightCtrl.text.trim().isNotEmpty)
          'weight': double.tryParse(weightCtrl.text.trim()),
      };

      final updated = await _catApi.updateCat(cat.id, updateData);
      setState(() {
        final index = _cats.indexWhere((c) => c.id == cat.id);
        if (index != -1) _cats[index] = updated;
      });
      _showSuccess('บันทึกข้อมูลแมวแล้ว ✅');
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

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
        // ── TabBar อยู่ใน bottom ของ AppBar ──────────────────────────────
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
              unselectedLabelStyle:
                  const TextStyle(fontSize: 13),
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
          // ── Tab 1: Orders ────────────────────────────────────────────────
          _buildOrdersTab(isDark),
          // ── Tab 2: Cat Analysis ──────────────────────────────────────────
          _buildCatTab(isDark),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 1 — ORDERS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrdersTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _orders.length,
      itemBuilder: (context, index) =>
          _buildOrderCard(_orders[index], isDark),
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
          // Header
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(order['date'],
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

          // Body
          Row(children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(order['image'],
                  color: Colors.grey[400], size: 30),
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
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 13)),
                  ]),
            ),
          ]),
          const SizedBox(height: 15),

          // Footer
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  child: Text(btnText,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13)),
                ),
              ]),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // TAB 2 — CAT ANALYSIS
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCatTab(bool isDark) {
    if (_isLoadingCats) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: Colors.orange),
          SizedBox(height: 16),
          Text('กำลังโหลดข้อมูล...', style: TextStyle(color: Colors.grey)),
        ]),
      );
    }

    if (_catError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_catError!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 15)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadCats,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ]),
        ),
      );
    }

    if (_cats.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.pets, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('ยังไม่มีประวัติการวัดขนาดแมว',
              style:
                  TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          Text('ถ่ายรูปแมวแล้ววิเคราะห์ได้เลย!',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCats,
      color: Colors.orange,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cats.length,
        itemBuilder: (context, index) =>
            _buildCatCard(_cats[index], isDark),
      ),
    );
  }

  Widget _buildCatCard(CatRecord cat, bool isDark) {
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
            // รูปแมว
            Container(
              width: 90,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: isDark
                    ? Colors.grey.shade800
                    : Colors.grey.shade200,
                border: Border.all(
                  color: isDark
                      ? Colors.grey.shade700
                      : Colors.grey.shade300,
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
                    : Icon(Icons.pets,
                        size: 36, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(width: 14),

            // ข้อมูล
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(cat.catColor,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
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
                    if (cat.breed != null)
                      _infoChip(Icons.pets, cat.breed!, isDark),
                    const SizedBox(height: 4),
                    Row(children: [
                      if (cat.age != null) ...[
                        _infoChip(Icons.cake_outlined,
                            '${cat.age} ปี', isDark),
                        const SizedBox(width: 8),
                      ],
                      _infoChip(
                        cat.gender == 1
                            ? Icons.male
                            : cat.gender == 2
                                ? Icons.female
                                : Icons.help_outline,
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    _conditionColor(cat.bodyCondition).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _conditionColor(cat.bodyCondition)
                      .withOpacity(0.3),
                ),
              ),
              child: Row(children: [
                Icon(Icons.favorite_border,
                    size: 16,
                    color: _conditionColor(cat.bodyCondition)),
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
                _measureChip('รอบอก',
                    '${cat.chestCm!.toStringAsFixed(1)} cm', isDark),
              if (cat.neckCm != null)
                _measureChip('รอบคอ',
                    '${cat.neckCm!.toStringAsFixed(1)} cm', isDark),
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
            Icon(Icons.access_time,
                size: 14, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                cat.detectedAt != null
                    ? _formatDate(cat.detectedAt!)
                    : 'ไม่ทราบวันที่',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade400),
              ),
            ),
            IconButton(
              onPressed: () => _editCat(cat),
              icon: Icon(Icons.edit_outlined,
                  color: Colors.blue.shade600, size: 22),
              tooltip: 'แก้ไข',
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => _deleteCat(cat),
              icon: Icon(Icons.delete_outline,
                  color: Colors.red.shade500, size: 22),
              tooltip: 'ลบ',
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
              color: isDark
                  ? Colors.grey.shade300
                  : Colors.grey.shade600)),
    ]);
  }

  Widget _measureChip(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? Colors.grey.shade300
                  : Colors.grey.shade700)),
    );
  }
}