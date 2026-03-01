import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_analysis/analysis_bloc.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_application_1/screen/history_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'dart:io';
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

// ═══════════════════════════════════════════════════════════
// MARK: - Config (ปรับ threshold ได้ในที่เดียว)
// ═══════════════════════════════════════════════════════════

class CatDetectorConfig {
  // 🐱 Cat Score
  static const double catScoreMin       = 0.45;
  static const double catScoreConfident = 0.65;
  static const double catScoreHigh      = 0.80; // bypass cartoon check

  // 🎨 Art/Cartoon
  static const double artScoreBlock  = 0.35;
  static const double artScoreWeak   = 0.25;
  static const double realAnimalMin  = 0.45;

  // 🐾 Non-Cat Animal
  static const double nonCatBlock = 0.45;
  static const double dogBlock    = 0.40;

  // 🐱🐱 Multi-Cat
  static const double regionCatMin = 0.60;
  static const double distRatio    = 0.30;
}

// ═══════════════════════════════════════════════════════════
// MARK: - Label Sets (Set → O(1) lookup)
// ═══════════════════════════════════════════════════════════

class CatLabels {
  static const Set<String> cat = {
    'cat', 'tabby', 'kitten', 'persian cat', 'siamese cat',
    'british shorthair', 'maine coon', 'bengal cat', 'ragdoll',
    'feline', 'domestic cat', 'house cat',
  };

  static const Set<String> dog = {
    'dog', 'puppy', 'canine', 'hound', 'labrador', 'poodle', 'bulldog',
    'beagle', 'husky', 'golden retriever', 'german shepherd', 'dachshund',
    'chihuahua', 'pomeranian', 'corgi', 'shih tzu', 'pug',
    'french bulldog', 'boston terrier', 'boxer', 'rottweiler', 'doberman',
    'dalmatian', 'schnauzer', 'maltese', 'yorkshire terrier', 'samoyed',
    'akita', 'shar pei', 'chow chow', 'spitz', 'basenji', 'whippet',
    'greyhound', 'mastiff', 'bichon',
  };

  static const Set<String> artStrong = {
    'cartoon', 'anime', 'illustration', 'animated cartoon', 'comic',
    'manga', 'clipart', 'vector', 'digital art', 'drawing', 'sketch',
    '3d render', 'cgi', 'computer graphics', 'low poly', 'pixel art',
    'animation', 'fictional character',
  };

  static const Set<String> artWeak = {
    'art', 'artwork', 'graphic', 'painting', 'poster', 'figure',
    'figurine', 'toy', 'stuffed animal', 'plush', 'statue', 'sculpture',
    'origami', 'papercraft', 'paper craft', 'paper model', 'paper art',
    'model', 'miniature', 'replica', 'doll', 'puppet', 'mannequin',
    'ceramic', 'porcelain', 'clay', 'plastic', 'wood carving',
    '3d model', 'render', 'craft', 'handmade', 'artifact',
    'decorative', 'low poly', 'polygon', 'geometric', 'object', 'prop',
  };

  static const Set<String> realAnimal = {
    'fur', 'whisker', 'mammal', 'wildlife', 'fauna', 'paw', 'animal',
    'pet', 'domestic animal', 'nose', 'claw', 'tail', 'coat', 'hair',
    'living', 'vertebrate', 'carnivore', 'snout', 'eye',
  };

  static const Set<String> nonCat = {
    'otter', 'sea otter', 'river otter', 'mink', 'ferret', 'weasel',
    'marten', 'beaver', 'badger', 'skunk', 'seal', 'sea lion', 'walrus',
    'dolphin', 'whale', 'shark', 'octopus', 'crab', 'lobster', 'fish',
    'fox', 'wolf', 'bear', 'panda', 'raccoon', 'squirrel', 'rabbit',
    'hare', 'hamster', 'guinea pig', 'gerbil', 'rat', 'mouse',
    'hedgehog', 'meerkat', 'mongoose', 'capybara', 'monkey', 'ape',
    'chimpanzee', 'gorilla', 'lemur', 'koala', 'kangaroo', 'deer',
    'elk', 'reindeer', 'moose', 'alpaca', 'llama', 'sheep', 'goat',
    'cow', 'horse', 'pig', 'bird', 'parrot', 'owl', 'eagle', 'chicken',
    'duck', 'tiger', 'lion', 'cheetah', 'leopard', 'jaguar', 'lynx',
    'bobcat', 'cougar', 'panther', 'snake', 'lizard', 'turtle', 'frog',
    'gecko', 'iguana', 'chameleon', 'crocodile', 'alligator', 'reptile',
    'dinosaur', 'dragon', 'spider', 'insect', 'scorpion',
  };
}

// ═══════════════════════════════════════════════════════════
// MARK: - Detection Result Model
// ═══════════════════════════════════════════════════════════

class DetectionResult {
  final bool   isCat;
  final String reason;
  final double catScore;
  final bool   isCartoon;
  final String detail;

  const DetectionResult({
    required this.isCat,
    required this.reason,
    required this.catScore,
    required this.isCartoon,
    this.detail = '',
  });
}

class _CartoonCheckResult {
  final bool   isCartoon;
  final double confidence;
  const _CartoonCheckResult({required this.isCartoon, required this.confidence});
}

// ═══════════════════════════════════════════════════════════
// MARK: - Cartoon Check (ปรับปรุง: รองรับแมวขนฟู)
// ═══════════════════════════════════════════════════════════

Future<_CartoonCheckResult> _cartoonCheck(String imagePath) async {
  try {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return const _CartoonCheckResult(isCartoon: false, confidence: 0);

    final small = img.copyResize(image, width: 120, height: 120);
    final int total = small.width * small.height;

    // ── 1. Color diversity
    final Set<int> uniqueColors = {};
    for (int y = 0; y < small.height; y++) {
      for (int x = 0; x < small.width; x++) {
        final p = small.getPixel(x, y);
        uniqueColors.add(((p.r ~/ 32) << 16) | ((p.g ~/ 32) << 8) | (p.b ~/ 32));
      }
    }
    final double colorDiversity = uniqueColors.length / total;

    // ── 2. Edge sharpness + soft gradient (ขนแมว)
    int sharpEdges = 0, softEdges = 0, checked = 0;
    final List<double> gradients = [];
    for (int y = 1; y < small.height - 1; y++) {
      for (int x = 1; x < small.width - 1; x++) {
        final c  = small.getPixel(x, y);
        final r  = small.getPixel(x + 1, y);
        final d  = small.getPixel(x, y + 1);
        final dx = ((c.r - r.r).abs() + (c.g - r.g).abs() + (c.b - r.b).abs()) / 3;
        final dy = ((c.r - d.r).abs() + (c.g - d.g).abs() + (c.b - d.b).abs()) / 3;
        final grad = sqrt(dx * dx + dy * dy);
        gradients.add(grad);
        if (grad > 60) sharpEdges++;
        if (grad > 10 && grad < 40) softEdges++; // soft = ขนแมวจริง
        checked++;
      }
    }
    final double sharpRatio = checked > 0 ? sharpEdges / checked : 0;
    final double softRatio  = checked > 0 ? softEdges  / checked : 0;

    // ── 3. Gradient variance
    final double avgGrad = gradients.isEmpty ? 0 : gradients.reduce((a, b) => a + b) / gradients.length;
    final double gradVariance = gradients.isEmpty
        ? 0
        : gradients.fold(0.0, (s, g) => s + pow(g - avgGrad, 2)) / gradients.length;

    // ── 4. Saturation
    double totalSat = 0;
    final List<double> satList = [];
    for (int y = 0; y < small.height; y++) {
      for (int x = 0; x < small.width; x++) {
        final p = small.getPixel(x, y);
        final rv = p.r / 255.0, gv = p.g / 255.0, bv = p.b / 255.0;
        final maxC = [rv, gv, bv].reduce(max);
        final minC = [rv, gv, bv].reduce(min);
        final sat = maxC > 0 ? (maxC - minC) / maxC : 0.0;
        satList.add(sat);
        totalSat += sat;
      }
    }
    final double avgSat = satList.isEmpty ? 0 : totalSat / satList.length;
    final double satVariance = satList.isEmpty
        ? 0
        : satList.fold(0.0, (s, v) => s + pow(v - avgSat, 2)) / satList.length;

    // ── 5. คะแนน cartoon signals
    int signals = 0;

    // สัญญาณการ์ตูน
    if (colorDiversity < 0.08)  signals += 3;
    if (colorDiversity < 0.12)  signals += 2;
    if (colorDiversity < 0.18)  signals += 1;
    if (satVariance < 0.010)    signals += 3;
    if (satVariance < 0.020)    signals += 2;
    if (satVariance < 0.035)    signals += 1;
    if (gradVariance < 200)     signals += 2;
    if (gradVariance < 400)     signals += 1;
    if (sharpRatio > 0.18 && colorDiversity < 0.15) signals += 2;

    // สัญญาณภาพจริง (หักแต้ม)
    if (softRatio > 0.25)      signals -= 2; // ขนแมว
    if (gradVariance > 800)    signals -= 2; // texture ซับซ้อน
    if (colorDiversity > 0.25) signals -= 2; // สีหลากหลาย
    if (avgSat > 0.20 && satVariance > 0.04) signals -= 1;

    signals = signals.clamp(0, 99);

    // threshold >= 5 (เดิม 3 → เข้มขึ้น ลด false reject แมวขนฟู)
    return _CartoonCheckResult(
      isCartoon: signals >= 5,
      confidence: (signals / 10.0).clamp(0.0, 1.0),
    );
  } catch (_) {
    return const _CartoonCheckResult(isCartoon: false, confidence: 0);
  }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Multi-Cat Detection (ปรับปรุง: 9 region + diagonal dist)
// ═══════════════════════════════════════════════════════════

Future<bool> _hasMultipleCats(
  String imagePath,
  ImageLabeler labeler, {
  bool Function()? isDisposed,
}) async {
  if (isDisposed?.call() ?? false) return false;
  try {
    final bytes = await File(imagePath).readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return false;

    final tempDir = await getTemporaryDirectory();
    final int w = image.width, h = image.height;

    // 3×3 grid + overlap 35%
    final int cols = 3, rows = 3;
    final int rw = (w / cols).round();
    final int rh = (h / rows).round();
    final int ov = (rw * 0.35).round();

    final List<Map<String, int>> regions = [];
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final int x    = max(0, col * rw - ov);
        final int y    = max(0, row * rh - ov);
        final int endX = min(w, (col + 1) * rw + ov);
        final int endY = min(h, (row + 1) * rh + ov);
        regions.add({'x': x, 'y': y, 'w': endX - x, 'h': endY - y});
      }
    }

    final List<Map<String, double>> catCentroids = [];

    for (int i = 0; i < regions.length; i++) {
      if (isDisposed?.call() ?? false) return false;
      final r = regions[i];

      final cropped = img.copyCrop(image,
          x: r['x']!, y: r['y']!, width: r['w']!, height: r['h']!);
      final regionFile = File(
          '${tempDir.path}/mc_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await regionFile.writeAsBytes(img.encodeJpg(cropped, quality: 70));

      try {
        final labels = await labeler.processImage(
            InputImage.fromFilePath(regionFile.path));

        double regionCatScore = 0.0;
        for (final label in labels) {
          final text = label.label.toLowerCase();
          for (final l in CatLabels.cat) {
            if (text.contains(l) && label.confidence > regionCatScore) {
              regionCatScore = label.confidence;
            }
          }
        }

        if (regionCatScore >= CatDetectorConfig.regionCatMin) {
          catCentroids.add({
            'score': regionCatScore,
            'cx': (r['x']! + r['w']! / 2).toDouble(),
            'cy': (r['y']! + r['h']! / 2).toDouble(),
          });
        }
      } catch (e) {
        print('❌ Region $i error: $e');
      } finally {
        try { regionFile.deleteSync(); } catch (_) {}
      }
    }

    if (catCentroids.length < 2) return false;

    // วัดระยะจาก diagonal ของภาพ (แม่นกว่า width/height เฉลี่ย)
    final double diagonal = sqrt(w * w.toDouble() + h * h.toDouble());
    final double distThreshold = diagonal * CatDetectorConfig.distRatio;

    for (int i = 0; i < catCentroids.length; i++) {
      for (int j = i + 1; j < catCentroids.length; j++) {
        final dx = catCentroids[i]['cx']! - catCentroids[j]['cx']!;
        final dy = catCentroids[i]['cy']! - catCentroids[j]['cy']!;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist > distThreshold) {
          print('🐱🐱 Multi-cat: dist=${dist.toStringAsFixed(1)} > threshold=${distThreshold.toStringAsFixed(1)}');
          return true;
        }
      }
    }
    return false;
  } catch (e) {
    print('❌ hasMultipleCats error: $e');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Main Detector (9-step logic flow)
// ═══════════════════════════════════════════════════════════

Future<DetectionResult> _detectCatPro(
  String imagePath,
  ImageLabeler labeler, {
  bool Function()? isDisposed,
}) async {
  const disposed = DetectionResult(isCat: false, reason: 'disposed', catScore: 0, isCartoon: false);
  if (isDisposed?.call() ?? false) return disposed;

  try {
    final labels = await labeler.processImage(InputImage.fromFilePath(imagePath));
    if (isDisposed?.call() ?? false) return disposed;

    // ── รวบรวม scores
    double catScore = 0, dogScore = 0;
    double artStrongScore = 0, artWeakScore = 0;
    double realAnimalScore = 0, nonCatScore = 0;
    String nonCatName = '';

    for (final label in labels) {
      final text = label.label.toLowerCase();
      final conf = label.confidence;
      print('🏷️ ${label.label}: ${conf.toStringAsFixed(2)}');

      for (final l in CatLabels.cat)       { if (text.contains(l) && conf > catScore)        catScore        = conf; }
      for (final l in CatLabels.dog)       { if (text.contains(l) && conf > dogScore)         dogScore        = conf; }
      for (final l in CatLabels.artStrong) { if (text.contains(l) && conf > artStrongScore)   artStrongScore  = conf; }
      for (final l in CatLabels.artWeak)   { if (text.contains(l) && conf > artWeakScore)     artWeakScore    = conf; }
      for (final l in CatLabels.realAnimal){ if (text.contains(l) && conf > realAnimalScore)  realAnimalScore = conf; }
      for (final l in CatLabels.nonCat)    {
        if (text.contains(l) && conf > nonCatScore) {
          nonCatScore = conf;
          nonCatName  = label.label;
        }
      }
    }

    // STEP 1: ❌ หมา
    if (dogScore >= CatDetectorConfig.dogBlock) {
      return DetectionResult(isCat: false, reason: 'is_dog',
          catScore: catScore, isCartoon: false,
          detail: 'dog=$dogScore');
    }

    // STEP 2: ❌ Cat score ต่ำเกินไป
    if (catScore < CatDetectorConfig.catScoreMin) {
      return DetectionResult(isCat: false, reason: 'cat_score_too_low',
          catScore: catScore, isCartoon: false,
          detail: 'cat=$catScore < min=${CatDetectorConfig.catScoreMin}');
    }

    // STEP 3: ❌ Art strong signal (ยกเว้น catScore สูงมาก + real animal ชัด)
    if (artStrongScore >= CatDetectorConfig.artScoreBlock) {
      final bool bypass = catScore  >= CatDetectorConfig.catScoreHigh &&
                          realAnimalScore >= CatDetectorConfig.realAnimalMin;
      if (!bypass) {
        return DetectionResult(isCat: false, reason: 'art_strong',
            catScore: catScore, isCartoon: true,
            detail: 'artStrong=$artStrongScore');
      }
    }

    // STEP 4: 🎨 Cartoon texture check (เฉพาะเมื่อ catScore ไม่สูงหรือมี art weak)
    _CartoonCheckResult? cartoonResult;
    if (catScore < CatDetectorConfig.catScoreHigh ||
        artWeakScore >= CatDetectorConfig.artScoreWeak) {
      cartoonResult = await _cartoonCheck(imagePath);
      if (isDisposed?.call() ?? false) return disposed;

      if (cartoonResult.isCartoon && catScore < CatDetectorConfig.catScoreHigh) {
        return DetectionResult(isCat: false, reason: 'cartoon_texture',
            catScore: catScore, isCartoon: true,
            detail: 'conf=${cartoonResult.confidence.toStringAsFixed(2)}');
      }
    }

    // STEP 5: ❌ Real animal signal ต่ำ (ยกเว้น catScore สูงมาก)
    if (catScore < CatDetectorConfig.catScoreHigh) {
      final double adjustedReal = dogScore >= 0.25
          ? realAnimalScore * (1.0 - dogScore * 0.5)
          : realAnimalScore;
      if (adjustedReal < CatDetectorConfig.realAnimalMin) {
        return DetectionResult(isCat: false, reason: 'no_real_animal_signal',
            catScore: catScore, isCartoon: cartoonResult?.isCartoon ?? false,
            detail: 'adjustedReal=$adjustedReal');
      }
    }

    // STEP 6: ❌ Non-cat animal
    if (nonCatScore >= CatDetectorConfig.nonCatBlock) {
      return DetectionResult(isCat: false, reason: 'non_cat_animal:$nonCatName',
          catScore: catScore, isCartoon: false,
          detail: '$nonCatName=$nonCatScore');
    }

    // STEP 7: ❌ Cat vs Dog ambiguous
    if (dogScore > 0.15 && (catScore - dogScore) < 0.20) {
      return DetectionResult(isCat: false, reason: 'ambiguous_cat_dog',
          catScore: catScore, isCartoon: false,
          detail: 'cat=$catScore dog=$dogScore diff=${(catScore - dogScore).toStringAsFixed(2)}');
    }

    // STEP 8: ❌ Cat score ยังไม่มั่นใจพอ
    if (catScore < CatDetectorConfig.catScoreConfident) {
      return DetectionResult(isCat: false, reason: 'cat_score_low',
          catScore: catScore, isCartoon: cartoonResult?.isCartoon ?? false,
          detail: 'cat=$catScore < confident=${CatDetectorConfig.catScoreConfident}');
    }

    // STEP 9: 🐱🐱 Multi-cat (ทำสุดท้ายเพราะช้าสุด)
    final bool multiCat = await _hasMultipleCats(imagePath, labeler, isDisposed: isDisposed);
    if (isDisposed?.call() ?? false) return disposed;
    if (multiCat) {
      return DetectionResult(isCat: false, reason: 'multiple_cats',
          catScore: catScore, isCartoon: false);
    }

    // ✅ ผ่านทุก step
    return DetectionResult(isCat: true, reason: 'passed',
        catScore: catScore, isCartoon: false,
        detail: 'real=$realAnimalScore');

  } catch (e) {
    return DetectionResult(isCat: false, reason: 'error',
        catScore: 0, isCartoon: false, detail: e.toString());
  }
}

// ═══════════════════════════════════════════════════════════
// MARK: - Camera Overlay Painter
// ═══════════════════════════════════════════════════════════

class _RectHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double rectW = size.width * 0.80;
    final double rectH = size.height * 0.55;
    final double left  = (size.width  - rectW) / 2;
    final double top   = (size.height - rectH) / 2;

    final rrect = RRect.fromLTRBR(
        left, top, left + rectW, top + rectH, const Radius.circular(20));
    final cutPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
      Path()..addRRect(rrect),
    );
    canvas.drawPath(cutPath, Paint()..color = Colors.black.withOpacity(0.55));
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.5));

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    const double cLen = 28.0, r = 20.0;

    // มุมกรอบ 4 มุม
    canvas.drawLine(Offset(left + r, top),          Offset(left + r + cLen, top),          accentPaint);
    canvas.drawLine(Offset(left, top + r),           Offset(left, top + r + cLen),           accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top),   Offset(left + rectW - r - cLen, top),   accentPaint);
    canvas.drawLine(Offset(left + rectW, top + r),   Offset(left + rectW, top + r + cLen),   accentPaint);
    canvas.drawLine(Offset(left + r, top + rectH),   Offset(left + r + cLen, top + rectH),   accentPaint);
    canvas.drawLine(Offset(left, top + rectH - r),   Offset(left, top + rectH - r - cLen),   accentPaint);
    canvas.drawLine(Offset(left + rectW - r, top + rectH), Offset(left + rectW - r - cLen, top + rectH), accentPaint);
    canvas.drawLine(Offset(left + rectW, top + rectH - r), Offset(left + rectW, top + rectH - r - cLen), accentPaint);
  }

  @override
  bool shouldRepaint(covariant _RectHolePainter old) => false;
}

// ═══════════════════════════════════════════════════════════
// MARK: - CatData Model
// ═══════════════════════════════════════════════════════════

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

  factory CatData.fromJson(Map<String, dynamic> json) => CatData(
        name:         json['name'],
        breed:        json['breed'],
        age:          json['age'],
        weight:       (json['weight'] as num).toDouble(),
        sizeCategory: json['size_category'],
        chestCm:      (json['chest_cm'] as num).toDouble(),
        neckCm:       json['neck_cm'] != null ? (json['neck_cm'] as num).toDouble() : null,
        bodyLengthCm: json['body_length_cm'] != null ? (json['body_length_cm'] as num).toDouble() : null,
        confidence:   (json['confidence'] as num).toDouble(),
        boundingBox:  List<double>.from(json['bounding_box'].map((e) => (e as num).toDouble())),
        imageUrl:     json['image_cat'] ?? json['image_url'] ?? '',
        thumbnailUrl: json['thumbnail_url'],
        detectedAt:   DateTime.parse(json['detected_at']),
        dbId:         json['db_id'],
      );
}

// ═══════════════════════════════════════════════════════════
// MARK: - Widget Entry Point
// ═══════════════════════════════════════════════════════════

class MeasureSizeCat extends StatelessWidget {
  const MeasureSizeCat({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CatAnalysisBloc(),
        child: const _MeasureSizeCatView(),
      );
}

class _MeasureSizeCatView extends StatefulWidget {
  const _MeasureSizeCatView();
  @override
  State<_MeasureSizeCatView> createState() => _MeasureSizeCatState();
}

// ═══════════════════════════════════════════════════════════
// MARK: - State
// ═══════════════════════════════════════════════════════════

class _MeasureSizeCatState extends State<_MeasureSizeCatView> {
  final ImagePicker        _picker       = ImagePicker();
  final FavouriteApiService _favouriteApi = FavouriteApiService();
  final BasketApiService    _basketApi    = BasketApiService();

  bool              _isCapturing = false;
  bool              _isDisposed  = false;
  CameraController? _cameraController;
  late ImageLabeler _imageLabeler;

  @override
  void initState() {
    super.initState();
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
    _imageLabeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: 0.45));
  }

  void _initCamera() async {
    if (!mounted || _isDisposed) return;
    try {
      final cameras = await availableCameras();
      if (!mounted || _isDisposed) return;
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      await _cameraController?.dispose();
      _cameraController = null;
      if (!mounted || _isDisposed) return;
      _cameraController =
          CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _cameraController!.initialize();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      if (mounted && !_isDisposed) _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  // ─── Image helpers ───────────────────────────────────────

  Future<File?> _cropToRectArea(String imagePath) async {
    try {
      final bytes = await File(imagePath).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      final int cropX = ((image.width  * 0.10)).toInt().clamp(0, image.width);
      final int cropY = ((image.height * 0.225)).toInt().clamp(0, image.height);
      final int cropW = (image.width  * 0.80).toInt().clamp(1, image.width  - cropX);
      final int cropH = (image.height * 0.55).toInt().clamp(1, image.height - cropY);
      final cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
      final tempDir = await getTemporaryDirectory();
      final f = File('${tempDir.path}/cat_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return f;
    } catch (_) { return null; }
  }

  Future<File?> _compressImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) return null;
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return null;
      const maxSize = 1920;
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(image,
            width:  image.width  > image.height ? maxSize : null,
            height: image.height > image.width  ? maxSize : null);
      }
      final tempDir = await getTemporaryDirectory();
      final f = File('${tempDir.path}/cat_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(image, quality: 92));
      return f;
    } catch (_) { return null; }
  }

  // ─── Capture / Pick ──────────────────────────────────────

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
      if (!mounted || _isDisposed) { croppedFile?.delete(); File(photo.path).delete(); return; }

      final result = await _detectCatPro(
        croppedFile?.path ?? photo.path,
        _imageLabeler,
        isDisposed: () => _isDisposed,
      );
      try { croppedFile?.delete(); } catch (_) {}
      if (!mounted || _isDisposed) { File(photo.path).delete(); return; }

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        try { File(photo.path).delete(); } catch (_) {}
        _showRejectDialog(result);
        return;
      }

      final processed = await _compressImage(File(photo.path));
      try { File(photo.path).delete(); } catch (_) {}
      if (!mounted || _isDisposed) return;

      await ctrl.dispose();
      if (mounted && !_isDisposed) {
        setState(() { _cameraController = null; _isCapturing = false; });
        if (processed != null) {
          context.read<CatAnalysisBloc>().add(CatImageSelected(processed));
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
          source: ImageSource.gallery, imageQuality: 95,
          maxWidth: 1920, maxHeight: 1920);
      if (image == null) return;
      if (!mounted || _isDisposed) return;

      setState(() => _isCapturing = true);

      final result = await _detectCatPro(
        image.path,
        _imageLabeler,
        isDisposed: () => _isDisposed,
      );
      if (!mounted || _isDisposed) return;

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        _showRejectDialog(result);
        return;
      }

      final processed = await _compressImage(File(image.path));
      if (!mounted || _isDisposed) return;

      if (processed != null) {
        await _cameraController?.dispose();
        _cameraController = null;
        if (mounted && !_isDisposed) {
          setState(() => _isCapturing = false);
          context.read<CatAnalysisBloc>().add(CatImageSelected(processed));
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

  void _clearData() {
    if (!mounted || _isDisposed) return;
    context.read<CatAnalysisBloc>().add(CatAnalysisReset());
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  // ─── Dialogs ─────────────────────────────────────────────

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
          const Icon(Icons.hourglass_bottom_rounded, size: 64, color: Colors.orange),
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
              style: TextStyle(fontSize: 14, color: Colors.orange.shade800, height: 1.5),
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

  void _showRejectDialog(DetectionResult result) {
    if (!mounted || _isDisposed) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String title, reason;
    IconData icon;
    Color iconColor;

    if (result.reason == 'multiple_cats') {
      title = '🐱🐱 ตรวจพบแมวหลายตัว';
      reason = 'ระบบตรวจพบแมวมากกว่า 1 ตัวในภาพ\nกรุณาถ่ายรูปแมวทีละตัวเท่านั้น';
      icon = Icons.pets; iconColor = Colors.purple;
    } else if (result.isCartoon || result.reason == 'art_strong' || result.reason == 'cartoon_texture') {
      title = '🎨 ตรวจพบภาพที่ไม่ใช่แมวจริง';
      reason = 'ระบบตรวจพบว่าเป็นภาพการ์ตูน, รูปวาด, โมเดล, ของปั้น หรือ origami';
      icon = Icons.draw_outlined; iconColor = Colors.orange;
    } else if (result.reason.startsWith('non_cat_animal:')) {
      final animalName = result.reason.split(':').last;
      title = '🚫 ตรวจพบสัตว์อื่น';
      reason = 'ระบบตรวจพบ "$animalName" ในภาพ\nฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
      icon = Icons.pets; iconColor = Colors.deepOrange;
    } else if (result.reason == 'is_dog' || result.reason == 'ambiguous_cat_dog') {
      title = '🐶 ตรวจพบสุนัข';
      reason = 'ภาพมีลักษณะคล้ายสุนัขมากกว่าแมว';
      icon = Icons.pets; iconColor = Colors.brown;
    } else {
      title = '😿 ไม่พบแมวในภาพ';
      reason = 'ไม่สามารถตรวจพบแมวในภาพได้\nลองปรับมุมกล้อง ให้เห็นแมวชัดเจนยิ่งขึ้น';
      icon = Icons.search_off; iconColor = Colors.grey;
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
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
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
          ),
        ],
      ),
    );
  }

  void _showProductDialog(BuildContext context, Map<String, dynamic> product, bool isDark) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final String uuid         = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final String name         = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final String imageUrl     = product['image_url'] ?? product['imageUrl'] ?? '';
    final double price        = (product['price'] as num?)?.toDouble() ?? 0.0;
    final double? discPrice   = (product['discount_price'] as num?)?.toDouble();
    final String priceDisplay = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0 ? '฿${price.toStringAsFixed(0)}' : '${product['price'] ?? ''}';

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
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const SizedBox(width: 32),
              Text(lang.translate(en: 'Added to Favorites', th: 'เพิ่มในรายการโปรด'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54, size: 24),
                onPressed: () => Navigator.pop(ctx),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              height: 220, width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.grey[800] : Colors.grey[200],
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: double.infinity, height: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(child: Icon(Icons.shopping_bag, size: 60, color: Colors.grey[400])))
                      : Center(child: Icon(Icons.shopping_bag, size: 60, color: Colors.grey[400])),
                ),
                Positioned(top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.favorite, color: Colors.red, size: 26),
                  )),
              ]),
            ),
            const SizedBox(height: 20),
            Text(name, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87),
                textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(lang.translate(en: 'Price: $priceDisplay', th: 'ราคา: $priceDisplay'),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
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
                      _showSuccessMessage(lang.translate(en: 'Added to cart!', th: 'เพิ่มลงตะกร้าแล้ว!'));
                    } catch (_) {
                      _showError(lang.translate(en: 'Failed to add to cart', th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang.translate(en: 'Buy', th: 'ซื้อ'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showInfoMessage(lang.translate(en: 'Opening details...', th: 'กำลังเปิดรายละเอียด...'));
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                      foregroundColor: isDark ? Colors.white : Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text(lang.translate(en: 'More', th: 'เพิ่มเติม'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(CatData catData) async {
    final colorCtrl = TextEditingController(text: catData.name);
    final breedCtrl = TextEditingController(text: catData.breed ?? '');
    final ageCtrl   = TextEditingController(text: catData.age?.toString() ?? '');
    String selectedSize = catData.sizeCategory;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx2, setModal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10)))),
              const Text('✏️ แก้ไขข้อมูลแมว',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: colorCtrl,
                  decoration: const InputDecoration(labelText: 'สีแมว / Cat Color', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: breedCtrl,
                  decoration: const InputDecoration(labelText: 'พันธุ์ / Breed', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: ageCtrl, keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'อายุ (ปี)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text('ขนาด', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['XS', 'S', 'M', 'L', 'XL'].map((size) {
                  final selected = selectedSize == size;
                  return GestureDetector(
                    onTap: () => setModal(() => selectedSize = size),
                    child: Container(
                      width: 52, height: 40, alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: selected ? Colors.orange : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(size, style: TextStyle(fontWeight: FontWeight.bold,
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
                      backgroundColor: Colors.orange, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('บันทึก', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (result != true) return;
    final updateData = <String, dynamic>{
      'cat_color': colorCtrl.text.trim().isNotEmpty ? colorCtrl.text.trim() : catData.name,
      'size_category': selectedSize,
      if (breedCtrl.text.trim().isNotEmpty) 'breed': breedCtrl.text.trim(),
      if (ageCtrl.text.trim().isNotEmpty) 'age': int.tryParse(ageCtrl.text.trim()),
    };
    if (mounted) context.read<CatAnalysisBloc>().add(CatDataUpdated(updateData));
  }

  Future<void> _confirmDeleteCat() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ยืนยันการลบ'),
        content: const Text('ต้องการลบข้อมูลแมวนี้ใช่หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('ลบ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (mounted) context.read<CatAnalysisBloc>().add(CatDataDeleted());
  }

  // ─── Snackbars ───────────────────────────────────────────

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

  // ─── Build ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeProvider    = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark  = themeProvider.themeMode == ThemeMode.dark;
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
          languageProvider.translate(en: 'MEOW SIZE', th: 'วัดขนาดตัวแมว'),
          style: TextStyle(fontFamily: 'catFont', fontSize: 30,
              fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryPage())),
            tooltip: 'ประวัติการวัด',
          ),
        ],
      ),
      body: BlocConsumer<CatAnalysisBloc, CatAnalysisState>(
        listener: (context, state) {
          if (state is CatAnalysisQuotaExceeded) _showQuotaDialog();
          if (state is CatAnalysisNotFound)  _showError('😿 ${state.message}');
          if (state is CatAnalysisSuccess)   _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
          if (state is CatDataUpdateSuccess) _showSuccessMessage(state.message);
          if (state is CatAnalysisFailure)   _showError(state.error);
          if (state is CatAnalysisInitial)   _initCamera();
        },
        builder: (context, state) {
          File? currentImage;
          if (state is CatImageReady)        currentImage = state.imageFile;
          if (state is CatAnalysisUploading) currentImage = state.imageFile;
          if (state is CatAnalysisAnalyzing) currentImage = state.imageFile;

          final isProcessing  = state is CatAnalysisUploading || state is CatAnalysisAnalyzing;
          final progress      = state is CatAnalysisUploading ? 0.3 : (state is CatAnalysisAnalyzing ? 0.7 : 0.0);
          final progressLabel = state is CatAnalysisUploading ? 'Uploading image...' : 'Analyzing cat...';

          return Stack(children: [
            Column(children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: state is CatAnalysisInitial
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Column(children: [
                    if (state is CatAnalysisInitial)
                      SizedBox(height: screenH * 0.78, child: _buildCameraPreview()),
                    if (state is CatImageReady)
                      _buildImageWithAnalyzeSection(isDark, state.imageFile, languageProvider, false),
                    if (state is CatAnalysisUploading || state is CatAnalysisAnalyzing)
                      _buildImageWithAnalyzeSection(isDark, currentImage!, languageProvider, true),
                    if (state is CatAnalysisSuccess)
                      _buildResultSection(isDark, state.catData, screenH, languageProvider, state.recommendations),
                    if (state is CatDataUpdateSuccess)
                      _buildResultSection(isDark, state.catData, screenH, languageProvider, state.recommendations),
                    if (state is CatDataUpdating)
                      _buildResultSection(isDark, state.catData, screenH, languageProvider, state.recommendations),
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

  // ─── Widgets ─────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(fit: StackFit.expand, children: [
      CameraPreview(_cameraController!),
      CustomPaint(painter: _RectHolePainter(), size: Size.infinite),
      Positioned(
        top: 20, left: 24, right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(14)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.pets, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text('วางแมวจริง 1 ตัวให้อยู่ในกรอบ เห็นทั้งตัว แล้วกดถ่ายรูป',
                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ),
          ]),
        ),
      ),
      if (_isCapturing)
        Container(
          color: Colors.black54,
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('🔍 กำลังตรวจจับแมว...',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('กรุณารอสักครู่', style: TextStyle(color: Colors.white70, fontSize: 13)),
          ])),
        ),
    ]);
  }

  Widget _buildProcessingOverlay(File? imageFile, double progress, String label) {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 190, height: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, _) => CircularProgressIndicator(
                  value: value, strokeWidth: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange)),
            ),
          ),
          Container(
            width: 145, height: 145,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: ClipOval(child: imageFile != null
                ? Image.file(imageFile, fit: BoxFit.cover)
                : const Icon(Icons.pets, size: 60)),
          ),
        ]),
        const SizedBox(height: 20),
        Text('${(progress * 100).toInt()}%',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ])),
    );
  }

  Widget _buildImageWithAnalyzeSection(
      bool isDark, File imageFile, LanguageProvider lang, bool isProcessing) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          height: 300,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))]),
          child: ClipRRect(borderRadius: BorderRadius.circular(16),
              child: Image.file(imageFile, fit: BoxFit.cover, width: double.infinity)),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
          child: Row(children: [
            Container(
              width: 100, height: 120,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
              child: ClipRRect(borderRadius: BorderRadius.circular(10),
                  child: Image.file(imageFile, fit: BoxFit.cover)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildInfoRow(lang.translate(en: 'Cat color:', th: 'สีแมว:'), 'N/A', isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Age:', th: 'อายุ:'), 'N/A', isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Breed:', th: 'พันธุ์:'), 'N/A', isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Size:', th: 'ขนาด:'), 'N/A', isDark),
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
                color: isDark ? Colors.orange[300] : Colors.orange[700], size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(
              lang.translate(
                  en: 'Please ensure that the cat is clearly visible for accurate measurement.',
                  th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
            )),
          ]),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => context.read<CatAnalysisBloc>().add(CatAnalysisStarted()),
              icon: isProcessing
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Icon(Icons.analytics),
              label: Text(
                isProcessing
                    ? lang.translate(en: 'Processing...', th: 'กำลังวิเคราะห์...')
                    : lang.translate(en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange, foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[400],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: isProcessing ? null : _clearData,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                backgroundColor: Colors.red, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Icon(Icons.close, size: 24),
          ),
        ]),
      ]),
    );
  }

  Widget _buildResultSection(bool isDark, CatData catData, double screenH,
      LanguageProvider lang, List<Map<String, dynamic>> recommendations) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 100, height: 120,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: catData.imageUrl.isNotEmpty
                    ? Image.network(catData.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(Icons.broken_image, size: 40, color: Colors.grey[400]))
                    : Icon(Icons.pets, size: 40, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildInfoRow(lang.translate(en: 'Cat Color:', th: 'สีแมว:'), catData.name, isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Age:', th: 'อายุ:'),
                  catData.age != null ? '${catData.age} years' : 'N/A', isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Breed:', th: 'พันธุ์:'), catData.breed ?? 'N/A', isDark),
              const SizedBox(height: 10),
              _buildInfoRow(lang.translate(en: 'Size:', th: 'ขนาด:'), catData.sizeCategory, isDark),
            ])),
            Column(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                onPressed: () => _showEditDialog(catData),
                icon: Icon(Icons.mode_edit_outline_outlined, color: Colors.blue.shade700, size: 28),
              ),
              IconButton(
                onPressed: _confirmDeleteCat,
                icon: Icon(Icons.delete_outline, color: Colors.red.shade600, size: 28),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        Text(lang.translate(en: 'Recommended Products', th: 'สินค้าแนะนำ'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(lang.translate(en: 'No matching products found', th: 'ไม่พบสินค้าที่เหมาะสม'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ]),
          )
        else
          SizedBox(
            height: screenH * 0.50,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 5, mainAxisSpacing: 12, childAspectRatio: 0.86),
              itemCount: recommendations.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(recommendations[index], index, isDark),
            ),
          ),
      ]),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
          color: isDark ? Colors.white70 : Colors.black87)),
      const SizedBox(width: 8),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 16, color: isDark ? Colors.white60 : Colors.black54))),
    ]);
  }

  Widget _buildProductCard(Map<String, dynamic> product, int index, bool isDark) {
    final lang = Provider.of<LanguageProvider>(context);
    final String uuid          = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final String name          = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final String imageUrl      = product['image_url'] ?? product['imageUrl'] ?? '';
    final double price         = (product['price'] as num?)?.toDouble() ?? 0.0;
    final double? discPrice    = (product['discount_price'] as num?)?.toDouble();
    final String? discPercent  = product['discount_percent'];
    final int stock            = (product['stock'] as num?)?.toInt() ?? 99;
    final double matchScore    = (product['match_score'] as num?)?.toDouble() ?? 0.0;
    final String priceDisplay  = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0 ? '฿${price.toStringAsFixed(0)}' : '${product['price'] ?? ''}';

    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: uuid),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!, width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    color: isDark ? Colors.grey[800] : Colors.grey[200]),
                child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey[400])))
                        : Center(child: Icon(Icons.shopping_bag, size: 40, color: Colors.grey[400]))),
              ),
              if (matchScore >= 0.8)
                Positioned(top: 6, left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(8)),
                    child: Text('${(matchScore * 100).toInt()}%',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )),
              if (discPercent != null)
                Positioned(top: 6, right: 34,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: Text('-$discPercent',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )),
              Positioned(top: 6, right: 6,
                child: GestureDetector(
                  onTap: () async {
                    if (isFav) {
                      await _favouriteApi.removeFromFavourite(clothingUuid: uuid);
                      _showSuccessMessage(lang.translate(
                          en: 'Removed from favourites', th: 'ลบออกจากรายการโปรดแล้ว'));
                    } else {
                      await _favouriteApi.addToFavourite(clothingUuid: uuid);
                      _showProductDialog(context, product, isDark);
                    }
                    if (mounted) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white, size: 18),
                  ),
                )),
            ]),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text(priceDisplay,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.orange[300] : Colors.orange[700],
                          fontWeight: FontWeight.bold)),
                  if (discPrice != null && price > 0) ...[
                    const SizedBox(width: 4),
                    Text('฿${price.toStringAsFixed(0)}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough)),
                  ],
                ]),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: stock > 0 ? () async {
                        try {
                          await _basketApi.addToBasket(clothingUuid: uuid);
                          _showSuccessMessage(lang.translate(en: 'Added to cart!', th: 'เพิ่มลงตะกร้าแล้ว!'));
                        } catch (_) {
                          _showError(lang.translate(en: 'Failed to add to cart', th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                        }
                      } : null,
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          backgroundColor: stock > 0 ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(0, 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text(stock > 0
                          ? lang.translate(en: 'Buy', th: 'ซื้อ')
                          : lang.translate(en: 'Out', th: 'หมด'),
                          style: const TextStyle(fontSize: 11)),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _showInfoMessage(
                        lang.translate(en: 'Opening details...', th: 'กำลังเปิดรายละเอียด...')),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                    child: Text(lang.translate(en: 'More', th: 'เพิ่มเติม'),
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

  Widget _buildBottomButtons(bool isDark, CatAnalysisState state, LanguageProvider lang) {
    if (state is! CatAnalysisInitial) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))]),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(
            lang.translate(
                en: 'Take a photo: Place the cat in the center of the frame and see the whole body\nChoose a photo: Use JPEG files no larger than 500KB',
                th: 'ถ่ายรูป: วางตัวแมวให้อยู่กลางกรอบ และเห็นทั้งตัว\nเลือกรูป: ใช้ไฟล์ JPEG ขนาดไม่เกิน 500KB'),
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _captureFromLiveCamera,
                icon: _isCapturing
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Icon(Icons.camera_alt),
                label: Text(
                  _isCapturing
                      ? lang.translate(en: 'Detecting...', th: 'กำลังตรวจสอบ...')
                      : lang.translate(en: 'Take Photo', th: 'ถ่ายรูป'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isCapturing ? null : _pickImage,
                icon: const Icon(Icons.photo_library),
                label: Text(lang.translate(en: 'Choose Photo', th: 'เลือกรูป'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}