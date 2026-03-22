// lib/blocs/home/home_bloc.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final BasketApiService _basketApi;

  HomeBloc({BasketApiService? basketApi})
      : _basketApi = basketApi ?? BasketApiService(),
        super(const HomeInitial()) {
    on<HomeAdsLoadRequested>(_onAdsLoadRequested);
    on<HomeItemDetailRequested>(_onItemDetailRequested);
    on<HomeAddToBasketRequested>(_onAddToBasketRequested);
  }

  // ── Load Ads ──────────────────────────────────────────────────────────────
  Future<void> _onAdsLoadRequested(
    HomeAdsLoadRequested event,
    Emitter<HomeState> emit,
  ) async {
    emit(const HomeLoading());
    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/home-advertiment'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final List<Map<String, dynamic>> ads = _parseAds(data);
        emit(HomeLoaded(ads));
      } else {
        emit(HomeFailure(
            'ไม่สามารถโหลดข้อมูลได้ (${response.statusCode})'));
      }
    } on SocketException {
      emit(const HomeFailure(
          'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend'));
    } on TimeoutException {
      emit(const HomeFailure('หมดเวลาการเชื่อมต่อ'));
    } catch (e) {
      emit(HomeFailure('เกิดข้อผิดพลาด: $e'));
    }
  }

  // ── Load Item Detail ──────────────────────────────────────────────────────
  Future<void> _onItemDetailRequested(
    HomeItemDetailRequested event,
    Emitter<HomeState> emit,
  ) async {
    final ads = _currentAds;
    emit(HomeItemDetailLoading(ads));

    try {
      final response = await http.get(
        Uri.parse('${_getBaseUrl()}/api/home-advertiment/${event.itemId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        Map<String, dynamic>? item;

        if (data is Map && data.containsKey('data')) {
          item = Map<String, dynamic>.from(data['data']);
        } else if (data is Map) {
          item = Map<String, dynamic>.from(data);
        }

        if (item != null) {
          final rawImages = item['images'];
          item['images'] = rawImages is String
              ? jsonDecode(rawImages)
              : rawImages ?? <String, dynamic>{};

          emit(HomeItemDetailLoaded(ads: ads, itemDetail: item));
        } else {
          emit(HomeItemDetailFailure(ads));
        }
      } else {
        emit(HomeItemDetailFailure(ads));
      }
    } catch (e) {
      emit(HomeItemDetailFailure(ads));
    }
  }

  // ── Add to Basket ─────────────────────────────────────────────────────────
  Future<void> _onAddToBasketRequested(
    HomeAddToBasketRequested event,
    Emitter<HomeState> emit,
  ) async {
    final ads = _currentAds;
    emit(HomeBasketActionInProgress(ads));

    try {
      await _basketApi.addToBasket(clothingUuid: event.clothingUuid);
      emit(HomeBasketActionSuccess(ads));
    } catch (e) {
      emit(HomeBasketActionFailure(ads: ads, message: 'basket_failed:$e'));
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _currentAds {
    final s = state;
    if (s is HomeLoaded) return s.ads;
    if (s is HomeItemDetailLoading) return s.ads;
    if (s is HomeItemDetailLoaded) return s.ads;
    if (s is HomeItemDetailFailure) return s.ads;
    if (s is HomeBasketActionInProgress) return s.ads;
    if (s is HomeBasketActionSuccess) return s.ads;
    if (s is HomeBasketActionFailure) return s.ads;
    return [];
  }

  List<Map<String, dynamic>> _parseAds(dynamic data) {
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map && data.containsKey('data')) {
      raw = data['data'] as List;
    }
    return raw.map<Map<String, dynamic>>((item) {
      final rawImages = item['images'];
      return {
        ...item as Map<String, dynamic>,
        'images':
            rawImages is String ? jsonDecode(rawImages) : rawImages,
      };
    }).toList();
  }

  String _getBaseUrl() {
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod')    return 'https://backend-catshop.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
  
  // เช็ค kIsWeb ก่อน Platform เสมอ
  if (kIsWeb) return 'https://backend-catshop.onrender.com';
  
  // import dart:io เฉพาะ non-web
  return 'http://10.0.2.2:10000';
  }
}