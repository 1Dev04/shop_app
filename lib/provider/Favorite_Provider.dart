import 'package:flutter/material.dart';

class ProductRecommendation {
  final String id;
  final String name;
  final String price;
  final String imageUrl;
  final String? detailUrl;

  ProductRecommendation({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.detailUrl,
  });
}

class FavoriteProvider with ChangeNotifier {
  final List<ProductRecommendation> _favorites = [];

  List<ProductRecommendation> get favorites => _favorites;

  bool isFavorite(String productId) {
    return _favorites.any((item) => item.id == productId);
  }

  void toggleFavorite(ProductRecommendation product) {
    if (isFavorite(product.id)) {
      _favorites.removeWhere((item) => item.id == product.id);
    } else {
      _favorites.add(product);
    }
    notifyListeners();
  }

  void removeFavorite(String productId) {
    _favorites.removeWhere((item) => item.id == productId);
    notifyListeners();
  }
}
