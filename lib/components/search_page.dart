// ----SearchPage with Favourite & Basket Integration (Fixed v2)--------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';

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
      shaderCallback: (bounds) {
        return gradient.createShader(
          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
        );
      },
      child: Text(
        text,
        style: style.copyWith(color: Colors.white),
      ),
    );
  }
}

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
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String getBaseUrl() {
  const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  if (env == 'prod') {
    return 'https://catshop-backend-9pzq.onrender.com';
  }

  if (env == 'prod-v2') {
    return 'https://catshop-backend-v2.onrender.com';
  }

  if (kIsWeb) {
    return 'http://localhost:10000';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:10000';
  }

  return 'http://localhost:10000';
}

// ============================================================================
// Models
// ============================================================================

class SearchCategory {
  final int id;
  final String name;
  final String categoryType;

  SearchCategory({
    required this.id,
    required this.name,
    required this.categoryType,
  });

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

  // ✅ เก็บ raw json ไว้ด้วย เพื่อใช้แบบเดียวกับหน้าอื่น (itemDetails['uuid'])
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

  // ✅ รองรับ null, String (JSON), Map ทุกกรณี — ไม่ crash เด็ดขาด
  static Map<String, dynamic> _parseImages(dynamic value) {
    try {
      if (value == null) return {};
      if (value is Map) {
        return Map<String, dynamic>.from(value);
      }
      if (value is String && value.isNotEmpty) {
        final decoded = jsonDecode(value);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return {};
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    // ✅ DEBUG: print all keys เพื่อดูว่า backend ส่งอะไรมา
    debugPrint('📦 [ClothingItem] keys: ${json.keys.toList()}');
    debugPrint('📦 [ClothingItem] images type: ${json['images']?.runtimeType}');

    // ✅ รองรับทุก field name ที่เป็นไปได้
    final uuid = json['uuid']?.toString() ??
        json['clothing_uuid']?.toString() ??
        json['item_uuid']?.toString() ??
        '';

    debugPrint(uuid.isEmpty
        ? '⚠️ [ClothingItem] uuid EMPTY! name=${json['clothing_name']}'
        : '✅ [ClothingItem] uuid=$uuid');

    // ✅ ป้องกัน null ทุก field
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
      rawJson: Map<String, dynamic>.from(json), // ✅ safe copy
    );
  }
}

// ============================================================================
// Main Search Page
// ============================================================================

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  final BasketApiService _basketApi = BasketApiService();

  List<SearchCategory> _autocompleteSuggestions = [];
  List<ClothingItem> _searchResults = [];
  List<ClothingItem> _outfitSuggestions = [];

  bool _isLoadingResults = false;
  bool _isLoadingOutfits = false;
  bool _showSuggestions = false;
  bool _hasSelected = false;
  bool _showGenderFilters = false;

  int? _selectedCategoryId;
  int? _selectedGender;

  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchAutocompleteSuggestions('');
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
      _fetchAutocompleteSuggestions(query);
    });
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    try {
      final baseUrl = getBaseUrl();
      final url = query.isEmpty
          ? '$baseUrl/api/search/autocomplete'
          : '$baseUrl/api/search/autocomplete?query=$query';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);

        setState(() {
          _autocompleteSuggestions =
              data.map((json) => SearchCategory.fromJson(json)).toList();
          _showSuggestions = _autocompleteSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching autocomplete: $e');
    }
  }

  Future<void> _searchClothing({int page = 1}) async {
    setState(() {
      _isLoadingResults = true;
      _currentPage = page;
    });

    try {
      final baseUrl = getBaseUrl();
      final params = <String>[];

      if (_selectedCategoryId != null) {
        params.add('category_id=$_selectedCategoryId');
      }
      if (_selectedGender != null) {
        params.add('gender=$_selectedGender');
      }
      params.add('page=$page');
      params.add('page_size=$_pageSize');

      final queryString = params.join('&');
      final url = '$baseUrl/api/search/clothing?$queryString';

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        final List<dynamic> items = data['items'];

        setState(() {
          _searchResults =
              items.map((json) => ClothingItem.fromJson(json)).toList();
          _totalPages = data['total_pages'] ?? 1;
          _isLoadingResults = false;
        });
      } else {
        setState(() => _isLoadingResults = false);
      }
    } catch (e) {
      setState(() => _isLoadingResults = false);
      debugPrint('Error searching clothing: $e');
    }
  }

  void _onSuggestionSelected(SearchCategory category) {
    FocusScope.of(context).unfocus();

    setState(() {
      _hasSelected = true;
      _showSuggestions = false;
      _autocompleteSuggestions.clear();
      _searchController.text = category.name;

      if (category.categoryType == 'gender') {
        _selectedGender = category.id == 0 ? null : category.id;
        _selectedCategoryId = null;
        _showGenderFilters = false;
      } else if (category.categoryType == 'style' ||
          category.categoryType == 'season' ||
          category.categoryType == 'festival') {
        _selectedCategoryId = category.id;
        _selectedGender = null;
        _showGenderFilters = true;
      } else if (category.categoryType == 'all') {
        _selectedCategoryId = category.id;
        _selectedGender = null;
        _showGenderFilters = true;
      }
    });

    _fetchOutfitSuggestions(category.id);
  }

  void _onGenderFilterSelected(int? genderId) {
    setState(() {
      _selectedGender = genderId;
    });

    if (_selectedCategoryId != null) {
      _fetchOutfitSuggestions(_selectedCategoryId!);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _searchClothing(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _searchClothing(page: _currentPage - 1);
    }
  }

  Future<void> _fetchOutfitSuggestions(int itemId) async {
    setState(() {
      _isLoadingOutfits = true;
      _outfitSuggestions = [];
    });

    try {
      final baseUrl = getBaseUrl();
      String url = '$baseUrl/api/search/btn/outfit/$itemId';
      if (_selectedGender != null) {
        url += '?gender=$_selectedGender';
      }

      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);

        try {
          final parsedItems =
              data.map((json) => ClothingItem.fromJson(json)).toList();

          setState(() {
            _outfitSuggestions = parsedItems;
            _isLoadingOutfits = false;
          });
        } catch (e) {
          setState(() => _isLoadingOutfits = false);
        }
      } else {
        setState(() => _isLoadingOutfits = false);
      }
    } catch (e) {
      setState(() => _isLoadingOutfits = false);
    }
  }

  // ============================================================================
  // ✅ Add to Basket — เหมือนหน้าอื่น ใช้ rawJson['uuid']
  // ============================================================================

  Future<void> _addToBasket(ClothingItem item) async {
    // ✅ ใช้ rawJson เหมือน itemDetails['uuid'] ของหน้าอื่น
    final clothingUuid = item.rawJson['uuid']?.toString() ??
        item.rawJson['clothing_uuid']?.toString() ??
        item.uuid;
    final languageProvider =
        Provider.of<LanguageProvider>(context, listen: false);
    debugPrint('🛒 [SearchPage] addToBasket uuid="$clothingUuid"');
    debugPrint('🛒 [SearchPage] rawJson keys: ${item.rawJson.keys.toList()}');

    if (clothingUuid.isEmpty) {
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to Basket: Invalid UUID',
              th: 'ไม่สามารถเพิ่มสินค้าได้: UUID ไม่ถูกต้อง',
            ),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
      return;
    }

    try {
      await _basketApi.addToBasket(
        clothingUuid: clothingUuid,
        quantity: 1,
      );

      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
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
      }
    } catch (e) {
      debugPrint('❌ [SearchPage] addToBasket error: $e');
      if (mounted) {
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to Basket: $e',
              th: 'เพิ่มลงตะกร้าไม่สำเร็จ: $e',
            ),
          ),
          animationDuration: const Duration(milliseconds: 1000),
          reverseAnimationDuration: const Duration(milliseconds: 200),
          displayDuration: const Duration(milliseconds: 1000),
        );
      }
    }
  }

  // ============================================================================
  // Item Detail Popup — ส่ง rawJson เหมือนหน้าอื่น
  // ============================================================================

  void _showItemDetail(ClothingItem item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        // ✅ ส่ง LanguageProvider เข้าไปใน dialog context
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(
              value: Provider.of<LanguageProvider>(context, listen: false),
            ),
          ],
          // ✅ ใช้ _ItemDetailCard พร้อม rawJson เหมือนหน้าอื่น
          child: _ItemDetailCard(
            item: item,
            onAddToBasket: () => _addToBasket(item),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, -1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        var fadeAnimation = animation.drive(
          Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
        );
        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: fadeAnimation, child: child),
        );
      },
    );
  }

  // ============================================================================
  // Build UI
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _buildContentArea(languageProvider, isDark),
          ),
          if (_searchResults.isNotEmpty && _outfitSuggestions.isEmpty)
            _buildPaginationControls(languageProvider),
          if (_showGenderFilters) _buildGenderFilterButtons(languageProvider),
          _buildSearchBar(languageProvider),
        ],
      ),
    );
  }

  Widget _buildContentArea(LanguageProvider languageProvider, bool isDark) {
    if (_isLoadingOutfits) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_outfitSuggestions.isNotEmpty) {
      return _buildOutfitSuggestionsList(languageProvider);
    }
    if (_isLoadingResults) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_searchResults.isEmpty) {
      return _buildEmptyState(languageProvider, isDark);
    }
    return _buildSearchResultsGrid();
  }

  Widget _buildPaginationControls(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _currentPage > 1 ? _previousPage : null,
          ),
          Text(
            languageProvider.translate(
              en: 'Page $_currentPage of $_totalPages',
              th: 'หน้า $_currentPage จาก $_totalPages',
            ),
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: _currentPage < _totalPages ? _nextPage : null,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderFilterButtons(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GenderFilterChip(
            label: languageProvider.translate(en: 'All', th: 'ทั้งหมด'),
            icon: Icons.pets,
            isSelected: _selectedGender == null,
            onTap: () => _onGenderFilterSelected(null),
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์'),
            icon: Icons.all_inclusive,
            isSelected: _selectedGender == 0,
            onTap: () => _onGenderFilterSelected(0),
            color: Colors.purple,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Male', th: 'เพศผู้'),
            icon: Icons.male,
            isSelected: _selectedGender == 1,
            onTap: () => _onGenderFilterSelected(1),
            color: Colors.blue,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Female', th: 'เพศเมีย'),
            icon: Icons.female,
            isSelected: _selectedGender == 2,
            onTap: () => _onGenderFilterSelected(2),
            color: Colors.pink,
          ),
          const SizedBox(width: 8),
          _GenderFilterChip(
            label: languageProvider.translate(en: 'Kitten', th: 'ลูกแมว'),
            icon: Icons.child_care,
            isSelected: _selectedGender == 3,
            onTap: () => _onGenderFilterSelected(3),
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
        Icon(Icons.pets_rounded,
            size: 80, color: isDark ? Colors.grey[600] : Colors.grey[400]),
        const SizedBox(height: 20),
        Text(
          languageProvider.translate(en: "Not Found", th: "ไม่พบข้อมูล"),
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
                en: "There are no products available for this category.",
                th: "ไม่มีสินค้าในหมวดหมู่นี้"),
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500]),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.7,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _ResultCard(item: item, onTap: () => _showItemDetail(item));
      },
    );
  }

  Widget _buildOutfitSuggestionsList(LanguageProvider languageProvider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              Text(
                languageProvider.translate(
                    en: 'Recommended Outfits', th: 'ชุดแนะนำ'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${_outfitSuggestions.length} ${languageProvider.translate(en: "items", th: "รายการ")}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _outfitSuggestions.length,
            itemBuilder: (context, index) {
              final item = _outfitSuggestions[index];
              return _OutfitSuggestionCard(
                item: item,
                onTap: () => _showItemDetail(item),
                onAddToBasket: () => _addToBasket(item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar(LanguageProvider languageProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_showSuggestions &&
              _autocompleteSuggestions.isNotEmpty &&
              !_hasSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _autocompleteSuggestions.length,
                itemBuilder: (context, index) {
                  final cat = _autocompleteSuggestions[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () => _onSuggestionSelected(cat),
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Text(cat.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      _hasSelected = false;
                      _selectedCategoryId = null;
                      _selectedGender = null;
                      _showSuggestions = true;
                      _outfitSuggestions = [];
                      _showGenderFilters = false;
                    } else if (_hasSelected) {
                      _showSuggestions = false;
                    }
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(50)),
                  hintText: 'ᓚ₍⑅^- .-^₎ -ᶻ 𝗓 𐰁',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _hasSelected
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _hasSelected = false;
                              _showSuggestions = true;
                              _autocompleteSuggestions.clear();
                              _outfitSuggestions = [];
                              _showGenderFilters = false;
                              _selectedGender = null;
                              _selectedCategoryId = null;
                            });
                          },
                        )
                      : null,
                ),
              ),
            ],
          )
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
              ? [
                  BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? Colors.white : Colors.grey[700], size: 20),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 14)),
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
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.clothingName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
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

  const _OutfitSuggestionCard({
    required this.item,
    required this.onTap,
    required this.onAddToBasket,
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
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
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
                                color:
                                    Theme.of(context).colorScheme.onSurface)),
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
                        Icon(Icons.inventory_2_outlined,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${languageProvider.translate(en: "Stock", th: "สินค้า")}: ${item.stock}',
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                          if (hasDiscount && item.discountPercent != null)
                            const SizedBox(width: 8),
                          if (hasDiscount && item.discountPercent != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
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
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: FloatingActionButton.small(
                  heroTag: 'basket_${item.uuid}_${item.id}',
                  onPressed: onAddToBasket,
                  backgroundColor:
                      Theme.of(context).floatingActionButtonTheme.backgroundColor,
                  child: Icon(Icons.shopping_cart_outlined,
                      size: 24,
                      color: Theme.of(context)
                          .floatingActionButtonTheme
                          .foregroundColor),
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
      case 1:
        return Colors.blue;
      case 2:
        return Colors.pink;
      case 3:
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }
}

// ============================================================================
// ✅ Item Detail Card — ใช้ pattern เดียวกับหน้าอื่น (itemDetails['uuid'])
// ============================================================================

class _ItemDetailCard extends StatefulWidget {
  final ClothingItem item;
  final VoidCallback onAddToBasket;

  const _ItemDetailCard({
    required this.item,
    required this.onAddToBasket,
  });

  @override
  State<_ItemDetailCard> createState() => _ItemDetailCardState();
}

class _ItemDetailCardState extends State<_ItemDetailCard> {
  bool _isFavourite = false;
  bool _isProcessing = false;

  final PageController _imagePageController = PageController();
  int _currentImagePage = 0;

  // ✅ ดึง uuid จาก rawJson เหมือน itemDetails['uuid'] ของหน้าอื่น
  String get _uuid =>
      widget.item.rawJson['uuid']?.toString() ??
      widget.item.rawJson['clothing_uuid']?.toString() ??
      widget.item.uuid;

  @override
  void initState() {
    super.initState();
    debugPrint('🔑 [ItemDetailCard] uuid="$_uuid"');
    debugPrint(
        '🔑 [ItemDetailCard] rawJson keys: ${widget.item.rawJson.keys.toList()}');
    _checkFavouriteStatus();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _checkFavouriteStatus() async {
    if (_uuid.isEmpty) {
      debugPrint('⚠️ [ItemDetailCard] uuid empty, skip checkFavourite');
      return;
    }

    try {
      final isFav = await FavouriteApiService().checkFavourite(
        clothingUuid: _uuid,
      );
      if (mounted) setState(() => _isFavourite = isFav);
    } catch (e) {
      debugPrint('❌ checkFavourite error: $e');
    }
  }

  // ✅ Toggle Favourite — pattern เดียวกับหน้าอื่น
  Future<void> _toggleFavourite() async {
    if (_uuid.isEmpty) {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);
      showTopSnackBar(
        Overlay.of(context),
        CustomSnackBar.error(
          message: languageProvider.translate(
            en: 'Failed to toggle Favourite: Invalid UUID',
            th: 'ไม่สามารถเพิ่ม Favourite ได้: UUID ไม่ถูกต้อง',
          ),
        ),
        animationDuration: const Duration(milliseconds: 1000),
        reverseAnimationDuration: const Duration(milliseconds: 200),
        displayDuration: const Duration(milliseconds: 1000),
      );
      return;
    }

    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final languageProvider =
          Provider.of<LanguageProvider>(context, listen: false);

      if (_isFavourite) {
        // ✅ ลบ — เหมือนหน้าอื่น
        await FavouriteApiService().removeFromFavourite(
          clothingUuid: _uuid,
        );

        if (mounted) {
          setState(() => _isFavourite = false);
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.info(
              message: languageProvider.translate(
                en: 'Removed from favourites!',
                th: 'ลบออกจากรายการโปรดแล้ว',
              ),
            ),
            animationDuration:
                const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
            reverseAnimationDuration:
                const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
            displayDuration:
                const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
          );
        }
      } else {
        // ✅ เพิ่ม — เหมือนหน้าอื่น
        await FavouriteApiService().addToFavourite(
          clothingUuid: _uuid,
        );

        if (mounted) {
          setState(() => _isFavourite = true);
          showTopSnackBar(
            Overlay.of(context),
            CustomSnackBar.success(
              message: languageProvider.translate(
                en: 'Added to favourites successfully!',
                th: 'เพิ่มลงรายการโปรดแล้ว!',
              ),
            ),
            animationDuration:
                const Duration(milliseconds: 1000), // เร็วแค่ไหนตอน popup
            reverseAnimationDuration:
                const Duration(milliseconds: 200), // เร็วแค่ไหนตอนหาย
            displayDuration:
                const Duration(milliseconds: 1000), // แสดงนานแค่ไหน
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final languageProvider =
            Provider.of<LanguageProvider>(context, listen: false);
        showTopSnackBar(
          Overlay.of(context),
          CustomSnackBar.error(
            message: languageProvider.translate(
              en: 'Failed to add to favourites: $e',
              th: 'เพิ่มลงรายการโปรดไม่สำเร็จ: $e',
            ),
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
                // ✅ รูป Slideshow + ปุ่มหัวใจ + จุด indicator
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(20)),
                      child: SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _imagePageController,
                          onPageChanged: (index) {
                            setState(() => _currentImagePage = index);
                          },
                          children: [
                            // รูปหลัก
                            CachedNetworkImage(
                              imageUrl: widget.item.imageUrl,
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                height: 300,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                height: 300,
                                child: Center(child: Icon(Icons.error)),
                              ),
                            ),
                            // รูปเสื้อผ้า
                            CachedNetworkImage(
                              imageUrl:
                                  widget.item.images['image_clothing'] ?? '',
                              width: double.infinity,
                              height: 300,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const SizedBox(
                                height: 300,
                                child:
                                    Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) =>
                                  const SizedBox(
                                height: 300,
                                child: Center(child: Icon(Icons.error)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ✅ จุด Page Indicator
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: List.generate(2, (index) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImagePage == index ? 20 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImagePage == index
                                  ? Colors.deepOrange
                                  : const Color.fromARGB(255, 0, 0, 0)
                                      .withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),

                    // ✅ ปุ่มหัวใจ
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
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Icon(
                                  _isFavourite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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
                            label: languageProvider.translate(
                                en: 'Category', th: 'หมวดหมู่'),
                            value: widget.item.category?.toString() ?? '',
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Size', th: 'ขนาด'),
                            value: widget.item.sizeCategory,
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Gender', th: 'เพศ'),
                            value: _formatGender(
                                widget.item.gender, languageProvider),
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Stock', th: 'สต็อก'),
                            value: widget.item.stock.toString(),
                          ),
                          _DetailRow(
                            label: languageProvider.translate(
                                en: 'Breed', th: 'สายพันธุ์'),
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
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(widget.item.description,
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.grey[700])),
                                const SizedBox(height: 16),
                              ],
                            ),
                          Row(
                            children: [
                              if (hasDiscount)
                                Text(
                                  '฿${widget.item.price.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                      decorationThickness: 2),
                                ),
                              if (hasDiscount) const SizedBox(width: 10),
                              Text(
                                hasDiscount
                                    ? '฿${widget.item.discountPrice!.toStringAsFixed(0)}'
                                    : '฿${widget.item.price.toStringAsFixed(0)}',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: hasDiscount
                                        ? Colors.red
                                        : Colors.black),
                              ),
                              if (hasDiscount) const SizedBox(width: 10),
                              if (hasDiscount &&
                                  widget.item.discountPercent != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                      '-${widget.item.discountPercent}%',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // ✅ Add to Basket button — เหมือนหน้าอื่น
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  debugPrint(
                                      '🛒 [ItemDetailCard] Add to basket uuid="$_uuid"');
                                  await BasketApiService().addToBasket(
                                    clothingUuid: _uuid,
                                  );

                                  if (context.mounted) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.success(
                                        message: languageProvider.translate(
                                          en: 'Added to Basket successfully!',
                                          th: 'เพิ่มลงตะกร้าสำเร็จ!',
                                        ),
                                      ),
                                      animationDuration: const Duration(
                                          milliseconds:
                                              1000), // เร็วแค่ไหนตอน popup
                                      reverseAnimationDuration: const Duration(
                                          milliseconds:
                                              200), // เร็วแค่ไหนตอนหาย
                                      displayDuration: const Duration(
                                          milliseconds: 1000), // แสดงนานแค่ไหน
                                    );
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    showTopSnackBar(
                                      Overlay.of(context),
                                      CustomSnackBar.error(
                                        message: languageProvider.translate(
                                          en: 'Failed to add to Basket: $e',
                                          th: 'เพิ่มลงตะกร้าไม่สำเร็จ: $e',
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
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
// Detail Row Widget
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
// Helper Functions
// ============================================================================

String _formatGender(int gender, LanguageProvider lang) {
  switch (gender) {
    case 0:
      return lang.translate(en: 'Unisex', th: 'ยูนิเซ็กซ์');
    case 1:
      return lang.translate(en: 'Male', th: 'เพศผู้');
    case 2:
      return lang.translate(en: 'Female', th: 'เพศเมีย');
    case 3:
      return lang.translate(en: 'Kitten', th: 'ลูกแมว');
    default:
      return lang.translate(en: 'Unknown', th: 'ไม่ระบุ');
  }
}

Color brighten(Color color, [double amount = 0.15]) {
  final hsl = HSLColor.fromColor(color);
  final hslBright = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
  return hslBright.toColor();
}

LinearGradient brightGradient(List<Color> colors) {
  return LinearGradient(colors: colors.map((c) => brighten(c)).toList());
}

final Map<String, List<Color>> gradientMap = {
  'Every Day': [
    const Color.fromARGB(255, 90, 102, 234),
    const Color.fromARGB(255, 109, 118, 202),
  ],
  'Pride Month': [
    const Color.fromARGB(255, 192, 92, 92),
    const Color.fromARGB(255, 192, 182, 92),
    const Color.fromARGB(255, 104, 200, 95),
    const Color.fromARGB(255, 101, 137, 190),
    const Color.fromARGB(255, 192, 92, 185),
  ],
  'Cyber': [
    const Color.fromARGB(255, 69, 105, 188),
    const Color.fromARGB(255, 48, 123, 118),
  ],
  'Chinese': [
    const Color.fromARGB(255, 160, 35, 35),
    const Color.fromARGB(255, 145, 137, 19),
  ],
  'Loy': [
    const Color.fromARGB(255, 65, 172, 202),
    const Color.fromARGB(255, 63, 65, 186),
  ],
  'Songkran': [
    const Color.fromARGB(255, 27, 150, 180),
    const Color.fromARGB(255, 45, 199, 132),
  ],
  'Valentine': [
    const Color.fromARGB(255, 218, 86, 128),
    const Color.fromARGB(255, 195, 58, 58),
  ],
  'Christmas': [
    const Color.fromARGB(255, 36, 159, 54),
    const Color.fromARGB(255, 169, 70, 70),
  ],
  'Winter': [
    const Color.fromARGB(255, 79, 128, 152),
    const Color.fromARGB(255, 40, 180, 183),
  ],
  'Summer': [
    const Color.fromARGB(255, 183, 107, 66),
    const Color.fromARGB(255, 185, 185, 63),
  ],
  'Rainy': [
    const Color.fromARGB(255, 68, 109, 144),
    const Color.fromARGB(255, 66, 109, 157),
  ],
  'Halloween': [
    const Color.fromARGB(255, 166, 102, 66),
    const Color.fromARGB(255, 184, 85, 85),
  ],
};

LinearGradient getTextGradient(String type, String name) {
  for (final entry in gradientMap.entries) {
    if (name.contains(entry.key)) {
      return brightGradient(entry.value);
    }
  }
  return brightGradient([
    const Color(0xFF424242),
    const Color(0xFF616161),
  ]);
}
