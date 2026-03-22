import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;


part 'detect_event.dart';
part 'detect_state.dart';

class DetectCatBloc extends Bloc<DetectCatEvent, DetectCatState> {
  DetectCatBloc() : super(DetectCatInitial()) {
    on<DetectCatStarted>(_onStarted);
    on<DetectCatReset>(_onReset);
  }

  // ── Base URL ────────────────────────────────────────────────────────────────
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

  // ── Firebase Token ──────────────────────────────────────────────────────────
  Future<String?> _getToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      return await user.getIdToken();
    } catch (_) {
      return null;
    }
  }

  // ── Handler ─────────────────────────────────────────────────────────────────
  Future<void> _onStarted(
    DetectCatStarted event,
    Emitter<DetectCatState> emit,
  ) async {
    emit(DetectCatLoading());
    try {
      // ✅ อ่าน bytes รองรับทั้ง File และ XFile
      final bytes = await event.imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // ✅ ดึง extension รองรับทั้ง 2 แบบ
      final path = event.imageFile.path as String;
      final ext =
          path.contains('.') ? path.split('.').last.toLowerCase() : 'jpg';
      final mimeType = 'image/${ext == 'jpg' ? 'jpeg' : ext}';

      // 2. Firebase token
      final token = await _getToken();
      if (token == null) {
        emit(DetectCatFailure('กรุณาเข้าสู่ระบบก่อน'));
        return;
      }

      // 3. POST /api/detect/cat
      final response = await http
          .post(
            Uri.parse('${_getBaseUrl()}/api/detect/cat'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'image_base64': base64Image,
              'mime_type': mimeType,
            }),
          )
          .timeout(const Duration(seconds: 30));

      // 4. Parse response
      if (response.statusCode == 429) {
        emit(DetectCatQuotaExceeded());
        return;
      }

      if (response.statusCode != 200) {
        final err = jsonDecode(utf8.decode(response.bodyBytes));
        emit(DetectCatFailure(
            err['detail'] ?? 'ตรวจจับไม่สำเร็จ (${response.statusCode})'));
        return;
      }

      final json = jsonDecode(utf8.decode(response.bodyBytes));
      final result = DetectCatResult.fromJson(json);

      // 5. Emit ตาม result
      if (result.passed) {
        emit(DetectCatSuccess(result));
      } else {
        emit(DetectCatRejected(result));
      }
    } on http.ClientException {
      emit(DetectCatFailure('ไม่สามารถเชื่อมต่อ Server ได้'));
    } catch (e) {
      emit(DetectCatFailure(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onReset(DetectCatReset event, Emitter<DetectCatState> emit) {
    emit(DetectCatInitial());
  }
}
