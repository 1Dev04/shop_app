import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// Product Model
// ============================================================================

class ProductRecommendation {
  final String id; // UUID string จาก cat_clothing
  final String name;
  final String price;
  final String imageUrl;
  final String? detailUrl;
  final double? discountPrice;
  final int? stock;

  ProductRecommendation({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.detailUrl,
    this.discountPrice,
    this.stock,
  });

  // สร้าง Object จาก JSON (จาก API)
  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      id: json['uuid']?.toString() ?? json['clothing_uuid']?.toString() ?? '',
      name: json['clothing_name'] ?? '',
      price: json['price']?.toString() ?? '0',
      imageUrl: json['image_url'] ?? '',
      detailUrl: json['detail_url'],
      discountPrice: json['discount_price']?.toDouble(),
      stock: json['stock'],
    );
  }

  // แปลงเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': id,
      'clothing_name': name,
      'price': price,
      'image_url': imageUrl,
      'detail_url': detailUrl,
      'discount_price': discountPrice,
      'stock': stock,
    };
  }
}

// ============================================================================
// Favorite Provider with API Integration
// ============================================================================

class FavoriteProvider with ChangeNotifier {
  final List<ProductRecommendation> _favorites = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<ProductRecommendation> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ฟังก์ชันหา Base URL
  String getBaseUrl() {
    // TODO: แก้ไขตาม Environment ของคุณ
    const String env = String.fromEnvironment('ENV', defaultValue: 'local');
    
    if (env == 'prod') {
      return 'https://catshop-backend-9pzq.onrender.com';
    }
    if (env == 'prod-v2') {
      return 'https://catshop-backend-v2.onrender.com';
    }
    
    // Local development
    return 'http://localhost:8000';
  }

  // ============================================================================
  // API Methods
  // ============================================================================

  /// ดึงรายการโปรดจาก Backend
  Future<void> fetchFavorites(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/get/person-favourite/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);

        _favorites.clear();
        for (var item in data) {
          _favorites.add(ProductRecommendation.fromJson(item));
        }

        _error = null;
      } else {
        _error = 'Failed to load favorites: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading favorites: $e';
      print('❌ Error fetching favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// เพิ่มสินค้าเข้ารายการโปรด
  Future<bool> addFavorite(int userId, ProductRecommendation product) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/post/person-favourite';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'clothing_uuid': product.id, // UUID string
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // เพิ่มใน Local State
        if (!isFavorite(product.id)) {
          _favorites.add(product);
          notifyListeners();
        }
        return true;
      } else {
        print('❌ Failed to add favorite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding favorite: $e');
      return false;
    }
  }

  /// ลบสินค้าออกจากรายการโปรด
  Future<bool> removeFavorite(int userId, String productId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/del/person-favourite';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'clothing_uuid': productId, // UUID string
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ลบจาก Local State
        _favorites.removeWhere((item) => item.id == productId);
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to remove favorite: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error removing favorite: $e');
      return false;
    }
  }

  /// Toggle Favorite (เพิ่ม/ลบ)
  Future<bool> toggleFavorite(int userId, ProductRecommendation product) async {
    if (isFavorite(product.id)) {
      return await removeFavorite(userId, product.id);
    } else {
      return await addFavorite(userId, product);
    }
  }

  /// เช็คว่าสินค้าอยู่ในรายการโปรดหรือไม่
  bool isFavorite(String productId) {
    return _favorites.any((item) => item.id == productId);
  }

  /// เช็คจาก Backend (Optional - สำหรับการ verify)
  Future<bool> checkFavoriteFromBackend(int userId, String clothingUuid) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/get/check-favourite/$userId/$clothingUuid';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_favourite'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ Error checking favorite: $e');
      return false;
    }
  }

  /// ดึงจำนวนรายการโปรดจาก Backend
  Future<int> getFavoriteCount(int userId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/get/person-favourite/count/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'] ?? 0;
      }
      return _favorites.length;
    } catch (e) {
      print('❌ Error getting favorite count: $e');
      return _favorites.length;
    }
  }

  // ============================================================================
  // Local-only Methods (สำหรับใช้งานแบบ Offline หรือ Testing)
  // ============================================================================

  /// เพิ่มรายการโปรด (Local only - ไม่เรียก API)
  void addFavoriteLocal(ProductRecommendation product) {
    if (!isFavorite(product.id)) {
      _favorites.add(product);
      notifyListeners();
    }
  }

  /// ลบรายการโปรด (Local only)
  void removeFavoriteLocal(String productId) {
    _favorites.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  /// Toggle Favorite (Local only)
  void toggleFavoriteLocal(ProductRecommendation product) {
    if (isFavorite(product.id)) {
      removeFavoriteLocal(product.id);
    } else {
      addFavoriteLocal(product);
    }
  }

  /// Clear all favorites
  void clearFavorites() {
    _favorites.clear();
    notifyListeners();
  }

  /// Load favorites from JSON (สำหรับ Cache)
  void loadFromJson(List<dynamic> jsonList) {
    _favorites.clear();
    for (var item in jsonList) {
      _favorites.add(ProductRecommendation.fromJson(item));
    }
    notifyListeners();
  }

  /// Export favorites to JSON (สำหรับ Cache)
  List<Map<String, dynamic>> toJson() {
    return _favorites.map((item) => item.toJson()).toList();
  }
}