// ----FavoritePage (Fixed with API Integration)--------------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/favorite_provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  int? _userId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadFavourites();
  }

  // ดึง userId และโหลดรายการโปรด
  Future<void> _loadFavourites() async {
    try {
      // TODO: แก้ไขให้ดึง userId จาก Backend ตาม firebase_uid
      // ตอนนี้ใช้ hardcode ไปก่อน
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // TODO: เรียก API เพื่อแปลง firebase_uid → user_id (INTEGER)
        // GET /api/get/user-id-from-firebase/{firebase_uid}
        
        setState(() {
          _userId = 1; // Temporary hardcode
          _isInitialized = true;
        });

        // โหลดรายการโปรดจาก Backend
        await context.read<FavoriteProvider>().fetchFavorites(_userId!);
      } else {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('❌ Error loading favourites: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    // แสดง Loading ขณะกำลังโหลด
    if (!_isInitialized) {
      return SafeArea(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // ตรวจสอบว่า Login หรือยัง
    if (_userId == null) {
      return SafeArea(
        child: _buildNotLoggedInState(context, languageProvider),
      );
    }

    return SafeArea(
      child: Consumer<FavoriteProvider>(
        builder: (context, favoriteProvider, child) {
          final favorites = favoriteProvider.favorites;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final isLoading = favoriteProvider.isLoading;
          final error = favoriteProvider.error;

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color.fromARGB(120, 88, 88, 88)
                      : Colors.grey[200],
                ),
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ไอคอนรายการโปรด
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 30,
                    ),
                    // จำนวนรายการ
                    Text(
                      languageProvider.translate(
                          en: "Items: ${favorites.length}",
                          th: "รายการ: ${favorites.length} รายการ"),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : error != null
                        ? _buildErrorState(context, error, languageProvider)
                        : favorites.isEmpty
                            ? _buildEmptyState(context, languageProvider, isDark)
                            : _buildFavoriteList(context, favorites, isDark, languageProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  // สถานะ: ยังไม่ได้ Login
  Widget _buildNotLoggedInState(BuildContext context, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.login,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            languageProvider.translate(
                en: 'Please login to view favorites',
                th: 'กรุณาเข้าสู่ระบบเพื่อดูรายการโปรด'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // สถานะ: เกิด Error
  Widget _buildErrorState(BuildContext context, String error, LanguageProvider languageProvider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red,
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (_userId != null) {
                context.read<FavoriteProvider>().fetchFavorites(_userId!);
              }
            },
            child: Text(languageProvider.translate(en: 'Retry', th: 'ลองใหม่')),
          ),
        ],
      ),
    );
  }

  // สถานะ: ไม่มีรายการโปรด
  Widget _buildEmptyState(BuildContext context, LanguageProvider languageProvider, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          SizedBox(height: 20),
          Text(
            languageProvider.translate(en: "No favorites", th: "ไม่มีรายการโปรด"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          SizedBox(height: 5),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              languageProvider.translate(
                  en: "Add products to your favorites list to check prices and stock availability.",
                  th: "เพิ่มสินค้าลงในรายการโปรดของคุณเพื่อตรวจสอบราคาและสถานะสต็อก"),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // แสดงรายการโปรด
  Widget _buildFavoriteList(
    BuildContext context,
    List<ProductRecommendation> favorites,
    bool isDark,
    LanguageProvider languageProvider,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final product = favorites[index];
        return Card(
          elevation: 2,
          color: isDark ? Colors.grey[900] : Colors.white,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                // ส่วนบน: รูป + ชื่อ + ราคา + ปุ่มลบ
                Row(
                  children: [
                    // รูปภาพ
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        product.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: Icon(Icons.shopping_bag, size: 30),
                          );
                        },
                      ),
                    ),

                    SizedBox(width: 12),

                    // ชื่อสินค้า + ราคา
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            languageProvider.translate(
                                en: 'Price: ${product.price}',
                                th: 'ราคา: ${product.price}'),
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ปุ่มลบ
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red, size: 24),
                      onPressed: () async {
                        // แสดง Confirmation Dialog
                        final confirmed = await _showDeleteConfirmation(
                          context,
                          product,
                          languageProvider,
                        );

                        if (confirmed == true && _userId != null) {
                          // ✅ เรียก API เพื่อลบ
                          final success = await context
                              .read<FavoriteProvider>()
                              .removeFavorite(_userId!, product.id);

                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageProvider.translate(
                                    en: 'Removed from favorites',
                                    th: 'ลบออกจากรายการโปรดแล้ว')),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(languageProvider.translate(
                                    en: 'Failed to remove',
                                    th: 'ลบไม่สำเร็จ')),
                                duration: Duration(seconds: 2),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      tooltip: languageProvider.translate(
                          en: 'Remove from favorites',
                          th: 'ลบออกจากรายการโปรด'),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // ส่วนล่าง: ปุ่ม Buy และ More
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(languageProvider.translate(
                                  en: 'Coming Soon!', th: 'เร็วๆ นี้!')),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          languageProvider.translate(en: 'Buy', th: 'ซื้อ'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(languageProvider.translate(
                                  en: 'Opening details...',
                                  th: 'กำลังเปิดรายละเอียด...')),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.grey[400],
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          languageProvider.translate(
                              en: 'More', th: 'เพิ่มเติม'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // แสดง Confirmation Dialog
  Future<bool?> _showDeleteConfirmation(
    BuildContext context,
    ProductRecommendation product,
    LanguageProvider languageProvider,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.translate(
            en: 'Remove from Favorites?',
            th: 'ลบออกจากรายการโปรด?')),
        content: Text(languageProvider.translate(
            en: 'Do you want to remove "${product.name}" from favorites?',
            th: 'คุณต้องการลบ "${product.name}" ออกจากรายการโปรดหรือไม่?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child:
                Text(languageProvider.translate(en: 'Cancel', th: 'ยกเลิก')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              languageProvider.translate(en: 'Remove', th: 'ลบ'),
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}