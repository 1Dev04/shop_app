import 'package:flutter/material.dart';

import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/api/service_recom_api.dart';
import 'package:flutter_application_1/blocs/cat_analysis/analysis_bloc.dart';
import 'package:flutter_application_1/blocs/cat_detect/detect_bloc.dart';
import 'package:flutter_application_1/blocs/cat_item_detail/item_detail_bloc.dart';
import 'package:flutter_application_1/components/controll_btn.dart';
import 'package:flutter_application_1/components/home_page.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/basket_page.dart';
import 'package:flutter_application_1/screen/history_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Camera Overlay Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _RectHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rw = size.width * 0.80;
    final rh = size.height * 0.55;
    final left = (size.width - rw) / 2;
    final top = (size.height - rh) / 2;

    final rrect = RRect.fromLTRBR(
        left, top, left + rw, top + rh, const Radius.circular(20));

    canvas.drawPath(
      Path.combine(
          PathOperation.difference,
          Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
          Path()..addRRect(rrect)),
      Paint()..color = Colors.black.withOpacity(0.55),
    );
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity(0.5));

    final acc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    const cL = 28.0, r = 20.0;
    canvas.drawLine(Offset(left + r, top), Offset(left + r + cL, top), acc);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + cL), acc);
    canvas.drawLine(
        Offset(left + rw - r, top), Offset(left + rw - r - cL, top), acc);
    canvas.drawLine(
        Offset(left + rw, top + r), Offset(left + rw, top + r + cL), acc);
    canvas.drawLine(
        Offset(left + r, top + rh), Offset(left + r + cL, top + rh), acc);
    canvas.drawLine(
        Offset(left, top + rh - r), Offset(left, top + rh - r - cL), acc);
    canvas.drawLine(Offset(left + rw - r, top + rh),
        Offset(left + rw - r - cL, top + rh), acc);
    canvas.drawLine(Offset(left + rw, top + rh - r),
        Offset(left + rw, top + rh - r - cL), acc);
  }

  @override
  bool shouldRepaint(covariant _RectHolePainter _) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - CatData Model
// ═══════════════════════════════════════════════════════════════════════════════

class CatData {
  final String name;
  final String? breed;
  final int? age;
  final double weight;
  final String sizeCategory;
  final double chestCm;
  final double? neckCm;
  final double? bodyLengthCm;
  final double confidence;
  final List<double> boundingBox;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime detectedAt;
  final int? dbId;

  CatData({
    required this.name,
    this.breed,
    this.age,
    required this.weight,
    required this.sizeCategory,
    required this.chestCm,
    this.neckCm,
    this.bodyLengthCm,
    required this.confidence,
    required this.boundingBox,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.detectedAt,
    this.dbId,
  });

  factory CatData.fromJson(Map<String, dynamic> j) => CatData(
        name: j['cat_color'] ?? j['name'] ?? 'Unknown',
        breed: j['breed'],
        age: j['age'] is num ? (j['age'] as num).toInt() : null,
        weight: j['weight'] != null ? (j['weight'] as num).toDouble() : 0.0,
        sizeCategory: j['size_category'] ?? 'M',
        chestCm:
            j['chest_cm'] != null ? (j['chest_cm'] as num).toDouble() : 0.0,
        neckCm: j['neck_cm'] != null ? (j['neck_cm'] as num).toDouble() : null,
        bodyLengthCm: j['body_length_cm'] != null
            ? (j['body_length_cm'] as num).toDouble()
            : null,
        confidence:
            j['confidence'] != null ? (j['confidence'] as num).toDouble() : 0.0,
        boundingBox: j['bounding_box'] != null
            ? List<double>.from(
                (j['bounding_box'] as List).map((e) => (e as num).toDouble()))
            : [0, 0, 1, 1],
        imageUrl: j['image_cat'] ?? j['image_clothing'] ?? j['image_url'] ?? '',
        thumbnailUrl: j['thumbnail_url'],
        detectedAt: j['detected_at'] != null
            ? DateTime.tryParse(j['detected_at'].toString()) ?? DateTime.now()
            : DateTime.now(),
        dbId: j['db_id'] is num
            ? (j['db_id'] as num).toInt()
            : j['id'] is num
                ? (j['id'] as num).toInt()
                : null,
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Widget Entry Point
// ═══════════════════════════════════════════════════════════════════════════════

class MeasureSizeCat extends StatelessWidget {
  final int? preloadCatId; // ✅ เพิ่ม
  const MeasureSizeCat({super.key, this.preloadCatId});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CatAnalysisBloc()),
          BlocProvider(create: (_) => DetectCatBloc()),
        ],
        child: _MeasureSizeCatView(preloadCatId: preloadCatId),
      );
}

class _MeasureSizeCatView extends StatefulWidget {
  final int? preloadCatId;
  const _MeasureSizeCatView({this.preloadCatId});

  @override
  State<_MeasureSizeCatView> createState() => _MeasureSizeCatState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - State
// ═══════════════════════════════════════════════════════════════════════════════

class _MeasureSizeCatState extends State<_MeasureSizeCatView> {
  final _picker = ImagePicker();
  final _favouriteApi = FavouriteApiService();
  final _recomApi = RecommendApiService();

  bool _isCapturing = false;
  bool _isDisposed = false;
  CameraController? _cameraCtrl;

  File? _pendingFile;
  VoidCallback? _detectCleanup;

  List<RecommendItem> _recomItems = [];
  CatSummary? _recomCat;
  Pagination? _recomPagination;
  bool _recomLoading = false;
  bool _recomLoadingMore = false;

  static const bool _useMock = false;

  @override
  void initState() {
    super.initState();
    if (widget.preloadCatId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _preloadFromHistory(widget.preloadCatId!);
      });
    } else if (!_useMock) {
      _initCamera(); // เดิม
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraCtrl?.dispose();
    _cameraCtrl = null;
    super.dispose();
  }

  // ─── Camera ────────────────────────────────────────────────────────────────

  void _initCamera() async {
    if (!mounted || _isDisposed) return;
    try {
      final cams = await availableCameras();
      if (!mounted || _isDisposed) return;
      final back = cams.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cams.first,
      );
      await _cameraCtrl?.dispose();
      _cameraCtrl = null;
      if (!mounted || _isDisposed) return;
      _cameraCtrl =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _cameraCtrl!.initialize();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      if (mounted && !_isDisposed) _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  Future<void> _preloadFromHistory(int catId) async {
    if (!mounted || _isDisposed) return;
    setState(() => _recomLoading = true);
    try {
      // ✅ ส่ง catId → backend ดึง recommendation ของแมวตัวนี้โดยตรง
      final result = await _recomApi.getRecommendations(page: 1, catId: catId);
      if (!mounted || _isDisposed) return;
      setState(() {
        _recomCat = result.cat;
        _recomItems = result.items;
        _recomPagination = result.pagination;
        _recomLoading = false;
      });
      if (mounted) {
        context.read<CatAnalysisBloc>().add(CatPreloadSuccess(catId: catId));
      }
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() => _recomLoading = false);
      _showError('โหลดข้อมูลแมวไม่สำเร็จ: $e');
    }
  }

  // ─── Recommend API calls ───────────────────────────────────────────────────

  Future<void> _loadRecommendations({bool reset = true}) async {
    if (!mounted || _isDisposed) return;
    setState(() => _recomLoading = reset);
    try {
      final result = await _recomApi.getRecommendations(page: 1);
      if (!mounted || _isDisposed) return;
      setState(() {
        _recomCat = result.cat;
        _recomItems = result.items;
        _recomPagination = result.pagination;
        _recomLoading = false;
      });
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() => _recomLoading = false);
      _showError('โหลดสินค้าแนะนำไม่สำเร็จ: $e');
    }
  }

  Future<void> _loadMoreRecommendations() async {
    final pagination = _recomPagination;
    if (pagination == null || !pagination.hasNext) return;
    if (_recomLoadingMore || !mounted || _isDisposed) return;

    setState(() => _recomLoadingMore = true);
    try {
      final result = await _recomApi.loadMore(current: pagination);
      if (!mounted || _isDisposed) return;
      setState(() {
        _recomItems = [..._recomItems, ...result.items];
        _recomPagination = result.pagination;
        _recomLoadingMore = false;
      });
    } catch (_) {
      if (mounted && !_isDisposed) setState(() => _recomLoadingMore = false);
    }
  }

  // ─── Image helpers ──────────────────────────────────────────────────────────

  Future<File?> _cropToFrame(String path) async {
    try {
      final image = img.decodeImage(await File(path).readAsBytes());
      if (image == null) return null;
      final x = (image.width * 0.10).toInt().clamp(0, image.width);
      final y = (image.height * 0.225).toInt().clamp(0, image.height);
      final w = (image.width * 0.80).toInt().clamp(1, image.width - x);
      final h = (image.height * 0.55).toInt().clamp(1, image.height - y);
      final cropped = img.copyCrop(image, x: x, y: y, width: w, height: h);
      final tmp = await getTemporaryDirectory();
      final f = File(
          '${tmp.path}/cat_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return f;
    } catch (_) {
      return null;
    }
  }

  Future<File?> _compress(File src) async {
    try {
      if (!await src.exists()) return null;
      var image = img.decodeImage(await src.readAsBytes());
      if (image == null) return null;
      const mx = 1920;
      if (image.width > mx || image.height > mx) {
        image = img.copyResize(image,
            width: image.width > image.height ? mx : null,
            height: image.height > image.width ? mx : null);
      }
      final tmp = await getTemporaryDirectory();
      final f = File(
          '${tmp.path}/cat_out_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(image, quality: 92));
      return f;
    } catch (_) {
      return null;
    }
  }

  // ─── Capture ────────────────────────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    if (_isCapturing || _isDisposed) return;
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _showError('กล้องยังไม่พร้อม');
      return;
    }
    if (mounted) setState(() => _isCapturing = true);
    try {
      final photo = await ctrl.takePicture();
      if (!mounted || _isDisposed) return;

      final cropped = await _cropToFrame(photo.path);
      final processed = await _compress(File(photo.path));

      if (!mounted || _isDisposed) {
        try {
          cropped?.delete();
        } catch (_) {}
        try {
          File(photo.path).delete();
        } catch (_) {}
        return;
      }

      _pendingFile = processed;
      final fileToDetect = cropped ?? File(photo.path);

      _detectCleanup = () {
        try {
          cropped?.delete();
        } catch (_) {}
        try {
          File(photo.path).delete();
        } catch (_) {}
      };

      context.read<DetectCatBloc>().add(DetectCatStarted(fileToDetect));
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('ถ่ายรูปไม่สำเร็จ: $e');
    }
  }

  // ─── Gallery ────────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isDisposed) return;
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
          maxWidth: 1920,
          maxHeight: 1920);
      if (picked == null || !mounted || _isDisposed) return;

      setState(() => _isCapturing = true);

      final processed = await _compress(File(picked.path));
      if (!mounted || _isDisposed) return;

      _pendingFile = processed;
      context.read<DetectCatBloc>().add(DetectCatStarted(File(picked.path)));
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  // ─── หลัง detect ผ่าน ──────────────────────────────────────────────────────

  void _proceedToAnalysis() {
    final file = _pendingFile;
    _pendingFile = null;
    if (file == null || !mounted || _isDisposed) return;

    _cameraCtrl?.dispose();
    _cameraCtrl = null;
    setState(() => _isCapturing = false);

    context.read<CatAnalysisBloc>().add(CatImageSelected(file));
    _showSuccessMessage('พบแมว! ✅ กดวิเคราะห์ได้เลย');
  }

  void _clearData() {
    if (!mounted || _isDisposed) return;
    _pendingFile = null;
    _recomItems = [];
    _recomCat = null;
    _recomPagination = null;
    context.read<DetectCatBloc>().add(DetectCatReset());
    context.read<CatAnalysisBloc>().add(CatAnalysisReset());
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  // ─── Edit Cat ────────────────────────────────────────────────────────────────

  Future<void> _editCat(CatData cat) async {
    final catId = _recomCat?.id ?? cat.dbId;
    if (catId == null) {
      _showError('ไม่พบ id ของแมว');
      return;
    }

    final colorCtrl = TextEditingController(text: cat.name);
    final breedCtrl = TextEditingController(text: cat.breed ?? '');
    final ageCtrl = TextEditingController(text: cat.age?.toString() ?? '');
    final weightCtrl = TextEditingController(text: cat.weight.toString());

    final chestCtrl = TextEditingController();
    final neckCtrl = TextEditingController();
    final waistCtrl = TextEditingController();
    final bodyLenCtrl = TextEditingController();
    final backLenCtrl = TextEditingController();
    final legLenCtrl = TextEditingController();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedSize = cat.sizeCategory;
    bool showMeasure = false;
    String? calculatedSize;

    // ── default measurement ต่อ size (midpoint ของช่วง) ─────────────────────
    // XS: รอบอก 28-32  S: 33-36  M: 37-40  L: 41-44  XL: 45-50+
    const Map<String, Map<String, double>> sizeDefaults = {
      'XS': {
        'chest': 30,
        'neck': 18,
        'waist': 26,
        'body': 28,
        'back': 25,
        'leg': 8
      },
      'S': {
        'chest': 34,
        'neck': 20,
        'waist': 28,
        'body': 32,
        'back': 28,
        'leg': 9
      },
      'M': {
        'chest': 38,
        'neck': 22,
        'waist': 32,
        'body': 36,
        'back': 32,
        'leg': 10
      },
      'L': {
        'chest': 42,
        'neck': 24,
        'waist': 36,
        'body': 40,
        'back': 36,
        'leg': 11
      },
      'XL': {
        'chest': 47,
        'neck': 26,
        'waist': 40,
        'body': 44,
        'back': 40,
        'leg': 12
      },
    };

    void fillMeasureFromSize(String size, StateSetter setModal) {
      final d = sizeDefaults[size];
      if (d == null) return;
      setModal(() {
        chestCtrl.text = d['chest']!.toStringAsFixed(1);
        neckCtrl.text = d['neck']!.toStringAsFixed(1);
        waistCtrl.text = d['waist']!.toStringAsFixed(1);
        bodyLenCtrl.text = d['body']!.toStringAsFixed(1);
        backLenCtrl.text = d['back']!.toStringAsFixed(1);
        legLenCtrl.text = d['leg']!.toStringAsFixed(1);
        calculatedSize = size;
      });
    }

    // XS:28-32 | S:33-36 | M:37-40 | L:41-44 | XL:45+
    String calcSizeFromChest(double chest) {
      if (chest <= 32) return 'XS';
      if (chest <= 36) return 'S';
      if (chest <= 40) return 'M';
      if (chest <= 44) return 'L';
      return 'XL';
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: StatefulBuilder(
          builder: (ctx2, setModal) {
            void recalcSize() {
              final chest = double.tryParse(chestCtrl.text);
              if (chest != null && chest > 0) {
                final s = calcSizeFromChest(chest);
                setModal(() {
                  calculatedSize = s;
                  selectedSize = s;
                });
              }
            }

            return SingleChildScrollView(
              child: Column(
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
                    style: const TextStyle(
                        color: Colors.black45, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'สีแมว / Cat Color',
                      prefixIcon: Icon(Icons.color_lens_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: breedCtrl,
                    style: const TextStyle(
                        color: Colors.black45, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(
                            color: Colors.black45, fontWeight: FontWeight.bold),
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
                        style: const TextStyle(
                            color: Colors.black45, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          labelText: 'น้ำหนัก (kg)',
                          prefixIcon: Icon(Icons.monitor_weight_outlined),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),

                  // ── Size selector ───────────────────────────────────────
                  Row(children: [
                    const Text('ขนาด / Size',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(width: 6),
                    if (showMeasure)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'กดเพื่อ auto-fill การวัด',
                          style: TextStyle(
                              fontSize: 10, color: Colors.orange.shade800),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                      final selected = selectedSize == size;
                      return GestureDetector(
                        onTap: () {
                          setModal(() => selectedSize = size);
                          // ถ้า measurement เปิดอยู่ → auto-fill ค่า
                          if (showMeasure) fillMeasureFromSize(size, setModal);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color:
                                selected ? Colors.orange : Colors.grey.shade200,
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
                                color: selected ? Colors.white : Colors.black87,
                              )),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // ── ปุ่มการวัดขนาดเอง ────────────────────────────────────
                  GestureDetector(
                    onTap: () {
                      setModal(() {
                        showMeasure = !showMeasure;
                        // เปิด → auto-fill จาก size ปัจจุบัน
                        if (showMeasure)
                          fillMeasureFromSize(selectedSize, setModal);
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: showMeasure
                            ? Colors.orange.shade50
                            : isDark
                                ? Colors.grey[800]
                                : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: showMeasure
                              ? Colors.orange
                              : Colors.grey.shade300,
                          width: 1.5,
                        ),
                      ),
                      child: Row(children: [
                        Icon(Icons.straighten_rounded,
                            size: 18,
                            color: showMeasure
                                ? Colors.orange
                                : Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text('การวัดขนาดเอง',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: showMeasure
                                  ? Colors.orange
                                  : Colors.grey.shade700,
                            )),
                        const Spacer(),
                        AnimatedRotation(
                          turns: showMeasure ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              color: showMeasure
                                  ? Colors.orange
                                  : Colors.grey.shade500),
                        ),
                      ]),
                    ),
                  ),

                  // ── Dropdown measurement fields ───────────────────────────
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 250),
                    crossFadeState: showMeasure
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.grey[850]
                                : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.info_outline,
                                    size: 14, color: Colors.orange),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'แก้ไขค่าการวัด (cm) — size คำนวณจากรอบอก',
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.shade800),
                                  ),
                                ),
                              ]),
                              const SizedBox(height: 4),
                              Text(
                                'XS:28-32 | S:33-36 | M:37-40 | L:41-44 | XL:45+',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange.shade700,
                                    fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: _measureField(
                                  controller: chestCtrl,
                                  label: 'รอบอก *',
                                  icon: Icons.radio_button_unchecked,
                                  onChanged: (_) => recalcSize(),
                                )),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _measureField(
                                  controller: neckCtrl,
                                  label: 'รอบคอ',
                                  icon: Icons.radio_button_unchecked,
                                )),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    child: _measureField(
                                  controller: bodyLenCtrl,
                                  label: 'ยาวตัว',
                                  icon: Icons.straighten,
                                )),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _measureField(
                                  controller: backLenCtrl,
                                  label: 'ยาวหลัง',
                                  icon: Icons.straighten,
                                )),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Expanded(
                                    child: _measureField(
                                  controller: waistCtrl,
                                  label: 'รอบเอว',
                                  icon: Icons.radio_button_unchecked,
                                )),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: _measureField(
                                  controller: legLenCtrl,
                                  label: 'ยาวขา',
                                  icon: Icons.straighten,
                                )),
                              ]),
                              if (calculatedSize != null) ...[
                                const SizedBox(height: 12),
                                Row(children: [
                                  const Icon(Icons.check_circle,
                                      size: 16, color: Colors.green),
                                  const SizedBox(width: 6),
                                  Text('Size ที่คำนวณได้: ',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(calculatedSize!,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14)),
                                  ),
                                ]),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
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
            );
          },
        ),
      ),
    );

    if (result != true || !mounted) return;

    final updateData = <String, dynamic>{
      'cat_color':
          colorCtrl.text.trim().isEmpty ? cat.name : colorCtrl.text.trim(),
      'size_category': selectedSize,
      if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
      if (ageCtrl.text.trim().isNotEmpty)
        'age': int.tryParse(ageCtrl.text.trim()),
      if (weightCtrl.text.trim().isNotEmpty)
        'weight': double.tryParse(weightCtrl.text.trim()),
      if (chestCtrl.text.trim().isNotEmpty)
        'chest_cm': double.tryParse(chestCtrl.text.trim()),
      if (neckCtrl.text.trim().isNotEmpty)
        'neck_cm': double.tryParse(neckCtrl.text.trim()),
      if (waistCtrl.text.trim().isNotEmpty)
        'waist_cm': double.tryParse(waistCtrl.text.trim()),
      if (bodyLenCtrl.text.trim().isNotEmpty)
        'body_length_cm': double.tryParse(bodyLenCtrl.text.trim()),
      if (backLenCtrl.text.trim().isNotEmpty)
        'back_length_cm': double.tryParse(backLenCtrl.text.trim()),
      if (legLenCtrl.text.trim().isNotEmpty)
        'leg_length_cm': double.tryParse(legLenCtrl.text.trim()),
    };

    if (!mounted || _isDisposed) return;
    setState(() => _recomLoading = true);

    try {
      final refreshed = await _recomApi.updateCatAndRefresh(
        catId: catId,
        updateData: updateData,
      );
      if (!mounted || _isDisposed) return;
      setState(() {
        _recomCat = refreshed.cat;
        _recomItems = refreshed.items;
        _recomPagination = refreshed.pagination;
        _recomLoading = false;
      });
      _showSuccessMessage('อัปเดตข้อมูลแมวแล้ว ✅ รีเฟรชสินค้าแนะนำ');
      context.read<CatAnalysisBloc>().add(CatDataUpdated(updateData));
    } catch (e) {
      if (!mounted || _isDisposed) return;
      setState(() => _recomLoading = false);
      _showError('แก้ไขข้อมูลแมวไม่สำเร็จ: $e');
    }
  }

// ── helper widget ─────────────────────────────────────────────────────────────
  Widget _measureField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 16, color: Colors.orange),
        suffixText: 'cm',
        suffixStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
      ),
    );
  }

  // ─── Dialogs ────────────────────────────────────────────────────────────────

  void _showQuotaDialog() {
    if (!mounted || _isDisposed) return;
    final dark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.hourglass_bottom_rounded,
              size: 64, color: Colors.orange),
          const SizedBox(height: 16),
          const Text('⏳ ระบบวิเคราะห์เต็มชั่วคราว',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              'ขณะนี้ระบบ AI วิเคราะห์แมวถูกใช้งานเต็มแล้ว\nกรุณาลองใหม่อีกครั้งในภายหลัง',
              style: TextStyle(
                  fontSize: 14, color: Colors.orange.shade800, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('รับทราบ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showItemDetailPopup(Map<String, dynamic> product) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) {
        return BlocProvider(
          create: (_) => ItemDetailBloc()
            ..add(
                ItemDetailFavCheckRequested(product['uuid']?.toString() ?? '')),
          child: ItemDetailsCard(itemDetails: product),
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

  void _showRecomItemDetailPopup(RecommendItem item) {
    final product = <String, dynamic>{
      'id': item.id,
      'uuid': item.uuid,
      'clothing_name': item.clothingName,
      'description': item.description,
      'category': item.category,
      'size_category': item.sizeCategory,
      'min_weight': item.minWeight,
      'max_weight': item.maxWeight,
      'chest_min_cm': item.chestMinCm,
      'chest_max_cm': item.chestMaxCm,
      'price': item.price,
      'discount_price': item.discountPrice,
      'discount_percent': item.discountPercent,
      'stock': item.stock,
      'image_url': item.imageUrl,
      'images': item.images,
      'gender': item.gender,
      'breed': item.breed,
      'is_featured': item.isFeatured,
      'clothing_like': item.clothingLike,
    };
    _showItemDetailPopup(product);
  }

  // ─── Reject Dialog ───────────────────────────────────────────────────────────

  void _showRejectDialog(DetectCatResult result) {
    if (!mounted || _isDisposed) return;
    final dark = Theme.of(context).brightness == Brightness.dark;

    String title, message;
    IconData icon;
    Color iconColor;

    switch (result.reason) {
      // ── NEW: subject_type จาก analysis_cat.py ────────────────────────────
      case 'human_in_costume':
        title = '🧑‍🎭 ตรวจพบมนุษย์แต่งชุดแมว';
        message =
            'ระบบตรวจพบมนุษย์ที่แต่งตัวเป็นแมว\nกรุณาถ่ายรูปแมวจริงเท่านั้น';
        icon = Icons.theater_comedy_outlined;
        iconColor = Colors.pink;
      case 'stuffed_toy':
        title = '🧸 ตรวจพบตุ๊กตาแมว';
        message =
            'ระบบตรวจพบตุ๊กตาหรือของเล่นรูปแมว\nกรุณาถ่ายรูปแมวที่มีชีวิตจริงเท่านั้น';
        icon = Icons.toys_outlined;
        iconColor = Colors.orange;
      case 'figurine_model':
        title = '🗿 ตรวจพบโมเดล/ฟิกเกอร์แมว';
        message =
            'ระบบตรวจพบโมเดล ฟิกเกอร์ หรือของประดับรูปแมว\nกรุณาถ่ายรูปแมวจริงเท่านั้น';
        icon = Icons.category_outlined;
        iconColor = Colors.brown;
      case 'cat_mask_prop':
        title = '🎭 ตรวจพบหน้ากากแมว';
        message =
            'ระบบตรวจพบหน้ากากหรืออุปกรณ์ประกอบฉากรูปแมว\nกรุณาถ่ายรูปแมวจริงเท่านั้น';
        icon = Icons.theater_comedy_outlined;
        iconColor = Colors.purple;
      // case 'printed_image':
      //   title = '🖥️ ตรวจพบภาพจากหน้าจอ/สิ่งพิมพ์';
      //   message = 'ระบบตรวจพบว่าถ่ายรูปจากหน้าจอหรือรูปพิมพ์\nกรุณาถ่ายแมวโดยตรงจากกล้อง';
      //   icon = Icons.monitor_outlined;
      //   iconColor = Colors.blueGrey;
      case 'other_animal':
      case 'no_cat':
        title = '😿 ไม่พบแมวในภาพ';
        message =
            'ไม่สามารถตรวจพบแมวในภาพได้\nลองถ่ายรูปใหม่ให้เห็นแมวชัดเจนทั้งตัว';
        icon = Icons.search_off;
        iconColor = Colors.grey;
      // ── EXISTING: จาก detect_bloc ────────────────────────────────────────
      case 'multiple_cats':
        title = '🐱🐱 ตรวจพบแมวหลายตัว';
        message =
            'ระบบตรวจพบแมวมากกว่า 1 ตัวในภาพ\nกรุณาถ่ายรูปแมวทีละตัวเท่านั้น';
        icon = Icons.pets;
        iconColor = Colors.purple;
      case 'cartoon':
        title = '🎨 ไม่ใช่ภาพแมวจริง';
        message =
            'ระบบตรวจพบว่าเป็นภาพการ์ตูน รูปวาด โมเดล\nหรือของเล่น กรุณาใช้รูปถ่ายแมวจริงเท่านั้น';
        icon = Icons.draw_outlined;
        iconColor = Colors.orange;
      case 'is_dog':
        title = '🐶 ตรวจพบสุนัข';
        message = 'ภาพนี้มีลักษณะของสุนัข\nฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
        icon = Icons.pets;
        iconColor = Colors.brown;
      case 'non_cat_animal':
        title = '🚫 ตรวจพบสัตว์อื่น';
        message = 'ฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
        icon = Icons.pets;
        iconColor = Colors.deepOrange;
      case 'other':
        title = '🤔 ไม่สามารถระบุได้';
        message = 'ลองถ่ายรูปใหม่ให้เห็นแมวชัดเจนยิ่งขึ้น';
        icon = Icons.help_outline;
        iconColor = Colors.orange;
      default:
        title = '😿 ไม่พบแมวในภาพ';
        message =
            'ไม่สามารถตรวจพบแมวในภาพได้\nลองถ่ายรูปใหม่ให้เห็นแมวชัดเจนทั้งตัว';
        icon = Icons.search_off;
        iconColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 64, color: iconColor),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Text(message,
                style: TextStyle(
                    fontSize: 14,
                    color: dark ? Colors.white70 : Colors.grey.shade700,
                    height: 1.5),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text('Confidence: ${(result.confidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ถ่ายใหม่',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบข้อมูลแมวนี้ใช่หรือไม่?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child:
                const Text('ลบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (mounted) context.read<CatAnalysisBloc>().add(CatDataDeleted());
  }

  // ─── Snackbars ───────────────────────────────────────────────────────────────

  void _showSuccessMessage(String m) {
    if (!mounted || _isDisposed) return;
    showTopSnackBar(Overlay.of(context), CustomSnackBar.success(message: m),
        animationDuration: const Duration(milliseconds: 200),
        reverseAnimationDuration: const Duration(milliseconds: 200),
        displayDuration: const Duration(milliseconds: 1000));
  }

  void _showError(String m) {
    if (!mounted || _isDisposed) return;
    showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: m),
        animationDuration: const Duration(milliseconds: 200),
        reverseAnimationDuration: const Duration(milliseconds: 200),
        displayDuration: const Duration(milliseconds: 1500));
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final lang = Provider.of<LanguageProvider>(context);
    final dark = theme.themeMode == ThemeMode.dark;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: dark ? Colors.white : Colors.black87, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              // มี route ก่อนหน้า → pop ปกติ
              Navigator.of(context).pop();
            } else {
              // ไม่มี route ให้ pop (เป็น root) → ไปหน้า Home
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const MyControll()),
                (route) => false,
              );
            }
          },
        ),
        title: Text(
          lang.translate(en: 'MEOW SIZE', th: 'วัดขนาดตัวแมว'),
          style: TextStyle(
              fontFamily: 'catFont',
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : Colors.black),
        ),
        backgroundColor: dark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: dark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_basket_outlined),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const BasketPage())),
            tooltip: 'ตระกร้า',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage())),
            tooltip: 'ประวัติการวัด',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<DetectCatBloc, DetectCatState>(
            listener: (context, state) {
              if (state is DetectCatLoading) return;
              if (mounted && !_isDisposed) setState(() => _isCapturing = false);
              _detectCleanup?.call();
              _detectCleanup = null;

              if (state is DetectCatSuccess) {
                _proceedToAnalysis();
              } else if (state is DetectCatRejected) {
                _pendingFile = null;
                _showRejectDialog(state.result);
              } else if (state is DetectCatQuotaExceeded) {
                _pendingFile = null;
                _showQuotaDialog();
              } else if (state is DetectCatFailure) {
                _pendingFile = null;
                _showError(state.error);
              }
            },
          ),
          BlocListener<CatAnalysisBloc, CatAnalysisState>(
            listener: (context, state) {
              if (state is CatAnalysisQuotaExceeded) _showQuotaDialog();
              if (state is CatAnalysisNotFound)
                _showError('😿 ${state.message}');
              if (state is CatAnalysisSuccess) {
                _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
                _loadRecommendations();
              }
              if (state is CatDataUpdateSuccess)
                _showSuccessMessage(state.message);
              if (state is CatAnalysisFailure) _showError(state.error);
              if (state is CatAnalysisInitial) _initCamera();
            },
          ),
        ],
        child: BlocBuilder<CatAnalysisBloc, CatAnalysisState>(
          builder: (context, state) {
            File? imgFile;
            if (state is CatImageReady) imgFile = state.imageFile;
            if (state is CatAnalysisUploading) imgFile = state.imageFile;
            if (state is CatAnalysisAnalyzing) imgFile = state.imageFile;

            final processing =
                state is CatAnalysisUploading || state is CatAnalysisAnalyzing;
            final progress = state is CatAnalysisUploading
                ? 0.3
                : state is CatAnalysisAnalyzing
                    ? 0.7
                    : 0.0;
            final progressLbl = state is CatAnalysisUploading
                ? 'Uploading image...'
                : 'Analyzing cat...';

            final showResult = state is CatAnalysisSuccess ||
                state is CatDataUpdateSuccess ||
                state is CatDataUpdating;

            CatData? catData;
            if (state is CatAnalysisSuccess) catData = state.catData;
            if (state is CatDataUpdateSuccess) catData = state.catData;
            if (state is CatDataUpdating) catData = state.catData;

            return Stack(children: [
              Column(children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: state is CatAnalysisInitial
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    child: Column(children: [
                      if (state is CatAnalysisInitial)
                        SizedBox(
                            height: screenH * 0.78,
                            child: _buildCameraPreview()),
                      if (state is CatImageReady)
                        _buildImageSection(dark, state.imageFile, lang, false),
                      if (state is CatAnalysisUploading ||
                          state is CatAnalysisAnalyzing)
                        _buildImageSection(dark, imgFile!, lang, true),
                      if (showResult && catData != null)
                        _buildResultSection(dark, catData, screenH, lang),
                    ]),
                  ),
                ),
                _buildBottomBar(dark, state, lang),
              ]),
              if (processing)
                _buildLoadingOverlay(imgFile, progress, progressLbl),
            ]);
          },
        ),
      ),
    );
  }

  // ─── Camera Preview ──────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    final detectState = context.watch<DetectCatBloc>().state;
    final detecting = detectState is DetectCatLoading;

    return Stack(fit: StackFit.expand, children: [
      CameraPreview(_cameraCtrl!),
      CustomPaint(painter: _RectHolePainter(), size: Size.infinite),
      Positioned(
        top: 20,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(14)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(
                  child: Text(
                      'วางแมวจริง 1 ตัวให้อยู่ในกรอบ เห็นทั้งตัว แล้วกดถ่ายรูป',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
      if (_isCapturing || detecting)
        Container(
          color: Colors.black54,
          child: const Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('🔍 กำลังตรวจจับแมว...',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('กรุณารอสักครู่',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
        ),
    ]);
  }

  // ─── Loading Overlay ─────────────────────────────────────────────────────────

  Widget _buildLoadingOverlay(File? file, double progress, String label) {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 190,
            height: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, __) => CircularProgressIndicator(
                  value: v,
                  strokeWidth: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange)),
            ),
          ),
          Container(
            width: 145,
            height: 145,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10)
                ]),
            child: ClipOval(
                child: file != null
                    ? Image.file(file, fit: BoxFit.cover)
                    : const Icon(Icons.pets, size: 60)),
          ),
        ]),
        const SizedBox(height: 20),
        Text('${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ])),
    );
  }

  // ─── Image Section ───────────────────────────────────────────────────────────

  Widget _buildImageSection(
      bool dark, File file, LanguageProvider lang, bool loading) {
    return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4))
                ]),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(file,
                    fit: BoxFit.cover, width: double.infinity)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: dark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                    width: 2)),
            child: Row(children: [
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: dark ? Colors.grey[600]! : Colors.grey[400]!,
                        width: 2)),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(file, fit: BoxFit.cover)),
              ),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    _infoRow(lang.translate(en: 'Cat color:', th: 'สีแมว:'),
                        'N/A', dark),
                    const SizedBox(height: 10),
                    _infoRow(
                        lang.translate(en: 'Age:', th: 'อายุ:'), 'N/A', dark),
                    const SizedBox(height: 10),
                    _infoRow(lang.translate(en: 'Breed:', th: 'พันธุ์:'), 'N/A',
                        dark),
                    const SizedBox(height: 10),
                    _infoRow(
                        lang.translate(en: 'Size:', th: 'ขนาด:'), 'N/A', dark),
                  ])),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: dark ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Icon(Icons.info_outline,
                  color: dark ? Colors.orange[300] : Colors.orange[700],
                  size: 20),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(
                lang.translate(
                    en: 'Please ensure that the cat is clearly visible for accurate measurement.',
                    th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
                style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.white70 : Colors.black87),
              )),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: ElevatedButton.icon(
              onPressed: loading
                  ? null
                  : () =>
                      context.read<CatAnalysisBloc>().add(CatAnalysisStarted()),
              icon: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.analytics),
              label: Text(
                loading
                    ? lang.translate(
                        en: 'Processing...', th: 'กำลังวิเคราะห์...')
                    : lang.translate(en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
            )),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: loading ? null : _clearData,
              style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Icon(Icons.close, size: 24),
            ),
          ]),
        ]));
  }

  // ─── Result Section ───────────────────────────────────────────────────────────

  Widget _buildResultSection(
      bool dark, CatData cat, double screenH, LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: dark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: dark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: cat.imageUrl.isNotEmpty
                    ? Image.network(cat.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.broken_image,
                            size: 40, color: Colors.grey[400]))
                    : Icon(Icons.pets, size: 40, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _infoRow(lang.translate(en: 'Cat Color:', th: 'สีแมว:'),
                      cat.name, dark),
                  const SizedBox(height: 10),
                  _infoRow(lang.translate(en: 'Age:', th: 'อายุ:'),
                      cat.age != null ? '${cat.age} years' : 'N/A', dark),
                  const SizedBox(height: 10),
                  _infoRow(lang.translate(en: 'Breed:', th: 'พันธุ์:'),
                      cat.breed ?? 'N/A', dark),
                  const SizedBox(height: 10),
                  _infoRow(lang.translate(en: 'Size:', th: 'ขนาด:'),
                      cat.sizeCategory, dark),
                ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: () => _editCat(cat),
                icon: Icon(Icons.mode_edit_outline_outlined,
                    color: Colors.blue.shade700, size: 28),
              ),
              IconButton(
                onPressed: _confirmDelete,
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade600, size: 28),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Row(children: [
          Text(lang.translate(en: 'Recommended Products', th: 'สินค้าแนะนำ'),
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: dark ? Colors.white : Colors.black87)),
          const Spacer(),
          if (!_recomLoading)
            IconButton(
              onPressed: _loadRecommendations,
              icon: Icon(Icons.refresh_rounded,
                  color: Colors.orange.shade600, size: 22),
              tooltip: 'รีเฟรช',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ]),
        const SizedBox(height: 12),
        if (_recomLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircularProgressIndicator(color: Colors.orange),
                SizedBox(height: 12),
                Text('กำลังโหลดสินค้าแนะนำ...',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
              ]),
            ),
          )
        else if (_recomItems.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                  lang.translate(
                      en: 'No matching products found',
                      th: 'ไม่พบสินค้าที่เหมาะสม'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ]),
          )
        else ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.62,
            ),
            itemCount: _recomItems.length,
            itemBuilder: (ctx, i) =>
                _buildRecomProductCard(_recomItems[i], dark, lang),
          ),
          if (_recomPagination?.hasNext == true) ...[
            const SizedBox(height: 16),
            Center(
              child: _recomLoadingMore
                  ? const CircularProgressIndicator(color: Colors.orange)
                  : OutlinedButton.icon(
                      onPressed: _loadMoreRecommendations,
                      icon: const Icon(Icons.expand_more, color: Colors.orange),
                      label: Text(
                        lang.translate(en: 'Load more', th: 'โหลดเพิ่ม'),
                        style: const TextStyle(
                            color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ]),
    );
  }

  Widget _infoRow(String label, String value, bool dark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: dark ? Colors.white70 : Colors.black54,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            color: dark ? Colors.white60 : Colors.black87,
          ),
        ),
      ),
    ]);
  }

  // ─── Product Card ─────────────────────────────────────────────────────────────

  Widget _buildRecomProductCard(
      RecommendItem item, bool dark, LanguageProvider lang) {
    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: item.uuid),
      builder: (ctx, snap) {
        final isFav = snap.data ?? false;

        return GestureDetector(
          onTap: () => _showRecomItemDetailPopup(item),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(dark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: item.resolvedImageUrl.isNotEmpty
                          ? Image.network(item.resolvedImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                    color: dark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    child: Icon(Icons.shopping_bag,
                                        size: 40, color: Colors.grey[400]),
                                  ))
                          : Container(
                              color: dark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(Icons.shopping_bag,
                                  size: 40, color: Colors.grey[400]),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        if (isFav) {
                          await _favouriteApi.removeFromFavourite(
                              clothingUuid: item.uuid);
                          _showSuccessMessage(lang.translate(
                              en: 'Removed from favourites',
                              th: 'ลบออกจากรายการโปรดแล้ว'));
                        } else {
                          await _favouriteApi.addToFavourite(
                              clothingUuid: item.uuid);
                          _showSuccessMessage(lang.translate(
                              en: 'Added to favourites!',
                              th: 'เพิ่มในรายการโปรดแล้ว!'));
                        }
                        if (mounted) setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFav
                              ? Colors.red.withOpacity(0.9)
                              : Colors.black.withOpacity(0.35),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 16),
                      ),
                    ),
                  ),
                  if (item.matchScore >= 0.8)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${(item.matchScore * 100).toInt()}%',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.clothingName,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: dark ? Colors.white : Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (item.hasDiscount) ...[
                            Text(
                              '฿${item.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[400],
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Flexible(
                            child: Text(
                              '฿${item.displayPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (item.discountPercent != null) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '-${item.discountPercent}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.touch_app_outlined,
                              size: 11,
                              color: dark ? Colors.white38 : Colors.grey[400]),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              lang.translate(
                                  en: 'Tap for details',
                                  th: 'แตะเพื่อดูรายละเอียด'),
                              style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      dark ? Colors.white38 : Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(
      bool dark, CatAnalysisState state, LanguageProvider lang) {
    if (state is! CatAnalysisInitial) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: dark ? Colors.grey[900] : Colors.white,
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
          ]),
      child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(
              lang.translate(
                  en: 'Take a photo: Place the cat in the center of the frame and see the whole body\n'
                      'Choose a photo: Use JPEG files no larger than 500KB',
                  th: 'ถ่ายรูป: วางตัวแมวให้อยู่กลางกรอบ และเห็นทั้งตัว\n'
                      'เลือกรูป: ใช้ไฟล์ JPEG ขนาดไม่เกิน 500KB'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: dark ? Colors.white70 : Colors.black87),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureFromCamera,
                icon: _isCapturing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isCapturing
                      ? lang.translate(
                          en: 'Detecting...', th: 'กำลังตรวจสอบ...')
                      : lang.translate(en: 'Take Photo', th: 'ถ่ายรูป'),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text(lang.translate(en: 'Choose Photo', th: 'เลือกรูป'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
              )),
            ]),
          ])),
    );
  }
}
