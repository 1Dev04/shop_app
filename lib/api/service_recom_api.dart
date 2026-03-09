// lib/api/service_recom_api.dart
//
// Recommend API Service
// เชื่อมกับ backend: app/api/recommen_api.py
//
// Endpoints:
//   GET /api/system/recommend/                      → list + pagination
//   GET /api/system/recommend/detail/{clothing_id}  → detail + cat match
//   PUT /api/system/cats/{cat_id}                   → update cat (re-use cat endpoint)
//
// Flow:
//   1. CatApiService.analyze() สำเร็จ → บันทึก cat ลง DB
//   2. RecommendApiService.getRecommendations() → ดึง clothing ที่เหมาะกับ cat ล่าสุด
//   3. User กด detail → RecommendApiService.getRecommendationDetail()
//   4. User กด Edit Cat → RecommendApiService.updateCatAndRefresh()
//      → PUT /system/cats/{id} แล้ว refresh recommendations อัตโนมัติ

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// ── Base URL (เหมือน service_cat_api.dart) ───────────────────────────────────
String _getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
  if (kIsWeb) return 'http://localhost:10000';
  if (Platform.isAndroid) return 'http://10.0.2.2:10000';
  return 'http://localhost:10000';
}

// ── Token helper ──────────────────────────────────────────────────────────────
Future<String?> _getFirebaseToken() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  } catch (_) {
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - Models
// ═══════════════════════════════════════════════════════════════════════════════

// ── CatSummary (ข้อมูลแมวที่ backend ส่งมาพร้อม recommend list) ───────────────
class CatSummary {
  final int id;
  final String catColor;
  final String? breed;
  final int? age;
  final int gender;
  final double? weight;
  final String sizeCategory;
  final double? chestCm;
  final double? neckCm;
  final double? bodyLengthCm;
  final String? ageCategory;
  final String? bodyCondition;
  final int? bodyConditionScore;
  final String? imageCat;
  final DateTime? detectedAt;

  CatSummary({
    required this.id,
    required this.catColor,
    this.breed,
    this.age,
    required this.gender,
    this.weight,
    required this.sizeCategory,
    this.chestCm,
    this.neckCm,
    this.bodyLengthCm,
    this.ageCategory,
    this.bodyCondition,
    this.bodyConditionScore,
    this.imageCat,
    this.detectedAt,
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _i(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory CatSummary.fromJson(Map<String, dynamic> j) => CatSummary(
        id: _i(j['id']) ?? 0,
        catColor: j['cat_color']?.toString() ?? 'Unknown',
        breed: j['breed']?.toString(),
        age: _i(j['age']),
        gender: _i(j['gender']) ?? 0,
        weight: _d(j['weight']),
        sizeCategory: j['size_category']?.toString() ?? 'M',
        chestCm: _d(j['chest_cm']),
        neckCm: _d(j['neck_cm']),
        bodyLengthCm: _d(j['body_length_cm']),
        ageCategory: j['age_category']?.toString(),
        bodyCondition: j['body_condition']?.toString(),
        bodyConditionScore: _i(j['body_condition_score']),
        imageCat: j['image_cat']?.toString(),
        detectedAt: j['detected_at'] != null
            ? DateTime.tryParse(j['detected_at'].toString())
            : null,
      );

  /// แปลงเป็น Map สำหรับส่ง PUT update
  Map<String, dynamic> toUpdateJson({
    String? catColor,
    String? breed,
    int? age,
    double? weight,
    String? sizeCategory,
  }) {
    return {
      'cat_color': catColor ?? this.catColor,
      'size_category': sizeCategory ?? this.sizeCategory,
      if ((breed ?? this.breed) != null) 'breed': breed ?? this.breed,
      if ((age ?? this.age) != null) 'age': age ?? this.age,
      if ((weight ?? this.weight) != null) 'weight': weight ?? this.weight,
    };
  }
}

// ── CatMatchInfo (match score ที่ backend คำนวณให้) ───────────────────────────
class CatMatchInfo {
  final int catId;
  final String catColor;
  final String catSize;
  final double catWeight;
  final double catChestCm;
  final double matchScore;
  final bool matchSize;
  final bool matchWeight;
  final bool matchChest;
  final String reason;

  CatMatchInfo({
    required this.catId,
    required this.catColor,
    required this.catSize,
    required this.catWeight,
    required this.catChestCm,
    required this.matchScore,
    required this.matchSize,
    required this.matchWeight,
    required this.matchChest,
    required this.reason,
  });

  factory CatMatchInfo.fromJson(Map<String, dynamic> j) => CatMatchInfo(
        catId: (j['cat_id'] as num?)?.toInt() ?? 0,
        catColor: j['cat_color']?.toString() ?? '',
        catSize: j['cat_size']?.toString() ?? '',
        catWeight: (j['cat_weight'] as num?)?.toDouble() ?? 0,
        catChestCm: (j['cat_chest_cm'] as num?)?.toDouble() ?? 0,
        matchScore: (j['match_score'] as num?)?.toDouble() ?? 0,
        matchSize: j['match_size'] == true,
        matchWeight: j['match_weight'] == true,
        matchChest: j['match_chest'] == true,
        reason: j['reason']?.toString() ?? '',
      );

  /// % ที่แสดงให้ user เห็น (0.0 – 1.0 → 0% – 100%)
  int get scorePercent => (matchScore * 100).round();

  /// ป้าย badge สี
  String get scoreLabel {
    if (matchScore >= 1.0) return 'เหมาะสมมาก';
    if (matchScore >= 0.8) return 'เหมาะสมดี';
    if (matchScore >= 0.5) return 'พอใช้ได้';
    return 'ไม่ค่อยเหมาะ';
  }
}

// ── RecommendItem (clothing card ใน list) ─────────────────────────────────────
class RecommendItem {
  final int id;
  final String uuid;
  final String clothingName;
  final String? description;
  final String? category;
  final String sizeCategory;
  final double? minWeight;
  final double? maxWeight;
  final double? chestMinCm;
  final double? chestMaxCm;
  final double price;
  final double? discountPrice;
  final String? discountPercent;
  final int stock;
  final String? imageUrl;
  final dynamic images; // Map or String JSON
  final int? gender;
  final String? breed;
  final bool isFeatured;
  final int clothingLike;
  final bool matchSize;
  final bool matchWeight;
  final bool matchChest;
  final double matchScore;

  RecommendItem({
    required this.id,
    required this.uuid,
    required this.clothingName,
    this.description,
    this.category,
    required this.sizeCategory,
    this.minWeight,
    this.maxWeight,
    this.chestMinCm,
    this.chestMaxCm,
    required this.price,
    this.discountPrice,
    this.discountPercent,
    required this.stock,
    this.imageUrl,
    this.images,
    this.gender,
    this.breed,
    required this.isFeatured,
    required this.clothingLike,
    required this.matchSize,
    required this.matchWeight,
    required this.matchChest,
    required this.matchScore,
  });

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  factory RecommendItem.fromJson(Map<String, dynamic> j) => RecommendItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        uuid: j['uuid']?.toString() ?? '',
        clothingName: j['clothing_name']?.toString() ?? 'Unknown',
        description: j['description']?.toString(),
        category: j['category']?.toString(),
        sizeCategory: j['size_category']?.toString() ?? 'M',
        minWeight: _d(j['min_weight']),
        maxWeight: _d(j['max_weight']),
        chestMinCm: _d(j['chest_min_cm']),
        chestMaxCm: _d(j['chest_max_cm']),
        price: _d(j['price']) ?? 0.0,
        discountPrice: _d(j['discount_price']),
        discountPercent: j['discount_percent']?.toString(),
        stock: (j['stock'] as num?)?.toInt() ?? 0,
        imageUrl: j['image_url']?.toString(),
        images: j['images'],
        gender: (j['gender'] as num?)?.toInt(),
        breed: j['breed']?.toString(),
        isFeatured: j['is_featured'] == true,
        clothingLike: (j['clothing_like'] as num?)?.toInt() ?? 0,
        matchSize: j['match_size'] == true,
        matchWeight: j['match_weight'] == true,
        matchChest: j['match_chest'] == true,
        matchScore: _d(j['match_score']) ?? 0.0,
      );

  /// ราคาที่แสดงจริง (discount ถ้ามี)
  double get displayPrice {
    if (discountPrice != null && discountPrice! < price) return discountPrice!;
    return price;
  }

  bool get hasDiscount => discountPrice != null && discountPrice! < price;

  /// ดึง image URL จาก images map หรือ image_url
  String get resolvedImageUrl {
    if (imageUrl != null && imageUrl!.isNotEmpty) return imageUrl!;
    if (images != null) {
      try {
        final Map<String, dynamic> map = images is String
            ? Map<String, dynamic>.from(jsonDecode(images))
            : images is Map
                ? Map<String, dynamic>.from(images)
                : {};
        if (map.isNotEmpty) return map.values.first?.toString() ?? '';
      } catch (_) {}
    }
    return '';
  }
}

// ── RecommendDetail (clothing detail + cat_match) ─────────────────────────────
class RecommendDetail {
  final RecommendItem item;
  final CatMatchInfo? catMatch;
  // extra fields ที่มีเฉพาะใน detail
  final String? clothingSeller;
  final DateTime? createdAt;

  RecommendDetail({
    required this.item,
    this.catMatch,
    this.clothingSeller,
    this.createdAt,
  });

  factory RecommendDetail.fromJson(Map<String, dynamic> j) {
    final itemJson = Map<String, dynamic>.from(j);
    return RecommendDetail(
      item: RecommendItem.fromJson(itemJson),
      catMatch: j['cat_match'] != null
          ? CatMatchInfo.fromJson(j['cat_match'])
          : null,
      clothingSeller: j['clothing_seller']?.toString(),
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString())
          : null,
    );
  }
}

// ── Pagination ────────────────────────────────────────────────────────────────
class Pagination {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const Pagination({
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory Pagination.fromJson(Map<String, dynamic> j) => Pagination(
        total: (j['total'] as num?)?.toInt() ?? 0,
        page: (j['page'] as num?)?.toInt() ?? 1,
        pageSize: (j['page_size'] as num?)?.toInt() ?? 10,
        totalPages: (j['total_pages'] as num?)?.toInt() ?? 0,
        hasNext: j['has_next'] == true,
        hasPrev: j['has_prev'] == true,
      );

  factory Pagination.empty() => const Pagination(
        total: 0, page: 1, pageSize: 10,
        totalPages: 0, hasNext: false, hasPrev: false,
      );
}

// ── RecommendListResult (response จาก GET /recommend/) ────────────────────────
class RecommendListResult {
  final CatSummary? cat;
  final List<RecommendItem> items;
  final Pagination pagination;
  final String? message;

  const RecommendListResult({
    this.cat,
    required this.items,
    required this.pagination,
    this.message,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// MARK: - RecommendApiService
// ═══════════════════════════════════════════════════════════════════════════════

class RecommendApiService {
  final String _base;
  final String _catBase;

  RecommendApiService()
      : _base = '${_getBaseUrl()}/api/system/recommend',
        _catBase = '${_getBaseUrl()}/api/system/cats';

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ──────────────────────────────────────────────────────────────────────────
  // 1. GET /system/recommend/
  //    ดึง clothing ที่เหมาะกับแมวล่าสุดของ user พร้อม pagination
  //    เรียกหลังจาก CatApiService analysis สำเร็จ หรือตอน user เปิดหน้า Recommend
  // ──────────────────────────────────────────────────────────────────────────
  Future<RecommendListResult> getRecommendations({
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final uri = Uri.parse('$_base/?page=$page&page_size=$pageSize');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));

      // กรณีที่ยังไม่มีข้อมูลแมว
      if (body['cat'] == null) {
        return RecommendListResult(
          cat: null,
          items: const [],
          pagination: Pagination.empty(),
          message: body['message']?.toString(),
        );
      }

      return RecommendListResult(
        cat: CatSummary.fromJson(body['cat']),
        items: (body['items'] as List? ?? [])
            .map((e) => RecommendItem.fromJson(e))
            .toList(),
        pagination: Pagination.fromJson(body['pagination']),
        message: body['message']?.toString(),
      );
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      throw Exception('โหลดรายการแนะนำไม่สำเร็จ (${response.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. GET /system/recommend/detail/{clothing_id}
  //    ดึง clothing detail + คำนวณ match score กับ cat ล่าสุด
  //    เรียกเมื่อ user กด "Learn More" / "ดูรายละเอียด"
  // ──────────────────────────────────────────────────────────────────────────
  Future<RecommendDetail> getRecommendationDetail(int clothingId) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final uri = Uri.parse('$_base/detail/$clothingId');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return RecommendDetail.fromJson(body['item']);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบสินค้า id=$clothingId');
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      throw Exception('โหลดรายละเอียดสินค้าไม่สำเร็จ (${response.statusCode})');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. PUT /system/cats/{cat_id}  +  refresh recommendations
  //    อัปเดตข้อมูลแมว แล้ว refresh recommendation list อัตโนมัติ
  //    เรียกเมื่อ user กด "Edit Cat" ในหน้า Recommend
  //    → return RecommendListResult ใหม่ที่ match กับข้อมูลแมวที่อัปเดตแล้ว
  // ──────────────────────────────────────────────────────────────────────────
  Future<RecommendListResult> updateCatAndRefresh({
    required int catId,
    required Map<String, dynamic> updateData,
    int page = 1,
    int pageSize = 10,
  }) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    // ── Step 1: PUT /system/cats/{cat_id} ──────────────────────────────────
    final putRes = await http
        .put(
          Uri.parse('$_catBase/$catId'),
          headers: _headers(token),
          body: jsonEncode(updateData),
        )
        .timeout(const Duration(seconds: 30));

    if (putRes.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else if (putRes.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว id=$catId');
    } else if (putRes.statusCode != 200) {
      final err = jsonDecode(utf8.decode(putRes.bodyBytes));
      throw Exception(err['detail'] ?? 'แก้ไขข้อมูลแมวไม่สำเร็จ');
    }

    // ── Step 2: GET /recommend/ อีกครั้งเพื่อ refresh ─────────────────────
    return getRecommendations(page: page, pageSize: pageSize);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. Convenience: ดึงหน้าถัดไป (infinite scroll / load more)
  // ──────────────────────────────────────────────────────────────────────────
  Future<RecommendListResult> loadMore({
    required Pagination current,
    int pageSize = 10,
  }) async {
    if (!current.hasNext) {
      throw Exception('ไม่มีหน้าถัดไปแล้ว');
    }
    return getRecommendations(
      page: current.page + 1,
      pageSize: pageSize,
    );
  }
}