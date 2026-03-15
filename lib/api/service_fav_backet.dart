import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';

// ============================================================================
// Helper - Base URL
// ============================================================================

String getBaseUrl() {
  const String env = String.fromEnvironment(
    'ENV',
    defaultValue: 'local',
  );

  if (env == 'prod') return 'https://backend-catshop.onrender.com';

  if (env == 'prod-v2') {
    return 'https://catshop-backend-v2.onrender.com';
  }

  if (env == 'prod-v3') return 'https://cat-shop-backend.onrender.com';

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
  print('🔑 [Auth] Getting Firebase UID...');
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    print('❌ [Auth] User not logged in!');
    throw Exception('User not logged in');
  }
  print('✅ [Auth] Firebase UID: ${user.uid.substring(0, 10)}...');
  return user.uid;
}

// ============================================================================
// Models
// ============================================================================

class BasketItem {
  final int basketId;
  final String firebaseUid;
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
  final String firebaseUid;
  final String clothingUuid;
  final String clothingName;
  final double price;
  final double? discountPrice;
  final int stock;
  final String imageUrl;
  final String images;
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
    required this.images,
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
      images: json['images'] ?? '',
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

  // ✅ GET: ดึงรายการตะกร้าทั้งหมด
  Future<Map<String, dynamic>> getBasket() async {
    print('\n🛒 [BasketApi] getBasket() - START');
    try {
      final firebaseUid = await getFirebaseUid();

      final url = Uri.parse('$baseUrl/api/get/person-baskets/$firebaseUid');
      print('📤 [BasketApi] GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [BasketApi] Items: ${data['items'].length}');

        final items = (data['items'] as List)
            .map((json) => BasketItem.fromJson(json))
            .toList();

        final summary = BasketSummary.fromJson(data['summary']);
        print(
            '✅ [BasketApi] Total: ${summary.totalItems} items, ฿${summary.totalPrice}');

        return {'items': items, 'summary': summary};
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to load basket: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
      rethrow;
    }
  }

  // ✅ GET: ดึงจำนวนสินค้าในตะกร้า
  Future<Map<String, int>> getBasketCount() async {
    print('\n📊 [BasketApi] getBasketCount() - START');
    try {
      final firebaseUid = await getFirebaseUid();
      final url =
          Uri.parse('$baseUrl/api/get/person-baskets/count/$firebaseUid');
      print('📤 [BasketApi] GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
            '✅ [BasketApi] Count: ${data['total_items']} items, ${data['total_quantity']} qty');
        return {
          'total_items': data['total_items'],
          'total_quantity': data['total_quantity'],
        };
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to load basket count');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
      rethrow;
    }
  }

  // ✅ POST: เพิ่มสินค้าลงตะกร้า
  Future<Map<String, dynamic>> addToBasket({
    required String clothingUuid,
    int quantity = 1,
  }) async {
    print('\n➕ [BasketApi] addToBasket() - START');
    print('📦 [BasketApi] Item: $clothingUuid, Qty: $quantity');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/post/person-baskets');
      print('📤 [BasketApi] POST $url');

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

      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [BasketApi] Added successfully');
        return data;
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to add to basket: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
      rethrow;
    }
  }

  // ✅ PUT: อัพเดทจำนวนสินค้า
  Future<Map<String, dynamic>> updateQuantity({
    required String clothingUuid,
    required int quantity,
  }) async {
    print('\n🔄 [BasketApi] updateQuantity() - START');
    print('📦 [BasketApi] Item: $clothingUuid, New Qty: $quantity');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/put/person-baskets/quantity');
      print('📤 [BasketApi] PUT $url');

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

      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [BasketApi] Updated successfully');
        return data;
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to update quantity: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ลบสินค้าออกจากตะกร้า
  Future<Map<String, dynamic>> removeFromBasket({
    required String clothingUuid,
  }) async {
    print('\n🗑️ [BasketApi] removeFromBasket() - START');
    print('📦 [BasketApi] Item: $clothingUuid');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/del/person-baskets');
      print('📤 [BasketApi] DELETE $url');

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

      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [BasketApi] Removed successfully');
        return data;
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to remove from basket: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ล้างตะกร้าทั้งหมด
  Future<Map<String, dynamic>> clearBasket() async {
    print('\n🧹 [BasketApi] clearBasket() - START');
    try {
      final firebaseUid = await getFirebaseUid();
      final url =
          Uri.parse('$baseUrl/api/del/person-baskets/clear/$firebaseUid');
      print('📤 [BasketApi] DELETE $url');

      final response =
          await http.delete(url).timeout(const Duration(seconds: 10));
      print('📥 [BasketApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [BasketApi] Cleared successfully');
        return data;
      } else {
        print('❌ [BasketApi] Failed: ${response.statusCode}');
        throw Exception('Failed to clear basket: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [BasketApi] Error: $e');
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
    print('\n❤️ [FavouriteApi] getFavourites() - START');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/get/person-favourite/$firebaseUid');
      print('📤 [FavouriteApi] GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      print('📥 [FavouriteApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<dynamic> data = json.decode(decodedBody);
        print('✅ [FavouriteApi] Items: ${data.length}');
        return data.map((json) => FavouriteItem.fromJson(json)).toList();
      } else {
        print('❌ [FavouriteApi] Failed: ${response.statusCode}');
        throw Exception('Failed to load favourites: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FavouriteApi] Error: $e');
      rethrow;
    }
  }

  // ✅ GET: ดึงจำนวนรายการโปรด
  Future<int> getFavouriteCount() async {
    print('\n📊 [FavouriteApi] getFavouriteCount() - START');
    try {
      final firebaseUid = await getFirebaseUid();
      final url =
          Uri.parse('$baseUrl/api/get/person-favourite/count/$firebaseUid');
      print('📤 [FavouriteApi] GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print('📥 [FavouriteApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ [FavouriteApi] Count: ${data['total']}');
        return data['total'];
      } else {
        print('❌ [FavouriteApi] Failed: ${response.statusCode}');
        throw Exception('Failed to load favourite count');
      }
    } catch (e) {
      print('❌ [FavouriteApi] Error: $e');
      rethrow;
    }
  }

  // ✅ POST: เพิ่มสินค้าเข้ารายการโปรด
  Future<Map<String, dynamic>> addToFavourite({
    required String clothingUuid,
  }) async {
    print('\n➕ [FavouriteApi] addToFavourite() - START');
    print('📦 [FavouriteApi] Item: $clothingUuid');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/post/person-favourite');
      print('📤 [FavouriteApi] POST $url');

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

      print('📥 [FavouriteApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [FavouriteApi] Added successfully');
        return data;
      } else {
        print('❌ [FavouriteApi] Failed: ${response.statusCode}');
        throw Exception('Failed to add to favourite: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FavouriteApi] Error: $e');
      rethrow;
    }
  }

  // ✅ DELETE: ลบสินค้าออกจากรายการโปรด
  Future<Map<String, dynamic>> removeFromFavourite({
    required String clothingUuid,
  }) async {
    print('\n🗑️ [FavouriteApi] removeFromFavourite() - START');
    print('📦 [FavouriteApi] Item: $clothingUuid');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse('$baseUrl/api/del/person-favourite');
      print('📤 [FavouriteApi] DELETE $url');

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

      print('📥 [FavouriteApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final data = json.decode(decodedBody);
        print('✅ [FavouriteApi] Removed successfully');
        return data;
      } else {
        print('❌ [FavouriteApi] Failed: ${response.statusCode}');
        throw Exception(
            'Failed to remove from favourite: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ [FavouriteApi] Error: $e');
      rethrow;
    }
  }

  // ✅ GET: ตรวจสอบว่าสินค้าอยู่ใน Favourite หรือไม่
  Future<bool> checkFavourite({
    required String clothingUuid,
  }) async {
    print('\n🔍 [FavouriteApi] checkFavourite() - START');
    print('📦 [FavouriteApi] Item: $clothingUuid');
    try {
      final firebaseUid = await getFirebaseUid();
      final url = Uri.parse(
          '$baseUrl/api/get/check-favourite/$firebaseUid/$clothingUuid');
      print('📤 [FavouriteApi] GET $url');

      final response = await http.get(url).timeout(const Duration(seconds: 5));
      print('📥 [FavouriteApi] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final isFav = data['is_favourite'] ?? false;
        print('✅ [FavouriteApi] Is Favourite: $isFav');
        return isFav;
      } else {
        print('❌ [FavouriteApi] Failed: ${response.statusCode}');
        throw Exception('Failed to check favourite');
      }
    } catch (e) {
      print('❌ [FavouriteApi] Error: $e');
      return false;
    }
  }
}
