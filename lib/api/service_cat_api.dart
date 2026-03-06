// lib/api/service_cat_api.dart
// Cat API Service — GET / PUT / DELETE
// เชื่อมกับ catshop_backend_vtwo/app/api/cat_crud_api.py

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// ── Base URL ──────────────────────────────────────────────────────────────────
String getBaseUrl() {
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
  } catch (e) {
    return null;
  }
}

// ── Model ─────────────────────────────────────────────────────────────────────
class CatRecord {
  final int id;
  final String catColor;
  final String? breed;
  final int? age;
  final int gender;
  final double? weight;
  final String sizeCategory;
  final double? chestCm;
  final double? neckCm;
  final double? waistCm;
  final double? bodyLengthCm;
  final double? backLengthCm;
  final double? legLengthCm;
  final double? confidence;
  final String? imageCat;
  final String? imageClothing;
  final String? thumbnailUrl;
  final String? ageCategory;
  final int? bodyConditionScore;
  final String? bodyCondition;
  final String? bodyConditionDescription;
  final double? bmi;
  final String? posture;
  final String? sizeRecommendation;
  final String? qualityFlag;
  final DateTime? detectedAt;

  CatRecord({
    required this.id,
    required this.catColor,
    this.breed,
    this.age,
    required this.gender,
    this.weight,
    required this.sizeCategory,
    this.chestCm,
    this.neckCm,
    this.waistCm,
    this.bodyLengthCm,
    this.backLengthCm,
    this.legLengthCm,
    this.confidence,
    this.imageCat,
    this.imageClothing,
    this.thumbnailUrl,
    this.ageCategory,
    this.bodyConditionScore,
    this.bodyCondition,
    this.bodyConditionDescription,
    this.bmi,
    this.posture,
    this.sizeRecommendation,
    this.qualityFlag,
    this.detectedAt,
  });

  // ── Safe parse helpers ────────────────────────────────────────────────────
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  factory CatRecord.fromJson(Map<String, dynamic> json) {
    return CatRecord(
      id: _toInt(json['id']) ?? 0,
      catColor: json['cat_color']?.toString() ?? 'Unknown',
      breed: json['breed']?.toString(),
      age: _toInt(json['age']),
      gender: _toInt(json['gender']) ?? 0,
      weight: _toDouble(json['weight']),
      sizeCategory: json['size_category']?.toString() ?? 'M',
      chestCm: _toDouble(json['chest_cm']),
      neckCm: _toDouble(json['neck_cm']),
      waistCm: _toDouble(json['waist_cm']),
      bodyLengthCm: _toDouble(json['body_length_cm']),
      backLengthCm: _toDouble(json['back_length_cm']),
      legLengthCm: _toDouble(json['leg_length_cm']),
      confidence: _toDouble(json['confidence']),
      imageCat: json['image_cat']?.toString(),
      imageClothing: json['image_clothing']?.toString(),
      thumbnailUrl: json['thumbnail_url']?.toString(),
      ageCategory: json['age_category']?.toString(),
      bodyConditionScore: _toInt(json['body_condition_score']),
      bodyCondition: json['body_condition']?.toString(),
      bodyConditionDescription: json['body_condition_description']?.toString(),
      bmi: _toDouble(json['bmi']),
      posture: json['posture']?.toString(),
      sizeRecommendation: json['size_recommendation']?.toString(),
      qualityFlag: json['quality_flag']?.toString(),
      detectedAt: json['detected_at'] != null
          ? DateTime.tryParse(json['detected_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      if (breed != null) 'breed': breed,
      if (age != null) 'age': age,
      'gender': gender,
      if (weight != null) 'weight': weight,
      'size_category': sizeCategory,
      'cat_color': catColor,
    };
  }
}

// ── CatApiService ─────────────────────────────────────────────────────────────
class CatApiService {
  String get _base => '${getBaseUrl()}/api/system/cats';

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // ── GET /system/cats ────────────────────────────────────────────────────────
  Future<List<CatRecord>> getUserCats({int skip = 0, int limit = 100}) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final uri = Uri.parse('$_base?skip=$skip&limit=$limit');
    final response = await http
        .get(uri, headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final List cats = json['data']['cats'];
      return cats.map((c) => CatRecord.fromJson(c)).toList();
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      throw Exception('โหลดข้อมูลแมวไม่สำเร็จ (${response.statusCode})');
    }
  }

  // ── GET /system/cats/{id} ───────────────────────────────────────────────────
  Future<CatRecord> getCatById(int catId) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http
        .get(Uri.parse('$_base/$catId'), headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return CatRecord.fromJson(json['data']);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว');
    } else {
      throw Exception('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})');
    }
  }

  // ── PUT /system/cats/{id} ───────────────────────────────────────────────────
  Future<CatRecord> updateCat(int catId, Map<String, dynamic> updateData) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http
        .put(
          Uri.parse('$_base/$catId'),
          headers: _headers(token),
          body: jsonEncode(updateData),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return CatRecord.fromJson(json['data']);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว');
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      final err = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(err['detail'] ?? 'แก้ไขข้อมูลไม่สำเร็จ');
    }
  }

  // ── DELETE /system/cats/{id} ────────────────────────────────────────────────
  Future<void> deleteCat(int catId) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http
        .delete(Uri.parse('$_base/$catId'), headers: _headers(token))
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return;
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว');
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      throw Exception('ลบข้อมูลไม่สำเร็จ (${response.statusCode})');
    }
  }
}