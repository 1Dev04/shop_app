import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_application_1/components/search_page.dart'
    show ClothingItem, SearchCategory;

part 'search_event.dart';
part 'search_state.dart';

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

  static Uri autocomplete(String query) => Uri.parse(
      query.isEmpty ? '$base/api/search/autocomplete' : '$base/api/search/autocomplete?query=$query');

  static Uri clothing({int? categoryId, int? gender, int page = 1, int pageSize = 10}) {
    final params = <String>[];
    if (categoryId != null) params.add('category_id=$categoryId');
    if (gender != null) params.add('gender=$gender');
    params.add('page=$page');
    params.add('page_size=$pageSize');
    return Uri.parse('$base/api/search/clothing?${params.join('&')}');
  }

  static Uri outfit(int itemId, {int? gender}) {
    final url = '$base/api/search/btn/outfit/$itemId';
    return Uri.parse(gender != null ? '$url?gender=$gender' : url);
  }
}

// ============================================================================
// SearchBloc
// ============================================================================

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(const SearchInitial()) {
    on<SearchAutocompleteRequested>(_onAutocomplete);
    on<SearchSuggestionSelected>(_onSuggestionSelected);
    on<SearchGenderFilterChanged>(_onGenderFilterChanged);
    on<SearchPageChanged>(_onPageChanged);
    on<SearchAddToBasketRequested>(_onAddToBasket);
    on<SearchItemDetailRequested>(_onItemDetail);
    on<SearchCleared>(_onCleared);
  }

  static const int _pageSize = 10;

  // ── helper: ดึงข้อมูลจาก state ปัจจุบัน ───────────────────────────────────

  _SearchData _dataFromState() {
    final s = state;
    if (s is SearchLoaded) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: s.outfits,
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: s.hasSelected,
      );
    }
    if (s is SearchResultsLoading) {
      return _SearchData(
        suggestions: s.suggestions,
        results: const [],
        outfits: s.outfits,
        currentPage: 1,
        totalPages: 1,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: true,
      );
    }
    if (s is SearchOutfitsLoading) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: const [],
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: true,
      );
    }
    if (s is SearchBasketInProgress) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: s.outfits,
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: s.hasSelected,
      );
    }
    if (s is SearchBasketSuccess) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: s.outfits,
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: s.hasSelected,
      );
    }
    if (s is SearchBasketFailure) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: s.outfits,
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: s.hasSelected,
      );
    }
    if (s is SearchItemDetailReady) {
      return _SearchData(
        suggestions: s.suggestions,
        results: s.results,
        outfits: s.outfits,
        currentPage: s.currentPage,
        totalPages: s.totalPages,
        selectedCategoryId: s.selectedCategoryId,
        selectedGender: s.selectedGender,
        showGenderFilters: s.showGenderFilters,
        hasSelected: s.hasSelected,
      );
    }
    // Initial / fallback
    return _SearchData(
      suggestions: state is SearchInitial
          ? (state as SearchInitial).suggestions
          : const [],
      results: const [],
      outfits: const [],
      currentPage: 1,
      totalPages: 1,
      selectedCategoryId: null,
      selectedGender: null,
      showGenderFilters: false,
      hasSelected: false,
    );
  }

  // ── Fetch helpers ──────────────────────────────────────────────────────────

  Future<List<SearchCategory>> _fetchAutocomplete(String query) async {
    final res = await http
        .get(_Api.autocomplete(query))
        .timeout(const Duration(seconds: 5));
    if (res.statusCode != 200) return [];
    final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
    return data.map((j) => SearchCategory.fromJson(j)).toList();
  }

  Future<({List<ClothingItem> items, int totalPages})> _fetchClothing({
    int? categoryId,
    int? gender,
    int page = 1,
  }) async {
    final res = await http
        .get(_Api.clothing(
            categoryId: categoryId,
            gender: gender,
            page: page,
            pageSize: _pageSize))
        .timeout(_Api.timeout);
    if (res.statusCode != 200) return (items: <ClothingItem>[], totalPages: 1);
    final data = json.decode(utf8.decode(res.bodyBytes));
    final List<dynamic> items = data['items'];
    return (
      items: items.map((j) => ClothingItem.fromJson(j)).toList(),
      totalPages: (data['total_pages'] as int?) ?? 1,
    );
  }

  Future<List<ClothingItem>> _fetchOutfits(int itemId, {int? gender}) async {
    final res = await http
        .get(_Api.outfit(itemId, gender: gender))
        .timeout(_Api.timeout);
    if (res.statusCode != 200) return [];
    final List<dynamic> data = json.decode(utf8.decode(res.bodyBytes));
    return data.map((j) => ClothingItem.fromJson(j)).toList();
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onAutocomplete(
    SearchAutocompleteRequested event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final suggestions = await _fetchAutocomplete(event.query);
      final d = _dataFromState();
      if (d.hasSelected) return; // ถ้าเลือกแล้วไม่ update suggestions
      emit(SearchInitial(suggestions: suggestions));
    } catch (_) {}
  }

  Future<void> _onSuggestionSelected(
    SearchSuggestionSelected event,
    Emitter<SearchState> emit,
  ) async {
    final cat = event.category;
    int? categoryId;
    int? gender;
    bool showGenderFilters = false;

    if (cat.categoryType == 'gender') {
      gender = cat.id == 0 ? null : cat.id;
    } else {
      categoryId = cat.id;
      showGenderFilters = true;
    }

    // emit loading ก่อน
    emit(SearchOutfitsLoading(
      suggestions: const [],
      results: const [],
      currentPage: 1,
      totalPages: 1,
      selectedCategoryId: categoryId,
      selectedGender: gender,
      showGenderFilters: showGenderFilters,
    ));

    try {
      final outfits = await _fetchOutfits(cat.id, gender: gender);
      emit(SearchLoaded(
        suggestions: const [],
        results: const [],
        outfits: outfits,
        currentPage: 1,
        totalPages: 1,
        selectedCategoryId: categoryId,
        selectedGender: gender,
        showGenderFilters: showGenderFilters,
        hasSelected: true,
      ));
    } catch (_) {
      emit(SearchLoaded(
        suggestions: const [],
        results: const [],
        outfits: const [],
        currentPage: 1,
        totalPages: 1,
        selectedCategoryId: categoryId,
        selectedGender: gender,
        showGenderFilters: showGenderFilters,
        hasSelected: true,
      ));
    }
  }

  Future<void> _onGenderFilterChanged(
    SearchGenderFilterChanged event,
    Emitter<SearchState> emit,
  ) async {
    final d = _dataFromState();
    if (d.selectedCategoryId == null) return;

    emit(SearchOutfitsLoading(
      suggestions: d.suggestions,
      results: d.results,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
      selectedCategoryId: d.selectedCategoryId,
      selectedGender: event.gender,
      showGenderFilters: d.showGenderFilters,
    ));

    try {
      final outfits = await _fetchOutfits(
        d.selectedCategoryId!,
        gender: event.gender,
      );
      emit(SearchLoaded(
        suggestions: d.suggestions,
        results: d.results,
        outfits: outfits,
        currentPage: d.currentPage,
        totalPages: d.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: event.gender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
      ));
    } catch (_) {
      emit(SearchLoaded(
        suggestions: d.suggestions,
        results: d.results,
        outfits: const [],
        currentPage: d.currentPage,
        totalPages: d.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: event.gender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
      ));
    }
  }

  Future<void> _onPageChanged(
    SearchPageChanged event,
    Emitter<SearchState> emit,
  ) async {
    final d = _dataFromState();

    emit(SearchResultsLoading(
      suggestions: d.suggestions,
      outfits: d.outfits,
      selectedCategoryId: d.selectedCategoryId,
      selectedGender: d.selectedGender,
      showGenderFilters: d.showGenderFilters,
    ));

    try {
      final result = await _fetchClothing(
        categoryId: d.selectedCategoryId,
        gender: d.selectedGender,
        page: event.page,
      );
      emit(SearchLoaded(
        suggestions: d.suggestions,
        results: result.items,
        outfits: d.outfits,
        currentPage: event.page,
        totalPages: result.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: d.selectedGender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
      ));
    } catch (_) {
      emit(SearchLoaded(
        suggestions: d.suggestions,
        results: const [],
        outfits: d.outfits,
        currentPage: d.currentPage,
        totalPages: d.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: d.selectedGender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
      ));
    }
  }

  Future<void> _onAddToBasket(
    SearchAddToBasketRequested event,
    Emitter<SearchState> emit,
  ) async {
    final d = _dataFromState();
    final uuid = event.item.rawJson['uuid']?.toString() ??
        event.item.rawJson['clothing_uuid']?.toString() ??
        event.item.uuid;

    emit(SearchBasketInProgress(
      suggestions: d.suggestions,
      results: d.results,
      outfits: d.outfits,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
      selectedCategoryId: d.selectedCategoryId,
      selectedGender: d.selectedGender,
      showGenderFilters: d.showGenderFilters,
      hasSelected: d.hasSelected,
      basketUuid: uuid,
    ));

    try {
      await BasketApiService().addToBasket(clothingUuid: uuid, quantity: 1);
      emit(SearchBasketSuccess(
        suggestions: d.suggestions,
        results: d.results,
        outfits: d.outfits,
        currentPage: d.currentPage,
        totalPages: d.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: d.selectedGender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
      ));
    } catch (e) {
      emit(SearchBasketFailure(
        suggestions: d.suggestions,
        results: d.results,
        outfits: d.outfits,
        currentPage: d.currentPage,
        totalPages: d.totalPages,
        selectedCategoryId: d.selectedCategoryId,
        selectedGender: d.selectedGender,
        showGenderFilters: d.showGenderFilters,
        hasSelected: d.hasSelected,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onItemDetail(
    SearchItemDetailRequested event,
    Emitter<SearchState> emit,
  ) async {
    final d = _dataFromState();
    emit(SearchItemDetailReady(
      suggestions: d.suggestions,
      results: d.results,
      outfits: d.outfits,
      currentPage: d.currentPage,
      totalPages: d.totalPages,
      selectedCategoryId: d.selectedCategoryId,
      selectedGender: d.selectedGender,
      showGenderFilters: d.showGenderFilters,
      hasSelected: d.hasSelected,
      selectedItem: event.item,
    ));
  }

  Future<void> _onCleared(
    SearchCleared event,
    Emitter<SearchState> emit,
  ) async {
    try {
      final suggestions = await _fetchAutocomplete('');
      emit(SearchInitial(suggestions: suggestions));
    } catch (_) {
      emit(const SearchInitial());
    }
  }
}

// ── Internal data holder ────────────────────────────────────────────────────

class _SearchData {
  final List<SearchCategory> suggestions;
  final List<ClothingItem> results;
  final List<ClothingItem> outfits;
  final int currentPage;
  final int totalPages;
  final int? selectedCategoryId;
  final int? selectedGender;
  final bool showGenderFilters;
  final bool hasSelected;

  const _SearchData({
    required this.suggestions,
    required this.results,
    required this.outfits,
    required this.currentPage,
    required this.totalPages,
    required this.selectedCategoryId,
    required this.selectedGender,
    required this.showGenderFilters,
    required this.hasSelected,
  });
}