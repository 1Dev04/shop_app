import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  RegisterBloc({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        super(const RegisterInitial()) {
    on<RegisterSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // ตรวจ password ตรงกันก่อน
    if (event.password.trim() != event.confirmPassword.trim()) {
      emit(const RegisterFailure('password_mismatch'));
      return;
    }

    emit(const RegisterLoading());

    try {
      // 1. ตรวจอีเมลซ้ำใน Firestore
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: event.email.trim())
          .get();

      if (query.docs.isNotEmpty) {
        emit(const RegisterFailure('email_already_registered'));
        return;
      }

      // 2. สร้าง Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password.trim(),
      );

      final user = credential.user!;
      final idToken = await user.getIdToken(true);

      // 3. เรียก Backend register
      final response = await http.post(
        Uri.parse('${_getBaseUrl()}/api/auth/register'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) {
        throw Exception('Backend register failed: ${response.body}');
      }

      // 4. บันทึกข้อมูลลง Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': event.name.trim(),
        'password': event.password.trim(),
        'confirmPassword': event.confirmPassword.trim(),
        'email': event.email.trim(),
        'phone': event.phone.trim(),
        'postal': event.postal.trim(),
        'gender': event.gender ?? '',
        'birthdate': event.birthdate?.toIso8601String() ?? '',
        'subscribeNewsletter': event.subscribeNewsletter,
        'acceptTerms': event.acceptTerms,
        'createdAt': FieldValue.serverTimestamp(),
      });

      emit(const RegisterSuccess());
    } on FirebaseAuthException catch (e) {
      emit(RegisterFailure('firebase:${e.message ?? e.code}'));
    } catch (e) {
      emit(RegisterFailure('error:$e'));
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  String _getBaseUrl() {
    const env = String.fromEnvironment('ENV', defaultValue: 'local');
    if (env == 'prod') return 'https://backend-catshop.onrender.com';
    if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
    if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
    if (kIsWeb) return 'http://localhost:10000';
    if (Platform.isAndroid) return 'http://10.0.2.2:10000';
    return 'http://localhost:10000';
  }
}