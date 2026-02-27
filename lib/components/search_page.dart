// SearchPage — refactored with BLoC

import 'dart:async';
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/blocs/cat_search/search_bloc.dart';

import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

// ============================================================================
// Helper
// ============================================================================

double _parseDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final cleaned = value.replaceAll('THB', '').replaceAll('%', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }
  return 0.0;
}

int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

// ============================================================================
// Models (คงไว้ที่ search_page.dart เพราะ bloc import จากที่นี่)
// ============================================================================

class SearchCategory {
  final int id;
  final String name;
  final String categoryType;

  SearchCategory({required this.id, required this.name, required this.categoryType});

  factory SearchCategory.fromJson(Map<String, dynamic> json) {
    return SearchCategory(
      id: json['id'],
      name: json['name_category'] ?? '',
      categoryType: json['category_type'] ?? '',
    );
  }
}

class ClothingItem {
  final int id;
  final String uuid;
  final String imageUrl;
  final Map<String, dynamic> images;
  final String clothingName;
  final String description;
  final dynamic category;
  final String? categoryNameEn;
  final String? categoryNameTh;
  final String sizeCategory;
  final double price;
  final double? discountPrice;
  final int? discountPercent;
  final int gender;
  final int stock;
  final String breed;
  final Map<String, dynamic> rawJson;

  ClothingItem({
    required this.id,
    required this.uuid,
    required this.imageUrl,
    required this.images,
    required this.clothingName,
    required this.description,
    required this.category,
    this.categoryNameEn,
    this.categoryNameTh,
    required this.sizeCategory,
    required this.price,
    this.discountPrice,
    this.discountPercent,
    required this.gender,
    required this.stock,
    required this.breed,
    required this.rawJson,
  });

  static Map<String, dynamic> _parseImages(dynamic value) {
    try {
      if (value == null) return {};
      if (value is Map) return Map<String, dynamic>.from(value);
      if (value is String && value.isNotEmpty) {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    final uuid = json['uuid']?.toString() ??
        json['clothing_uuid']?.toString() ??
        json['item_uuid']?.toString() ??
        '';
    return ClothingItem(
      id: _parseInt(json['id']),
      uuid: uuid,
      imageUrl: json['image_url']?.toString() ?? '',
      images: _parseImages(json['images']),
      clothingName: json['clothing_name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category'],
      categoryNameEn: json['category_name_en']?.toString(),
      categoryNameTh: json['category_name_th']?.toString(),
      sizeCategory: json['size_category']?.toString() ?? '',
      price: _parseDouble(json['price']),
      discountPrice: json['discount_price'] != null
          ? _parseDouble(json['discount_price'])
          : null,
      discountPercent: json['discount_percent'] != null
          ? _parseInt(json['discount_percent'])
          : null,
      gender: _parseInt(json['gender']),
      stock: _parseInt(json['stock']),
      breed: json['breed']?.toString() ?? '',
      rawJson: Map<String, dynamic>.from(json),
    );
  }
}

// ============================================================================
// GradientText
// ============================================================================

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final LinearGradient gradient;

  const GradientText({
    super.key,
    required this.text,
    required this.gradient,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) =>
          gradient.createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
      child: Text(text, style: style.copyWith(color: Colors.white)),
    );
  }
}

// ============================================================================
// SearchPage — entry point
// ============================================================================

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SearchBloc()
        ..add(const SearchAutocompleteRequested('')),
      child: const _SearchView(),
    );
  }
}

// ============================================================================
// _SearchView
// ============================================================================

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final query = _searchController.text.trim();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SearchBloc>().add(SearchAutocompleteRequested(query));
    });
  }

  void _showItemDetailPopup(BuildContext ctx, ClothingItem item) {
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(ctx).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) => MultiProvider(
        providers: [
          ChangeNotifierProvider.value(
            value: Provider.of<LanguageProvider>(ctx, listen: false),
          ),
        ],
        child: _ItemDetailCard(
          item: item,
          onAddToBasket: () =>
              ctx.read<SearchBloc>().add(SearchAddToBasketRequested(item)),
        ),
      ),
      transitionBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, -1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeInOut)),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0)
                  .chain(CurveTween(curve: Curves.easeInOut)),
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<SearchBloc, SearchState>(
      listener: (ctx, state) {
        // เปิด popup detail
        if (state is SearchItemDetailReady) {
          _showItemDetailPopup(ctx, state.selectedItem);
        }

        // basket success/failure
        if (state is SearchBasketSuccess) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Added to Basket successfully!',
                th: 'เพิ่มลงตะกร้าสำเร็จ!',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        } else if (state is SearchBasketFailure) {
          showTopSnackBar(
            Overlay.of(ctx),
            CustomSnackBar.error(
              message: languageProvider.translate(
                en: 'Failed to add to Basket',
                th: 'เพิ่มลงตะกร้าไม่สำเร็จ',
              ),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      },
      builder: (ctx, state) {
        final suggestions = _suggestionsFromState(state);
        final results = _resultsFromState(state);
        final outfits = _outfitsFromState(state);
        final currentPage = _currentPageFromState(state);
        final totalPages = _totalPagesFromState(state);
        final showGenderFilters = _showGenderFiltersFromState(state);
        final hasSelected = _hasSelectedFromState(state);
        final selectedGender = _selectedGenderFromState(state);
        final basketUuid = state is SearchBasketInProgress ? state.basketUuid : null;

        final isResultsLoading = state is SearchResultsLoading;
        final isOutfitsLoading = state is SearchOutfitsLoading;

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: _buildContentArea(
                  ctx: ctx,
                  languageProvider: languageProvider,
                  isDark: isDark,
                  results: results,
                  outfits: outfits,
                  isResultsLoading: isResultsLoading,
                  isOutfitsLoading: isOutfitsLoading,
                  basketUuid: basketUuid,
                ),
              ),
              if (results.isNotEmpty && outfits.isEmpty)
                _buildPaginationControls(
                  ctx: ctx,
                  languageProvider: languageProvider,
                  currentPage: currentPage,
                  totalPages: totalPages,
                ),
              if (showGenderFilters)
                _buildGenderFilterButtons(
                  ctx: ctx,
                  languageProvider: languageProvider,
                  selectedGender: selectedGender,
                ),
              _buildSearchBar(
                ctx: ctx,
                languageProvider: languageProvider,
                suggestions: suggestions,
                hasSelected: hasSelected,
              ),
            ],
          ),
        );
      },
    );
  }

  // ── State extractors ───────────────────────────────────────────────────────

  List<SearchCategory> _suggestionsFromState(SearchState s) {
    if (s is SearchInitial) return s.suggestions;
    if (s is SearchLoaded) return s.suggestions;
    if (s is SearchResultsLoading) return s.suggestions;
    if (s is SearchOutfitsLoading) return s.suggestions;
    if (s is SearchBasketInProgress) return s.suggestions;
    if (s is SearchBasketSuccess) return s.suggestions;
    if (s is SearchBasketFailure) return s.suggestions;
    if (s is SearchItemDetailReady) return s.suggestions;
    return [];
  }

  List<ClothingItem> _resultsFromState(SearchState s) {
    if (s is SearchLoaded) return s.results;
    if (s is SearchBasketInProgress) return s.results;
    if (s is SearchBasketSuccess) return s.results;
    if (s is SearchBasketFailure) return s.results;
    if (s is SearchItemDetailReady) return s.results;
    if (s is SearchOutfitsLoading) return s.results;
    return [];
  }

  List<ClothingItem> _outfitsFromState(SearchState s) {
    if (s is SearchLoaded) return s.outfits;
    if (s is SearchBasketInProgress) return s.outfits;
    if (s is SearchBasketSuccess) return s.outfits;
    if (s is SearchBasketFailure) return s.outfits;
    if (s is SearchItemDetailReady) return s.outfits;
    if (s is SearchResultsLoading) return s.outfits;
    return [];
  }

  int _currentPageFromState(SearchState s) {
    if (s is SearchLoaded) return s.currentPage;
    if (s is SearchBasketInProgress) return s.currentPage;
    if (s is SearchBasketSuccess) return s.currentPage;
    if (s is SearchBasketFailure) return s.currentPage;
    if (s is SearchItemDetailReady) return s.currentPage;
    if (s is SearchOutfitsLoading) return s.currentPage;
    return 1;
  }

  int _totalPagesFromState(SearchState s) {
    if (s is SearchLoaded) return s.totalPages;
    if (s is SearchBasketInProgress) return s.totalPages;
    if (s is SearchBasketSuccess) return s.totalPages;
    if (s is SearchBasketFailure) return s.totalPages;
    if (s is SearchItemDetailReady) return s.totalPages;
    if (s is SearchOutfitsLoading) return s.totalPages;
    return 1;
  }

  bool _showGenderFiltersFromState(SearchState s) {
    if (s is SearchLoaded) return s.showGenderFilters;
    if (s is SearchResultsLoading) return s.showGenderFilters;
    if (s is SearchOutfitsLoading) return s.showGenderFilters;
    if (s is SearchBasketInProgress) return s.showGenderFilters;
    if (s is SearchBasketSuccess) return s.showGenderFilters;
    if (s is SearchBasketFailure) return s.showGenderFilters;
    if (s is SearchItemDetailReady) return s.showGenderFilters;
    return false;
  }

  bool _hasSelectedFromState(SearchState s) {
    if (s is SearchLoaded) return s.hasSelected;
    if (s is SearchBasketInProgress) return s.hasSelected;
    if (s is SearchBasketSuccess) return s.hasSelected;
    if (s is SearchBasketFailure) return s.hasSelected;
    if (s is SearchItemDetailReady) return s.hasSelected;
    return false;
  }

  int? _selectedGenderFromState(SearchState s) {
    if (s is SearchLoaded) return s.selectedGender;
    if (s is SearchResultsLoading) return s.selectedGender;
    if (s is SearchOutfitsLoading) return s.selectedGender;
    if (s is SearchBasketInProgress) return s.selectedGender;
    if (s is SearchBasketSuccess) return s.selectedGender;
    if (s is SearchBasketFailure) return s.selectedGender;
    if (s is SearchItemDetailReady) return s.selectedGender;
    return null;
  }

  // ── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildContentArea({
    required BuildContext ctx,
    required LanguageProvider languageProvider,
    required bool isDark,
    required List<ClothingItem> results,
    required List<ClothingItem> outfits,
    required bool isResultsLoading,
    required bool isOutfitsLoading,
    required String? basketUuid,
  }) {
    if (isOutfitsLoading) return const Center(child: CircularProgressIndicator());
    if (outfits.isNotEmpty) {
      return _buildOutfitSuggestionsList(
        ctx: ctx,
        languageProvider: languageProvider,
        outfits: outfits,
        basketUuid: basketUuid,
      );
    }
    if (isResultsLoading) return const Center(child: CircularProgressIndicator());
    if (results.isEmpty) return _buildEmptyState(languageProvider, isDark);
    return _buildSearchResultsGrid(ctx: ctx, results: results);
  }

  Widget _buildPaginationControls({
    required BuildContext ctx,
    required LanguageProvider languageProvider,
    required int currentPage,
    required int totalPages,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentPage > 1
                ? () => ctx.read<SearchBloc>().add(SearchPageChanged(currentPage - 1))
                : null,
          ),
          Text(
            languageProvider.translate(
              en: 'Page $currentPage of $totalPages',
              th: 'หน้า $currentPage จาก $totalPages',
            ),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: currentPage < totalPages
                ? () => ctx.read<SearchBloc>().add(SearchPageChanged(currentPage + 1))
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilterButtons({
    required BuildContext ctx,
    required LanguageProvider languageProvider,
    required int? selectedGender,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GenderFilterChip(
            label: languageProvider.translate(en: 'All', th: 'ทั้งหมด'),
            icon: Icons.pets,
            isSelected: selectedGender == null,
            onTap: () => ctx.read<SearchBloc>().add(const SearchGenderFilterChanged(null)),
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์'),
            icon: Icons.all_inclusive,
            isSelected: selectedGender == 0,
            onTap: () => ctx.read<SearchBloc>().add(const SearchGenderFilterChanged(0)),
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Male', th: 'เพศผู้'),
            icon: Icons.male,
            isSelected: selectedGender == 1,
            onTap: () => ctx.read<SearchBloc>().add(const SearchGenderFilterChanged(1)),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Female', th: 'เพศเมีย'),
            icon: Icons.female,
            isSelected: selectedGender == 2,
            onTap: () => ctx.read<SearchBloc>().add(const SearchGenderFilterChanged(2)),
            color: Colors.pink,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Kitten', th: 'ลูกแมว'),
            icon: Icons.child_care,
            isSelected: selectedGender == 3,
            onTap: () => ctx.read<SearchBloc>().add(const SearchGenderFilterChanged(3)),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(LanguageProvider languageProvider, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.pets_rounded, size: 80, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        const SizedBox(height: 20),
        Text(
          languageProvider.translate(en: 'Not Found', th: 'ไม่พบข้อมูล'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            languageProvider.translate(
              en: 'There are no products available for this category.',
              th: 'ไม่มีสินค้าในหมวดหมู่นี้',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsGrid({
    required BuildContext ctx,
    required List<ClothingItem> results,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: results.length,
      itemBuilder: (_, index) {
        final item = results[index];
        return _ResultCard(
          item: item,
          onTap: () => ctx.read<SearchBloc>().add(SearchItemDetailRequested(item)),
        );
      },
    );
  }

  Widget _buildOutfitSuggestionsList({
    required BuildContext ctx,
    required LanguageProvider languageProvider,
    required List<ClothingItem> outfits,
    required String? basketUuid,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                languageProvider.translate(en: 'Recommended Outfits', th: 'ชุดแนะนำ'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${outfits.length} ${languageProvider.translate(en: "items", th: "รายการ")}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: outfits.length,
            itemBuilder: (_, index) {
              final item = outfits[index];
              return _OutfitSuggestionCard(
                item: item,
                isBasketLoading: basketUuid == item.uuid,
                onTap: () => ctx.read<SearchBloc>().add(SearchItemDetailRequested(item)),
                onAddToBasket: () =>
                    ctx.read<SearchBloc>().add(SearchAddToBasketRequested(item)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar({
    required BuildContext ctx,
    required LanguageProvider languageProvider,
    required List<SearchCategory> suggestions,
    required bool hasSelected,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (suggestions.isNotEmpty && !hasSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                itemBuilder: (_, index) {
                  final cat = suggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        _searchController.text = cat.name;
                        ctx.read<SearchBloc>().add(SearchSuggestionSelected(cat));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: getTextGradient(cat.categoryType, cat.name),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          cat.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.black),
            onChanged: (value) {
              if (value.isEmpty) {
                ctx.read<SearchBloc>().add(const SearchCleared());
              }
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(50)),
              hintText: 'ᓚ₍⑅^- .-^₎ -ᶻ 𝗓 𐰁',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSelected
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ctx.read<SearchBloc>().add(const SearchCleared());
                      },
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Gender Filter Chip
// ============================================================================

class _GenderFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _GenderFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: isSelected ? color : Colors.grey[400]!, width: 2),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey[700], size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Result Card
// ============================================================================

class _ResultCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const _ResultCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = item.discountPrice != null &&
        item.discountPrice! > 0 &&
        item.discountPrice! < item.price;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.clothingName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasDiscount)
                        Text('฿${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey)),
                      if (hasDiscount) const SizedBox(width: 4),
                      Text(
                        hasDiscount
                            ? '฿${item.discountPrice!.toStringAsFixed(0)}'
                            : '฿${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: hasDiscount ? Colors.red : Colors.black),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Outfit Suggestion Card
// ============================================================================

class _OutfitSuggestionCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;
  final VoidCallback onAddToBasket;
  final bool isBasketLoading;

  const _OutfitSuggestionCard({
    required this.item,
    required this.onTap,
    required this.onAddToBasket,
    required this.isBasketLoading,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hasDiscount = item.discountPrice != null &&
        item.discountPrice! > 0 &&
        item.discountPrice! < item.price;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: isDark ? Colors.grey[700] : Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: screenWidth * 0.28,
                  height: screenWidth * 0.32,
                  fit: BoxFit.cover,
                  placeholder: (_, __) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatGender(item.gender, languageProvider),
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getGenderColor(item.gender)),
                        ),
                        const SizedBox(width: 30),
                        Text(item.sizeCategory,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(item.clothingName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${languageProvider.translate(en: "Stock", th: "สินค้า")}: ${item.stock}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (hasDiscount)
                            Text('฿${item.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 14,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey)),
                          if (hasDiscount) const SizedBox(width: 6),
                          Text(
                            hasDiscount
                                ? '฿${item.discountPrice!.toStringAsFixed(0)}'
                                : '฿${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: hasDiscount
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary),
                          ),
                          if (hasDiscount && item.discountPercent != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('-${item.discountPercent}%',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: FloatingActionButton.small(
                  heroTag: 'basket_${item.uuid}_${item.id}',
                  onPressed: isBasketLoading ? null : onAddToBasket,
                  backgroundColor: isBasketLoading
                      ? Colors.grey
                      : Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  child: isBasketLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.shopping_cart_outlined,
                          size: 24,
                          color: Theme.of(context).floatingActionButtonTheme.foregroundColor,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGenderColor(int gender) {
    switch (gender) {
      case 1: return Colors.blue;
      case 2: return Colors.pink;
      case 3: return Colors.orange;
      default: return Colors.purple;
    }
  }
}

// ============================================================================
// Item Detail Card (StatefulWidget — fav ยังคง local)
// ============================================================================

class _ItemDetailCard extends StatefulWidget {
  final ClothingItem item;
  final VoidCallback onAddToBasket;

  const _ItemDetailCard({required this.item, required this.onAddToBasket});

  @override
  State<_ItemDetailCard> createState() => _ItemDetailCardState();
}

class _ItemDetailCardState extends State<_ItemDetailCard> {
  bool _isFavourite = false;
  bool _isProcessing = false;

  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  String get _uuid =>
      widget.item.rawJson['uuid']?.toString() ??
      widget.item.rawJson['clothing_uuid']?.toString() ??
      widget.item.uuid;

  @override
  void initState() {
    super.initState();
    _checkFavouriteStatus();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavouriteStatus() async {
    if (_uuid.isEmpty) return;
    try {
      final isFav = await FavouriteApiService().checkFavourite(clothingUuid: _uuid);
      if (mounted) setState(() => _isFavourite = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFavourite() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    try {
      if (_isFavourite) {
        await FavouriteApiService().removeFromFavourite(clothingUuid: _uuid);
        if (mounted) setState(() => _isFavourite = false);
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: languageProvider.translate(
                  en: 'Removed from favourites!', th: 'ลบออกจากรายการโปรดแล้ว'),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      } else {
        await FavouriteApiService().addToFavourite(clothingUuid: _uuid);
        if (mounted) setState(() => _isFavourite = true);
        if (mounted) {
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: languageProvider.translate(
                  en: 'Added to favourites successfully!',
                  th: 'เพิ่มลงรายการโปรดแล้ว!'),
            ),
            animationDuration: const Duration(milliseconds: 1000),
            reverseAnimationDuration: const Duration(milliseconds: 200),
            displayDuration: const Duration(milliseconds: 1000),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
                en: 'Failed to update favourites',
                th: 'อัปเดตรายการโปรดไม่สำเร็จ'),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hasDiscount = widget.item.discountPrice != null &&
        widget.item.discountPrice! > 0 &&
        widget.item.discountPrice! < widget.item.price;

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          elevation: 10,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
              maxWidth: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _imagePageController,
                          onPageChanged: (i) =>
                              setState(() => _currentImagePage = i),
                          children: [
                            CachedNetworkImage(
                              imageUrl: widget.item.imageUrl,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                  height: 300,
                                  child: Center(child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error))),
                            ),
                            CachedNetworkImage(
                              imageUrl: widget.item.images['image_clothing'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const SizedBox(
                                  height: 300,
                                  child: Center(child: CircularProgressIndicator())),
                              errorWidget: (_, __, ___) => const SizedBox(
                                  height: 300,
                                  child: Center(child: Icon(Icons.error))),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(2, (i) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImagePage == i ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImagePage == i
                                  ? Colors.deepOrange
                                  : Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: _isProcessing ? null : _toggleFavourite,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isFavourite
                                ? Colors.red.withOpacity(0.8)
                                : Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: _isProcessing
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  _isFavourite ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 24,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.item.clothingName,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          _DetailRow(
                            label: languageProvider.translate(en: 'Category', th: 'หมวดหมู่'),
                            value: widget.item.category?.toString() ?? '',
                          ),
                          _DetailRow(
                            label: languageProvider.translate(en: 'Size', th: 'ขนาด'),
                            value: widget.item.sizeCategory,
                          ),
                          _DetailRow(
                            label: languageProvider.translate(en: 'Gender', th: 'เพศ'),
                            value: _formatGender(widget.item.gender, languageProvider),
                          ),
                          _DetailRow(
                            label: languageProvider.translate(en: 'Stock', th: 'สต็อก'),
                            value: widget.item.stock.toString(),
                          ),
                          _DetailRow(
                            label: languageProvider.translate(en: 'Breed', th: 'สายพันธุ์'),
                            value: widget.item.breed,
                          ),
                          if (widget.item.description.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageProvider.translate(
                                      en: 'Description', th: 'รายละเอียด'),
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(widget.item.description,
                                    style: TextStyle(fontSize: 16, color: Colors.grey[700])),
                                const SizedBox(height: 16),
                              ],
                            ),
                          Row(
                            children: [
                              if (hasDiscount)
                                Text('฿${widget.item.price.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                        decoration: TextDecoration.lineThrough,
                                        decorationThickness: 2)),
                              if (hasDiscount) const SizedBox(width: 10),
                              Text(
                                hasDiscount
                                    ? '฿${widget.item.discountPrice!.toStringAsFixed(0)}'
                                    : '฿${widget.item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: hasDiscount ? Colors.red : Colors.black),
                              ),
                              if (hasDiscount && widget.item.discountPercent != null) ...[
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text('-${widget.item.discountPercent}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await BasketApiService()
                                      .addToBasket(clothingUuid: _uuid);
                                  if (context.mounted) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.success(
                                        message: languageProvider.translate(
                                          en: 'Added to Basket successfully!',
                                          th: 'เพิ่มลงตะกร้าสำเร็จ!',
                                        ),
                                      ),
                                      animationDuration:
                                          const Duration(milliseconds: 1000),
                                      reverseAnimationDuration:
                                          const Duration(milliseconds: 200),
                                      displayDuration:
                                          const Duration(milliseconds: 1000),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.error(
                                        message: languageProvider.translate(
                                          en: 'Failed to add to Basket',
                                          th: 'เพิ่มลงตะกร้าไม่สำเร็จ',
                                        ),
                                      ),
                                      animationDuration:
                                          const Duration(milliseconds: 1000),
                                      reverseAnimationDuration:
                                          const Duration(milliseconds: 200),
                                      displayDuration:
                                          const Duration(milliseconds: 1000),
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.add_shopping_cart_sharp),
                              label: Text(
                                languageProvider.translate(
                                    en: 'Add to Basket', th: 'เพิ่มลงตะกร้า'),
                                style: const TextStyle(fontSize: 16),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// Detail Row
// ============================================================================

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text('$label:',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Helpers
// ============================================================================

String _formatGender(int gender, LanguageProvider lang) {
  switch (gender) {
    case 0: return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
    case 1: return lang.translate(en: 'Male', th: 'เพศผู้');
    case 2: return lang.translate(en: 'Female', th: 'เพศเมีย');
    case 3: return lang.translate(en: 'Kitten', th: 'ลูกแมว');
    default: return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
  }
}

Color brighten(Color color, [double amount = 0.15]) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

LinearGradient brightGradient(List<Color> colors) {
  return LinearGradient(colors: colors.map((c) => brighten(c)).toList());
}

final Map<String, List<Color>> gradientMap = {
  'Every Day': [const Color.fromARGB(255, 90, 102, 234), const Color.fromARGB(255, 109, 118, 202)],
  'Pride Month': [const Color.fromARGB(255, 192, 92, 92), const Color.fromARGB(255, 192, 182, 92), const Color.fromARGB(255, 104, 200, 95), const Color.fromARGB(255, 101, 137, 190), const Color.fromARGB(255, 192, 92, 185)],
  'Cyber': [const Color.fromARGB(255, 69, 105, 188), const Color.fromARGB(255, 48, 123, 118)],
  'Chinese': [const Color.fromARGB(255, 160, 35, 35), const Color.fromARGB(255, 145, 137, 19)],
  'Loy': [const Color.fromARGB(255, 65, 172, 202), const Color.fromARGB(255, 63, 65, 186)],
  'Songkran': [const Color.fromARGB(255, 27, 150, 180), const Color.fromARGB(255, 45, 199, 132)],
  'Valentine': [const Color.fromARGB(255, 218, 86, 128), const Color.fromARGB(255, 195, 58, 58)],
  'Christmas': [const Color.fromARGB(255, 36, 159, 54), const Color.fromARGB(255, 169, 70, 70)],
  'Winter': [const Color.fromARGB(255, 79, 128, 152), const Color.fromARGB(255, 40, 180, 183)],
  'Summer': [const Color.fromARGB(255, 183, 107, 66), const Color.fromARGB(255, 185, 185, 63)],
  'Rainy': [const Color.fromARGB(255, 68, 109, 144), const Color.fromARGB(255, 66, 109, 157)],
  'Halloween': [const Color.fromARGB(255, 166, 102, 66), const Color.fromARGB(255, 184, 85, 85)],
};

LinearGradient getTextGradient(String type, String name) {
  for (final entry in gradientMap.entries) {
    if (name.contains(entry.key)) return brightGradient(entry.value);
  }
  return brightGradient([const Color(0xFF424242), const Color(0xFF616161)]);
}