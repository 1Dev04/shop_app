import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_analysis/analysis_bloc.dart';
import 'package:flutter_application_1/blocs/cat_detect/detect_bloc.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
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
        name: j['name'],
        breed: j['breed'],
        age: j['age'],
        weight: (j['weight'] as num).toDouble(),
        sizeCategory: j['size_category'],
        chestCm: (j['chest_cm'] as num).toDouble(),
        neckCm: j['neck_cm'] != null ? (j['neck_cm'] as num).toDouble() : null,
        bodyLengthCm: j['body_length_cm'] != null
            ? (j['body_length_cm'] as num).toDouble()
            : null,
        confidence: (j['confidence'] as num).toDouble(),
        boundingBox: List<double>.from(
            j['bounding_box'].map((e) => (e as num).toDouble())),
        imageUrl: j['image_cat'] ?? j['image_url'] ?? '',
        thumbnailUrl: j['thumbnail_url'],
        detectedAt: DateTime.parse(j['detected_at']),
        dbId: j['db_id'],
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Widget Entry Point
// ═══════════════════════════════════════════════════════════════════════════════

class MeasureSizeCat extends StatelessWidget {
  const MeasureSizeCat({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CatAnalysisBloc()),
          BlocProvider(create: (_) => DetectCatBloc()),
        ],
        child: const _MeasureSizeCatView(),
      );
}

class _MeasureSizeCatView extends StatefulWidget {
  const _MeasureSizeCatView();
  @override
  State<_MeasureSizeCatView> createState() => _MeasureSizeCatState();
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - State
// ═══════════════════════════════════════════════════════════════════════════════

class _MeasureSizeCatState extends State<_MeasureSizeCatView> {
  final _picker = ImagePicker();
  final _favouriteApi = FavouriteApiService();
  final _basketApi = BasketApiService();

  bool _isCapturing = false;
  bool _isDisposed = false;
  CameraController? _cameraCtrl;

  // ไฟล์ที่รอส่ง analyze หลัง detect ผ่าน
  File? _pendingFile;

  // callback ลบ temp files หลัง detect เสร็จ
  VoidCallback? _detectCleanup;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraCtrl?.dispose();
    _cameraCtrl = null;
    super.dispose();
  }

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

  // ─── Image helpers ────────────────────────────────────────────────────────

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

  // ─── Capture from Camera ──────────────────────────────────────────────────

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

      // crop เฉพาะกรอบก่อน detect
      final cropped = await _cropToFrame(photo.path);

      // compress ภาพเต็มไว้รอก่อน (ใช้ถ้า detect ผ่าน)
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

      // ✅ ส่ง detect:
      // - ถ้า crop สำเร็จ → ส่ง cropped (ลบ photo หลัง detect เสร็จใน listener)
      // - ถ้า crop ล้มเหลว → ส่ง photo.path ตรงๆ
      final fileToDetect = cropped ?? File(photo.path);

      // เก็บ path ไว้ลบทีหลัง (หลัง detect เสร็จแล้ว)
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

  // ─── Pick from Gallery ────────────────────────────────────────────────────

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

      // compress ไว้รอก่อน
      final processed = await _compress(File(picked.path));
      if (!mounted || _isDisposed) return;

      _pendingFile = processed;

      // ✅ gallery ส่งภาพเต็ม (ผู้ใช้เลือกมาเองแล้ว)
      context.read<DetectCatBloc>().add(DetectCatStarted(File(picked.path)));
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  // ─── หลัง detect ผ่าน → ส่งต่อ analyze ────────────────────────────────────

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
    context.read<DetectCatBloc>().add(DetectCatReset());
    context.read<CatAnalysisBloc>().add(CatAnalysisReset());
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  // ─── Dialogs ──────────────────────────────────────────────────────────────

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

  void _showRejectDialog(DetectCatResult result) {
    if (!mounted || _isDisposed) return;
    final dark = Theme.of(context).brightness == Brightness.dark;

    String title, message;
    IconData icon;
    Color iconColor;

    switch (result.reason) {
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
      default: // no_cat
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

  void _showProductDialog(
      BuildContext context, Map<String, dynamic> product, bool dark) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final uuid = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final name = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final imageUrl = product['image_url'] ?? product['imageUrl'] ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final discPrice = (product['discount_price'] as num?)?.toDouble();
    final priceDisplay = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0
            ? '฿${price.toStringAsFixed(0)}'
            : '${product['price'] ?? ''}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(ctx).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 400, minWidth: 320),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: dark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 32),
              Text(
                  lang.translate(
                      en: 'Added to Favorites', th: 'เพิ่มในรายการโปรด'),
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: dark ? Colors.white : Colors.black87)),
              IconButton(
                icon: Icon(Icons.close,
                    color: dark ? Colors.white70 : Colors.black54, size: 24),
                onPressed: () => Navigator.pop(ctx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: dark ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 60, color: Colors.grey[400])))
                      : Center(
                          child: Icon(Icons.shopping_bag,
                              size: 60, color: Colors.grey[400])),
                ),
                Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.favorite,
                          color: Colors.red, size: 26),
                    )),
              ]),
            ),
            const SizedBox(height: 20),
            Text(name,
                style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                lang.translate(
                    en: 'Price: $priceDisplay', th: 'ราคา: $priceDisplay'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      try {
                        await _basketApi.addToBasket(clothingUuid: uuid);
                        _showSuccessMessage(lang.translate(
                            en: 'Added to cart!', th: 'เพิ่มลงตะกร้าแล้ว!'));
                      } catch (_) {
                        _showError(lang.translate(
                            en: 'Failed to add to cart',
                            th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text(lang.translate(en: 'Buy', th: 'ซื้อ'),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  )),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showInfoMessage(lang.translate(
                      en: 'Opening details...', th: 'กำลังเปิดรายละเอียด...'));
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: dark ? Colors.grey[700] : Colors.grey[300],
                    foregroundColor: dark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(lang.translate(en: 'More', th: 'เพิ่มเติม'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(CatData cat) async {
    final colorCtrl = TextEditingController(text: cat.name);
    final breedCtrl = TextEditingController(text: cat.breed ?? '');
    final ageCtrl = TextEditingController(text: cat.age?.toString() ?? '');
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    String selSize = cat.sizeCategory;
    final ok = await showModalBottomSheet<bool>(
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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx2, setM) => Column(
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
                          borderRadius: BorderRadius.circular(10)))),
              const Text('✏️ แก้ไขข้อมูลแมว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                  controller: colorCtrl,
                  decoration: const InputDecoration(
                      labelText: 'สีแมว / Cat Color',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: breedCtrl,
                  decoration: const InputDecoration(
                      labelText: 'พันธุ์ / Breed',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'อายุ (ปี)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text('ขนาด',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['XS', 'S', 'M', 'L', 'XL'].map((sz) {
                  final sel = selSize == sz;
                  return GestureDetector(
                    onTap: () => setM(() => selSize = sz),
                    child: Container(
                      width: 52,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: sel ? Colors.orange : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(sz,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: sel ? Colors.white : Colors.black87)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('บันทึก',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;
    final data = <String, dynamic>{
      'cat_color':
          colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : cat.name,
      'size_category': selSize,
      if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
      if (ageCtrl.text.trim().isNotEmpty)
        'age': int.tryParse(ageCtrl.text.trim()),
    };
    if (mounted) context.read<CatAnalysisBloc>().add(CatDataUpdated(data));
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
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

  // ─── Snackbars ────────────────────────────────────────────────────────────

  void _showSuccessMessage(String m) {
    if (!mounted || _isDisposed) return;
    showTopSnackBar(Overlay.of(context), CustomSnackBar.success(message: m),
        animationDuration: const Duration(milliseconds: 200),
        reverseAnimationDuration: const Duration(milliseconds: 200),
        displayDuration: const Duration(milliseconds: 1000));
  }

  void _showInfoMessage(String m) {
    if (!mounted || _isDisposed) return;
    showTopSnackBar(Overlay.of(context), CustomSnackBar.info(message: m),
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

  // ─── Build ────────────────────────────────────────────────────────────────

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
          onPressed: () => Navigator.of(context).pop(),
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
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage())),
            tooltip: 'ประวัติการวัด',
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // ─── DetectCatBloc listener ────────────────────────────────────────
          BlocListener<DetectCatBloc, DetectCatState>(
            listener: (context, state) {
              if (state is DetectCatLoading) return;

              // ทุก state ที่ไม่ใช่ loading → reset _isCapturing
              if (mounted && !_isDisposed) {
                setState(() => _isCapturing = false);
              }

              // ✅ ลบ temp files หลัง detect เสร็จเสมอ ไม่ว่าจะผ่านหรือไม่
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
          // ─── CatAnalysisBloc listener ──────────────────────────────────────
          BlocListener<CatAnalysisBloc, CatAnalysisState>(
            listener: (context, state) {
              if (state is CatAnalysisQuotaExceeded) _showQuotaDialog();
              if (state is CatAnalysisNotFound)
                _showError('😿 ${state.message}');
              if (state is CatAnalysisSuccess)
                _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
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
                      if (state is CatAnalysisSuccess)
                        _buildResultSection(dark, state.catData, screenH, lang,
                            state.recommendations),
                      if (state is CatDataUpdateSuccess)
                        _buildResultSection(dark, state.catData, screenH, lang,
                            state.recommendations),
                      if (state is CatDataUpdating)
                        _buildResultSection(dark, state.catData, screenH, lang,
                            state.recommendations),
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

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    // ✅ ดู DetectCatBloc state ด้วย เพื่อแสดง loading overlay ระหว่าง detect
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

  Widget _buildResultSection(bool dark, CatData cat, double screenH,
      LanguageProvider lang, List<Map<String, dynamic>> recs) {
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
                onPressed: () => _showEditDialog(cat),
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
        Text(lang.translate(en: 'Recommended Products', th: 'สินค้าแนะนำ'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        if (recs.isEmpty)
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
        else
          SizedBox(
            height: screenH * 0.50,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.65),
              itemCount: recs.length,
              itemBuilder: (ctx, i) => _buildProductCard(recs[i], dark),
            ),
          ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, bool dark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white70 : Colors.black87)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: dark ? Colors.white60 : Colors.black54))),
    ]);
  }

Widget _buildProductCard(Map<String, dynamic> product, bool dark) {
    final lang = Provider.of<LanguageProvider>(context);
    final uuid = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final name = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final imageUrl = product['image_url'] ?? product['imageUrl'] ?? '';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;
    final discPrice = (product['discount_price'] as num?)?.toDouble();
    final discPct = product['discount_percent'];
    final stock = (product['stock'] as num?)?.toInt() ?? 99;
    final match = (product['match_score'] as num?)?.toDouble() ?? 0.0;
    final priceDisplay = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0
            ? '฿${price.toStringAsFixed(0)}'
            : '${product['price'] ?? ''}';

    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: uuid),
      builder: (ctx, snap) {
        final isFav = snap.data ?? false;
        return Container(
          width: 160,
          height: 230, 
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              color: dark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.5)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(children: [
                Container(
                  height: 100,
                  decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      color: dark ? Colors.grey[800] : Colors.grey[200]),
                  child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                  child: Icon(Icons.shopping_bag,
                                      size: 40, color: Colors.grey[400])))
                          : Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 40, color: Colors.grey[400]))),
                ),
                if (match >= 0.8)
                  Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${(match * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )),
                if (discPct != null)
                  Positioned(
                      top: 6,
                      right: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('-$discPct',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      )),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () async {
                      if (isFav) {
                        await _favouriteApi.removeFromFavourite(
                            clothingUuid: uuid);
                        _showSuccessMessage(lang.translate(
                            en: 'Removed from favourites',
                            th: 'ลบออกจากรายการโปรดแล้ว'));
                      } else {
                        await _favouriteApi.addToFavourite(clothingUuid: uuid);
                        _showProductDialog(context, product, dark);
                      }
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 18),
                    ),
                  ),
                ),
              ]),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: TextStyle(
                                  fontSize: 12, // ปรับขนาดลงนิดนึงกันล้น
                                  fontWeight: FontWeight.w600,
                                  color: dark ? Colors.white : Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(priceDisplay,
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: dark
                                          ? Colors.orange[300]
                                          : Colors.orange[700],
                                      fontWeight: FontWeight.bold)),
                              if (discPrice != null && price > 0) ...[
                                const SizedBox(width: 4),
                                Text('฿${price.toStringAsFixed(0)}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[500],
                                        decoration:
                                            TextDecoration.lineThrough)),
                              ],
                            ],
                          ),
                        ],
                      ),
                      
                      // ส่วนของปุ่มกด
                      Row(children: [
                        Expanded(
                            child: ElevatedButton(
                          onPressed: stock > 0
                              ? () async {
                                  try {
                                    await _basketApi.addToBasket(
                                        clothingUuid: uuid);
                                    _showSuccessMessage(lang.translate(
                                        en: 'Added to cart!',
                                        th: 'เพิ่มลงตะกร้าแล้ว!'));
                                  } catch (_) {
                                    _showError(lang.translate(
                                        en: 'Failed to add to cart',
                                        th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero, // 
                              backgroundColor:
                                  stock > 0 ? Colors.green : Colors.grey,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Text(
                              stock > 0
                                  ? lang.translate(en: 'Buy', th: 'ซื้อ')
                                  : lang.translate(en: 'Out', th: 'หมด'),
                              style: const TextStyle(fontSize: 11)),
                        )),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _showInfoMessage(lang.translate(
                              en: 'Opening details...',
                              th: 'กำลังเปิดรายละเอียด...')),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8), 
                              backgroundColor:
                                  dark ? Colors.grey[700] : Colors.grey[300],
                              foregroundColor:
                                  dark ? Colors.white : Colors.black87,
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Text(lang.translate(en: 'More', th: 'เพิ่มเติม'),
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
