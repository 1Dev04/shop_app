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

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Config
// ═══════════════════════════════════════════════════════════════════════════════

class _Cfg {
  // ── ML Kit threshold ─────────────────────────────────────────────────────
  // ต่ำไว้ก่อน แล้วกรองด้วย logic เอง (มาตรฐาน Google ML Kit)
  static const double mlkitThreshold = 0.40;

  // ── Cat gate ──────────────────────────────────────────────────────────────
  static const double catMin       = 0.42; // ขั้นต่ำที่จะพิจารณาเป็นแมว
  static const double catPass      = 0.55; // ผ่านขั้นสุดท้าย
  static const double catHighConf  = 0.75; // bypass บางเงื่อนไข

  // ── Dog gate ──────────────────────────────────────────────────────────────
  static const double dogHard      = 0.55; // block ทันที ไม่ดูอย่างอื่น
  static const double dogSoft      = 0.35; // ต้องดู diff กับ cat ด้วย
  static const double catDogMinDiff = 0.22; // cat - dog ต้องห่างกันเท่านี้

  // ── Art / Cartoon ─────────────────────────────────────────────────────────
  static const double artHard      = 0.50; // block ทันที
  static const double artSoft      = 0.35; // ต้องผ่าน pixel check
  static const int    cartoonSig   = 5;    // pixel signal >= นี้ = การ์ตูน

  // ── Non-cat animal ────────────────────────────────────────────────────────
  static const double nonCatHard   = 0.55;

  // ── Real animal signal ────────────────────────────────────────────────────
  static const double realMin      = 0.38;

  // ── Multi-cat (ปรับใหม่: ลด false positive มาก) ──────────────────────────
  static const double regionMin    = 0.72; // confidence ต่อ region ที่จะ count
  static const double distRatio    = 0.50; // ต้องห่างกัน 50% ของ diagonal
  static const double mergeRatio   = 0.18; // merge ถ้าใกล้กันกว่า 18%
  static const int    minCatRegions = 2;   // ต้องเจอ cat ใน >= 2 region ที่แตกต่างกัน
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Label Sets
// ═══════════════════════════════════════════════════════════════════════════════

class _Labels {
  // ── แมว (ครบทุกสายพันธุ์หลัก) ────────────────────────────────────────────
  static const Set<String> cat = {
    'cat', 'cats', 'tabby', 'tabby cat', 'kitten', 'kittens',
    'persian cat', 'persian', 'siamese cat', 'siamese',
    'british shorthair', 'maine coon', 'bengal cat', 'bengal',
    'ragdoll', 'scottish fold', 'russian blue', 'abyssinian',
    'burmese cat', 'burmese', 'norwegian forest cat', 'sphynx',
    'sphynx cat', 'birman', 'tonkinese', 'munchkin', 'munchkin cat',
    'bombay cat', 'bombay', 'devon rex', 'cornish rex',
    'turkish angora', 'turkish van', 'exotic shorthair',
    'american shorthair', 'oriental shorthair',
    'feline', 'domestic cat', 'house cat', 'tomcat', 'tabbycat',
  };

  // ── หมา (ครบทุกสายพันธุ์หลัก) ────────────────────────────────────────────
  static const Set<String> dog = {
    'dog', 'dogs', 'puppy', 'puppies', 'canine', 'hound', 'doggy',
    'labrador', 'labrador retriever', 'golden retriever',
    'poodle', 'standard poodle', 'miniature poodle', 'toy poodle',
    'bulldog', 'english bulldog', 'french bulldog',
    'beagle', 'husky', 'siberian husky', 'alaskan malamute',
    'german shepherd', 'alsatian',
    'dachshund', 'chihuahua', 'pomeranian', 'spitz', 'japanese spitz',
    'corgi', 'pembroke welsh corgi', 'cardigan welsh corgi',
    'shih tzu', 'pug', 'boston terrier', 'boxer', 'rottweiler',
    'doberman', 'dobermann', 'dalmatian', 'schnauzer',
    'maltese', 'yorkshire terrier', 'yorkie', 'samoyed',
    'akita', 'shar pei', 'chow chow', 'basenji', 'whippet',
    'greyhound', 'mastiff', 'bichon', 'bichon frise',
    'cocker spaniel', 'border collie', 'australian shepherd',
    'great dane', 'saint bernard', 'bernese mountain dog',
    'weimaraner', 'pointer', 'setter', 'retriever', 'spaniel', 'terrier',
    'pitbull', 'pit bull', 'american pit bull',
    'shiba inu', 'shiba', 'chow',
  };

  // ── Art / Cartoon แรง ─────────────────────────────────────────────────────
  static const Set<String> artStrong = {
    'cartoon', 'anime', 'illustration', 'animated cartoon', 'comic',
    'manga', 'clipart', 'clip art', 'vector', 'digital art', 'drawing',
    'sketch', '3d render', 'cgi', 'computer graphics', 'low poly',
    'pixel art', 'animation', 'fictional character', 'caricature',
    'graphic novel', 'sticker', 'emoticon', 'emoji',
  };

  // ── Art / Cartoon อ่อน ────────────────────────────────────────────────────
  static const Set<String> artWeak = {
    'art', 'artwork', 'graphic', 'painting', 'poster', 'figure',
    'figurine', 'toy', 'stuffed animal', 'plush', 'plushie',
    'statue', 'sculpture', 'origami', 'papercraft', 'paper craft',
    'model', 'miniature', 'replica', 'doll', 'puppet',
    'ceramic', 'porcelain', 'clay', 'plastic toy',
    'wood carving', '3d model', 'render', 'craft',
    'decorative', 'merchandise', 'cushion', 'pillow cover',
  };

  // ── สัญญาณสัตว์จริง ───────────────────────────────────────────────────────
  static const Set<String> realAnimal = {
    'fur', 'furry', 'whisker', 'whiskers', 'mammal', 'wildlife',
    'fauna', 'paw', 'paws', 'animal', 'pet', 'domestic animal',
    'nose', 'claw', 'claws', 'tail', 'coat', 'hair',
    'vertebrate', 'carnivore', 'snout', 'muzzle',
  };

  // ── สัตว์อื่นที่ไม่ใช่แมวหรือหมา ─────────────────────────────────────────
  static const Set<String> nonCat = {
    'otter', 'sea otter', 'ferret', 'weasel', 'mink', 'marten',
    'beaver', 'badger', 'skunk', 'seal', 'sea lion', 'walrus',
    'fox', 'wolf', 'bear', 'panda', 'giant panda', 'red panda',
    'raccoon', 'squirrel', 'rabbit', 'hare', 'hamster',
    'guinea pig', 'gerbil', 'rat', 'mouse', 'hedgehog',
    'meerkat', 'mongoose', 'capybara', 'monkey', 'ape',
    'chimpanzee', 'gorilla', 'orangutan', 'lemur',
    'koala', 'kangaroo', 'wallaby', 'deer', 'elk', 'reindeer',
    'moose', 'alpaca', 'llama', 'sheep', 'goat', 'cow', 'horse',
    'pig', 'boar', 'elephant', 'giraffe', 'zebra', 'hippo', 'rhino',
    // แมวป่าขนาดใหญ่ ≠ แมวบ้าน
    'tiger', 'lion', 'cheetah', 'leopard', 'jaguar', 'lynx',
    'bobcat', 'cougar', 'puma', 'panther', 'snow leopard', 'ocelot',
    'serval', 'caracal', 'wildcat',
    // นก
    'bird', 'parrot', 'owl', 'eagle', 'chicken', 'duck', 'pigeon', 'penguin',
    // สัตว์เลื้อยคลาน / ครึ่งบกครึ่งน้ำ
    'snake', 'lizard', 'turtle', 'frog', 'toad',
    'gecko', 'iguana', 'chameleon', 'crocodile', 'alligator', 'reptile',
    // ทะเล
    'dolphin', 'whale', 'shark', 'octopus', 'crab', 'lobster', 'fish',
    // แมลง
    'spider', 'insect', 'scorpion', 'butterfly', 'bee',
  };
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Detection Result
// ═══════════════════════════════════════════════════════════════════════════════

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

  @override
  String toString() =>
      'DetectionResult(isCat=$isCat reason=$reason cat=${catScore.toStringAsFixed(2)})';
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Pixel Cartoon Check (ปรับ threshold ให้ conservative กว่าเดิม)
// ═══════════════════════════════════════════════════════════════════════════════

Future<({bool isCartoon, double conf})> _pixelCartoonCheck(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final img.Image? raw = img.decodeImage(bytes);
    if (raw == null) return (isCartoon: false, conf: 0.0);

    // resize เป็น 100×100 พอ (เร็วกว่า และเพียงพอ)
    final s = img.copyResize(raw, width: 100, height: 100);
    final total = s.width * s.height;

    // ── 1. Color diversity (quantize 5-bit per channel)
    final colors = <int>{};
    for (int y = 0; y < s.height; y++) {
      for (int x = 0; x < s.width; x++) {
        final p = s.getPixel(x, y);
        colors.add(((p.r ~/ 32) << 10) | ((p.g ~/ 32) << 5) | (p.b ~/ 32));
      }
    }
    final colorDiv = colors.length / total; // สูง = ภาพจริง

    // ── 2. Edge: sharp vs soft
    int sharp = 0, soft = 0, n = 0;
    final grads = <double>[];
    for (int y = 1; y < s.height - 1; y++) {
      for (int x = 1; x < s.width - 1; x++) {
        final c = s.getPixel(x, y);
        final r = s.getPixel(x + 1, y);
        final d = s.getPixel(x, y + 1);
        final dx = ((c.r-r.r).abs()+(c.g-r.g).abs()+(c.b-r.b).abs())/3.0;
        final dy = ((c.r-d.r).abs()+(c.g-d.g).abs()+(c.b-d.b).abs())/3.0;
        final g = sqrt(dx*dx + dy*dy);
        grads.add(g);
        if (g > 60) sharp++;
        if (g > 8 && g < 40) soft++;
        n++;
      }
    }
    final sharpR = n > 0 ? sharp / n : 0.0;
    final softR  = n > 0 ? soft  / n : 0.0;

    // ── 3. Gradient variance
    final avgG    = grads.isEmpty ? 0.0 : grads.reduce((a,b)=>a+b)/grads.length;
    final gradVar = grads.isEmpty ? 0.0
        : grads.fold(0.0,(s,g)=>s+pow(g-avgG,2))/grads.length;

    // ── 4. Saturation variance
    final sats = <double>[];
    for (int y = 0; y < s.height; y++) {
      for (int x = 0; x < s.width; x++) {
        final p = s.getPixel(x, y);
        final rv=p.r/255.0; final gv=p.g/255.0; final bv=p.b/255.0;
        final mx=[rv,gv,bv].reduce(max); final mn=[rv,gv,bv].reduce(min);
        sats.add(mx>0?(mx-mn)/mx:0.0);
      }
    }
    final avgSat  = sats.reduce((a,b)=>a+b)/sats.length;
    final satVar  = sats.fold(0.0,(s,v)=>s+pow(v-avgSat,2))/sats.length;

    // ── 5. Signal score (conservative: threshold เพิ่มขึ้น)
    int score = 0;

    // สัญญาณการ์ตูน
    if (colorDiv   < 0.05) score += 4;
    else if (colorDiv < 0.09) score += 3;
    else if (colorDiv < 0.14) score += 2;
    else if (colorDiv < 0.20) score += 1;

    if (satVar < 0.006)  score += 3;
    else if (satVar < 0.015) score += 2;
    else if (satVar < 0.025) score += 1;

    if (gradVar < 100)   score += 3;
    else if (gradVar < 250)  score += 2;
    else if (gradVar < 450)  score += 1;

    if (sharpR > 0.22 && colorDiv < 0.12) score += 2;

    // สัญญาณภาพจริง (หักแต้ม — ขนแมวทำให้ softR สูง)
    if (softR   > 0.22) score -= 3;   // ขนแมวฟู
    if (gradVar > 700)  score -= 3;   // texture ซับซ้อน
    if (colorDiv > 0.22) score -= 3;  // สีหลากหลาย
    if (satVar > 0.040) score -= 2;

    score = score.clamp(0, 20);

    print('🎨 PixelCheck: score=$score colorDiv=${colorDiv.toStringAsFixed(3)} '
        'gradVar=${gradVar.toStringAsFixed(1)} softR=${softR.toStringAsFixed(3)}');

    return (
      isCartoon: score >= _Cfg.cartoonSig,
      conf: (score / 12.0).clamp(0.0, 1.0),
    );
  } catch (e) {
    print('❌ pixelCartoonCheck: $e');
    return (isCartoon: false, conf: 0.0);
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Multi-Cat Detection  (แก้ปัญหา false positive)
//
// รากของปัญหา "1 แมวแต่บอกหลายตัว":
//   → region overlap ทำให้ centroid หลาย region ชี้ที่เดิม
//   → distRatio ต่ำเกินไป (0.30-0.45) ทำให้ 2 region ในแมวตัวเดียวกัน
//     ดูเหมือนห่างกัน
//
// แก้โดย:
//   1. เพิ่ม distRatio → 0.50 (ต้องอยู่คนละครึ่งภาพ)
//   2. เพิ่ม regionMin → 0.72
//   3. ใช้ NMS-style: ถ้า cluster ใด overlap > 50% กับอีก cluster → merge
//   4. ต้องมี catScore ที่แตกต่างกัน (ไม่ใช่ region เดิม label ซ้ำ)
// ═══════════════════════════════════════════════════════════════════════════════

Future<bool> _hasMultipleCats(
  String imagePath,
  ImageLabeler labeler, {
  bool Function()? isDisposed,
}) async {
  if (isDisposed?.call() ?? false) return false;
  try {
    final bytes = await File(imagePath).readAsBytes();
    final img.Image? image = img.decodeImage(bytes);
    if (image == null) return false;

    final tempDir = await getTemporaryDirectory();
    final w = image.width, h = image.height;

    // 3×3 grid (ไม่ overlap ก็ได้ — overlap ทำให้เกิด false positive)
    const cols = 3, rows = 3;
    final rw = (w / cols).round();
    final rh = (h / rows).round();

    final List<Map<String,double>> catRegions = [];

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        if (isDisposed?.call() ?? false) return false;

        final x    = col * rw;
        final y    = row * rh;
        final endX = min(w, x + rw);
        final endY = min(h, y + rh);
        if ((endX-x) < 1 || (endY-y) < 1) continue;

        final cropped = img.copyCrop(
            image, x: x, y: y, width: endX-x, height: endY-y);
        final tmp = File(
            '${tempDir.path}/mc_${row}_${col}_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await tmp.writeAsBytes(img.encodeJpg(cropped, quality: 65));

        try {
          final labels = await labeler.processImage(
              InputImage.fromFilePath(tmp.path));
          double best = 0;
          for (final lb in labels) {
            final t = lb.label.toLowerCase();
            for (final l in _Labels.cat) {
              if ((t == l || t.contains(l)) && lb.confidence > best) {
                best = lb.confidence;
              }
            }
          }
          if (best >= _Cfg.regionMin) {
            catRegions.add({
              'score': best,
              'cx': (x + rw / 2).toDouble(),
              'cy': (y + rh / 2).toDouble(),
              'col': col.toDouble(),
              'row': row.toDouble(),
            });
          }
        } catch (_) {
        } finally {
          try { tmp.deleteSync(); } catch (_) {}
        }
      }
    }

    print('🐱 Multi-cat: found ${catRegions.length} regions with score >= ${_Cfg.regionMin}');
    if (catRegions.length < _Cfg.minCatRegions) return false;

    final diag    = sqrt(w * w.toDouble() + h * h.toDouble());
    final mergeTh = diag * _Cfg.mergeRatio;
    final distTh  = diag * _Cfg.distRatio;

    // ── Merge ที่ใกล้กัน (แมวตัวเดียวกัน)
    final used   = List.filled(catRegions.length, false);
    final merged = <Map<String,double>>[];
    for (int i = 0; i < catRegions.length; i++) {
      if (used[i]) continue;
      double sx=catRegions[i]['cx']!, sy=catRegions[i]['cy']!;
      int cnt=1;
      for (int j=i+1; j<catRegions.length; j++) {
        if (used[j]) continue;
        final dx=catRegions[i]['cx']!-catRegions[j]['cx']!;
        final dy=catRegions[i]['cy']!-catRegions[j]['cy']!;
        if (sqrt(dx*dx+dy*dy) < mergeTh) {
          sx+=catRegions[j]['cx']!; sy+=catRegions[j]['cy']!;
          cnt++; used[j]=true;
        }
      }
      merged.add({'cx':sx/cnt,'cy':sy/cnt});
      used[i]=true;
    }

    print('🐱 Multi-cat: ${merged.length} clusters after merge');
    if (merged.length < 2) return false;

    // ── ตรวจว่า cluster ที่เหลือห่างกันพอ
    for (int i=0; i<merged.length; i++) {
      for (int j=i+1; j<merged.length; j++) {
        final dx=merged[i]['cx']!-merged[j]['cx']!;
        final dy=merged[i]['cy']!-merged[j]['cy']!;
        final dist=sqrt(dx*dx+dy*dy);
        if (dist > distTh) {
          print('🐱🐱 Multiple cats confirmed: dist=${dist.toStringAsFixed(0)} > ${distTh.toStringAsFixed(0)}');
          return true;
        }
      }
    }
    return false;
  } catch (e) {
    print('❌ hasMultipleCats: $e');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Score Aggregator
// ═══════════════════════════════════════════════════════════════════════════════

class _Scores {
  double cat=0, dog=0, artStrong=0, artWeak=0;
  double realAnimal=0, nonCat=0;
  String nonCatName='';

  void collect(List<ImageLabel> labels) {
    for (final lb in labels) {
      final t = lb.label.toLowerCase().trim();
      final c = lb.confidence;
      print('🏷️  ${lb.label}: ${(c*100).toStringAsFixed(1)}%');

      for (final l in _Labels.cat)      { if ((t==l||t.contains(l))&&c>cat) cat=c; }
      for (final l in _Labels.dog)      { if ((t==l||t.contains(l))&&c>dog) dog=c; }
      for (final l in _Labels.artStrong){ if ((t==l||t.contains(l))&&c>artStrong) artStrong=c; }
      for (final l in _Labels.artWeak)  { if ((t==l||t.contains(l))&&c>artWeak) artWeak=c; }
      for (final l in _Labels.realAnimal){ if ((t==l||t.contains(l))&&c>realAnimal) realAnimal=c; }
      for (final l in _Labels.nonCat)   {
        if ((t==l||t.contains(l))&&c>nonCat) { nonCat=c; nonCatName=lb.label; }
      }
    }
    print('📊 cat=${cat.toStringAsFixed(2)} dog=${dog.toStringAsFixed(2)} '
        'artS=${artStrong.toStringAsFixed(2)} artW=${artWeak.toStringAsFixed(2)} '
        'real=${realAnimal.toStringAsFixed(2)} nonCat=$nonCatName(${nonCat.toStringAsFixed(2)})');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Main Detector
//
// ปัญหาเดิม:
//   "บอกว่าเป็นหมาทั้งที่เป็นแมว" → dogBlock=0.40 ต่ำเกินไป
//     บางสายพันธุ์แมว (เช่น Maine Coon, Scottish Fold) ML Kit label ว่า dog ด้วย
//     เพราะหน้าตาคล้าย → แก้ด้วยการเพิ่ม dogHard=0.55 และเช็ค catScore ก่อน
//
//   "บอกว่ามีหลายตัวทั้งที่มีตัวเดียว" → ดู MARK: Multi-Cat
// ═══════════════════════════════════════════════════════════════════════════════

Future<DetectionResult> detectCat(
  String imagePath,
  ImageLabeler labeler, {
  bool Function()? isDisposed,
}) async {
  const _disposed = DetectionResult(
      isCat:false, reason:'disposed', catScore:0, isCartoon:false);
  if (isDisposed?.call() ?? false) return _disposed;

  try {
    final labels = await labeler.processImage(
        InputImage.fromFilePath(imagePath));
    if (isDisposed?.call() ?? false) return _disposed;

    final s = _Scores()..collect(labels);

    // ── GATE 1: ไม่มี cat signal เลย ────────────────────────────────────────
    if (s.cat < _Cfg.catMin) {
      return DetectionResult(
        isCat:false, reason:'no_cat',
        catScore:s.cat, isCartoon:false,
        detail:'cat=${s.cat.toStringAsFixed(2)} < ${_Cfg.catMin}',
      );
    }

    // ── GATE 2: หมาแน่ๆ (dogHard) ────────────────────────────────────────────
    // เพิ่ม threshold จาก 0.40 → 0.55 เพื่อแก้ปัญหา "แมวถูกเรียกว่าหมา"
    if (s.dog >= _Cfg.dogHard) {
      return DetectionResult(
        isCat:false, reason:'is_dog',
        catScore:s.cat, isCartoon:false,
        detail:'dog=${s.dog.toStringAsFixed(2)}',
      );
    }

    // ── GATE 3: Cat score สูงกว่า dog มากพอ (ถ้าไม่ผ่านให้ ambiguous) ────────
    // dogSoft = 0.35: ถ้า dog >=0.35 และ cat-dog < 0.22 → ambiguous
    if (s.dog >= _Cfg.dogSoft && (s.cat - s.dog) < _Cfg.catDogMinDiff) {
      // ยกเว้นถ้า cat สูงมากพอ (highConf) → เชื่อ cat
      if (s.cat < _Cfg.catHighConf) {
        return DetectionResult(
          isCat:false, reason:'ambiguous_cat_dog',
          catScore:s.cat, isCartoon:false,
          detail:'cat=${s.cat.toStringAsFixed(2)} dog=${s.dog.toStringAsFixed(2)}',
        );
      }
    }

    // ── GATE 4: Art/Cartoon แรง ───────────────────────────────────────────────
    if (s.artStrong >= _Cfg.artHard) {
      // bypass ถ้า cat สูงมาก + real animal ชัด
      final bypass = s.cat >= _Cfg.catHighConf && s.realAnimal >= _Cfg.realMin;
      if (!bypass) {
        return DetectionResult(
          isCat:false, reason:'art_cartoon',
          catScore:s.cat, isCartoon:true,
          detail:'artStrong=${s.artStrong.toStringAsFixed(2)}',
        );
      }
    }

    // ── GATE 5: Pixel-level cartoon check ─────────────────────────────────────
    // ทำเฉพาะเมื่อ cat ไม่สูงมาก หรือมี art signal
    ({bool isCartoon, double conf})? pixelResult;
    if (s.cat < _Cfg.catHighConf || s.artWeak >= _Cfg.artSoft) {
      pixelResult = await _pixelCartoonCheck(imagePath);
      if (isDisposed?.call() ?? false) return _disposed;

      if (pixelResult.isCartoon) {
        // bypass ถ้า cat สูงมาก + real animal ชัด
        final bypass = s.cat >= _Cfg.catHighConf && s.realAnimal >= _Cfg.realMin;
        if (!bypass) {
          return DetectionResult(
            isCat:false, reason:'cartoon_texture',
            catScore:s.cat, isCartoon:true,
            detail:'pixelConf=${pixelResult.conf.toStringAsFixed(2)}',
          );
        }
      }
    }

    // ── GATE 6: ต้องมี real animal signal (ยกเว้น cat สูงมาก) ───────────────
    if (s.cat < _Cfg.catHighConf) {
      final adjReal = s.dog >= 0.20
          ? s.realAnimal * (1.0 - s.dog * 0.35)
          : s.realAnimal;
      if (adjReal < _Cfg.realMin) {
        return DetectionResult(
          isCat:false, reason:'no_real_animal',
          catScore:s.cat, isCartoon: pixelResult?.isCartoon ?? false,
          detail:'adjReal=${adjReal.toStringAsFixed(2)}',
        );
      }
    }

    // ── GATE 7: Non-cat animal ────────────────────────────────────────────────
    if (s.nonCat >= _Cfg.nonCatHard) {
      // bypass ถ้า cat ชนะ nonCat อย่างชัดเจน
      final bypass = s.cat >= _Cfg.catHighConf && (s.cat - s.nonCat) > 0.20;
      if (!bypass) {
        return DetectionResult(
          isCat:false, reason:'non_cat:${s.nonCatName}',
          catScore:s.cat, isCartoon:false,
          detail:'${s.nonCatName}=${s.nonCat.toStringAsFixed(2)}',
        );
      }
    }

    // ── GATE 8: Cat score ต้องผ่าน threshold ──────────────────────────────────
    if (s.cat < _Cfg.catPass) {
      return DetectionResult(
        isCat:false, reason:'cat_score_low',
        catScore:s.cat, isCartoon: pixelResult?.isCartoon ?? false,
        detail:'cat=${s.cat.toStringAsFixed(2)} < ${_Cfg.catPass}',
      );
    }

    // ── GATE 9: Multi-cat (ทำสุดท้ายเพราะช้าสุด) ────────────────────────────
    final multi = await _hasMultipleCats(imagePath, labeler, isDisposed: isDisposed);
    if (isDisposed?.call() ?? false) return _disposed;
    if (multi) {
      return DetectionResult(
        isCat:false, reason:'multiple_cats',
        catScore:s.cat, isCartoon:false,
      );
    }

    // ── ✅ ผ่านทุก gate ─────────────────────────────────────────────────────
    print('✅ Cat passed all gates! score=${s.cat.toStringAsFixed(2)}');
    return DetectionResult(
      isCat:true, reason:'passed',
      catScore:s.cat, isCartoon:false,
      detail:'real=${s.realAnimal.toStringAsFixed(2)}',
    );
  } catch (e,st) {
    print('❌ detectCat error: $e\n$st');
    return DetectionResult(
        isCat:false, reason:'error', catScore:0, isCartoon:false, detail:'$e');
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Camera Overlay Painter
// ═══════════════════════════════════════════════════════════════════════════════

class _RectHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rw   = size.width  * 0.80;
    final rh   = size.height * 0.55;
    final left = (size.width  - rw) / 2;
    final top  = (size.height - rh) / 2;

    final rrect = RRect.fromLTRBR(
        left, top, left+rw, top+rh, const Radius.circular(20));

    canvas.drawPath(
      Path.combine(PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0,0,size.width,size.height)),
        Path()..addRRect(rrect)),
      Paint()..color = Colors.black.withOpacity(0.55),
    );
    canvas.drawRRect(rrect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = Colors.white.withOpacity(0.5));

    final acc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = Colors.white
      ..strokeCap = StrokeCap.round;
    const cL = 28.0, r = 20.0;
    canvas.drawLine(Offset(left+r, top),         Offset(left+r+cL, top),         acc);
    canvas.drawLine(Offset(left, top+r),          Offset(left, top+r+cL),          acc);
    canvas.drawLine(Offset(left+rw-r, top),       Offset(left+rw-r-cL, top),       acc);
    canvas.drawLine(Offset(left+rw, top+r),       Offset(left+rw, top+r+cL),       acc);
    canvas.drawLine(Offset(left+r, top+rh),       Offset(left+r+cL, top+rh),       acc);
    canvas.drawLine(Offset(left, top+rh-r),       Offset(left, top+rh-r-cL),       acc);
    canvas.drawLine(Offset(left+rw-r, top+rh),    Offset(left+rw-r-cL, top+rh),    acc);
    canvas.drawLine(Offset(left+rw, top+rh-r),    Offset(left+rw, top+rh-r-cL),    acc);
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

  factory CatData.fromJson(Map<String,dynamic> j) => CatData(
    name:         j['name'],
    breed:        j['breed'],
    age:          j['age'],
    weight:       (j['weight'] as num).toDouble(),
    sizeCategory: j['size_category'],
    chestCm:      (j['chest_cm'] as num).toDouble(),
    neckCm:       j['neck_cm'] != null ? (j['neck_cm'] as num).toDouble() : null,
    bodyLengthCm: j['body_length_cm'] != null ? (j['body_length_cm'] as num).toDouble() : null,
    confidence:   (j['confidence'] as num).toDouble(),
    boundingBox:  List<double>.from(j['bounding_box'].map((e)=>(e as num).toDouble())),
    imageUrl:     j['image_cat'] ?? j['image_url'] ?? '',
    thumbnailUrl: j['thumbnail_url'],
    detectedAt:   DateTime.parse(j['detected_at']),
    dbId:         j['db_id'],
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Widget Entry Point
// ═══════════════════════════════════════════════════════════════════════════════

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

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - State
// ═══════════════════════════════════════════════════════════════════════════════

class _MeasureSizeCatState extends State<_MeasureSizeCatView> {
  final _picker       = ImagePicker();
  final _favouriteApi = FavouriteApiService();
  final _basketApi    = BasketApiService();

  bool              _isCapturing = false;
  bool              _isDisposed  = false;
  CameraController? _cameraCtrl;
  late ImageLabeler _labeler;

  @override
  void initState() {
    super.initState();
    _initMLKit();
    _initCamera();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cameraCtrl?.dispose();
    _cameraCtrl = null;
    _labeler.close();
    super.dispose();
  }

  void _initMLKit() {
    // ใช้ threshold ต่ำ แล้วกรองด้วย logic เอง (มาตรฐาน)
    _labeler = ImageLabeler(
        options: ImageLabelerOptions(confidenceThreshold: _Cfg.mlkitThreshold));
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
      _cameraCtrl = CameraController(back, ResolutionPreset.high, enableAudio: false);
      await _cameraCtrl!.initialize();
      if (mounted && !_isDisposed) setState(() {});
    } catch (e) {
      if (mounted && !_isDisposed) _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  // ─── Image helpers ───────────────────────────────────────────────────────

  Future<File?> _cropToFrame(String path) async {
    try {
      final image = img.decodeImage(await File(path).readAsBytes());
      if (image == null) return null;
      final x = (image.width  * 0.10).toInt().clamp(0, image.width);
      final y = (image.height * 0.225).toInt().clamp(0, image.height);
      final w = (image.width  * 0.80).toInt().clamp(1, image.width  - x);
      final h = (image.height * 0.55).toInt().clamp(1, image.height - y);
      final cropped = img.copyCrop(image, x:x, y:y, width:w, height:h);
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/cat_crop_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(cropped, quality: 92));
      return f;
    } catch (_) { return null; }
  }

  Future<File?> _compress(File src) async {
    try {
      if (!await src.exists()) return null;
      var image = img.decodeImage(await src.readAsBytes());
      if (image == null) return null;
      const mx = 1920;
      if (image.width > mx || image.height > mx) {
        image = img.copyResize(image,
            width:  image.width  > image.height ? mx : null,
            height: image.height > image.width  ? mx : null);
      }
      final tmp = await getTemporaryDirectory();
      final f = File('${tmp.path}/cat_out_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await f.writeAsBytes(img.encodeJpg(image, quality: 92));
      return f;
    } catch (_) { return null; }
  }

  // ─── Capture ─────────────────────────────────────────────────────────────

  Future<void> _captureFromCamera() async {
    if (_isCapturing || _isDisposed) return;
    final ctrl = _cameraCtrl;
    if (ctrl == null || !ctrl.value.isInitialized) {
      _showError('กล้องยังไม่พร้อม'); return;
    }
    if (mounted) setState(() => _isCapturing = true);
    try {
      final photo = await ctrl.takePicture();
      if (!mounted || _isDisposed) return;

      final cropped = await _cropToFrame(photo.path);
      if (!mounted || _isDisposed) { cropped?.delete(); File(photo.path).delete(); return; }

      final result = await detectCat(
        cropped?.path ?? photo.path, _labeler,
        isDisposed: () => _isDisposed,
      );
      try { cropped?.delete(); } catch (_) {}
      if (!mounted || _isDisposed) { File(photo.path).delete(); return; }

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        try { File(photo.path).delete(); } catch (_) {}
        _showRejectDialog(result);
        return;
      }

      final processed = await _compress(File(photo.path));
      try { File(photo.path).delete(); } catch (_) {}
      if (!mounted || _isDisposed) return;

      await ctrl.dispose();
      if (mounted && !_isDisposed) {
        setState(() { _cameraCtrl = null; _isCapturing = false; });
        if (processed != null) {
          context.read<CatAnalysisBloc>().add(CatImageSelected(processed));
          _showSuccessMessage('พบแมว! ✅ กดวิเคราะห์ได้เลย');
        }
      }
    } catch (e) {
      if (mounted && !_isDisposed) setState(() => _isCapturing = false);
      if (mounted && !_isDisposed) _showError('ถ่ายรูปไม่สำเร็จ: $e');
    }
  }

  // ─── Pick from Gallery ───────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isDisposed) return;
    try {
      final picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 95,
          maxWidth: 1920, maxHeight: 1920);
      if (picked == null || !mounted || _isDisposed) return;

      setState(() => _isCapturing = true);

      // สำหรับแกลเลอรี: ตรวจภาพเต็ม (ไม่ crop) เพราะผู้ใช้เลือกมาเองแล้ว
      final result = await detectCat(
        picked.path, _labeler,
        isDisposed: () => _isDisposed,
      );
      if (!mounted || _isDisposed) return;

      if (!result.isCat) {
        setState(() => _isCapturing = false);
        _showRejectDialog(result);
        return;
      }

      final processed = await _compress(File(picked.path));
      if (!mounted || _isDisposed) return;

      if (processed != null) {
        await _cameraCtrl?.dispose();
        _cameraCtrl = null;
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
    final dark = Theme.of(context).brightness == Brightness.dark;

    String title, message;
    IconData icon; Color iconColor;

    final r = result.reason;
    if (r == 'multiple_cats') {
      title='🐱🐱 ตรวจพบแมวหลายตัว';
      message='ระบบตรวจพบแมวมากกว่า 1 ตัวในภาพ\nกรุณาถ่ายรูปแมวทีละตัวเท่านั้น';
      icon=Icons.pets; iconColor=Colors.purple;
    } else if (result.isCartoon || r=='art_cartoon' || r=='cartoon_texture') {
      title='🎨 ไม่ใช่ภาพแมวจริง';
      message='ระบบตรวจพบว่าเป็นภาพการ์ตูน รูปวาด โมเดล\nหรือของเล่น กรุณาใช้รูปถ่ายแมวจริงเท่านั้น';
      icon=Icons.draw_outlined; iconColor=Colors.orange;
    } else if (r=='is_dog') {
      title='🐶 ตรวจพบสุนัข';
      message='ภาพนี้มีลักษณะของสุนัข\nฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
      icon=Icons.pets; iconColor=Colors.brown;
    } else if (r=='ambiguous_cat_dog') {
      title='🤔 ไม่สามารถระบุได้';
      message='ระบบไม่แน่ใจว่าเป็นแมวหรือสุนัข\nลองถ่ายรูปให้เห็นแมวชัดเจนยิ่งขึ้น';
      icon=Icons.help_outline; iconColor=Colors.orange;
    } else if (r.startsWith('non_cat:')) {
      final name = r.split(':').last;
      title='🚫 ตรวจพบสัตว์อื่น';
      message='ระบบตรวจพบ "$name" ในภาพ\nฟีเจอร์นี้รองรับเฉพาะแมวเท่านั้น';
      icon=Icons.pets; iconColor=Colors.deepOrange;
    } else {
      title='😿 ไม่พบแมวในภาพ';
      message='ไม่สามารถตรวจพบแมวในภาพได้\nลองถ่ายรูปใหม่ให้เห็นแมวชัดเจนทั้งตัว';
      icon=Icons.search_off; iconColor=Colors.grey;
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
          if (result.catScore > 0) ...[
            const SizedBox(height: 8),
            Text('Cat score: ${(result.catScore*100).toStringAsFixed(0)}%',
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

  void _showProductDialog(BuildContext context, Map<String,dynamic> product, bool dark) {
    final lang        = Provider.of<LanguageProvider>(context, listen: false);
    final uuid        = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final name        = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final imageUrl    = product['image_url'] ?? product['imageUrl'] ?? '';
    final price       = (product['price'] as num?)?.toDouble() ?? 0.0;
    final discPrice   = (product['discount_price'] as num?)?.toDouble();
    final priceDisplay = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0 ? '฿${price.toStringAsFixed(0)}' : '${product['price']??''}';

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
              Text(lang.translate(en: 'Added to Favorites', th: 'เพิ่มในรายการโปรด'),
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
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
              height: 220, width: double.infinity,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: dark ? Colors.grey[800] : Colors.grey[200],
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10, offset: const Offset(0,4))]),
              child: Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, width: double.infinity,
                          height: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_,__,___) => Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 60, color: Colors.grey[400])))
                      : Center(child: Icon(Icons.shopping_bag,
                          size: 60, color: Colors.grey[400])),
                ),
                Positioned(top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle),
                      child: const Icon(Icons.favorite, color: Colors.red, size: 26),
                    )),
              ]),
            ),
            const SizedBox(height: 20),
            Text(name,
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold,
                    color: dark ? Colors.white : Colors.black87),
                textAlign: TextAlign.center,
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(
                lang.translate(en: 'Price: $priceDisplay', th: 'ราคา: $priceDisplay'),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
              ),
            ),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  try {
                    await _basketApi.addToBasket(clothingUuid: uuid);
                    _showSuccessMessage(
                        lang.translate(en: 'Added to cart!', th: 'เพิ่มลงตะกร้าแล้ว!'));
                  } catch (_) {
                    _showError(lang.translate(
                        en: 'Failed to add to cart', th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                  }
                },
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: Text(lang.translate(en: 'Buy', th: 'ซื้อ'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              )),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    final ageCtrl   = TextEditingController(text: cat.age?.toString() ?? '');
    String selSize  = cat.sizeCategory;

    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: StatefulBuilder(
          builder: (ctx2, setM) => Column(
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
                  decoration: const InputDecoration(
                      labelText: 'สีแมว / Cat Color',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: breedCtrl,
                  decoration: const InputDecoration(
                      labelText: 'พันธุ์ / Breed',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'อายุ (ปี)',
                      border: OutlineInputBorder())),
              const SizedBox(height: 12),
              const Text('ขนาด', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: ['XS','S','M','L','XL'].map((sz) {
                  final sel = selSize == sz;
                  return GestureDetector(
                    onTap: () => setM(() => selSize = sz),
                    child: Container(
                      width: 52, height: 40, alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: sel ? Colors.orange : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(sz, style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: sel ? Colors.white : Colors.black87)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.orange, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('บันทึก',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (ok != true) return;
    final data = <String,dynamic>{
      'cat_color': colorCtrl.text.trim().isNotEmpty
          ? colorCtrl.text.trim() : cat.name,
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
            child: const Text('ลบ',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
    final theme  = context.watch<ThemeProvider>();
    final lang   = Provider.of<LanguageProvider>(context);
    final dark   = theme.themeMode == ThemeMode.dark;
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
          style: TextStyle(fontFamily: 'catFont', fontSize: 30,
              fontWeight: FontWeight.bold,
              color: dark ? Colors.white : Colors.black),
        ),
        backgroundColor: dark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(color: dark ? Colors.white : Colors.black),
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
          File? img;
          if (state is CatImageReady)        img = state.imageFile;
          if (state is CatAnalysisUploading) img = state.imageFile;
          if (state is CatAnalysisAnalyzing) img = state.imageFile;

          final processing   = state is CatAnalysisUploading || state is CatAnalysisAnalyzing;
          final progress     = state is CatAnalysisUploading ? 0.3
              : state is CatAnalysisAnalyzing ? 0.7 : 0.0;
          final progressLbl  = state is CatAnalysisUploading
              ? 'Uploading image...' : 'Analyzing cat...';

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
                      _buildImageSection(dark, state.imageFile, lang, false),
                    if (state is CatAnalysisUploading || state is CatAnalysisAnalyzing)
                      _buildImageSection(dark, img!, lang, true),
                    if (state is CatAnalysisSuccess)
                      _buildResultSection(dark, state.catData, screenH, lang, state.recommendations),
                    if (state is CatDataUpdateSuccess)
                      _buildResultSection(dark, state.catData, screenH, lang, state.recommendations),
                    if (state is CatDataUpdating)
                      _buildResultSection(dark, state.catData, screenH, lang, state.recommendations),
                  ]),
                ),
              ),
              _buildBottomBar(dark, state, lang),
            ]),
            if (processing)
              _buildLoadingOverlay(img, progress, progressLbl),
          ]);
        },
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildCameraPreview() {
    if (_cameraCtrl == null || !_cameraCtrl!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return Stack(fit: StackFit.expand, children: [
      CameraPreview(_cameraCtrl!),
      CustomPaint(painter: _RectHolePainter(), size: Size.infinite),
      Positioned(top: 20, left: 24, right: 24,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(14)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pets, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text(
                  'วางแมวจริง 1 ตัวให้อยู่ในกรอบ เห็นทั้งตัว แล้วกดถ่ายรูป',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
      if (_isCapturing)
        Container(color: Colors.black54,
          child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('🔍 กำลังตรวจจับแมว...',
                style: TextStyle(color: Colors.white, fontSize: 16,
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
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Stack(alignment: Alignment.center, children: [
          SizedBox(
            width: 190, height: 190,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              builder: (_, v, __) => CircularProgressIndicator(
                  value: v, strokeWidth: 6,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: const AlwaysStoppedAnimation(Colors.orange)),
            ),
          ),
          Container(
            width: 145, height: 145,
            decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: ClipOval(child: file != null
                ? Image.file(file, fit: BoxFit.cover)
                : const Icon(Icons.pets, size: 60)),
          ),
        ]),
        const SizedBox(height: 20),
        Text('${(progress*100).toInt()}%',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
      ])),
    );
  }

  Widget _buildImageSection(
      bool dark, File file, LanguageProvider lang, bool loading) {
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      Container(
        height: 300,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [BoxShadow(
                color: Colors.black26, blurRadius: 10, offset: Offset(0,4))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(16),
            child: Image.file(file, fit: BoxFit.cover, width: double.infinity)),
      ),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: dark ? Colors.grey[850] : Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: dark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
        child: Row(children: [
          Container(
            width: 100, height: 120,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: dark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
            child: ClipRRect(borderRadius: BorderRadius.circular(10),
                child: Image.file(file, fit: BoxFit.cover)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _infoRow(lang.translate(en:'Cat color:',th:'สีแมว:'), 'N/A', dark),
            const SizedBox(height: 10),
            _infoRow(lang.translate(en:'Age:',th:'อายุ:'), 'N/A', dark),
            const SizedBox(height: 10),
            _infoRow(lang.translate(en:'Breed:',th:'พันธุ์:'), 'N/A', dark),
            const SizedBox(height: 10),
            _infoRow(lang.translate(en:'Size:',th:'ขนาด:'), 'N/A', dark),
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
              color: dark ? Colors.orange[300] : Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(
            lang.translate(
                en: 'Please ensure that the cat is clearly visible for accurate measurement.',
                th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
            style: TextStyle(
                fontSize: 12, color: dark ? Colors.white70 : Colors.black87),
          )),
        ]),
      ),
      const SizedBox(height: 16),
      Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: loading ? null
              : () => context.read<CatAnalysisBloc>().add(CatAnalysisStarted()),
          icon: loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Icon(Icons.analytics),
          label: Text(
            loading
                ? lang.translate(en:'Processing...',th:'กำลังวิเคราะห์...')
                : lang.translate(en:'Analyze Data',th:'วิเคราะห์ข้อมูล'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.orange, foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
        )),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: loading ? null : _clearData,
          style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              backgroundColor: Colors.red, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          child: const Icon(Icons.close, size: 24),
        ),
      ]),
    ]));
  }

  Widget _buildResultSection(bool dark, CatData cat, double screenH,
      LanguageProvider lang, List<Map<String,dynamic>> recs) {
    return Padding(padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: dark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: dark ? Colors.grey[700]! : Colors.grey[300]!, width: 2)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 100, height: 120,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: dark ? Colors.grey[600]! : Colors.grey[400]!, width: 2)),
              child: ClipRRect(borderRadius: BorderRadius.circular(10),
                child: cat.imageUrl.isNotEmpty
                    ? Image.network(cat.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_,__,___) => Icon(Icons.broken_image,
                            size: 40, color: Colors.grey[400]))
                    : Icon(Icons.pets, size: 40, color: Colors.grey[400]),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _infoRow(lang.translate(en:'Cat Color:',th:'สีแมว:'), cat.name, dark),
              const SizedBox(height: 10),
              _infoRow(lang.translate(en:'Age:',th:'อายุ:'),
                  cat.age != null ? '${cat.age} years' : 'N/A', dark),
              const SizedBox(height: 10),
              _infoRow(lang.translate(en:'Breed:',th:'พันธุ์:'), cat.breed ?? 'N/A', dark),
              const SizedBox(height: 10),
              _infoRow(lang.translate(en:'Size:',th:'ขนาด:'), cat.sizeCategory, dark),
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
        Text(lang.translate(en:'Recommended Products',th:'สินค้าแนะนำ'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: dark ? Colors.white : Colors.black87)),
        const SizedBox(height: 12),
        if (recs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            child: Column(children: [
              Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(lang.translate(
                  en:'No matching products found', th:'ไม่พบสินค้าที่เหมาะสม'),
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ]),
          )
        else
          SizedBox(
            height: screenH * 0.50,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 5,
                  mainAxisSpacing: 12, childAspectRatio: 0.86),
              itemCount: recs.length,
              itemBuilder: (ctx, i) => _buildProductCard(recs[i], dark),
            ),
          ),
      ]),
    );
  }

  Widget _infoRow(String label, String value, bool dark) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
          color: dark ? Colors.white70 : Colors.black87)),
      const SizedBox(width: 8),
      Expanded(child: Text(value,
          style: TextStyle(fontSize: 16,
              color: dark ? Colors.white60 : Colors.black54))),
    ]);
  }

  Widget _buildProductCard(Map<String,dynamic> product, bool dark) {
    final lang        = Provider.of<LanguageProvider>(context);
    final uuid        = product['uuid']?.toString() ?? product['id']?.toString() ?? '';
    final name        = product['clothing_name'] ?? product['name'] ?? 'Unknown';
    final imageUrl    = product['image_url'] ?? product['imageUrl'] ?? '';
    final price       = (product['price'] as num?)?.toDouble() ?? 0.0;
    final discPrice   = (product['discount_price'] as num?)?.toDouble();
    final discPct     = product['discount_percent'];
    final stock       = (product['stock'] as num?)?.toInt() ?? 99;
    final match       = (product['match_score'] as num?)?.toDouble() ?? 0.0;
    final priceDisplay = discPrice != null
        ? '฿${discPrice.toStringAsFixed(0)}'
        : price > 0 ? '฿${price.toStringAsFixed(0)}' : '${product['price']??''}';

    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: uuid),
      builder: (ctx, snap) {
        final isFav = snap.data ?? false;
        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
              color: dark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: dark ? Colors.grey[700]! : Colors.grey[300]!,
                  width: 1.5)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              Container(
                height: 100,
                decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    color: dark ? Colors.grey[800] : Colors.grey[200]),
                child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(imageUrl, width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => Center(
                                child: Icon(Icons.shopping_bag,
                                    size: 40, color: Colors.grey[400])))
                        : Center(child: Icon(Icons.shopping_bag,
                            size: 40, color: Colors.grey[400]))),
              ),
              if (match >= 0.8)
                Positioned(top: 6, left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('${(match*100).toInt()}%',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
              if (discPct != null)
                Positioned(top: 6, right: 34,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text('-$discPct',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    )),
              Positioned(top: 6, right: 6,
                child: GestureDetector(
                  onTap: () async {
                    if (isFav) {
                      await _favouriteApi.removeFromFavourite(clothingUuid: uuid);
                      _showSuccessMessage(lang.translate(
                          en:'Removed from favourites',
                          th:'ลบออกจากรายการโปรดแล้ว'));
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
                    child: Icon(isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.white, size: 18),
                  ),
                )),
            ]),
            Padding(padding: const EdgeInsets.all(8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                        color: dark ? Colors.white : Colors.black87),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(children: [
                  Text(priceDisplay,
                      style: TextStyle(fontSize: 12,
                          color: dark ? Colors.orange[300] : Colors.orange[700],
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
                  Expanded(child: ElevatedButton(
                    onPressed: stock > 0 ? () async {
                      try {
                        await _basketApi.addToBasket(clothingUuid: uuid);
                        _showSuccessMessage(lang.translate(
                            en:'Added to cart!', th:'เพิ่มลงตะกร้าแล้ว!'));
                      } catch (_) {
                        _showError(lang.translate(
                            en:'Failed to add to cart',
                            th:'เพิ่มลงตะกร้าไม่สำเร็จ'));
                      }
                    } : null,
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: stock > 0 ? Colors.green : Colors.grey,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text(stock > 0
                        ? lang.translate(en:'Buy',th:'ซื้อ')
                        : lang.translate(en:'Out',th:'หมด'),
                        style: const TextStyle(fontSize: 11)),
                  )),
                  const SizedBox(width: 4),
                  ElevatedButton(
                    onPressed: () => _showInfoMessage(lang.translate(
                        en:'Opening details...', th:'กำลังเปิดรายละเอียด...')),
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 6, horizontal: 8),
                        backgroundColor: dark ? Colors.grey[700] : Colors.grey[300],
                        foregroundColor: dark ? Colors.white : Colors.black87,
                        minimumSize: const Size(0, 28),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8))),
                    child: Text(lang.translate(en:'More',th:'เพิ่มเติม'),
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

  Widget _buildBottomBar(bool dark, CatAnalysisState state, LanguageProvider lang) {
    if (state is! CatAnalysisInitial) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: dark ? Colors.grey[900] : Colors.white,
          boxShadow: const [BoxShadow(
              color: Colors.black12, blurRadius: 8, offset: Offset(0,-2))]),
      child: SafeArea(top: false, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(
          lang.translate(
              en: 'Take a photo: Place the cat in the center of the frame and see the whole body\n'
                  'Choose a photo: Use JPEG files no larger than 500KB',
              th: 'ถ่ายรูป: วางตัวแมวให้อยู่กลางกรอบ และเห็นทั้งตัว\n'
                  'เลือกรูป: ใช้ไฟล์ JPEG ขนาดไม่เกิน 500KB'),
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12,
              color: dark ? Colors.white70 : Colors.black87),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: ElevatedButton.icon(
            onPressed: _isCapturing ? null : _captureFromCamera,
            icon: _isCapturing
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
                : const Icon(Icons.camera_alt),
            label: Text(
              _isCapturing
                  ? lang.translate(en:'Detecting...',th:'กำลังตรวจสอบ...')
                  : lang.translate(en:'Take Photo',th:'ถ่ายรูป'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.blue, foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton.icon(
            onPressed: _isCapturing ? null : _pickFromGallery,
            icon: const Icon(Icons.photo_library),
            label: Text(lang.translate(en:'Choose Photo',th:'เลือกรูป'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.green, foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey[400],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          )),
        ]),
      ])),
    );
  }
}