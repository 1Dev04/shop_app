import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;

  AuthBloc({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance,
        super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthGoogleLoginRequested>(_onGoogleLoginRequested);
  }

  // ── Email + Password Login ────────────────────────────────────────────────
  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await _auth.signOut();

      final credential = await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password.trim(),
      );

      final idToken = await credential.user!.getIdToken(true);
      await _callBackendLogin(idToken!);

      emit(const AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure('Error: $e'));
    }
  }

  // ── Google Login ──────────────────────────────────────────────────────────
  Future<void> _onGoogleLoginRequested(
    AuthGoogleLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // ผู้ใช้ยกเลิกเอง
        emit(const AuthInitial());
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final idToken = await userCredential.user!.getIdToken(true);
      await _callBackendLogin(idToken!);

      emit(const AuthSuccess());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(_mapFirebaseError(e)));
    } catch (e) {
      emit(AuthFailure('Error: $e'));
    }
  }

  // ── Backend Login ─────────────────────────────────────────────────────────
  Future<void> _callBackendLogin(String idToken) async {
    final uri = Uri.parse('${_getBaseUrl()}/api/auth/login');
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw Exception('Backend login failed: ${response.body}');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      default:
        return e.message ?? 'Login failed';
    }
  }

  String _getBaseUrl() {
    const env = String.fromEnvironment('ENV', defaultValue: 'local');
    if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
    if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
    if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
    if (kIsWeb) return 'http://localhost:10000';
    if (Platform.isAndroid) return 'http://10.0.2.2:10000';
    return 'http://localhost:10000';
  }
}