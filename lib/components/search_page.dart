// ----SearchPage with Gender Filter Buttons (FIXED)--------------------------------------------------------------------------

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

// ✅ FIX: Helper function to parse int safely
int _parseInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is String) {
    return int.tryParse(value) ?? 0;
  }
  return 0;
}

String getBaseUrl() {
  if (kIsWeb) {
    return 'http://localhost:8000';
  } else if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  } else {
    return 'http://localhost:8000';
  }
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
  final String imageUrl;
  final Map<String, dynamic> images;
  final String clothingName;
  final String description;
  final dynamic category; // ✅ FIX: เปลี่ยนเป็น dynamic เพราะ API ส่งมาทั้ง String และ int
  final String? categoryNameEn;
  final String? categoryNameTh;
  final String sizeCategory;
  final double price;
  final double? discountPrice;
  final int? discountPercent;
  final int gender;
  final int stock;
  final String breed;

  ClothingItem({
    required this.id,
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
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: _parseInt(json['id']), // ✅ FIX: ใช้ _parseInt
      imageUrl: json['image_url'] ?? '',
      images: json['images'] is String
          ? jsonDecode(json['images'])
          : json['images'] ?? {},
      clothingName: json['clothing_name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'], // ✅ FIX: เก็บค่าเป็น dynamic
      categoryNameEn: json['category_name_en'],
      categoryNameTh: json['category_name_th'],
      sizeCategory: json['size_category'] ?? '',
      price: _parseDouble(json['price']),
      discountPrice: _parseDouble(json['discount_price']),
      discountPercent: _parseInt(json['discount_percent']), // ✅ FIX: ใช้ _parseInt
      gender: _parseInt(json['gender']), // ✅ FIX: ใช้ _parseInt
      stock: _parseInt(json['stock']), // ✅ FIX: ใช้ _parseInt
      breed: json['breed'] ?? '',
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // ============================================================================
  // Search Logic
  // ============================================================================

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    final query = _searchController.text.trim();

    if (query.length < 1) {
      setState(() {
        _autocompleteSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchAutocompleteSuggestions(query);
    });
  }

  Future<void> _fetchAutocompleteSuggestions(String query) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/search/autocomplete?query=$query';

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _autocompleteSuggestions =
              data.map((json) => SearchCategory.fromJson(json)).toList();
          _showSuggestions = _autocompleteSuggestions.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error fetching autocomplete: $e');
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

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
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
      print('Error searching clothing: $e');
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

      print('📡 Calling API: $url');

      final response = await http.get(Uri.parse(url)).timeout(
            const Duration(seconds: 5),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
   
        if (data.isNotEmpty) {
          print('📦 First item raw: ${data[0]}');
        }

        try {
          final parsedItems = data.map((json) {
            try {
              return ClothingItem.fromJson(json);
            } catch (e) {
              print('❌ Error parsing item: $e');
              print('📦 Problematic item: $json');
              rethrow;
            }
          }).toList();

          setState(() {
            _outfitSuggestions = parsedItems;
            _isLoadingOutfits = false;
          });
          
          print('✅ Successfully parsed ${_outfitSuggestions.length} outfit suggestions');
        } catch (e) {
          print('❌ Error during parsing: $e');
          setState(() => _isLoadingOutfits = false);
        }
      } else {
        print('❌ API returned error: ${response.statusCode}');
        setState(() => _isLoadingOutfits = false);
      }
    } catch (e) {
      setState(() => _isLoadingOutfits = false);
      print('❌ Error fetching outfit suggestions: $e');
    }
  }

  // ============================================================================
  // Item Detail Popup
  // ============================================================================

  void _showItemDetail(ClothingItem item) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ItemDetailCard(item: item);
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
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
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
          // Results or Outfit Suggestions or Empty State
          Expanded(
            child: _buildContentArea(languageProvider, isDark),
          ),

          // Pagination Controls
          if (_searchResults.isNotEmpty && _outfitSuggestions.isEmpty)
            _buildPaginationControls(languageProvider),

          // Gender Filter Buttons
          if (_showGenderFilters) _buildGenderFilterButtons(languageProvider),

          // Search Bar with Autocomplete
          _buildSearchBar(languageProvider),
        ],
      ),
    );
  }

  // ✅ FIX: แยก logic การแสดงผลออกมาเป็น method เพื่อให้อ่านง่ายขึ้น
  Widget _buildContentArea(LanguageProvider languageProvider, bool isDark) {

    if (_isLoadingOutfits) {
      print('   → Showing loading for outfits');
      return const Center(child: CircularProgressIndicator());
    }

    if (_outfitSuggestions.isNotEmpty) {
      print('   → Showing outfit suggestions list');
      return _buildOutfitSuggestionsList(languageProvider);
    }

    if (_isLoadingResults) {
      print('   → Showing loading for results');
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      print('   → Showing empty state');
      return _buildEmptyState(languageProvider, isDark);
    }

    print('   → Showing search results grid');
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
        Icon(
          Icons.pets_rounded,
          size: 80,
          color: isDark ? Colors.grey[600] : Colors.grey[400],
        ),
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
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
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
        return _ResultCard(
          item: item,
          onTap: () => _showItemDetail(item),
        );
      },
    );
  }

  // ✅ FIX: ปรับปรุง outfit suggestions list ให้คล้าย ShopPage มากขึ้น
  Widget _buildOutfitSuggestionsList(LanguageProvider languageProvider) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                languageProvider.translate(
                  en: 'Recommended Outfits',
                  th: 'ชุดแนะนำ',
                ),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_outfitSuggestions.length} ${languageProvider.translate(en: "items", th: "รายการ")}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),

        // ✅ FIX: ใช้ ListView แทน Expanded เพื่อให้ scroll ได้ดีขึ้น
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _outfitSuggestions.length,
            itemBuilder: (context, index) {
              final item = _outfitSuggestions[index];
              return _OutfitSuggestionCard(
                item: item,
                onTap: () => _showItemDetail(item),
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
          // Autocomplete Suggestions
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
                            Text(
                              cat.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
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
                    borderRadius: BorderRadius.circular(50),
                  ),
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
// Gender Filter Chip Widget
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
            color: isSelected ? color : Colors.grey[400]!,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 20,
            ),
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
// Result Card Widget (Grid)
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
            // Image
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

            // Info
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.clothingName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (hasDiscount)
                        Text(
                          '฿${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 12,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey,
                          ),
                        ),
                      if (hasDiscount) const SizedBox(width: 4),
                      Text(
                        hasDiscount
                            ? '฿${item.discountPrice!.toStringAsFixed(0)}'
                            : '฿${item.price.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: hasDiscount ? Colors.red : Colors.black,
                        ),
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
// Outfit Suggestion Card Widget (Vertical List) - ✅ ปรับปรุงให้คล้าย ShopPage
// ============================================================================

class _OutfitSuggestionCard extends StatelessWidget {
  final ClothingItem item;
  final VoidCallback onTap;

  const _OutfitSuggestionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hasDiscount = item.discountPrice != null &&
        item.discountPrice! > 0 &&
        item.discountPrice! < item.price;
  final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color:  isDark
                      ?  Colors.grey[700]
                      : Colors.grey[100],
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  width: 120,
                  height: 140,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),

              const SizedBox(width: 12),

         
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gender + Size
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          _formatGender(item.gender, languageProvider),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getGenderColor(item.gender),
                          ),
                        ),
                        SizedBox(width: 30),
                        Text(
                          item.sizeCategory,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // ชื่อสินค้า
                    Text(
                      item.clothingName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Stock
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${languageProvider.translate(en: "Stock", th: "สินค้า")}: ${item.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // ✅ ราคา + ส่วนลด - คล้าย ShopPage
                    Row(
                      children: [
                        if (hasDiscount)
                          Text(
                            '฿${item.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
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
                                : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (hasDiscount && item.discountPercent != null)
                          const SizedBox(width: 8),
                        if (hasDiscount && item.discountPercent != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '-${item.discountPercent}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ✅ Cart Button
              
              FloatingActionButton.small(
                
                onPressed: () {
                  showTopSnackBar(
                    Overlay.of(context),
                    CustomSnackBar.success(
                      message: languageProvider.translate(
                        en: 'Added to cart!',
                        th: 'เพิ่มลงตะกร้าแล้ว!',
                      ),
                    ),
                  );
                },
                backgroundColor:
                    Theme.of(context).floatingActionButtonTheme.backgroundColor,
              
                child: Icon(
                  
                  Icons.shopping_cart_outlined,
                  size: 24,
                  color: Theme.of(context)
                      .floatingActionButtonTheme
                      .foregroundColor,
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
// Item Detail Card (Popup)
// ============================================================================

class _ItemDetailCard extends StatelessWidget {
  final ClothingItem item;

  const _ItemDetailCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final hasDiscount = item.discountPrice != null &&
        item.discountPrice! > 0 &&
        item.discountPrice! < item.price;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 50, left: 20, right: 20),
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปภาพสินค้า
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                  child: CachedNetworkImage(
                    imageUrl: item.imageUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 300,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 300,
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ชื่อสินค้า
                      Text(
                        item.clothingName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      // Detail rows
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Category', th: 'หมวดหมู่'),
                        value: item.category?.toString() ?? '',
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Size', th: 'ขนาด'),
                        value: item.sizeCategory,
                      ),
                      _DetailRow(
                        label:
                            languageProvider.translate(en: 'Gender', th: 'เพศ'),
                        value: _formatGender(item.gender, languageProvider),
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Stock', th: 'สต็อก'),
                        value: item.stock.toString(),
                      ),
                      _DetailRow(
                        label: languageProvider.translate(
                            en: 'Breed', th: 'สายพันธุ์'),
                        value: item.breed,
                      ),

                      // รายละเอียด
                      if (item.description.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              languageProvider.translate(
                                  en: 'Description', th: 'รายละเอียด'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // ราคา
                      Row(
                        children: [
                          if (hasDiscount)
                            Text(
                              '฿${item.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                                decorationThickness: 2,
                              ),
                            ),
                          if (hasDiscount) const SizedBox(width: 10),
                          Text(
                            hasDiscount
                                ? '฿${item.discountPrice!.toStringAsFixed(0)}'
                                : '฿${item.price.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: hasDiscount ? Colors.red : Colors.black,
                            ),
                          ),
                          if (hasDiscount) const SizedBox(width: 10),
                          if (hasDiscount && item.discountPercent != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '-${item.discountPercent}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // ปุ่ม Add to Cart
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            showTopSnackBar(
                              Overlay.of(context),
                              CustomSnackBar.success(
                                message: languageProvider.translate(
                                  en: 'Added to cart successfully!',
                                  th: 'เพิ่มลงตะกร้าสำเร็จ!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_shopping_cart_sharp),
                          label: Text(
                            languageProvider.translate(
                                en: 'Add to Cart', th: 'เพิ่มลงตะกร้า'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
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

LinearGradient getTextGradient(String type, String name) {
  if (name.contains('Everday')) {
    return const LinearGradient(
      colors: [
        Color.fromARGB(255, 113, 131, 179),
        Color.fromARGB(255, 131, 174, 254)
      ],
    );
  }

  if (name.contains('LGBT')) {
    return const LinearGradient(
      colors: [
        Color(0xFFFF5F6D),
        Color(0xFFFFC371),
        Color(0xFF47CACC),
        Color(0xFF845EC2),
      ],
    );
  }

  if (name.contains('Cyber')) {
    return const LinearGradient(
      colors: [
        Color(0xFFB721FF),
        Color(0xFF21D4FD),
      ],
    );
  }

  if (name.contains('Chinese')) {
    return const LinearGradient(
      colors: [
        Color(0xFFD31027),
        Color(0xFFEA384D),
      ],
    );
  }

  if (name.contains('Loy')) {
    return const LinearGradient(
      colors: [
        Color(0xFF2193B0),
        Color(0xFF6DD5ED),
      ],
    );
  }

  if (name.contains('Songkran')) {
    return const LinearGradient(
      colors: [
        Color(0xFF56CCF2),
        Color(0xFF2F80ED),
      ],
    );
  }

  if (name.contains('Valentine')) {
    return const LinearGradient(
      colors: [
        Color(0xFFFF758C),
        Color(0xFFFF7EB3),
      ],
    );
  }

  if (name.contains('Christmas')) {
    return const LinearGradient(
      colors: [
        Color.fromARGB(255, 255, 52, 52),
        Color(0xFF38EF7D),
      ],
    );
  }

  if (name.contains('Winter')) {
    return const LinearGradient(
      colors: [
        Color(0xFF83A4D4),
        Color.fromARGB(255, 133, 242, 248),
      ],
    );
  }

  if (name.contains('Summer')) {
    return const LinearGradient(
      colors: [
        Color(0xFFFFC371),
        Color(0xFFFF5F6D),
      ],
    );
  }

  if (name.contains('Rainy')) {
    return const LinearGradient(
      colors: [
        Color(0xFF4FACFE),
        Color(0xFF00F2FE),
      ],
    );
  }

  return const LinearGradient(
    colors: [Color(0xFFBDBDBD), Color(0xFFE0E0E0)],
  );
}