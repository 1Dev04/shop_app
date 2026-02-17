import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ เพิ่มนี้

// ============================================================================
// Helper - Base URL
// ============================================================================

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

  // local
  if (kIsWeb) {
    return 'http://localhost:10000';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:10000';
  }

  return 'http://localhost:10000';
}

// ============================================================================
// Helper - Get Firebase UID
// ============================================================================

Future<String> getFirebaseUid() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    throw Exception('User not logged in');
  }
  return user.uid;
}

// ============================================================================
// Models
// ============================================================================

class BasketItem {
  final int basketId;
  final String firebaseUid; // ✅ เปลี่ยนจาก userId
  final String clothingUuid;
  final int quantity;
  final String clothingName;
  final double price;
  final double? discountPrice;
  final int stock;
  final String imageUrl;
  final String category;
  final String sizeCategory;
  final int gender;
  final String breed;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  BasketItem({
    required this.basketId,
    required this.firebaseUid,
    required this.clothingUuid,
    required this.quantity,
    required this.clothingName,
    required this.price,
    this.discountPrice,
    required this.stock,
    required this.imageUrl,
    required this.category,
    required this.sizeCategory,
    required this.gender,
    required this.breed,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BasketItem.fromJson(Map<String, dynamic> json) {
    return BasketItem(
      basketId: json['basket_id'],
      firebaseUid: json['firebase_uid'] ?? '',
      clothingUuid: json['clothing_uuid'],
      quantity: json['quantity'],
      clothingName: json['clothing_name'] ?? '',
      price: _parseDouble(json['price']),
      discountPrice: _parseDouble(json['discount_price']),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      category: json['category']?.toString() ?? '',
      sizeCategory: json['size_category'] ?? '',
      gender: json['gender'] ?? 0,
      breed: json['breed'] ?? '',
      totalPrice: _parseDouble(json['total_price']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

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
      totalPrice: (json['total_price'] ?? 0.0).toDouble(),
    );
  }
}

class FavouriteItem {
  final int favouriteId;
  final String firebaseUid; // ✅ เปลี่ยนจาก userId
  final String clothingUuid;
  final String clothingName;
  final double price;
  final double? discountPrice;
  final int stock;
  final String imageUrl;
  final String category;
  final String sizeCategory;
  final int gender;
  final String breed;
  final String description;
  final DateTime createdAt;

  FavouriteItem({
    required this.favouriteId,
    required this.firebaseUid,
    required this.clothingUuid,
    required this.clothingName,
    required this.price,
    this.discountPrice,
    required this.stock,
    required this.imageUrl,
    required this.category,
    required this.sizeCategory,
    required this.gender,
    required this.breed,
    required this.description,
    required this.createdAt,
  });

  factory FavouriteItem.fromJson(Map<String, dynamic> json) {
    return FavouriteItem(
      favouriteId: json['favourite_id'],
      firebaseUid: json['firebase_uid'] ?? '',
      clothingUuid: json['clothing_uuid'],
      clothingName: json['clothing_name'] ?? '',
      price: _parseDouble(json['price']),
      discountPrice: _parseDouble(json['discount_price']),
      stock: json['stock'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      category: json['category']?.toString() ?? '',
      sizeCategory: json['size_category'] ?? '',
      gender: json['gender'] ?? 0,
      breed: json['breed'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

// ============================================================================
// API Service - Basket
// ============================================================================

class BasketApiService {
  final String baseUrl = getBaseUrl();

  // ✅ GET: ดึงรายการตะกร้าทั้งหมด (ใช้ firebase_uid จาก Firebase Auth)
  Future<Map<String, dynamic>> getBasket() async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/get/person-baskets/$firebaseUid');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);

        final items = (data['items'] as List)
            .map((json) => BasketItem.fromJson(json))
            .toList();

        final summary = BasketSummary.fromJson(data['summary']);

        return {
          'items': items,
          'summary': summary,
        };
      } else {
        throw Exception('Failed to load basket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting basket: $e');
      rethrow;
    }
  }

  // ✅ GET: ดึงจำนวนสินค้าในตะกร้า
  Future<Map<String, int>> getBasketCount() async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/get/person-baskets/count/$firebaseUid');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'total_items': data['total_items'],
          'total_quantity': data['total_quantity'],
        };
      } else {
        throw Exception('Failed to load basket count');
      }
    } catch (e) {
      print('Error getting basket count: $e');
      rethrow;
    }
  }

  // ✅ POST: เพิ่มสินค้าลงตะกร้า (ไม่ต้องส่ง userId)
  Future<Map<String, dynamic>> addToBasket({
    required String clothingUuid,
    int quantity = 1,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/post/person-baskets');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebase_uid': firebaseUid,
              'clothing_uuid': clothingUuid,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Failed to add to basket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding to basket: $e');
      rethrow;
    }
  }

  // ✅ PUT: อัพเดทจำนวนสินค้า
  Future<Map<String, dynamic>> updateQuantity({
    required String clothingUuid,
    required int quantity,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/put/person-baskets/quantity');
      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebase_uid': firebaseUid,
              'clothing_uuid': clothingUuid,
              'quantity': quantity,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Failed to update quantity: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating quantity: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ลบสินค้าออกจากตะกร้า
  Future<Map<String, dynamic>> removeFromBasket({
    required String clothingUuid,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/del/person-baskets');
      final response = await http
          .delete(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebase_uid': firebaseUid,
              'clothing_uuid': clothingUuid,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Failed to remove from basket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing from basket: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ล้างตะกร้าทั้งหมด
  Future<Map<String, dynamic>> clearBasket() async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/del/person-baskets/clear/$firebaseUid');
      final response = await http.delete(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Failed to clear basket: ${response.statusCode}');
      }
    } catch (e) {
      print('Error clearing basket: $e');
      rethrow;
    }
  }
}

// ============================================================================
// API Service - Favourite
// ============================================================================

class FavouriteApiService {
  final String baseUrl = getBaseUrl();

  // ✅ GET: ดึงรายการโปรดทั้งหมด
  Future<List<FavouriteItem>> getFavourites() async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/get/person-favourite/$firebaseUid');
      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => FavouriteItem.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load favourites: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting favourites: $e');
      rethrow;
    }
  }

  // ✅ GET: ดึงจำนวนรายการโปรด
  Future<int> getFavouriteCount() async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/get/person-favourite/count/$firebaseUid');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['total'];
      } else {
        throw Exception('Failed to load favourite count');
      }
    } catch (e) {
      print('Error getting favourite count: $e');
      rethrow;
    }
  }

  // ✅ POST: เพิ่มสินค้าเข้ารายการโปรด (ไม่ต้องส่ง userId)
  Future<Map<String, dynamic>> addToFavourite({
    required String clothingUuid,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/post/person-favourite');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebase_uid': firebaseUid,
              'clothing_uuid': clothingUuid,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception('Failed to add to favourite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding to favourite: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ลบสินค้าออกจากรายการโปรด
  Future<Map<String, dynamic>> removeFromFavourite({
    required String clothingUuid,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/del/person-favourite');
      final response = await http
          .delete(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'firebase_uid': firebaseUid,
              'clothing_uuid': clothingUuid,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody);
      } else {
        throw Exception(
            'Failed to remove from favourite: ${response.statusCode}');
      }
    } catch (e) {
      print('Error removing from favourite: $e');
      rethrow;
    }
  }

  // ✅ GET: ตรวจสอบว่าสินค้าอยู่ใน Favourite หรือไม่
  Future<bool> checkFavourite({
    required String clothingUuid,
  }) async {
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse(
          '$baseUrl/api/get/check-favourite/$firebaseUid/$clothingUuid');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['is_favourite'] ?? false;
      } else {
        throw Exception('Failed to check favourite');
      }
    } catch (e) {
      print('Error checking favourite: $e');
      return false;
    }
  }
}