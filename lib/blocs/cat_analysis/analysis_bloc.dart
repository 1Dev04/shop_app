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
      // Step 1: Upload
      emit(CatAnalysisUploading(imageFile));
      final imageUrl = await _uploadToCloudinary(imageFile);
      if (imageUrl == null) {
        emit(CatAnalysisFailure('อัปโหลดรูปภาพไม่สำเร็จ'));
        emit(CatAnalysisInitial());
        return;
      };

      // Step 2: Get token
      final token = await _getFirebaseToken();
      if (token == null) {
        emit(CatAnalysisFailure('กรุณาเข้าสู่ระบบก่อนใช้งาน'));
        emit(CatAnalysisInitial());
        return;
      }

      // Step 3: Analyze
      emit(CatAnalysisAnalyzing(imageFile));
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/vision/analyze-cat'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        // ✅ FIX: ใช้ image_cat ให้ตรงกับที่ backend ต้องการ
        body: jsonEncode({'image_cat': imageUrl}),
      ).timeout(const Duration(seconds: 60));

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
        // ✅ FIX: emit กลับไป CatImageReady เพื่อให้ยังเห็นรูปและกด Analyze ใหม่ได้
        // แทนที่จะเป็น state ที่ไม่มี UI รองรับ
        emit(CatAnalysisNotFound(body['message'] ?? 'ไม่พบแมวในภาพ'));
        // Reset กลับให้ user ถ่ายรูปใหม่
        emit(CatAnalysisInitial());
        return;
      }

      emit(CatAnalysisSuccess(CatData.fromJson(body)));
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

  // ── Update ─────────────────────────────────────────────
  Future<void> _onDataUpdated(
    CatDataUpdated event,
    Emitter<CatAnalysisState> emit,
  ) async {
    final currentState = state;
    if (currentState is! CatAnalysisSuccess &&
        currentState is! CatDataUpdateSuccess) return;

    final catData = currentState is CatAnalysisSuccess
        ? currentState.catData
        : (currentState as CatDataUpdateSuccess).catData;

    if (catData.dbId == null) return;

    try {
      emit(CatDataUpdating(catData));
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

      emit(CatDataUpdateSuccess(updated, 'บันทึกข้อมูลแล้ว ✅'));
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
      final response =
          await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes))['secure_url'];
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ✅ FIX: เพิ่ม 'prod' env กลับมา (หายไปในโค้ดใหม่)
  String _getBaseUrl() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');
    if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
    if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
    if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
    if (kIsWeb) return 'http://localhost:10000';
    if (Platform.isAndroid) return 'http://10.0.2.2:10000';
    return 'http://localhost:10000';
  }
}