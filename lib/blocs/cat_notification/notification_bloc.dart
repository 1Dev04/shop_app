import 'dart:convert';


import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:http/http.dart' as http;

// import models จาก notification_page (หรือย้าย model มาไว้ที่นี่ก็ได้)
import 'package:flutter_application_1/components/notification_page.dart'
    show NotificationItemMess, NotificationItemNews;

part 'notification_event.dart';
part 'notification_state.dart';

// ============================================================================
// API Config (ย้ายมาจาก notification_page)
// ============================================================================

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

class _ApiConfig {
  static String get baseUrl => _getBaseUrl();
  static const Duration timeout = Duration(seconds: 10);

  static Uri messagesUri() => Uri.parse('$baseUrl/api/notifications/messages');
  static Uri messageDetailUri(String id) =>
      Uri.parse('$baseUrl/api/notifications/messages/$id');
  static Uri newsUri() => Uri.parse('$baseUrl/api/notifications/news');
  static Uri newsDetailUri(String id) =>
      Uri.parse('$baseUrl/api/notifications/news/$id');
}

// ============================================================================
// NotificationBloc
// ============================================================================

class NotificationBloc
    extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(const NotificationInitial()) {
    on<NotificationLoadRequested>(_onLoad);
    on<NotificationRefreshRequested>(_onRefresh);
    on<NotificationMessageDetailRequested>(_onMessageDetail);
    on<NotificationNewsDetailRequested>(_onNewsDetail);
    on<NotificationAddToBasketRequested>(_onAddToBasket);
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  List<NotificationItemMess> _messagesFromState() {
    final s = state;
    if (s is NotificationLoaded) return s.messages;
    if (s is NotificationDetailLoading) return s.messages;
    if (s is NotificationDetailLoaded) return s.messages;
    if (s is NotificationDetailFailure) return s.messages;
    if (s is NotificationBasketInProgress) return s.messages;
    if (s is NotificationBasketSuccess) return s.messages;
    if (s is NotificationBasketFailure) return s.messages;
    return [];
  }

  List<NotificationItemNews> _newsFromState() {
    final s = state;
    if (s is NotificationLoaded) return s.news;
    if (s is NotificationDetailLoading) return s.news;
    if (s is NotificationDetailLoaded) return s.news;
    if (s is NotificationDetailFailure) return s.news;
    if (s is NotificationBasketInProgress) return s.news;
    if (s is NotificationBasketSuccess) return s.news;
    if (s is NotificationBasketFailure) return s.news;
    return [];
  }

  String _errorMessage(dynamic e) {
    final str = e.toString();
    if (str.contains('TimeoutException')) {
      return 'Request timeout. Please check your connection.';
    }
    if (str.contains('SocketException')) return 'No internet connection';
    return 'Error: $str';
  }

  // ── fetch helpers ───────────────────────────────────────────────────────────

  Future<List<NotificationItemMess>> _fetchMessages() async {
    final res = await http
        .get(_ApiConfig.messagesUri())
        .timeout(_ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load messages (${res.statusCode})');
    }
    final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
    return data.map((j) => NotificationItemMess.fromJson(j)).toList();
  }

  Future<List<NotificationItemNews>> _fetchNews() async {
    final res =
        await http.get(_ApiConfig.newsUri()).timeout(_ApiConfig.timeout);
    if (res.statusCode != 200) {
      throw Exception('Failed to load news (${res.statusCode})');
    }
    final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
    return data.map((j) => NotificationItemNews.fromJson(j)).toList();
  }

  // ── handlers ────────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    NotificationLoadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(const NotificationLoading());
    try {
      final messages = await _fetchMessages();
      final news = await _fetchNews();
      emit(NotificationLoaded(messages: messages, news: news));
    } catch (e) {
      emit(NotificationFailure(_errorMessage(e)));
    }
  }

  Future<void> _onRefresh(
    NotificationRefreshRequested event,
    Emitter<NotificationState> emit,
  ) async {
    // refresh โดยไม่ซ่อน UI เดิม
    try {
      final messages = await _fetchMessages();
      final news = await _fetchNews();
      emit(NotificationLoaded(messages: messages, news: news));
    } catch (e) {
      // refresh ล้มเหลว → เก็บข้อมูลเดิมไว้ แค่ emit failure
      emit(NotificationDetailFailure(
        messages: _messagesFromState(),
        news: _newsFromState(),
        errorMessage: _errorMessage(e),
      ));
    }
  }

  Future<void> _onMessageDetail(
    NotificationMessageDetailRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationDetailLoading(
      messages: _messagesFromState(),
      news: _newsFromState(),
    ));
    try {
      final res = await http
          .get(_ApiConfig.messageDetailUri(event.id))
          .timeout(_ApiConfig.timeout);
      if (res.statusCode != 200) {
        throw Exception('Failed to load message detail (${res.statusCode})');
      }
      final data = json.decode(utf8.decode(res.bodyBytes));
      final item = NotificationItemMess.fromJson(data);
      emit(NotificationDetailLoaded(
        messages: _messagesFromState(),
        news: _newsFromState(),
        itemDetail: item,
      ));
    } catch (e) {
      emit(NotificationDetailFailure(
        messages: _messagesFromState(),
        news: _newsFromState(),
        errorMessage: _errorMessage(e),
      ));
    }
  }

  Future<void> _onNewsDetail(
    NotificationNewsDetailRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationDetailLoading(
      messages: _messagesFromState(),
      news: _newsFromState(),
    ));
    try {
      final res = await http
          .get(_ApiConfig.newsDetailUri(event.id))
          .timeout(_ApiConfig.timeout);
      if (res.statusCode != 200) {
        throw Exception('Failed to load news detail (${res.statusCode})');
      }
      final data = json.decode(utf8.decode(res.bodyBytes));
      final item = NotificationItemNews.fromJson(data);
      emit(NotificationDetailLoaded(
        messages: _messagesFromState(),
        news: _newsFromState(),
        itemDetail: item,
      ));
    } catch (e) {
      emit(NotificationDetailFailure(
        messages: _messagesFromState(),
        news: _newsFromState(),
        errorMessage: _errorMessage(e),
      ));
    }
  }

  Future<void> _onAddToBasket(
    NotificationAddToBasketRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(NotificationBasketInProgress(
      messages: _messagesFromState(),
      news: _newsFromState(),
      uuid: event.uuid,
    ));
    try {
      await BasketApiService().addToBasket(clothingUuid: event.uuid);
      emit(NotificationBasketSuccess(
        messages: _messagesFromState(),
        news: _newsFromState(),
      ));
    } catch (e) {
      emit(NotificationBasketFailure(
        messages: _messagesFromState(),
        news: _newsFromState(),
        errorMessage: _errorMessage(e),
      ));
    }
  }
}