// lib/api/service_cat_api.dart
// Cat API Service — GET / PUT / DELETE
// เชื่อมกับ catshop_backend_vtwo/app/api/cat_crud_api.py

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

// ── Base URL (เหมือนกับ measure_size_cat.dart) ────────────────────────────────
String getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
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

  factory CatRecord.fromJson(Map<String, dynamic> json) {
    return CatRecord(
      id: json['id'],
      catColor: json['cat_color'] ?? 'Unknown',
      breed: json['breed'],
      age: json['age'],
      gender: json['gender'] ?? 0,
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      sizeCategory: json['size_category'] ?? 'M',
      chestCm: json['chest_cm'] != null ? (json['chest_cm'] as num).toDouble() : null,
      neckCm: json['neck_cm'] != null ? (json['neck_cm'] as num).toDouble() : null,
      waistCm: json['waist_cm'] != null ? (json['waist_cm'] as num).toDouble() : null,
      bodyLengthCm: json['body_length_cm'] != null ? (json['body_length_cm'] as num).toDouble() : null,
      backLengthCm: json['back_length_cm'] != null ? (json['back_length_cm'] as num).toDouble() : null,
      legLengthCm: json['leg_length_cm'] != null ? (json['leg_length_cm'] as num).toDouble() : null,
      confidence: json['confidence'] != null ? (json['confidence'] as num).toDouble() : null,
      imageCat: json['image_cat'],
      thumbnailUrl: json['thumbnail_url'],
      ageCategory: json['age_category'],
      bodyConditionScore: json['body_condition_score'],
      bodyCondition: json['body_condition'],
      bodyConditionDescription: json['body_condition_description'],
      bmi: json['bmi'] != null ? (json['bmi'] as num).toDouble() : null,
      posture: json['posture'],
      sizeRecommendation: json['size_recommendation'],
      qualityFlag: json['quality_flag'],
      detectedAt: json['detected_at'] != null ? DateTime.tryParse(json['detected_at']) : null,
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

  // ── GET /system/cats — ดูแมวทั้งหมดของ user ────────────────────────────────
  Future<List<CatRecord>> getUserCats({int skip = 0, int limit = 100}) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final uri = Uri.parse('$_base?skip=$skip&limit=$limit');
    final response = await http.get(uri, headers: _headers(token))
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

  // ── GET /system/cats/{id} — ดูแมวตัวเดียว ──────────────────────────────────
  Future<CatRecord> getCatById(int catId) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http.get(
      Uri.parse('$_base/$catId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final json = jsonDecode(utf8.decode(response.bodyBytes));
      return CatRecord.fromJson(json['data']);
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว');
    } else {
      throw Exception('โหลดข้อมูลไม่สำเร็จ (${response.statusCode})');
    }
  }

  // ── PUT /system/cats/{id} — แก้ไขข้อมูลแมว ────────────────────────────────
  Future<CatRecord> updateCat(int catId, Map<String, dynamic> updateData) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http.put(
      Uri.parse('$_base/$catId'),
      headers: _headers(token),
      body: jsonEncode(updateData),
    ).timeout(const Duration(seconds: 30));

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

  // ── DELETE /system/cats/{id} — ลบข้อมูลแมว ────────────────────────────────
  Future<void> deleteCat(int catId) async {
    final token = await _getFirebaseToken();
    if (token == null) throw Exception('กรุณาเข้าสู่ระบบก่อน');

    final response = await http.delete(
      Uri.parse('$_base/$catId'),
      headers: _headers(token),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      return; // สำเร็จ
    } else if (response.statusCode == 404) {
      throw Exception('ไม่พบข้อมูลแมว');
    } else if (response.statusCode == 401) {
      throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
    } else {
      throw Exception('ลบข้อมูลไม่สำเร็จ (${response.statusCode})');
    }
  }
}