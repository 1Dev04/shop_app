import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      // Step 1: Upload to Cloudinary
      emit(CatAnalysisUploading(imageFile));
      final imageUrl = await _uploadToCloudinary(imageFile);
      if (imageUrl == null) {
        emit(CatAnalysisFailure('อัปโหลดรูปภาพไม่สำเร็จ'));
        emit(CatAnalysisInitial());
        return;
      }

      // Step 2: Get Firebase token
      final token = await _getFirebaseToken();
      if (token == null) {
        emit(CatAnalysisFailure('กรุณาเข้าสู่ระบบก่อนใช้งาน'));
        emit(CatAnalysisInitial());
        return;
      }

      // Step 3: Analyze — backend จะ INSERT cat + query recommendations ให้เลย
      emit(CatAnalysisAnalyzing(imageFile));
      final response = await http
          .post(
            Uri.parse('${_getBaseUrl()}/api/vision/analyze-cat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'image_cat': imageUrl}),
          )
          .timeout(const Duration(seconds: 60));

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      // Step 4: Handle response
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

      // ✅ Parse recommendations จาก backend โดยตรง
      // vision.py ส่ง recommendations[] มาพร้อมกันเลย ไม่ต้อง call เพิ่ม
      final recommendations = _parseRecommendations(body['recommendations']);

      emit(CatAnalysisSuccess(
        CatData.fromJson(body),
        recommendations: recommendations,
      ));
    } on TimeoutException {
      emit(CatAnalysisFailure('Backend ใช้เวลานานเกินไป'));
      emit(CatAnalysisInitial());
    } on SocketException {
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
        weight: catRecord.weight ?? 0.0,
        sizeCategory: catRecord.sizeCategory,
        chestCm: catRecord.chestCm ?? 0.0,
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

    // ดึง catData + recommendations จาก state ปัจจุบัน
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

      final updated = CatData(
        name: event.updateData['cat_color'] ?? catData.name,
        breed: event.updateData['breed'] ?? catData.breed,
        age: event.updateData['age'] ?? catData.age,
        weight: catData.weight,
        sizeCategory: event.updateData['size_category'] ?? catData.sizeCategory,
        chestCm: catData.chestCm,
        neckCm: catData.neckCm,
        bodyLengthCm: catData.bodyLengthCm,
        confidence: catData.confidence,
        boundingBox: catData.boundingBox,
        imageUrl: catData.imageUrl,
        thumbnailUrl: catData.thumbnailUrl,
        detectedAt: catData.detectedAt,
        dbId: catData.dbId,
      );

      // ✅ ส่ง recommendations ต่อไปให้ state ใหม่ด้วย — ไม่หายหลัง edit
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

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/$_cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = _cloudinaryUploadPreset;
      request.fields['folder'] = _cloudinaryFolder;
      request.files
          .add(await http.MultipartFile.fromPath('file', imageFile.path));
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
    if (kIsWeb) return 'http://localhost:10000';
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:10000';
    return 'http://localhost:10000';
  }
}
