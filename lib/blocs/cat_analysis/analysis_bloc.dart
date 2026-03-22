import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/api/service_cat_api.dart';
import 'package:flutter_application_1/screen/measure_size_cat.dart';
import 'package:http/http.dart' as http;

part 'analysis_event.dart';
part 'analysis_state.dart';

class CatAnalysisBloc extends Bloc<CatAnalysisEvent, CatAnalysisState> {
  final CatApiService _catApi;

  static const String _cloudinaryCloudName = 'dag73dhpl';
  static const String _cloudinaryUploadPreset = 'cat_img_detect';
  static const String _cloudinaryFolder = 'Fetch_Img_SizeCat';

  CatAnalysisBloc({CatApiService? catApi})
      : _catApi = catApi ?? CatApiService(),
        super(CatAnalysisInitial()) {
    on<CatImageSelected>(_onImageSelected);
    on<CatAnalysisStarted>(_onAnalysisStarted);
    on<CatAnalysisReset>(_onReset);
    on<CatDataUpdated>(_onDataUpdated);
    on<CatDataDeleted>(_onDataDeleted);
    on<CatPreloadSuccess>(_onPreloadSuccess);
  }

  // ── เลือกรูปแล้ว ──────────────────────────────────────
  void _onImageSelected(CatImageSelected event, Emitter emit) {
    emit(CatImageReady(event.imageFile));
  }

// ── เริ่มวิเคราะห์ ─────────────────────────────────────
  Future<void> _onAnalysisStarted(
    CatAnalysisStarted event,
    Emitter<CatAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CatImageReady) return;
    final imageFile = currentState.imageFile;

    try {
      emit(CatAnalysisUploading(imageFile));
      final imageUrl = await _uploadToCloudinary(imageFile);
      if (imageUrl == null) {
        emit(CatAnalysisFailure('อัปโหลดรูปภาพไม่สำเร็จ'));
        emit(CatAnalysisInitial());
        return;
      }

      final token = await _getFirebaseToken();
      if (token == null) {
        emit(CatAnalysisFailure('กรุณาเข้าสู่ระบบก่อนใช้งาน'));
        emit(CatAnalysisInitial());
        return;
      }

      emit(CatAnalysisAnalyzing(imageFile));

      // ✅ ส่ง measurements ไปด้วยถ้ามี
      final requestBody = <String, dynamic>{'image_cat': imageUrl};
      if (event.measurements != null && event.measurements!.isNotEmpty) {
        // กรอง null ออก ไม่ส่ง field ที่ไม่มีค่า
        final cleaned = Map<String, dynamic>.fromEntries(
          event.measurements!.entries.where((e) => e.value != null),
        );
        if (cleaned.isNotEmpty) {
          requestBody['measurements'] = cleaned;
        }
      }

      final response = await http
          .post(
            Uri.parse('${_getBaseUrl()}/api/vision/analyze-cat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 500) {
        final detail = body['detail'] ?? '';
        if (detail.contains('quota') ||
            detail.contains('429') ||
            detail.contains('RESOURCE_EXHAUSTED')) {
          emit(CatAnalysisQuotaExceeded());
          emit(CatAnalysisInitial());
          return;
        }
        emit(CatAnalysisFailure(detail.isNotEmpty ? detail : 'Server Error'));
        emit(CatAnalysisInitial());
        return;
      }
      if (response.statusCode == 401) {
        emit(CatAnalysisFailure('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่'));
        emit(CatAnalysisInitial());
        return;
      }
      if (response.statusCode != 200) {
        emit(CatAnalysisFailure('HTTP ${response.statusCode}'));
        emit(CatAnalysisInitial());
        return;
      }
      if (body['is_cat'] != true) {
        emit(CatAnalysisNotFound(body['message'] ?? 'ไม่พบแมวในภาพ'));
        emit(CatAnalysisInitial());
        return;
      }

      final recommendations = _parseRecommendations(body['recommendations']);
      emit(CatAnalysisSuccess(CatData.fromJson(body),
          recommendations: recommendations));
    } on TimeoutException {
      emit(CatAnalysisFailure('Backend ใช้เวลานานเกินไป'));
      emit(CatAnalysisInitial());
    } on http.ClientException {
    emit(CatAnalysisFailure('ไม่สามารถเชื่อมต่อ Backend ได้'));
      emit(CatAnalysisInitial());
    } catch (e) {
      emit(CatAnalysisFailure(e.toString().replaceAll('Exception: ', '')));
      emit(CatAnalysisInitial());
    }
  }

  // ── Reset ──────────────────────────────────────────────
  void _onReset(CatAnalysisReset event, Emitter emit) {
    emit(CatAnalysisInitial());
  }

// ── Preload จาก history ────────────────────────────────
  Future<void> _onPreloadSuccess(
    CatPreloadSuccess event,
    Emitter<CatAnalysisState> emit,
  ) async {
    try {
      final catRecord = await CatApiService().getCatById(event.catId);
      final cat = CatData(
        name: catRecord.catColor,
        breed: catRecord.breed,
        age: catRecord.age,
        // ✅ NULL-safe — ไม่ใช้ ?? 0.0
        weight: catRecord.weight ?? 0.0,
        chestCm: catRecord.chestCm,
        sizeCategory: catRecord.sizeCategory,
        neckCm: catRecord.neckCm,
        bodyLengthCm: catRecord.bodyLengthCm,
        confidence: catRecord.confidence ?? 0.0,
        boundingBox: [0, 0, 1, 1],
        imageUrl: catRecord.imageCat ?? '',
        detectedAt: catRecord.detectedAt ?? DateTime.now(),
        dbId: catRecord.id,
      );
      emit(CatAnalysisSuccess(cat));
    } catch (e) {
      emit(CatAnalysisFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

// ── Update ─────────────────────────────────────────────
  Future<void> _onDataUpdated(
    CatDataUpdated event,
    Emitter<CatAnalysisState> emit,
  ) async {
    final currentState = state;
    CatData? catData;
    List<Map<String, dynamic>> recommendations = const [];

    if (currentState is CatAnalysisSuccess) {
      catData = currentState.catData;
      recommendations = currentState.recommendations;
    } else if (currentState is CatDataUpdateSuccess) {
      catData = currentState.catData;
      recommendations = currentState.recommendations;
    }

    if (catData == null || catData.dbId == null) return;

    try {
      emit(CatDataUpdating(catData, recommendations: recommendations));
      await _catApi.updateCat(catData.dbId!, event.updateData);

      // ✅ อัปเดตทุก field จาก updateData รวม weight และ chestCm
      final newWeight = event.updateData['weight'] != null
          ? (event.updateData['weight'] as num).toDouble()
          : catData.weight;

      final newChestCm = event.updateData['chest_cm'] != null
          ? (event.updateData['chest_cm'] as num).toDouble()
          : catData.chestCm;

      final newNeckCm = event.updateData['neck_cm'] != null
          ? (event.updateData['neck_cm'] as num).toDouble()
          : catData.neckCm;

      final newBodyLengthCm = event.updateData['body_length_cm'] != null
          ? (event.updateData['body_length_cm'] as num).toDouble()
          : catData.bodyLengthCm;

      final updated = CatData(
        name: event.updateData['cat_color'] ?? catData.name,
        breed: event.updateData['breed'] ?? catData.breed,
        age: event.updateData['age'] != null
            ? (event.updateData['age'] as num).toInt()
            : catData.age,
        weight: newWeight, // ✅ ใช้ค่าใหม่
        sizeCategory: event.updateData['size_category'] ?? catData.sizeCategory,
        chestCm: newChestCm, // ✅ ใช้ค่าใหม่
        neckCm: newNeckCm, // ✅ ใช้ค่าใหม่
        bodyLengthCm: newBodyLengthCm,
        confidence: catData.confidence,
        boundingBox: catData.boundingBox,
        imageUrl: catData.imageUrl,
        thumbnailUrl: catData.thumbnailUrl,
        detectedAt: catData.detectedAt,
        dbId: catData.dbId,
      );

      emit(CatDataUpdateSuccess(
        updated,
        'บันทึกข้อมูลแล้ว ✅',
        recommendations: recommendations,
      ));
    } catch (e) {
      emit(CatAnalysisFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ── Delete ─────────────────────────────────────────────
  Future<void> _onDataDeleted(
    CatDataDeleted event,
    Emitter<CatAnalysisState> emit,
  ) async {
    final currentState = state;
    CatData? catData;

    if (currentState is CatAnalysisSuccess) catData = currentState.catData;
    if (currentState is CatDataUpdateSuccess) catData = currentState.catData;
    if (catData?.dbId == null) return;

    try {
      await _catApi.deleteCat(catData!.dbId!);
      emit(CatAnalysisInitial());
    } catch (e) {
      emit(CatAnalysisFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // ── Helpers ────────────────────────────────────────────

  /// Parse recommendations[] จาก backend response
  /// backend ส่ง List<Map> แต่ dynamic cast ต้องระวัง
  List<Map<String, dynamic>> _parseRecommendations(dynamic raw) {
    if (raw == null) return const [];
    try {
      return List<Map<String, dynamic>>.from(
        (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
      );
    } catch (_) {
      return const [];
    }
  }

  Future<String?> _getFirebaseToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadToCloudinary(dynamic imageFile) async {
  try {
    final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
    final request = http.MultipartRequest('POST', url);
    request.fields['upload_preset'] = _cloudinaryUploadPreset;
    request.fields['folder'] = _cloudinaryFolder;

    // ✅ Web ใช้ fromBytes แทน fromPath
    if (kIsWeb) {
      final bytes = await imageFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: 'cat_image.jpg',
      ));
    } else {
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
    }

    final response = await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes))['secure_url'];
    }
    return null;
  } catch (_) {
    return null;
  }
}

  String _getBaseUrl() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');
    if (env == 'prod') return 'https://backend-catshop.onrender.com';
    if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
    if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';

    // เช็ค kIsWeb ก่อน Platform เสมอ
    if (kIsWeb) return 'https://backend-catshop.onrender.com';

    // import dart:io เฉพาะ non-web
    return 'http://10.0.2.2:10000';
  }
}
