import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// ============================================================================
// Basket Item Model
// ============================================================================

class BasketItem {
  final int basketId;
  final String clothingUuid;
  final String clothingName;
  final int quantity;
  final double price;
  final double discountPrice;
  final int stock;
  final String imageUrl;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  BasketItem({
    required this.basketId,
    required this.clothingUuid,
    required this.clothingName,
    required this.quantity,
    required this.price,
    this.discountPrice = 0,
    required this.stock,
    required this.imageUrl,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  // คำนวณราคารวมของรายการนี้
  double get totalPrice {
    final effectivePrice = discountPrice > 0 ? discountPrice : price;
    return effectivePrice * quantity;
  }

  // มีส่วนลดหรือไม่
  bool get hasDiscount => discountPrice > 0;

  // สร้าง Object จาก JSON
  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      basketId: json['basket_id'],
      clothingUuid: json['clothing_uuid']?.toString() ?? '',
      clothingName: json['clothing_name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? 0).toDouble(),
      discountPrice: (json['discount_price'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      category: json['category'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  // แปลงเป็น JSON
  Map<String, dynamic> toJson() {
    return {
      'basket_id': basketId,
      'clothing_uuid': clothingUuid,
      'clothing_name': clothingName,
      'quantity': quantity,
      'price': price,
      'discount_price': discountPrice,
      'stock': stock,
      'image_url': imageUrl,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// ============================================================================
// Basket Summary Model
// ============================================================================

class BasketSummary {
  final int totalItems;
  final int totalQuantity;
  final double totalPrice;

  BasketSummary({
    required this.totalItems,
    required this.totalQuantity,
    required this.totalPrice,
  });

  factory BasketSummary.fromJson(Map<String, dynamic> json) {
    return BasketSummary(
      totalItems: json['total_items'] ?? 0,
      totalQuantity: json['total_quantity'] ?? 0,
      totalPrice: (json['total_price'] ?? 0).toDouble(),
    );
  }
}

// ============================================================================
// Basket Provider with API Integration
// ============================================================================

class BasketProvider with ChangeNotifier {
  List<BasketItem> _basketItems = [];
  BasketSummary? _summary;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<BasketItem> get basketItems => _basketItems;
  BasketSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get itemCount => _basketItems.length;
  int get totalQuantity => _summary?.totalQuantity ?? 0;
  double get totalPrice => _summary?.totalPrice ?? 0.0;

  // ฟังก์ชันหา Base URL
String getBaseUrl() {
  // prod / prod-v2 / local
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

  // ===== local =====
  if (kIsWeb) {
    return 'http://localhost:10000';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:10000';
  }

  return 'http://localhost:10000';
}


  // ============================================================================
  // API Methods
  // ============================================================================

  /// ดึงตะกร้าสินค้าจาก Backend
  Future<void> fetchBasket(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/get/person-baskets/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        // Parse items
        final List<dynamic> itemsList = data['items'] ?? [];
        _basketItems = itemsList.map((item) => BasketItem.fromJson(item)).toList();

        // Parse summary
        if (data['summary'] != null) {
          _summary = BasketSummary.fromJson(data['summary']);
        }

        _error = null;
      } else {
        _error = 'Failed to load basket: ${response.statusCode}';
      }
    } catch (e) {
      _error = 'Error loading basket: $e';
      print('❌ Error fetching basket: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// เพิ่มสินค้าลงตะกร้า
  Future<bool> addToBasket(int userId, String clothingUuid, int quantity) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/post/person-baskets';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'clothing_uuid': clothingUuid,
          'quantity': quantity,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // โหลดตะกร้าใหม่เพื่ออัพเดท
        await fetchBasket(userId);
        return true;
      } else {
        print('❌ Failed to add to basket: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error adding to basket: $e');
      return false;
    }
  }

  /// อัพเดทจำนวนสินค้าในตะกร้า
  Future<bool> updateQuantity(int userId, String clothingUuid, int newQuantity) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/put/person-baskets/quantity';

      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'clothing_uuid': clothingUuid,
          'quantity': newQuantity,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // อัพเดท Local State
        final index = _basketItems.indexWhere((item) => item.clothingUuid == clothingUuid);
        if (index != -1) {
          if (newQuantity <= 0) {
            _basketItems.removeAt(index);
          } else {
            // โหลดใหม่เพื่อให้แน่ใจว่าข้อมูลถูกต้อง
            await fetchBasket(userId);
          }
        }
        return true;
      } else {
        print('❌ Failed to update quantity: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error updating quantity: $e');
      return false;
    }
  }

  /// เพิ่มจำนวน (+1)
  Future<bool> incrementQuantity(int userId, String clothingUuid) async {
    final item = _basketItems.firstWhere(
      (item) => item.clothingUuid == clothingUuid,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.quantity >= item.stock) {
      _error = 'Maximum stock reached';
      notifyListeners();
      return false;
    }

    return await updateQuantity(userId, clothingUuid, item.quantity + 1);
  }

  /// ลดจำนวน (-1)
  Future<bool> decrementQuantity(int userId, String clothingUuid) async {
    final item = _basketItems.firstWhere(
      (item) => item.clothingUuid == clothingUuid,
      orElse: () => throw Exception('Item not found'),
    );

    if (item.quantity <= 1) {
      return await removeFromBasket(userId, clothingUuid);
    }

    return await updateQuantity(userId, clothingUuid, item.quantity - 1);
  }

  /// ลบสินค้าออกจากตะกร้า
  Future<bool> removeFromBasket(int userId, String clothingUuid) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/del/person-baskets';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'clothing_uuid': clothingUuid,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // ลบจาก Local State
        _basketItems.removeWhere((item) => item.clothingUuid == clothingUuid);
        _recalculateSummary();
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to remove from basket: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error removing from basket: $e');
      return false;
    }
  }

  /// ล้างตะกร้าทั้งหมด
  Future<bool> clearBasket(int userId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/del/person-baskets/clear/$userId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _basketItems.clear();
        _summary = BasketSummary(totalItems: 0, totalQuantity: 0, totalPrice: 0.0);
        notifyListeners();
        return true;
      } else {
        print('❌ Failed to clear basket: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error clearing basket: $e');
      return false;
    }
  }

  /// ดึงจำนวนสินค้าในตะกร้า
  Future<Map<String, int>> getBasketCount(int userId) async {
    try {
      final baseUrl = getBaseUrl();
      final url = '$baseUrl/api/get/person-baskets/count/$userId';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'total_items': data['total_items'] ?? 0,
          'total_quantity': data['total_quantity'] ?? 0,
        };
      }
      return {'total_items': 0, 'total_quantity': 0};
    } catch (e) {
      print('❌ Error getting basket count: $e');
      return {'total_items': 0, 'total_quantity': 0};
    }
  }

  // ============================================================================
  // Local Helper Methods
  // ============================================================================

  /// คำนวณ Summary ใหม่ (Local)
  void _recalculateSummary() {
    final totalItems = _basketItems.length;
    final totalQuantity = _basketItems.fold(0, (sum, item) => sum + item.quantity);
    final totalPrice = _basketItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    _summary = BasketSummary(
      totalItems: totalItems,
      totalQuantity: totalQuantity,
      totalPrice: totalPrice,
    );
  }

  /// เช็คว่าสินค้าอยู่ในตะกร้าหรือไม่
  bool isInBasket(String clothingUuid) {
    return _basketItems.any((item) => item.clothingUuid == clothingUuid);
  }

  /// ดึงจำนวนสินค้าที่อยู่ในตะกร้า
  int getItemQuantity(String clothingUuid) {
    final item = _basketItems.firstWhere(
      (item) => item.clothingUuid == clothingUuid,
      orElse: () => BasketItem(
        basketId: 0,
        clothingUuid: '',
        clothingName: '',
        quantity: 0,
        price: 0,
        stock: 0,
        imageUrl: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return item.quantity;
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}