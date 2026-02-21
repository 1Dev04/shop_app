import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/provider/language_provider.dart';

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

Future<String?> _getFirebaseToken() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  } catch (e) {
    return null;
  }
}

String getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (kIsWeb) return 'http://localhost:10000';
  if (Platform.isAndroid) return 'http://10.0.2.2:10000';
  return 'http://localhost:10000';
}

class _RectHolePainter extends CustomPainter {
  final Color borderColor;
  _RectHolePainter({this.borderColor = Colors.white});

  @override
  void paint(Canvas canvas, Size size) {
    final double rectW = size.width * 0.75;
    final double rectH = size.height * 0.60;
    final double left = (size.width - rectW) / 2;
    final double top = (size.height - rectH) / 2;

    final rrect = RRect.fromLTRBR(
      left, top, left + rectW, top + rectH,
      const Radius.circular(20),
    );

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect);
    final cutPath = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(cutPath, Paint()..color = Colors.black.withOpacity(0.55));

    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = borderColor.withOpacity(0.5));

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = borderColor
      ..strokeCap = StrokeCap.round;

    const double cLen = 28.0;
    const double r = 20.0;

    canvas.drawLine(Offset(left + r, top), Offset(left + r + cLen, top), accentPaint);
    canvas.drawLine(Offset(left, top + r), Offset(left, top + r + cLen), accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top), Offset(left + rectW - r - cLen, top), accentPaint);
    canvas.drawLine(Offset(left + rectW, top + r), Offset(left + rectW, top + r + cLen), accentPaint);
    canvas.drawLine(Offset(left + r, top + rectH), Offset(left + r + cLen, top + rectH), accentPaint);
    canvas.drawLine(Offset(left, top + rectH - r), Offset(left, top + rectH - r - cLen), accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top + rectH), Offset(left + rectW - r - cLen, top + rectH), accentPaint);
    canvas.drawLine(Offset(left + rectW, top + rectH - r), Offset(left + rectW, top + rectH - r - cLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _RectHolePainter old) => old.borderColor != borderColor;
}

// ─────────────────────────────────────────────
//  🔬 PRO DETECTION RESULT
// ─────────────────────────────────────────────
class _DetectionResult {
  final bool isCat;
  final String reason;
  final double catScore;
  final bool isCartoon;

  const _DetectionResult({
    required this.isCat,
    required this.reason,
    required this.catScore,
    required this.isCartoon,
  });
}

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
  });

  factory CatData.fromJson(Map<String, dynamic> json) {
    return CatData(
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      weight: (json['weight'] as num).toDouble(),
      sizeCategory: json['size_category'],
      chestCm: (json['chest_cm'] as num).toDouble(),
      neckCm: json['neck_cm'] != null ? (json['neck_cm'] as num).toDouble() : null,
      bodyLengthCm: json['body_length_cm'] != null ? (json['body_length_cm'] as num).toDouble() : null,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: List<double>.from(json['bounding_box'].map((e) => (e as num).toDouble())),
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      detectedAt: DateTime.parse(json['detected_at']),
    );
  }
}

class MeasureSizeCat extends StatefulWidget {
  const MeasureSizeCat({super.key});

  @override
  State<MeasureSizeCat> createState() => _MeasureSizeCatState();
}

class _MeasureSizeCatState extends State<MeasureSizeCat> {
  final ImagePicker _picker = ImagePicker();
  final FavouriteApiService _favouriteApi = FavouriteApiService();
  final BasketApiService _basketApi = BasketApiService();

  File? _selectedImage;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressLabel = 'Please wait...';

  CatData? _analysisCat;
  List<Map<String, dynamic>> _recommendedProducts = [];

  CameraController? _cameraController;
  Timer? _detectTimer;
  late ImageLabeler _imageLabeler;

  bool? _isCatDetected;
  bool _isDetecting = false;

  static const String cloudinaryCloudName = 'dag73dhpl';
  static const String cloudinaryUploadPreset = 'cat_img_detect';
  static const String cloudinaryFolder = 'Fetch_Img_SizeCat';

  // ─── Label sets ───────────────────────────────────────────
  static const List<String> _catLabels = [
    'cat', 'tabby', 'kitten', 'persian cat', 'siamese cat',
    'british shorthair', 'maine coon', 'bengal cat', 'ragdoll', 'feline',
  ];
  static const List<String> _dogLabels = [
    'dog', 'puppy', 'canine', 'hound', 'labrador', 'poodle',
    'bulldog', 'beagle', 'husky', 'golden retriever', 'german shepherd',
    'dachshund', 'chihuahua', 'pomeranian', 'corgi', 'shih tzu',
  ];
  // Labels ที่บ่งบอกว่าเป็น artwork / illustration / cartoon
  static const List<String> _artLabels = [
    'cartoon', 'illustration', 'anime', 'drawing', 'animation',
    'art', 'artwork', 'fictional character', 'animated cartoon',
    'graphic', 'comic', 'sketch', 'painting', 'digital art',
    'manga', 'clipart', 'vector', 'poster', 'figure', 'figurine',
    'toy', 'stuffed animal', 'plush', 'statue', 'sculpture',
  ];
  // Labels ที่ยืนยันว่าเป็นสิ่งมีชีวิตจริง (real photo context)
  static const List<String> _realAnimalLabels = [
    'fur', 'whisker', 'mammal', 'wildlife', 'fauna', 'paw',
    'animal', 'pet', 'domestic animal',
  ];

  // 🚫 Labels สัตว์อื่นที่ไม่ใช่แมว — reject ทันที
  static const List<String> _nonCatAnimalLabels = [
    // สัตว์น้ำ/กึ่งน้ำ
    'otter', 'sea otter', 'river otter', 'mink', 'ferret', 'weasel', 'marten',
    'beaver', 'seal', 'sea lion', 'walrus', 'dolphin', 'whale', 'fish',
    // สัตว์ป่า
    'fox', 'wolf', 'bear', 'raccoon', 'squirrel', 'rabbit', 'hare', 'hamster',
    'guinea pig', 'gerbil', 'rat', 'mouse', 'hedgehog', 'skunk', 'badger',
    'mongoose', 'meerkat', 'panda', 'koala', 'kangaroo', 'monkey', 'ape',
    'chimpanzee', 'gorilla', 'lemur', 'deer', 'elk', 'reindeer', 'moose',
    // นก/สัตว์เลื้อยคลาน/อื่นๆ
    'bird', 'parrot', 'owl', 'eagle', 'snake', 'lizard', 'turtle', 'frog',
    'hamster', 'capybara', 'alpaca', 'llama', 'sheep', 'goat', 'cow', 'horse',
    'pig', 'chicken', 'duck', 'tiger', 'lion', 'cheetah', 'leopard', 'jaguar',
    'lynx', 'bobcat', 'cougar', 'panther',
  ];

  String get pythonBackendAnalysis => '${getBaseUrl()}/api/vision/analyze-cat';



  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
    _initMLKit();
    _initCamera();
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _cameraController?.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  void _initMLKit() {
    // ลด threshold เล็กน้อยเพื่อรับ label ได้มากขึ้น แล้วกรองที่ logic แทน
    final options = ImageLabelerOptions(confidenceThreshold: 0.35);
    _imageLabeler = ImageLabeler(options: options);
  }

  // ─────────────────────────────────────────────────────────
  //  🔬 PRO DETECTION — ตรวจจับแมวจริง vs การ์ตูน/ของเล่น
  // ─────────────────────────────────────────────────────────
  Future<_DetectionResult> _detectCatPro(String imagePath) async {
    try {
      // ── 1. ML Kit label analysis ─────────────────────────
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      double catScore = 0.0;
      double dogScore = 0.0;
      double artScore = 0.0;
      double realAnimalScore = 0.0;
      double nonCatAnimalScore = 0.0; // 🚫 สัตว์อื่นที่ไม่ใช่แมว
      String nonCatAnimalName = '';   // ชื่อสัตว์ที่ตรวจพบ

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final conf = label.confidence;
        print('🔍 ML Kit: "$text" conf=${conf.toStringAsFixed(2)}');

        for (final l in _catLabels) {
          if (text.contains(l) && conf > catScore) catScore = conf;
        }
        for (final l in _dogLabels) {
          if (text.contains(l) && conf > dogScore) dogScore = conf;
        }
        for (final l in _artLabels) {
          if (text.contains(l) && conf > artScore) artScore = conf;
        }
        for (final l in _realAnimalLabels) {
          if (text.contains(l) && conf > realAnimalScore) realAnimalScore = conf;
        }
        // 🚫 ตรวจสัตว์อื่น
        for (final l in _nonCatAnimalLabels) {
          if (text.contains(l) && conf > nonCatAnimalScore) {
            nonCatAnimalScore = conf;
            nonCatAnimalName = label.label;
          }
        }
      }

      print('🐱 cat=$catScore | 🐶 dog=$dogScore | 🎨 art=$artScore | 🐾 real=$realAnimalScore | 🚫 nonCat=$nonCatAnimalScore ($nonCatAnimalName)');

      // ── 2. Image texture analysis (cartoon detection) ─────
      final isCartoonByTexture = await _isLikelyCartoon(imagePath);
      print('🖼️ Cartoon texture: $isCartoonByTexture');

      // ── 3. Decision logic — CAT ONLY STRICT MODE ──────────

      // Rule A: ถ้า art score สูงมาก → การ์ตูน
      if (artScore >= 0.60) {
        return _DetectionResult(
          isCat: false,
          reason: 'art_label_high',
          catScore: catScore,
          isCartoon: true,
        );
      }

      // Rule B: texture บ่งว่าเป็นการ์ตูน + catScore ไม่สูงพอ
      if (isCartoonByTexture && catScore < 0.80) {
        return _DetectionResult(
          isCat: false,
          reason: 'cartoon_texture',
          catScore: catScore,
          isCartoon: true,
        );
      }

      // Rule C: catScore ต่ำเกิน → ไม่ใช่แมว
      if (catScore < 0.70) {
        return _DetectionResult(
          isCat: false,
          reason: 'cat_score_low',
          catScore: catScore,
          isCartoon: isCartoonByTexture,
        );
      }

      // Rule D: dog score แข่งกัน
      if (dogScore >= 0.50 && (catScore - dogScore) < 0.20) {
        return _DetectionResult(
          isCat: false,
          reason: 'ambiguous_cat_dog',
          catScore: catScore,
          isCartoon: isCartoonByTexture,
        );
      }

      // Rule E: art score พอมี + ไม่มี real animal signals
      if (artScore >= 0.35 && realAnimalScore < 0.30 && catScore < 0.85) {
        return _DetectionResult(
          isCat: false,
          reason: 'art_suspected_no_real_signal',
          catScore: catScore,
          isCartoon: true,
        );
      }

      // ── 🚫 Rule F: STRICT CAT-ONLY ────────────────────────
      // ถ้าตรวจพบสัตว์อื่นที่ confidence สูงพอ → reject ทันที
      // ไม่ว่า catScore จะสูงแค่ไหนก็ตาม
      if (nonCatAnimalScore >= 0.45) {
        return _DetectionResult(
          isCat: false,
          reason: 'non_cat_animal:$nonCatAnimalName',
          catScore: catScore,
          isCartoon: false,
        );
      }

      // ── 🚫 Rule G: catScore ต้องชนะทุกสัตว์อื่นอย่างชัดเจน
      // ป้องกัน edge case เช่น นาก/สุนัขจิ้งจอก ที่ catScore พอผ่าน
      // แต่ nonCatAnimalScore ก็ไม่น้อยมาก
      if (nonCatAnimalScore > 0.30 && (catScore - nonCatAnimalScore) < 0.30) {
        return _DetectionResult(
          isCat: false,
          reason: 'cat_not_dominant_over_other_animal:$nonCatAnimalName',
          catScore: catScore,
          isCartoon: false,
        );
      }

      // ── ✅ Rule H: ผ่านทุก rule → เป็นแมวจริง
      return _DetectionResult(
        isCat: true,
        reason: 'passed',
        catScore: catScore,
        isCartoon: false,
      );
    } catch (e) {
      print('❌ Pro detection error: $e');
      return _DetectionResult(isCat: false, reason: 'error', catScore: 0, isCartoon: false);
    }
  }

  // ─────────────────────────────────────────────────────────
  //  🖼️ CARTOON TEXTURE DETECTOR
  //  วิเคราะห์ว่าภาพมี "flat color zones" สูงหรือเปล่า
  //  ภาพการ์ตูนมักมีสีแบน edge คม contrast สูงน้อยบริเวณกว้าง
  // ─────────────────────────────────────────────────────────
  Future<bool> _isLikelyCartoon(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return false;

      // Resize ให้เล็กลงเพื่อความเร็ว
      final small = img.copyResize(image, width: 100, height: 100);

      // ── วิเคราะห์ unique color count (ภาพการ์ตูน = สีน้อย)
      final Set<int> uniqueColors = {};
      int totalPixels = small.width * small.height;

      for (int y = 0; y < small.height; y++) {
        for (int x = 0; x < small.width; x++) {
          final pixel = small.getPixel(x, y);
          // Quantize เพื่อ group สีใกล้เคียงกัน (32-step)
          final r = (pixel.r ~/ 32) * 32;
          final g = (pixel.g ~/ 32) * 32;
          final b = (pixel.b ~/ 32) * 32;
          uniqueColors.add((r << 16) | (g << 8) | b);
        }
      }

      // ── วิเคราะห์ edge sharpness (Sobel-like)
      // ภาพการ์ตูนมี edge คม + พื้นที่ภายใน flat
      int sharpEdgeCount = 0;
      int checkedPixels = 0;

      for (int y = 1; y < small.height - 1; y++) {
        for (int x = 1; x < small.width - 1; x++) {
          final center = small.getPixel(x, y);
          final right = small.getPixel(x + 1, y);
          final down = small.getPixel(x, y + 1);

          final dr = (center.r - right.r).abs();
          final dg = (center.g - right.g).abs();
          final db = (center.b - right.b).abs();
          final dd = (center.r - down.r).abs() + (center.g - down.g).abs() + (center.b - down.b).abs();

          final grad = (dr + dg + db + dd) / 2;
          if (grad > 80) sharpEdgeCount++;
          checkedPixels++;
        }
      }

      final double colorDiversity = uniqueColors.length / totalPixels; // ต่ำ = การ์ตูน
      final double edgeRatio = checkedPixels > 0 ? sharpEdgeCount / checkedPixels : 0;

      print('🎨 ColorDiversity=${colorDiversity.toStringAsFixed(3)} EdgeRatio=${edgeRatio.toStringAsFixed(3)} UniqueColors=${uniqueColors.length}');

      // ── วิเคราะห์ color saturation distribution
      // ภาพการ์ตูนมักมี saturation สูงและสม่ำเสมอมากกว่าภาพจริง
      double totalSat = 0;
      List<double> satList = [];
      for (int y = 0; y < small.height; y++) {
        for (int x = 0; x < small.width; x++) {
          final pixel = small.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          final maxC = [r, g, b].reduce(max);
          final minC = [r, g, b].reduce(min);
          final sat = maxC > 0 ? (maxC - minC) / maxC : 0.0;
          satList.add(sat);
          totalSat += sat;
        }
      }
      final avgSat = totalSat / satList.length;
      // Variance of saturation
      final satVariance = satList.fold(0.0, (sum, s) => sum + pow(s - avgSat, 2)) / satList.length;

      print('🎨 AvgSat=${avgSat.toStringAsFixed(3)} SatVariance=${satVariance.toStringAsFixed(4)}');

      // ── Decision
      int cartoonSignals = 0;

      // ภาพการ์ตูน: unique color หลังทำ quantize น้อย (< 15% ของ pixels)
      if (colorDiversity < 0.15) cartoonSignals++;

      // ภาพการ์ตูน: saturation variance ต่ำ (สีสม่ำเสมอ)
      if (satVariance < 0.04) cartoonSignals++;

      // ภาพการ์ตูน: edge ratio สูง (เส้นขอบคม) แต่ unique color ยังน้อย
      if (edgeRatio > 0.12 && colorDiversity < 0.20) cartoonSignals++;

      // ภาพการ์ตูน: avg saturation สูงมาก (สีฉูดฉาด)
      if (avgSat > 0.55 && colorDiversity < 0.20) cartoonSignals++;

      print('🎨 CartoonSignals=$cartoonSignals/4');

      // ถ้า signal >= 2 จาก 4 ถือว่าเป็นการ์ตูน
      return cartoonSignals >= 2;
    } catch (e) {
      print('❌ Cartoon detector error: $e');
      return false;
    }
  }

  void _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
      _cameraController = CameraController(backCamera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
        _startLiveDetect();
      }
    } catch (e) {
      print('❌ Camera error: $e');
      _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  void _startLiveDetect() {
    _detectTimer = Timer.periodic(const Duration(milliseconds: 700), (_) async {
      if (!mounted) return;
      if (_cameraController == null || !_cameraController!.value.isInitialized) return;
      if (_isDetecting || _isProcessing) return;

      _isDetecting = true;
      try {
        final XFile photo = await _cameraController!.takePicture();
        final croppedFile = await _cropToRectArea(photo.path);
        final checkPath = croppedFile?.path ?? photo.path;
        final result = await _detectCatPro(checkPath);
        try { await File(photo.path).delete(); } catch (_) {}
        try { croppedFile?.delete(); } catch (_) {}
        if (mounted) setState(() => _isCatDetected = result.isCat);
      } catch (e) {
        print('❌ Live detect error: $e');
      } finally {
        _isDetecting = false;
      }
    });
  }

  void _loadRecommendedProducts() {
    setState(() {
      _recommendedProducts = [
        {'id': '1', 'name': 'Cat Clothing Set A', 'price': '\$25', 'imageUrl': 'https://via.placeholder.com/150/FF6347/FFFFFF?text=Product+1'},
        {'id': '2', 'name': 'Cute Cat Sweater', 'price': '\$30', 'imageUrl': 'https://via.placeholder.com/150/4682B4/FFFFFF?text=Product+2'},
        {'id': '3', 'name': 'Winter Cat Outfit', 'price': '\$28', 'imageUrl': 'https://via.placeholder.com/150/32CD32/FFFFFF?text=Product+3'},
        {'id': '4', 'name': 'Premium Cat Dress', 'price': '\$35', 'imageUrl': 'https://via.placeholder.com/150/FFD700/FFFFFF?text=Product+4'},
      ];
    });
  }

  Future<File?> _cropToRectArea(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;

      final double rectW = image.width * 0.75;
      final double rectH = image.height * 0.60;
      final int cropX = ((image.width - rectW) / 2).toInt().clamp(0, image.width);
      final int cropY = ((image.height - rectH) / 2).toInt().clamp(0, image.height);
      final int cropW = rectW.toInt().clamp(1, image.width - cropX);
      final int cropH = rectH.toInt().clamp(1, image.height - cropY);

      final cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cat_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 80));
      return tempFile;
    } catch (e) {
      print('❌ Crop error: $e');
      return null;
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1024, maxHeight: 1024);
      if (image != null) {
        setState(() { _isProcessing = true; _progressLabel = 'กำลังตรวจสอบภาพ...'; _progress = 0.2; });

        final croppedFile = await _cropToRectArea(image.path);
        final checkPath = croppedFile?.path ?? image.path;
        final result = await _detectCatPro(checkPath);
        try { croppedFile?.delete(); } catch (_) {}

        setState(() => _isCatDetected = result.isCat);

        if (!result.isCat) {
          setState(() => _isProcessing = false);
          final msg = _buildRejectionMessage(result);
          _showError(msg);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _isCatDetected = null);
          return;
        }

        final processedImage = await _validateAndCompressGalleryImage(File(image.path));
        if (processedImage != null) {
          _detectTimer?.cancel();
          await _cameraController?.dispose();
          _cameraController = null;
          setState(() { _selectedImage = processedImage; _analysisCat = null; _isProcessing = false; });
          _showSuccessMessage('พบแมว! เลือกรูปภาพสำเร็จ 🐱');
        } else {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  // ── ✅ ถ่ายรูปแล้ววนซ้ำได้ (ไม่ dispose กล้อง) ────────────
  Future<void> _captureFromLiveCamera() async {
    try {
      final ctrl = _cameraController;
      if (ctrl == null || !ctrl.value.isInitialized) {
        _showError('กล้องยังไม่พร้อม กรุณารอสักครู่');
        return;
      }

      // หยุด live detect ชั่วคราว
      _detectTimer?.cancel();
      _detectTimer = null;

      int wait = 0;
      while (_isDetecting && wait < 15) {
        await Future.delayed(const Duration(milliseconds: 100));
        wait++;
      }
      _isDetecting = false;

      if (!mounted || ctrl != _cameraController || !ctrl.value.isInitialized) {
        _showError('กล้องไม่พร้อม ลองใหม่อีกครั้ง');
        return;
      }

      // แสดงสถานะ detecting
      setState(() => _isCatDetected = null);

      final XFile photo = await ctrl.takePicture();
      final result = await _detectCatPro(photo.path);

      if (!result.isCat) {
        try { File(photo.path).delete(); } catch (_) {}
        setState(() => _isCatDetected = false);
        final msg = _buildRejectionMessage(result);
        _showError(msg);
        // ✅ วนกลับมา detect ใหม่ได้เลย ไม่ dispose กล้อง
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isCatDetected = null);
          _startLiveDetect();
        }
        return;
      }

      setState(() => _isCatDetected = true);
      await Future.delayed(const Duration(milliseconds: 300));

      final processedImage = await _validateAndCompressGalleryImage(File(photo.path));
      if (processedImage != null) {
        // ✅ ได้รูปแล้ว → dispose กล้องแล้วไปหน้าวิเคราะห์
        await ctrl.dispose();
        _detectTimer?.cancel();
        if (mounted) {
          setState(() {
            _cameraController = null;
            _selectedImage = processedImage;
            _analysisCat = null;
            _isCatDetected = null;
          });
        }
        _showSuccessMessage('พบแมว! ถ่ายรูปสำเร็จ 🐱');
      } else {
        // processedImage null → วนกลับถ่ายใหม่
        if (mounted) {
          setState(() => _isCatDetected = null);
          _startLiveDetect();
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isCatDetected = null);
      _showError('ถ่ายรูปไม่สำเร็จ: $e');
      _startLiveDetect();
    }
  }

  Future<File?> _validateAndCompressGalleryImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) { _showError('รูปภาพไม่ถูกต้อง'); return null; }

      const maxSize = 1024;
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(image,
          width: image.width > image.height ? maxSize : null,
          height: image.height > image.width ? maxSize : null,
        );
      }

      final compressedBytes = img.encodeJpg(image, quality: 70);
      if (compressedBytes.length > 500 * 1024) {
        _showError('รูปใหญ่เกินไป (${(compressedBytes.length / 1024).toStringAsFixed(0)} KB)');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/cat_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);
      return tempFile;
    } catch (e) {
      _showError('ไม่สามารถประมวลผลรูปได้: $e');
      return null;
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = cloudinaryUploadPreset;
      if (cloudinaryFolder.isNotEmpty) request.fields['folder'] = cloudinaryFolder;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      final response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) return jsonDecode(utf8.decode(response.bodyBytes))['secure_url'];
      throw Exception('Upload failed: ${response.statusCode}');
    } catch (e) {
      print('❌ Cloudinary error: $e');
      return null;
    }
  }

  Future<void> _analyzeCat() async {
    if (_selectedImage == null) return;
    setState(() { _isProcessing = true; _progress = 0.1; _progressLabel = 'Uploading image...'; });

    try {
      final token = await _getFirebaseToken();
      if (token == null || token.isEmpty) { setState(() => _isProcessing = false); _showError('กรุณาเข้าสู่ระบบก่อนใช้งาน'); return; }

      final imageUrl = await _uploadToCloudinary(_selectedImage!);
      if (imageUrl == null) throw Exception('Upload failed');

      setState(() { _progress = 0.4; _progressLabel = 'Detecting cat...'; });

      final response = await http.post(
        Uri.parse(pythonBackendAnalysis),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer $token'},
        body: jsonEncode({'image_url': imageUrl}),
      ).timeout(const Duration(seconds: 60), onTimeout: () => throw TimeoutException('Backend ใช้เวลานานเกินไป'));

      final decodedBody = utf8.decode(response.bodyBytes);
      if (response.statusCode == 401) throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      if (response.statusCode == 500) { final err = jsonDecode(decodedBody); throw Exception('Backend Error:\n${err['message'] ?? err['detail'] ?? 'Internal Server Error'}'); }
      if (response.statusCode != 200) { final err = jsonDecode(decodedBody); throw Exception('HTTP ${response.statusCode}:\n${err['message'] ?? 'Unknown error'}'); }

      final jsonData = jsonDecode(decodedBody);
      if (jsonData['is_cat'] != true) {
        setState(() { _progress = 1.0; _isProcessing = false; });
        _showError('😿 ${jsonData['message'] ?? 'ไม่พบแมวในภาพ'}');
        return;
      }

      setState(() { _progress = 1.0; _isProcessing = false; _analysisCat = CatData.fromJson(jsonData); });
      _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
      _loadRecommendedProducts();
    } catch (e) {
      setState(() => _isProcessing = false);
      String msg = e.toString().replaceAll('Exception: ', '');
      if (e.toString().contains('SocketException')) msg = 'ไม่สามารถเชื่อมต่อ Backend ได้';
      if (e.toString().contains('Upload failed')) msg = 'อัปโหลดรูปภาพไม่สำเร็จ';
      _showError(msg);
    }
  }

  void _clearData() {
    setState(() { _selectedImage = null; _analysisCat = null; _isCatDetected = null; });
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  void _showSuccessMessage(String message) => showTopSnackBar(Overlay.of(context), CustomSnackBar.success(message: message), displayDuration: const Duration(seconds: 2));
  void _showInfoMessage(String message) => showTopSnackBar(Overlay.of(context), CustomSnackBar.info(message: message), displayDuration: const Duration(seconds: 2));
  void _showError(String message) => showTopSnackBar(Overlay.of(context), CustomSnackBar.error(message: message), displayDuration: const Duration(seconds: 3));

  // ── แปลง rejection reason → ข้อความที่ผู้ใช้เข้าใจง่าย ──
  String _buildRejectionMessage(_DetectionResult result) {
    if (result.isCartoon) {
      return '😿 ตรวจพบรูปการ์ตูน/ภาพวาด กรุณาใช้รูปแมวจริงเท่านั้น';
    }
    final reason = result.reason;
    if (reason.startsWith('non_cat_animal:') || reason.startsWith('cat_not_dominant_over_other_animal:')) {
      final animalName = reason.contains(':') ? reason.split(':').last : 'สัตว์อื่น';
      return '🚫 ตรวจพบ "$animalName" ไม่ใช่แมว\nกรุณาใช้รูปแมวเท่านั้น';
    }
    if (reason == 'ambiguous_cat_dog') {
      return '🐶 ตรวจพบสุนัข ไม่ใช่แมว กรุณาเลือกรูปแมวเท่านั้น';
    }
    return '😿 ไม่พบแมวในภาพ กรุณาเลือกรูปแมวเท่านั้น';
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!),
        // ✅ กรอบขาวตลอด
        CustomPaint(painter: _RectHolePainter(borderColor: Colors.white), size: Size.infinite),

        // ✅ Status banner ด้านบน (แทนการเปลี่ยนสีกรอบ)
        Positioned(
          top: 20, left: 24, right: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildStatusBanner(),
          ),
        ),

        // ✅ hint ด้านล่าง
        Positioned(
          bottom: 20, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20)),
              child: const Text(
                'วางแมวให้อยู่ในกรอบ แล้วกดถ่ายรูป',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBanner() {
    if (_isCatDetected == null) {
      // กำลัง scan อยู่
      return Container(
        key: const ValueKey('scanning'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white70)),
            ),
            const SizedBox(width: 10),
            const Text('🔍 กำลังสแกนหาแมว...', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    if (_isCatDetected == true) {
      return Container(
        key: const ValueKey('found'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: Colors.green.shade700.withOpacity(0.85), borderRadius: BorderRadius.circular(14)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('🐱 พบแมวแล้ว! กดถ่ายรูปได้เลย', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    // ไม่พบแมว
    return Container(
      key: const ValueKey('notfound'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.red.shade700.withOpacity(0.85), borderRadius: BorderRadius.circular(14)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          SizedBox(width: 8),
          Text('❌ ไม่พบแมว / ตรวจพบการ์ตูน', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(width: 190, height: 190,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) => CircularProgressIndicator(value: value, strokeWidth: 6, backgroundColor: Colors.grey.shade300, valueColor: const AlwaysStoppedAnimation(Colors.orange)),
                  ),
                ),
                Container(
                  width: 145, height: 145,
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 4), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                  child: ClipOval(child: _selectedImage != null ? Image.file(_selectedImage!, fit: BoxFit.cover) : const Icon(Icons.pets, size: 60)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('${(_progress * 100).toInt()}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(_progressLabel, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(languageProvider.translate(en: "MEOW SIZE", th: "วัดขนาดตัวแมว"),
            style: TextStyle(fontFamily: "catFont", fontSize: 30, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: (_selectedImage == null && _analysisCat == null) ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (_selectedImage == null && _analysisCat == null) SizedBox(height: 678, child: _buildCameraPreview()),
                      if (_selectedImage != null && _analysisCat == null) _buildImageWithAnalyzeSection(isDark),
                      if (_analysisCat != null) _buildResultSection(isDark),
                    ],
                  ),
                ),
              ),
              _buildBottomButtons(isDark),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageWithAnalyzeSection(bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
            child: ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
            child: Row(
              children: [
                Container(
                  width: 100, height: 120,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_selectedImage!, fit: BoxFit.cover)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(languageProvider.translate(en: 'Cat color:', th: 'สีแมว:'), 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Age:', th: 'อายุ:'), 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Breed:', th: 'พันธุ์:'), 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Size:', th: 'ขนาด:'), 'N/A', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey[200], borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: isDark ? Colors.orange[300] : Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(languageProvider.translate(en: 'Please ensure that the cat is clearly visible for accurate measurement.', th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'), style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _analyzeCat,
                  icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Icon(Icons.analytics),
                  label: Text(_isProcessing ? languageProvider.translate(en: 'Processing...', th: 'กำลังวิเคราะห์...') : languageProvider.translate(en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.orange, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _clearData,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Icon(Icons.close, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection(bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.grey[50], borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 100, height: 120,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _analysisCat?.imageUrl != null
                        ? Image.network(_analysisCat!.imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: isDark ? Colors.grey[800] : Colors.grey[200], child: Icon(Icons.broken_image, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400])))
                        : Container(color: isDark ? Colors.grey[800] : Colors.grey[200], child: Icon(Icons.pets, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400])),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(languageProvider.translate(en: 'Cat Color:', th: 'สีแมว:'), _analysisCat?.name ?? 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Age:', th: 'อายุ:'), _analysisCat?.age != null ? '${_analysisCat!.age} years' : 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Breed:', th: 'พันธุ์:'), _analysisCat?.breed ?? 'N/A', isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(languageProvider.translate(en: 'Size:', th: 'ขนาด:'), _analysisCat?.sizeCategory ?? 'N/A', isDark),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context, isScrollControlled: true,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                          builder: (context) => Container(
                            height: MediaQuery.of(context).size.height * 0.5, padding: const EdgeInsets.all(16),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 12), decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
                              Text(languageProvider.translate(en: 'Edit Data', th: 'แก้ไขข้อมูล'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              TextField(decoration: InputDecoration(labelText: languageProvider.translate(en: 'Cat Color', th: 'สีแมว'), border: const OutlineInputBorder())),
                              const SizedBox(height: 8),
                              TextField(decoration: InputDecoration(labelText: languageProvider.translate(en: 'Age', th: 'อายุ'), border: const OutlineInputBorder())),
                              const SizedBox(height: 8),
                              TextField(decoration: InputDecoration(labelText: languageProvider.translate(en: 'Breed', th: 'พันธุ์'), border: const OutlineInputBorder())),
                              const SizedBox(height: 8),
                              TextField(decoration: InputDecoration(labelText: languageProvider.translate(en: 'Size', th: 'ขนาด'), border: const OutlineInputBorder())),
                              const Spacer(),
                              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.translate(en: 'Save', th: 'บันทึก')))),
                            ]),
                          ),
                        );
                      },
                      icon: Icon(Icons.mode_edit_outline_outlined, color: Colors.blue.shade700, size: 28),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(languageProvider.translate(en: 'Confirm Deletion', th: 'ยืนยันการลบ')),
                            content: Text(languageProvider.translate(en: 'Do you want to delete this cat data?', th: 'คุณต้องการลบข้อมูลแมวนี้ใช่หรือไม่?')),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: Text(languageProvider.translate(en: 'Cancel', th: 'ยกเลิก'))),
                              TextButton(
                                onPressed: () { Navigator.pop(context); setState(() { _analysisCat = null; _recommendedProducts = []; _selectedImage = null; _isCatDetected = null; }); _initCamera(); _showSuccessMessage(languageProvider.translate(en: 'Deleted data successfully', th: 'ลบข้อมูลแล้ว')); },
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: Text(languageProvider.translate(en: 'Delete', th: 'ลบ')),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(languageProvider.translate(en: 'Recommended Products', th: 'สินค้าแนะนำ'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          SizedBox(
            height: 450,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 5, mainAxisSpacing: 12, childAspectRatio: 0.86),
              itemCount: _recommendedProducts.length,
              itemBuilder: (context, index) => _buildProductCard(_recommendedProducts[index], index, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black87)),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: TextStyle(fontSize: 16, color: isDark ? Colors.white60 : Colors.black54))),
    ]);
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index, bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: product['id']),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return Container(
          width: 160, margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: isDark ? Colors.grey[850] : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(height: 100,
                decoration: BoxDecoration(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), color: isDark ? Colors.grey[800] : Colors.grey[200]),
                child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(product['imageUrl'], width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Center(child: Icon(Icons.shopping_bag, size: 40, color: isDark ? Colors.grey[600] : Colors.grey[400])))),
              ),
              Positioned(top: 6, right: 6,
                child: GestureDetector(
                  onTap: () async {
                    if (isFav) { await _favouriteApi.removeFromFavourite(clothingUuid: product['id']); _showSuccessMessage(languageProvider.translate(en: 'Removed from favourites', th: 'ลบออกจากรายการโปรดแล้ว')); }
                    else { await _favouriteApi.addToFavourite(clothingUuid: product['id']); _showSuccessMessage(languageProvider.translate(en: 'Added to favourites!', th: 'เพิ่มลงรายการโปรดแล้ว!')); }
                    setState(() {});
                  },
                  child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle), child: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.white, size: 18)),
                ),
              ),
            ]),
            Padding(padding: const EdgeInsets.all(8.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product['name'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(languageProvider.translate(en: 'Price: ${product['price']}', th: 'ราคา: ${product['price']}'), style: TextStyle(fontSize: 12, color: isDark ? Colors.orange[300] : Colors.orange[700], fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: ElevatedButton(
                  onPressed: () async { try { await _basketApi.addToBasket(clothingUuid: product['id']); _showSuccessMessage(languageProvider.translate(en: 'Added to cart!', th: 'เพิ่มลงตะกร้าแล้ว!')); } catch (e) { _showError(languageProvider.translate(en: 'Failed to add to cart', th: 'เพิ่มลงตะกร้าไม่สำเร็จ')); } },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6), backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(0, 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(languageProvider.translate(en: 'Buy', th: 'ซื้อ'), style: const TextStyle(fontSize: 11)),
                )),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: () => _showInfoMessage(languageProvider.translate(en: 'Opening details...', th: 'กำลังเปิดรายละเอียด...')),
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8), backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300], foregroundColor: isDark ? Colors.white : Colors.black87, minimumSize: const Size(0, 28), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  child: Text(languageProvider.translate(en: 'More', th: 'เพิ่มเติม'), style: const TextStyle(fontSize: 11)),
                ),
              ]),
            ])),
          ]),
        );
      },
    );
  }

  Widget _buildBottomButtons(bool isDark) {
    if (_selectedImage != null || _analysisCat != null) return const SizedBox.shrink();
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? Colors.grey[900] : Colors.white, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(languageProvider.translate(en: 'Place the cat inside the frame and see the whole body', th: 'วางตัวแมวให้อยู่ในกรอบ และเห็นทั้งตัว'),
            textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _captureFromLiveCamera,
            icon: const Icon(Icons.camera_alt),
            label: Text(languageProvider.translate(en: 'Take Photo', th: 'ถ่ายรูป'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.blue, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickImage,
            icon: const Icon(Icons.photo_library),
            label: Text(languageProvider.translate(en: 'Choose Photo', th: 'เลือกรูป'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), backgroundColor: Colors.green, foregroundColor: Colors.white, disabledBackgroundColor: Colors.grey[400], shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          )),
        ]),
      ])),
    );
  }
}