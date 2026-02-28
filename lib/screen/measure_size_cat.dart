import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_analysis/analysis_bloc.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/history_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/provider/theme_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

String getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
  if (kIsWeb) return 'http://localhost:10000';
  if (Platform.isAndroid) return 'http://10.0.2.2:10000';
  return 'http://localhost:10000';
}

Future<bool> _cartoonCheckIsolate(String imagePath) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return false;

    final small = img.copyResize(image, width: 100, height: 100);
    final Set<int> uniqueColors = {};
    final int totalPixels = small.width * small.height;

    for (int y = 0; y < small.height; y++) {
      for (int x = 0; x < small.width; x++) {
        final pixel = small.getPixel(x, y);
        uniqueColors.add(
          ((pixel.r ~/ 32) * 32 << 16) |
              ((pixel.g ~/ 32) * 32 << 8) |
              (pixel.b ~/ 32) * 32,
        );
      }
    }

    int sharpEdgeCount = 0, checkedPixels = 0;
    for (int y = 1; y < small.height - 1; y++) {
      for (int x = 1; x < small.width - 1; x++) {
        final c = small.getPixel(x, y);
        final r = small.getPixel(x + 1, y);
        final d = small.getPixel(x, y + 1);
        final grad = ((c.r - r.r).abs() +
                (c.g - r.g).abs() +
                (c.b - r.b).abs() +
                (c.r - d.r).abs() +
                (c.g - d.g).abs() +
                (c.b - d.b).abs()) /
            2;
        if (grad > 80) sharpEdgeCount++;
        checkedPixels++;
      }
    }

    double totalSat = 0;
    final List<double> satList = [];
    for (int y = 0; y < small.height; y++) {
      for (int x = 0; x < small.width; x++) {
        final pixel = small.getPixel(x, y);
        final rv = pixel.r / 255.0, gv = pixel.g / 255.0, bv = pixel.b / 255.0;
        final maxC = [rv, gv, bv].reduce(max);
        final minC = [rv, gv, bv].reduce(min);
        final sat = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        satList.add(sat);
        totalSat += sat;
      }
    }

    final avgSat = totalSat / satList.length;
    final satVariance =
        satList.fold(0.0, (sum, s) => sum + pow(s - avgSat, 2)) /
            satList.length;
    final colorDiversity = uniqueColors.length / totalPixels;
    final edgeRatio = checkedPixels > 0 ? sharpEdgeCount / checkedPixels : 0;

    int signals = 0;
    if (colorDiversity < 0.15) signals++;
    if (satVariance < 0.04) signals++;
    if (edgeRatio > 0.12 && colorDiversity < 0.20) signals++;
    if (avgSat > 0.55 && colorDiversity < 0.20) signals++;
    if (colorDiversity < 0.05) signals += 2;
    if (colorDiversity < 0.08) signals++;
    if (satVariance < 0.015) signals++;
    if (satVariance < 0.025) signals++;
    if (avgSat < 0.08 && colorDiversity < 0.10) signals++;
    if (avgSat < 0.12 && colorDiversity < 0.12) signals++;

    return signals >= 3;
  } catch (e) {
    return false;
  }
}

class _RectHolePainter extends CustomPainter {
  _RectHolePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final double rectW = size.width * 0.80;
    final double rectH = size.height * 0.55;
    final double left = (size.width - rectW) / 2;
    final double top = (size.height - rectH) / 2;

    final rrect = RRect.fromLTRBR(
        left, top, left + rectW, top + rectH, const Radius.circular(20));
    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(rrect);
    final cutPath = Path.combine(PathOperation.difference, fullPath, holePath);
    canvas.drawPath(cutPath, Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white.withOpacity(0.5));
    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    const double cLen = 28.0;
    const double r = 20.0;
    canvas.drawLine(
        Offset(left + r, top), Offset(left + r + cLen, top), accentPaint);
    canvas.drawLine(
        Offset(left, top + r), Offset(left, top + r + cLen), accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top),
        Offset(left + rectW - r - cLen, top), accentPaint);
    canvas.drawLine(Offset(left + rectW, top + r),
        Offset(left + rectW, top + r + cLen), accentPaint);
    canvas.drawLine(Offset(left + r, top + rectH),
        Offset(left + r + cLen, top + rectH), accentPaint);
    canvas.drawLine(Offset(left, top + rectH - r),
        Offset(left, top + rectH - r - cLen), accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top + rectH),
        Offset(left + rectW - r - cLen, top + rectH), accentPaint);
    canvas.drawLine(Offset(left + rectW, top + rectH - r),
        Offset(left + rectW, top + rectH - r - cLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _RectHolePainter old) => false;
}

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

  factory CatData.fromJson(Map<String, dynamic> json) {
    return CatData(
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      weight: (json['weight'] as num).toDouble(),
      sizeCategory: json['size_category'],
      chestCm: (json['chest_cm'] as num).toDouble(),
      neckCm:
          json['neck_cm'] != null ? (json['neck_cm'] as num).toDouble() : null,
      bodyLengthCm: json['body_length_cm'] != null
          ? (json['body_length_cm'] as num).toDouble()
          : null,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: List<double>.from(
          json['bounding_box'].map((e) => (e as num).toDouble())),
      imageUrl: json['image_cat'] ?? json['image_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      detectedAt: DateTime.parse(json['detected_at']),
      dbId: json['db_id'],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ WRAPPER: ใส่ BlocProvider ที่นี่ แทนที่จะไปแก้ parent
// ─────────────────────────────────────────────────────────────
class MeasureSizeCat extends StatelessWidget {
  const MeasureSizeCat({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CatAnalysisBloc(),
      child: const _MeasureSizeCatView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ✅ VIEW: ตัวหน้าจอจริงๆ
// ─────────────────────────────────────────────────────────────
class _MeasureSizeCatView extends StatefulWidget {
  const _MeasureSizeCatView();

  @override
  State<_MeasureSizeCatView> createState() => _MeasureSizeCatState();
}

class _MeasureSizeCatState extends State<_MeasureSizeCatView> {
  final ImagePicker _picker = ImagePicker();
  final FavouriteApiService _favouriteApi = FavouriteApiService();
  final BasketApiService _basketApi = BasketApiService();

  bool _isCapturing = false;
  bool _isDisposed = false;
  List<Map<String, dynamic>> _recommendedProducts = [];
  CameraController? _cameraController;
  late ImageLabeler _imageLabeler;

  static const List<String> _catLabels = [
    'cat',
    'tabby',
    'kitten',
    'persian cat',
    'siamese cat',
    'british shorthair',
    'maine coon',
    'bengal cat',
    'ragdoll',
    'feline',
  ];
  static const List<String> _dogLabels = [
    'dog', 'puppy', 'canine', 'hound', 'labrador', 'poodle', 'bulldog',
    'beagle', 'husky', 'golden retriever', 'german shepherd', 'dachshund',
    'chihuahua', 'pomeranian', 'corgi', 'shih tzu',
    // ─── เพิ่มใหม่ ───
    'pug', 'french bulldog', 'boston terrier', 'boxer', 'mastiff',
    'rottweiler', 'doberman', 'dalmatian', 'schnauzer', 'maltese',
    'yorkshire terrier', 'bichon', 'samoyed', 'akita', 'shar pei',
    'chow chow', 'spitz', 'basenji', 'whippet', 'greyhound',
  ];
  static const List<String> _artLabels = [
    'cartoon',
    'illustration',
    'anime',
    'drawing',
    'animation',
    'art',
    'artwork',
    'fictional character',
    'animated cartoon',
    'graphic',
    'comic',
    'sketch',
    'painting',
    'digital art',
    'manga',
    'clipart',
    'vector',
    'poster',
    'figure',
    'figurine',
    'toy',
    'stuffed animal',
    'plush',
    'statue',
    'sculpture',
    'origami',
    'paper craft',
    'papercraft',
    'paper model',
    'paper art',
    'model',
    'miniature',
    'replica',
    'doll',
    'puppet',
    'mannequin',
    'ceramic',
    'porcelain',
    'clay',
    'plastic',
    'wood carving',
    '3d model',
    'render',
    '3d render',
    'cgi',
    'computer graphics',
    'craft',
    'handmade',
    'artifact',
    'decorative',
    'low poly',
    'polygon',
    'geometric',
    'object',
    'prop',
  ];
  static const List<String> _realAnimalLabels = [
    'fur',
    'whisker',
    'mammal',
    'wildlife',
    'fauna',
    'paw',
    'animal',
    'pet',
    'domestic animal',
    'nose',
    'claw',
    'tail',
    'coat',
    'hair',
    'living',
    'vertebrate',
    'carnivore',
  ];
  static const List<String> _nonCatAnimalLabels = [
    'otter',
    'sea otter',
    'river otter',
    'mink',
    'ferret',
    'weasel',
    'marten',
    'beaver',
    'badger',
    'skunk',
    'seal',
    'sea lion',
    'walrus',
    'dolphin',
    'whale',
    'shark',
    'octopus',
    'crab',
    'lobster',
    'fish',
    'fox',
    'wolf',
    'bear',
    'panda',
    'raccoon',
    'squirrel',
    'rabbit',
    'hare',
    'hamster',
    'guinea pig',
    'gerbil',
    'rat',
    'mouse',
    'hedgehog',
    'meerkat',
    'mongoose',
    'capybara',
    'monkey',
    'ape',
    'chimpanzee',
    'gorilla',
    'lemur',
    'koala',
    'kangaroo',
    'deer',
    'elk',
    'reindeer',
    'moose',
    'alpaca',
    'llama',
    'sheep',
    'goat',
    'cow',
    'horse',
    'pig',
    'bird',
    'parrot',
    'owl',
    'eagle',
    'chicken',
    'duck',
    'tiger',
    'lion',
    'cheetah',
    'leopard',
    'jaguar',
    'lynx',
    'bobcat',
    'cougar',
    'panther',
    'snake',
    'lizard',
    'turtle',
    'frog',
    'gecko',
    'iguana',
    'chameleon',
    'crocodile',
    'alligator',
    'reptile',
    'dinosaur',
    'dragon',
    'spider',
    'insect',
    'scorpion',
  ];

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
    _initMLKit();
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraController?.dispose();
    _cameraController = null;
    _imageLabeler.close();
    super.dispose();
  }

  void _initMLKit() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.45);
    _imageLabeler = ImageLabeler(options: options);
  }

  Future<bool> _hasMultipleCats(String imagePath) async {
    if (_isDisposed) return false;
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return false;

      final tempDir = await getTemporaryDirectory();

      // แบ่งเป็น 6 regions แบบ overlap (3x2 grid) ครอบคลุมกว่า quadrant
      // แต่แต่ละ region ใหญ่กว่า เพื่อให้ catch แมวที่อยู่ตรงกลาง
      final int w3 = image.width ~/ 3;
      final int h2 = image.height ~/ 2;
      final int overlap = (w3 * 0.3).toInt(); // 30% overlap

      final List<Map<String, int>> regions = [
        // row 1
        {'x': 0, 'y': 0, 'w': w3 + overlap, 'h': h2 + overlap},
        {'x': w3 - overlap, 'y': 0, 'w': w3 + overlap * 2, 'h': h2 + overlap},
        {'x': w3 * 2 - overlap, 'y': 0, 'w': w3 + overlap, 'h': h2 + overlap},
        // row 2
        {'x': 0, 'y': h2 - overlap, 'w': w3 + overlap, 'h': h2 + overlap},
        {
          'x': w3 - overlap,
          'y': h2 - overlap,
          'w': w3 + overlap * 2,
          'h': h2 + overlap
        },
        {
          'x': w3 * 2 - overlap,
          'y': h2 - overlap,
          'w': w3 + overlap,
          'h': h2 + overlap
        },
      ];

      // เก็บ score + center position ของแต่ละ region ที่พบแมว
      final List<Map<String, double>> catRegions = [];

      for (int i = 0; i < regions.length; i++) {
        if (_isDisposed) return false;
        final r = regions[i];

        // clamp ให้อยู่ในขอบ
        final int rx = r['x']!.clamp(0, image.width - 1);
        final int ry = r['y']!.clamp(0, image.height - 1);
        final int rw = r['w']!.clamp(1, image.width - rx);
        final int rh = r['h']!.clamp(1, image.height - ry);

        final cropped =
            img.copyCrop(image, x: rx, y: ry, width: rw, height: rh);
        final regionFile = File(
            '${tempDir.path}/region_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await regionFile.writeAsBytes(img.encodeJpg(cropped, quality: 75));

        try {
          final inputImage = InputImage.fromFilePath(regionFile.path);
          final labels = await _imageLabeler.processImage(inputImage);
          double regionCatScore = 0.0;
          for (final label in labels) {
            final text = label.label.toLowerCase();
            for (final catLabel in _catLabels) {
              if (text.contains(catLabel) &&
                  label.confidence > regionCatScore) {
                regionCatScore = label.confidence;
              }
            }
          }
          // threshold สูงขึ้น: 0.65 (เดิม 0.50) เพื่อลด false positive
          if (regionCatScore >= 0.65) {
            catRegions.add({
              'score': regionCatScore,
              'cx': (rx + rw / 2).toDouble(),
              'cy': (ry + rh / 2).toDouble(),
            });
          }
        } catch (e) {
          print('❌ Region $i error: $e');
        } finally {
          try {
            regionFile.delete();
          } catch (_) {}
        }
      }

      if (catRegions.length < 2) return false;

      // ตรวจสอบว่า high-score regions กระจายตัวมากพอที่จะเป็น "คนละตัว"
      // ถ้า centers อยู่ใกล้กัน (< 35% ของ image size) = แมวตัวเดียว
      final double distThreshold =
          (image.width * 0.35 + image.height * 0.35) / 2;

      for (int i = 0; i < catRegions.length; i++) {
        for (int j = i + 1; j < catRegions.length; j++) {
          final dx = catRegions[i]['cx']! - catRegions[j]['cx']!;
          final dy = catRegions[i]['cy']! - catRegions[j]['cy']!;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist > distThreshold) return true; // ห่างกันมาก = คนละตัว
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<_DetectionResult> _detectCatPro(String imagePath) async {
    if (_isDisposed)
      return const _DetectionResult(
          isCat: false, reason: 'disposed', catScore: 0, isCartoon: false);
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);
      if (_isDisposed)
        return const _DetectionResult(
            isCat: false, reason: 'disposed', catScore: 0, isCartoon: false);

      double catScore = 0.0, dogScore = 0.0, artScore = 0.0;
      double realAnimalScore = 0.0, nonCatAnimalScore = 0.0;
      String nonCatAnimalName = '';

      // Debug: print all labels
      for (final label in labels) {
        print('🏷️ ${label.label}: ${label.confidence.toStringAsFixed(2)}');
      }

      for (final label in labels) {
        final text = label.label.toLowerCase();
        final conf = label.confidence;
        for (final l in _catLabels) {
          if (text.contains(l) && conf > catScore) catScore = conf;
        }
        for (final l in _dogLabels) {
          if (text.contains(l) && conf > dogScore) dogScore = conf;
        }
        for (final l in _artLabels) {
          if (text.contains(l) && conf > artScore) artScore = conf;
        }
        // realAnimalScore: ไม่นับถ้า dogScore >= 0.45
        // เพราะ Pug มี fur/mammal/animal labels ที่ทำให้ผ่านได้
        for (final l in _realAnimalLabels) {
          if (text.contains(l) && conf > realAnimalScore) {
            realAnimalScore = conf;
          }
        }
        for (final l in _nonCatAnimalLabels) {
          if (text.contains(l) && conf > nonCatAnimalScore) {
            nonCatAnimalScore = conf;
            nonCatAnimalName = label.label;
          }
        }
      }

      // ─── RULE 0: ถ้า dog score สูง → reject ทันที ─────────
      // แก้ปัญหา Pug ผ่าน: dogScore >= 0.40 ก็พอแล้ว
      if (dogScore >= 0.40) {
        return _DetectionResult(
          isCat: false,
          reason: 'ambiguous_cat_dog',
          catScore: catScore,
          isCartoon: false,
        );
      }

      // ─── RULE 1: catScore ต้องสูงพอ ───────────────────────
      if (catScore < 0.50) {
        return _DetectionResult(
            isCat: false,
            reason: 'cat_score_low',
            catScore: catScore,
            isCartoon: false);
      }

      // ─── RULE 2: ตรวจ cartoon/art ────────────────────────
      final isCartoon = await _cartoonCheckIsolate(imagePath);
      if (_isDisposed)
        return const _DetectionResult(
            isCat: false, reason: 'disposed', catScore: 0, isCartoon: false);

      if (artScore >= 0.30 && realAnimalScore < 0.55) {
        return _DetectionResult(
            isCat: false,
            reason: 'art_suspected',
            catScore: catScore,
            isCartoon: true);
      }
      if (isCartoon && catScore < 0.80) {
        return _DetectionResult(
            isCat: false,
            reason: 'cartoon_texture',
            catScore: catScore,
            isCartoon: true);
      }

      // ─── RULE 3: realAnimal ต้องมีพอ ─────────────────────
      // แต่ถ้า dogScore >= 0.30 ให้หัก realAnimalScore ออก (เพราะอาจมาจากสุนัข)
      final effectiveRealAnimalScore = dogScore >= 0.30
          ? realAnimalScore *
              (1.0 - dogScore) // ลด real animal score ตาม dog confidence
          : realAnimalScore;

      if (effectiveRealAnimalScore < 0.40) {
        return _DetectionResult(
            isCat: false,
            reason: 'art_suspected_no_real_signal',
            catScore: catScore,
            isCartoon: true);
      }

      // ─── RULE 4: non-cat animal ───────────────────────────
      if (nonCatAnimalScore >= 0.40) {
        return _DetectionResult(
          isCat: false,
          reason: 'non_cat_animal:$nonCatAnimalName',
          catScore: catScore,
          isCartoon: false,
        );
      }

      // ─── RULE 5: catScore ต้องชนะ dogScore อย่างชัดเจน ──
      // เพิ่ม margin จาก 0.20 → 0.25
      if (dogScore > 0 && (catScore - dogScore) < 0.25) {
        return _DetectionResult(
            isCat: false,
            reason: 'ambiguous_cat_dog',
            catScore: catScore,
            isCartoon: false);
      }

      // ─── RULE 6: catScore ต้องสูงพอ (strict) ────────────
      if (catScore < 0.60) {
        return _DetectionResult(
            isCat: false,
            reason: 'cat_score_low',
            catScore: catScore,
            isCartoon: isCartoon);
      }

      // ─── RULE 7: ตรวจหลายตัว (เฉพาะเมื่อผ่านทุก rule) ──
      final hasMultiple = await _hasMultipleCats(imagePath);
      if (_isDisposed)
        return const _DetectionResult(
            isCat: false, reason: 'disposed', catScore: 0, isCartoon: false);
      if (hasMultiple) {
        return _DetectionResult(
            isCat: false,
            reason: 'multiple_cats',
            catScore: catScore,
            isCartoon: false);
      }

      return _DetectionResult(
          isCat: true, reason: 'passed', catScore: catScore, isCartoon: false);
    } catch (e) {
      return _DetectionResult(
          isCat: false, reason: 'error', catScore: 0, isCartoon: false);
    }
  }

  void _initCamera() async {
    if (!mounted || _isDisposed) return;
    try {
      final cameras = await availableCameras();
      if (!mounted || _isDisposed) return;
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      await _cameraController?.dispose();
      _cameraController = null;
      if (!mounted || _isDisposed) return;
      _cameraController = CameraController(backCamera, ResolutionPreset.high,
          enableAudio: false);
      await _cameraController!.initialize();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      if (mounted && !_isDisposed) _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  void _loadRecommendedProducts() {
    setState(() {
      _recommendedProducts = [
        {
          'id': '1',
          'name': 'Cat Clothing Set A',
          'price': '\$25',
          'imageUrl':
              'https://via.placeholder.com/150/FF6347/FFFFFF?text=Product+1'
        },
        {
          'id': '2',
          'name': 'Cute Cat Sweater',
          'price': '\$30',
          'imageUrl':
              'https://via.placeholder.com/150/4682B4/FFFFFF?text=Product+2'
        },
        {
          'id': '3',
          'name': 'Winter Cat Outfit',
          'price': '\$28',
          'imageUrl':
              'https://via.placeholder.com/150/32CD32/FFFFFF?text=Product+3'
        },
        {
          'id': '4',
          'name': 'Premium Cat Dress',
          'price': '\$35',
          'imageUrl':
              'https://via.placeholder.com/150/FFD700/FFFFFF?text=Product+4'
        },
      ];
    });
  }

  // ─── helpers ───────────────────────────────────────────────
  Future<File?> _cropToRectArea(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      final double rectW = image.width * 0.80;
      final double rectH = image.height * 0.55;
      final int cropX =
          ((image.width - rectW) / 2).toInt().clamp(0, image.width);
      final int cropY =
          ((image.height - rectH) / 2).toInt().clamp(0, image.height);
      final cropped = img.copyCrop(image,
          x: cropX,
          y: cropY,
          width: rectW.toInt().clamp(1, image.width - cropX),
          height: rectH.toInt().clamp(1, image.height - cropY));
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/cat_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return tempFile;
    } catch (e) {
      return null;
    }
  }

  Future<File?> _validateAndCompressGalleryImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) return null;
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      const maxSize = 1920;
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(image,
            width: image.width > image.height ? maxSize : null,
            height: image.height > image.width ? maxSize : null);
      }
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/cat_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(img.encodeJpg(image, quality: 92));
      return tempFile;
    } catch (e) {
      return null;
    }
  }

  // ─── camera capture ────────────────────────────────────────
  Future<void> _captureFromLiveCamera() async {
    if (_isCapturing || _isDisposed) return;
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _showError('กล้องยังไม่พร้อม');
      return;
    }
    if (mounted) setState(() => _isCapturing = true);
    try {
      final XFile photo = await ctrl.takePicture();
      if (!mounted || _isDisposed) return;

      final croppedFile = await _cropToRectArea(photo.path);
      if (!mounted || _isDisposed) {
        croppedFile?.delete();
        File(photo.path).delete();
        return;
      }

      final checkPath = croppedFile?.path ?? photo.path;
      final result = await _detectCatPro(checkPath);
      try {
        croppedFile?.delete();
      } catch (_) {}

      if (!mounted || _isDisposed) {
        File(photo.path).delete();
        return;
      }

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        try {
          File(photo.path).delete();
        } catch (_) {}
        _showRejectDialog(result);
        return;
      }

      final processedImage =
          await _validateAndCompressGalleryImage(File(photo.path));
      try {
        File(photo.path).delete();
      } catch (_) {}
      if (!mounted || _isDisposed) return;

      await ctrl.dispose();
      if (mounted && !_isDisposed) {
        setState(() {
          _cameraController = null;
          _isCapturing = false;
        });
        if (processedImage != null) {
          context.read<CatAnalysisBloc>().add(CatImageSelected(processedImage));
          _showSuccessMessage('กดวิเคราะห์ได้เลย');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('ถ่ายรูปไม่สำเร็จ: $e');
    }
  }

  Future<void> _pickImage() async {
    if (_isCapturing || _isDisposed) return;
    try {
      final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 95,
          maxWidth: 1920,
          maxHeight: 1920);
      if (image == null) return;
      if (!mounted || _isDisposed) return;

      setState(() => _isCapturing = true);

      final result = await _detectCatPro(image.path);
      if (!mounted || _isDisposed) return;

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        _showRejectDialog(result);
        return;
      }

      final processedImage =
          await _validateAndCompressGalleryImage(File(image.path));
      if (!mounted || _isDisposed) return;

      if (processedImage != null) {
        await _cameraController?.dispose();
        _cameraController = null;
        if (mounted && !_isDisposed) {
          setState(() => _isCapturing = false);
          context.read<CatAnalysisBloc>().add(CatImageSelected(processedImage));
          _showSuccessMessage('พบแมว! ✅ กดวิเคราะห์ได้เลย');
        }
      } else {
        if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      }
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  // ─── dialogs ───────────────────────────────────────────────
  void _showQuotaDialog() {
    if (!mounted || _isDisposed) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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

  void _showRejectDialog(_DetectionResult result) {
    if (!mounted || _isDisposed) return;
    String title, reason;
    IconData icon;
    Color iconColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (result.reason == 'multiple_cats') {
      title = '🐱🐱 ตรวจพบแมวหลายตัว';
      reason =
          'ระบบตรวจพบแมวมากกว่า 1 ตัวในภาพ\nกรุณาถ่ายรูปแมวทีละตัวเท่านั้น';
      icon = Icons.pets;
      iconColor = Colors.purple;
    } else if (result.isCartoon) {
      title = '🎨 ตรวจพบภาพที่ไม่ใช่แมวจริง';
      reason =
          'ระบบตรวจพบว่าเป็นภาพการ์ตูน, รูปวาด, โมเดล, ของปั้น หรือ origami';
      icon = Icons.draw_outlined;
      iconColor = Colors.orange;
    } else if (result.reason.startsWith('non_cat_animal:') ||
        result.reason.startsWith('cat_not_dominant_over_other_animal:')) {
      final animalName = result.reason.split(':').last;
      title = '🚫 ตรวจพบสัตว์อื่น';
      reason =
          'ระบบตรวจพบ "$animalName" ในภาพ\nฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
      icon = Icons.pets;
      iconColor = Colors.deepOrange;
    } else if (result.reason == 'ambiguous_cat_dog') {
      title = '🐶 ตรวจพบสุนัข';
      reason = 'ภาพมีลักษณะคล้ายสุนัขมากกว่าแมว';
      icon = Icons.pets;
      iconColor = Colors.brown;
    } else {
      title = '😿 ไม่พบแมวในภาพ';
      reason =
          'ไม่สามารถตรวจพบแมวในภาพได้\nลองปรับมุมกล้อง ให้เห็นแมวชัดเจนยิ่งขึ้น';
      icon = Icons.search_off;
      iconColor = Colors.grey;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12)),
            child: Text(reason,
                style: TextStyle(
                    fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center),
          ),
          if (result.catScore > 0) ...[
            const SizedBox(height: 8),
            Text('Cat score: ${(result.catScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ถ่ายใหม่',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  // ─── ✅ RESTORED: Product Dialog (จากโค้ดเก่า) ────────────
  void _showProductDialog(
      BuildContext context, Map<String, dynamic> product, bool isDark) {
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(ctx).size.width * 0.9,
            constraints: const BoxConstraints(maxWidth: 400, minWidth: 320),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    Text(
                      languageProvider.translate(
                          en: 'Added to Favorites', th: 'เพิ่มในรายการโปรด'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 24),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // รูปภาพสินค้า
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product['imageUrl'],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            );
                          },
                        ),
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
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ชื่อสินค้า
                Text(
                  product['name'],
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),

                // ราคา
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    languageProvider.translate(
                        en: 'Price: ${product['price']}',
                        th: 'ราคา: ${product['price']}'),
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange),
                  ),
                ),
                const SizedBox(height: 24),

                // ปุ่ม Buy + More
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          try {
                            await _basketApi.addToBasket(
                                clothingUuid: product['id']);
                            _showSuccessMessage(languageProvider.translate(
                                en: 'Added to cart!',
                                th: 'เพิ่มลงตะกร้าแล้ว!'));
                          } catch (e) {
                            _showError(languageProvider.translate(
                                en: 'Failed to add to cart',
                                th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            languageProvider.translate(en: 'Buy', th: 'ซื้อ'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showInfoMessage(languageProvider.translate(
                              en: 'Opening details...',
                              th: 'กำลังเปิดรายละเอียด...'));
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.grey[300],
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                            languageProvider.translate(
                                en: 'More', th: 'เพิ่มเติม'),
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditDialog(CatData catData) async {
    final colorCtrl = TextEditingController(text: catData.name);
    final breedCtrl = TextEditingController(text: catData.breed ?? '');
    final ageCtrl = TextEditingController(text: catData.age?.toString() ?? '');
    String selectedSize = catData.sizeCategory;

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
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
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
                children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                  final selected = selectedSize == size;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedSize = size),
                    child: Container(
                      width: 52,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color:
                              selected ? Colors.orange : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(size,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: selected ? Colors.white : Colors.black87)),
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

    if (result != true) return;

    final updateData = <String, dynamic>{
      'cat_color': colorCtrl.text.trim().isNotEmpty
          ? colorCtrl.text.trim()
          : catData.name,
      'size_category': selectedSize,
      if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
      if (ageCtrl.text.trim().isNotEmpty)
        'age': int.tryParse(ageCtrl.text.trim()),
    };
    if (mounted)
      context.read<CatAnalysisBloc>().add(CatDataUpdated(updateData));
  }

  Future<void> _confirmDeleteCat() async {
    final confirm = await showDialog<bool>(
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
    if (confirm != true) return;
    if (mounted) context.read<CatAnalysisBloc>().add(CatDataDeleted());
  }

  void _clearData() {
    if (!mounted || _isDisposed) return;
    context.read<CatAnalysisBloc>().add(CatAnalysisReset());
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  // ─── snackbars ─────────────────────────────────────────────
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

  // ─── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;
    final screenH = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          languageProvider.translate(en: "MEOW SIZE", th: "วัดขนาดตัวแมว"),
          style: TextStyle(
              fontFamily: "catFont",
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const HistoryPage())),
            tooltip: 'ประวัติการวัด',
          ),
        ],
      ),
      body: BlocConsumer<CatAnalysisBloc, CatAnalysisState>(
        listener: (context, state) {
          if (state is CatAnalysisQuotaExceeded) _showQuotaDialog();
          if (state is CatAnalysisNotFound) _showError('😿 ${state.message}');
          if (state is CatAnalysisSuccess) {
            _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
            _loadRecommendedProducts();
          }
          if (state is CatDataUpdateSuccess) _showSuccessMessage(state.message);
          if (state is CatAnalysisFailure) _showError(state.error);
          if (state is CatAnalysisInitial) _initCamera();
        },
        builder: (context, state) {
          File? currentImage;
          if (state is CatImageReady) currentImage = state.imageFile;
          if (state is CatAnalysisUploading) currentImage = state.imageFile;
          if (state is CatAnalysisAnalyzing) currentImage = state.imageFile;

          final isProcessing =
              state is CatAnalysisUploading || state is CatAnalysisAnalyzing;
          final progress = state is CatAnalysisUploading
              ? 0.3
              : (state is CatAnalysisAnalyzing ? 0.7 : 0.0);
          final progressLabel = state is CatAnalysisUploading
              ? 'Uploading image...'
              : 'Analyzing cat...';

          return Stack(children: [
            Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: (state is CatAnalysisInitial)
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Column(children: [
                    if (state is CatAnalysisInitial)
                      SizedBox(
                          height: screenH * 0.78, child: _buildCameraPreview()),
                    if (state is CatImageReady)
                      _buildImageWithAnalyzeSection(
                          isDark, state.imageFile, languageProvider, false),
                    if (state is CatAnalysisUploading ||
                        state is CatAnalysisAnalyzing)
                      _buildImageWithAnalyzeSection(
                          isDark, currentImage!, languageProvider, true),
                    if (state is CatAnalysisSuccess)
                      _buildResultSection(
                          isDark, state.catData, screenH, languageProvider),
                    if (state is CatDataUpdateSuccess)
                      _buildResultSection(
                          isDark, state.catData, screenH, languageProvider),
                    if (state is CatDataUpdating)
                      _buildResultSection(
                          isDark, state.catData, screenH, languageProvider),
                  ]),
                ),
              ),
              _buildBottomButtons(isDark, state, languageProvider),
            ]),
            if (isProcessing)
              _buildProcessingOverlay(currentImage, progress, progressLabel),
          ]);
        },
      ),
    );
  }

  // ─── widgets ───────────────────────────────────────────────
  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(fit: StackFit.expand, children: [
      CameraPreview(_cameraController!),
      CustomPaint(painter: _RectHolePainter(), size: Size.infinite),
      Positioned(
        top: 20,
        left: 24,
        right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(14)),
          child:
              const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.pets, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  'วางแมวจริง 1 ตัวให้อยู่ในกรอบ เห็นทั้งตัว แล้วกดถ่ายรูป',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),
      ),
      if (_isCapturing)
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

  Widget _buildProcessingOverlay(
      File? imageFile, double progress, String label) {
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
              builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
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
                child: imageFile != null
                    ? Image.file(imageFile, fit: BoxFit.cover)
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

  Widget _buildImageWithAnalyzeSection(bool isDark, File imageFile,
      LanguageProvider languageProvider, bool isProcessing) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          height: 300,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(imageFile,
                  fit: BoxFit.cover, width: double.infinity)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2)),
          child: Row(children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 2)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.file(imageFile, fit: BoxFit.cover)),
            ),
            const SizedBox(width: 16),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _buildInfoRow(
                      languageProvider.translate(
                          en: 'Cat color:', th: 'สีแมว:'),
                      'N/A',
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                      'N/A',
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Breed:', th: 'พันธุ์:'),
                      'N/A',
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Size:', th: 'ขนาด:'),
                      'N/A',
                      isDark),
                ])),
          ]),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Icon(Icons.info_outline,
                color: isDark ? Colors.orange[300] : Colors.orange[700],
                size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                languageProvider.translate(
                    en: 'Please ensure that the cat is clearly visible for accurate measurement.',
                    th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () =>
                      context.read<CatAnalysisBloc>().add(CatAnalysisStarted()),
              icon: isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.analytics),
              label: Text(
                isProcessing
                    ? languageProvider.translate(
                        en: 'Processing...', th: 'กำลังวิเคราะห์...')
                    : languageProvider.translate(
                        en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'),
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
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isProcessing ? null : _clearData,
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
      ]),
    );
  }

  Widget _buildResultSection(bool isDark, CatData catData, double screenH,
      LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 2)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 100,
              height: 120,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: catData.imageUrl.isNotEmpty
                    ? Image.network(catData.imageUrl,
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
                  _buildInfoRow(
                      languageProvider.translate(
                          en: 'Cat Color:', th: 'สีแมว:'),
                      catData.name,
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                      catData.age != null ? '${catData.age} years' : 'N/A',
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Breed:', th: 'พันธุ์:'),
                      catData.breed ?? 'N/A',
                      isDark),
                  const SizedBox(height: 10),
                  _buildInfoRow(
                      languageProvider.translate(en: 'Size:', th: 'ขนาด:'),
                      catData.sizeCategory,
                      isDark),
                ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: () => _showEditDialog(catData),
                icon: Icon(Icons.mode_edit_outline_outlined,
                    color: Colors.blue.shade700, size: 28),
              ),
              IconButton(
                onPressed: _confirmDeleteCat,
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade600, size: 28),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text(
            languageProvider.translate(
                en: 'Recommended Products', th: 'สินค้าแนะนำ'),
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        SizedBox(
          height: screenH * 0.50,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 5,
                mainAxisSpacing: 12,
                childAspectRatio: 0.86),
            itemCount: _recommendedProducts.length,
            itemBuilder: (context, index) =>
                _buildProductCard(_recommendedProducts[index], index, isDark),
          ),
        ),
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : Colors.black87)),
      const SizedBox(width: 8),
      Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black54))),
    ]);
  }

  Widget _buildProductCard(
      Map<String, dynamic> product, int index, bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: product['id']),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.5)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    color: isDark ? Colors.grey[800] : Colors.grey[200]),
                child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Image.network(product['imageUrl'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                            child: Icon(Icons.shopping_bag,
                                size: 40, color: Colors.grey[400])))),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () async {
                    if (isFav) {
                      await _favouriteApi.removeFromFavourite(
                          clothingUuid: product['id']);
                      _showSuccessMessage(languageProvider.translate(
                          en: 'Removed from favourites',
                          th: 'ลบออกจากรายการโปรดแล้ว'));
                    } else {
                      await _favouriteApi.addToFavourite(
                          clothingUuid: product['id']);
                      // ✅ RESTORED: แสดง Product Dialog เมื่อกดหัวใจเพิ่ม favorite
                      _showProductDialog(context, product, isDark);
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
                          size: 18)),
                ),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product['name'],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(
                        languageProvider.translate(
                            en: 'Price: ${product['price']}',
                            th: 'ราคา: ${product['price']}'),
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.orange[300]
                                : Colors.orange[700],
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _basketApi.addToBasket(
                                  clothingUuid: product['id']);
                              _showSuccessMessage(languageProvider.translate(
                                  en: 'Added to cart!',
                                  th: 'เพิ่มลงตะกร้าแล้ว!'));
                            } catch (e) {
                              _showError(languageProvider.translate(
                                  en: 'Failed to add to cart',
                                  th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: Text(
                              languageProvider.translate(en: 'Buy', th: 'ซื้อ'),
                              style: const TextStyle(fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () => _showInfoMessage(
                            languageProvider.translate(
                                en: 'Opening details...',
                                th: 'กำลังเปิดรายละเอียด...')),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            backgroundColor:
                                isDark ? Colors.grey[700] : Colors.grey[300],
                            foregroundColor:
                                isDark ? Colors.white : Colors.black87,
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: Text(
                            languageProvider.translate(
                                en: 'More', th: 'เพิ่มเติม'),
                            style: const TextStyle(fontSize: 11)),
                      ),
                    ]),
                  ]),
            ),
          ]),
        );
      },
    );
  }

  // ✅ RESTORED: hint text ใต้ปุ่มถ่าย/เลือกรูป (จากโค้ดเก่า)
  Widget _buildBottomButtons(
      bool isDark, CatAnalysisState state, LanguageProvider languageProvider) {
    if (state is! CatAnalysisInitial) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
          ]),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ RESTORED: hint text จากโค้ดเก่า
            Text(
              languageProvider.translate(
                  en: 'Take a photo: Place the cat in the center of the frame and see the whole body\nChoose a photo: Use JPEG files no larger than 500KB',
                  th: 'ถ่ายรูป: วางตัวแมวให้อยู่กลางกรอบ และเห็นทั้งตัว\nเลือกรูป: ใช้ไฟล์ JPEG ขนาดไม่เกิน 500KB'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureFromLiveCamera,
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
                        ? languageProvider.translate(
                            en: 'Detecting...', th: 'กำลังตรวจสอบ...')
                        : languageProvider.translate(
                            en: 'Take Photo', th: 'ถ่ายรูป'),
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                      languageProvider.translate(
                          en: 'Choose Photo', th: 'เลือกรูป'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
