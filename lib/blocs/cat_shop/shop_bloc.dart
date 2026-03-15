import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

part 'shop_event.dart';
part 'shop_state.dart';

// ============================================================================
// API Config
// ============================================================================

String _getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://backend-catshop.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';
  if (kIsWeb) return 'http://localhost:10000';
  if (Platform.isAndroid) return 'http://10.0.2.2:10000';
  return 'http://localhost:10000';
}

class _Api {
  static String get base => _getBaseUrl();
  static const Duration timeout = Duration(seconds: 10);
  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Uri like() => Uri.parse('$base/api/clothing-shop/like');
  static Uri seller() => Uri.parse('$base/api/clothing-shop/seller');
  static Uri detail(int id) => Uri.parse('$base/api/home-advertiment/$id');
}

// ============================================================================
// ShopBloc
// ============================================================================

class ShopBloc extends Bloc<ShopEvent, ShopState> {
  ShopBloc() : super(const ShopInitial()) {
    on<ShopLoadRequested>(_onLoad);
    on<ShopItemDetailRequested>(_onItemDetail);
    on<ShopAddToBasketRequested>(_onAddToBasket);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _likeFromState() {
    final s = state;
    if (s is ShopLoaded) return s.likeItems;
    if (s is ShopItemDetailLoading) return s.likeItems;
    if (s is ShopItemDetailLoaded) return s.likeItems;
    if (s is ShopItemDetailFailure) return s.likeItems;
    if (s is ShopBasketInProgress) return s.likeItems;
    if (s is ShopBasketSuccess) return s.likeItems;
    if (s is ShopBasketFailure) return s.likeItems;
    return [];
  }

  List<Map<String, dynamic>> _sellerFromState() {
    final s = state;
    if (s is ShopLoaded) return s.sellerItems;
    if (s is ShopItemDetailLoading) return s.sellerItems;
    if (s is ShopItemDetailLoaded) return s.sellerItems;
    if (s is ShopItemDetailFailure) return s.sellerItems;
    if (s is ShopBasketInProgress) return s.sellerItems;
    if (s is ShopBasketSuccess) return s.sellerItems;
    if (s is ShopBasketFailure) return s.sellerItems;
    return [];
  }

  // ── parse items ────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _parseItems(dynamic data) {
    List<dynamic> raw = [];
    if (data is List) {
      raw = data;
    } else if (data is Map && data.containsKey('data')) {
      raw = data['data']; // ✅ ลบ "as List<dynamic>" ออก
    }
    return raw.map<Map<String, dynamic>>((item) {
      final rawImages = item['images'];
      return {
        ...item,
        'images': rawImages is String ? jsonDecode(rawImages) : rawImages,
      };
    }).toList();
  }

  // ── handlers ───────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    ShopLoadRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(const ShopLoading());

    String likeError = '';
    String sellerError = '';
    List<Map<String, dynamic>> likeItems = [];
    List<Map<String, dynamic>> sellerItems = [];

    // โหลดพร้อมกัน
    await Future.wait([
      () async {
        try {
          final res = await http
              .get(_Api.like(), headers: _Api.headers)
              .timeout(_Api.timeout);
          if (res.statusCode == 200) {
            likeItems = _parseItems(json.decode(utf8.decode(res.bodyBytes)));
          } else {
            likeError = 'ไม่สามารถโหลดข้อมูลได้ (${res.statusCode})';
          }
        } on SocketException {
          likeError = 'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend';
        } on TimeoutException {
          likeError = 'หมดเวลาการเชื่อมต่อ';
        } catch (e) {
          likeError = 'เกิดข้อผิดพลาด: $e';
        }
      }(),
      () async {
        try {
          final res = await http
              .get(_Api.seller(), headers: _Api.headers)
              .timeout(_Api.timeout);
          if (res.statusCode == 200) {
            sellerItems = _parseItems(json.decode(utf8.decode(res.bodyBytes)));
          } else {
            sellerError = 'ไม่สามารถโหลดข้อมูลได้ (${res.statusCode})';
          }
        } on SocketException {
          sellerError = 'ไม่สามารถเชื่อมต่อได้\nกรุณาตรวจสอบ Backend';
        } on TimeoutException {
          sellerError = 'หมดเวลาการเชื่อมต่อ';
        } catch (e) {
          sellerError = 'เกิดข้อผิดพลาด: $e';
        }
      }(),
    ]);

    if (likeError.isNotEmpty || sellerError.isNotEmpty) {
      emit(ShopFailure(likeError: likeError, sellerError: sellerError));
    } else {
      emit(ShopLoaded(likeItems: likeItems, sellerItems: sellerItems));
    }
  }

  Future<void> _onItemDetail(
    ShopItemDetailRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(ShopItemDetailLoading(
      likeItems: _likeFromState(),
      sellerItems: _sellerFromState(),
    ));

    try {
      final res = await http
          .get(_Api.detail(event.itemId), headers: _Api.headers)
          .timeout(_Api.timeout);

      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        final detail = data is Map && data.containsKey('data')
            ? Map<String, dynamic>.from(data['data'])
            : Map<String, dynamic>.from(data);

        emit(ShopItemDetailLoaded(
          likeItems: _likeFromState(),
          sellerItems: _sellerFromState(),
          itemDetail: detail,
        ));
      } else {
        emit(ShopItemDetailFailure(
          likeItems: _likeFromState(),
          sellerItems: _sellerFromState(),
        ));
      }
    } catch (_) {
      emit(ShopItemDetailFailure(
        likeItems: _likeFromState(),
        sellerItems: _sellerFromState(),
      ));
    }
  }

  Future<void> _onAddToBasket(
    ShopAddToBasketRequested event,
    Emitter<ShopState> emit,
  ) async {
    emit(ShopBasketInProgress(
      likeItems: _likeFromState(),
      sellerItems: _sellerFromState(),
      uuid: event.uuid,
    ));

    try {
      await BasketApiService().addToBasket(clothingUuid: event.uuid);
      emit(ShopBasketSuccess(
        likeItems: _likeFromState(),
        sellerItems: _sellerFromState(),
      ));
    } catch (e) {
      emit(ShopBasketFailure(
        likeItems: _likeFromState(),
        sellerItems: _sellerFromState(),
        errorMessage: e.toString(),
      ));
    }
  }
}