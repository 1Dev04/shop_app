import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/Favorite_Provider.dart';
import 'package:flutter_application_1/provider/Theme_Provider.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

// Model สำหรับข้อมูลแมว
class CatData {
  final String name;
  final String? breed;
  final int? age;

  final double weight;
  final String sizeCategory;

  final double chestCm;
  final double? neckCm;
  final double? bodyLengthCm;

  final double confidence;
  final List<double> boundingBox;

  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime detectedAt;

  CatData({
    required this.name,
    this.breed,
    this.age,
    required this.weight,
    required this.sizeCategory,
    required this.chestCm,
    this.neckCm,
    this.bodyLengthCm,
    required this.confidence,
    required this.boundingBox,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.detectedAt,
  });

  factory CatData.fromJson(Map<String, dynamic> json) {
    return CatData(
      name: json['name'],
      breed: json['breed'],
      age: json['age'],
      weight: (json['weight'] as num).toDouble(),
      sizeCategory: json['size_category'],
      chestCm: (json['chest_cm'] as num).toDouble(),
      neckCm:
          json['neck_cm'] != null ? (json['neck_cm'] as num).toDouble() : null,
      bodyLengthCm: json['body_length_cm'] != null
          ? (json['body_length_cm'] as num).toDouble()
          : null,
      confidence: (json['confidence'] as num).toDouble(),
      boundingBox: List<double>.from(
          json['bounding_box'].map((e) => (e as num).toDouble())),
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      detectedAt: DateTime.parse(json['detected_at']),
    );
  }
}

class MeasureSizeCat extends StatefulWidget {
  const MeasureSizeCat({super.key});

  @override
  State<MeasureSizeCat> createState() => _MeasureSizeCatState();
}

class _MeasureSizeCatState extends State<MeasureSizeCat> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  CatData? _detectedCat;
  List<ProductRecommendation> _recommendedProducts = [];

  // Cloudinary Config
  static const String cloudinaryCloudName = 'dag73dhpl';
  static const String cloudinaryUploadPreset = 'cat_img_detect';
  static const String cloudinaryFolder = 'Fetch_Img_SizeCat';

  static const String pythonBackendUrl =
    'http://localhost:8000/api/cat/detect';

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
  }

  void _loadRecommendedProducts() {
    setState(() {
      _recommendedProducts = [
        ProductRecommendation(
          id: '1',
          name: 'Cat Clothing Set A',
          price: '\$25',
          imageUrl:
              'https://via.placeholder.com/150/FF6347/FFFFFF?text=Product+1',
          detailUrl: 'https://example.com/product1',
        ),
        ProductRecommendation(
          id: '2',
          name: 'Cute Cat Sweater',
          price: '\$30',
          imageUrl:
              'https://via.placeholder.com/150/4682B4/FFFFFF?text=Product+2',
          detailUrl: 'https://example.com/product2',
        ),
        ProductRecommendation(
          id: '3',
          name: 'Winter Cat Outfit',
          price: '\$28',
          imageUrl:
              'https://via.placeholder.com/150/32CD32/FFFFFF?text=Product+3',
          detailUrl: 'https://example.com/product3',
        ),
        ProductRecommendation(
          id: '4',
          name: 'Premium Cat Dress',
          price: '\$35',
          imageUrl:
              'https://via.placeholder.com/150/FFD700/FFFFFF?text=Product+4',
          detailUrl: 'https://example.com/product4',
        ),
      ];
    });
  }

// เพิ่ม method แสดง Dialog
  void _showProductDialog(
      BuildContext context, ProductRecommendation product, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxWidth: 400, minWidth: 320),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(width: 32),
                    Text(
                      'Added to Favorites',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close,
                          color: isDark ? Colors.white70 : Colors.black54,
                          size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                // รูปภาพ
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          product.imageUrl,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(Icons.shopping_bag,
                                  size: 60,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(Icons.favorite, color: Colors.red, size: 26),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),

                // ชื่อสินค้า
                Text(
                  product.name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10),

                // ราคา
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Price: ${product.price}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // ปุ่ม
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showInfoMessage('Coming Soon!');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Buy',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showInfoMessage('Opening details...');
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          backgroundColor:
                              isDark ? Colors.grey[700] : Colors.grey[300],
                          foregroundColor:
                              isDark ? Colors.white : Colors.black87,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('More',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
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

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (photo != null) {
        setState(() {
          _selectedImage = File(photo.path);
          _detectedCat = null;
        });
        _showSuccessMessage('ถ่ายรูปสำเร็จ');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _detectedCat = null;
        });
        _showSuccessMessage('เลือกรูปภาพสำเร็จ');
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
      print('🔄 เริ่มอัปโหลดไป Cloudinary...');

      final url = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
      );

      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = cloudinaryUploadPreset;

      if (cloudinaryFolder.isNotEmpty) {
        request.fields['folder'] = cloudinaryFolder;
      }

      final file = await http.MultipartFile.fromPath('file', imageFile.path);
      request.files.add(file);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        final imageUrl = jsonMap['secure_url'];
        print('✅ อัปโหลดสำเร็จ! URL: $imageUrl');
        return imageUrl;
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading to Cloudinary: $e');
      return null;
    }
  }

  Future<CatData?> detectCatFromBackend(String imageUrl) async {
    try {
      print('🔄 กำลังส่งรูปไป Python Backend...');

      final response = await http.post(
        Uri.parse(pythonBackendUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'image_url': imageUrl}),
      );

      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['error'] != null) {
          throw Exception(jsonData['error']);
        }

        return CatData.fromJson(jsonData);
      } else {
        final errorMessage =
            jsonDecode(response.body)['error'] ?? 'Unknown error';
        throw Exception('Detection failed: $errorMessage');
      }
    } catch (e) {
      print('❌ Error detecting from backend: $e');
      rethrow;
    }
  }

  Future<void> _analyzeCat() async {
    if (_selectedImage == null) return;

    setState(() => _isProcessing = true);

    try {
      _showInfoMessage('กำลังอัปโหลดรูปภาพ...');
      final imageUrl = await _uploadToCloudinary(_selectedImage!);

      if (imageUrl == null) {
        throw Exception('ไม่สามารถอัปโหลดรูปภาพได้');
      }

      _showSuccessMessage('อัปโหลดรูปภาพสำเร็จ!');
      _showInfoMessage('กำลังวิเคราะห์ขนาดแมว...');

        await Future.delayed(Duration(seconds: 2)); // จำลองการประมวลผล
    
    final mockCatData = CatData(
      name: 'Fluffy',
      breed: 'Persian',
      age: 3,
      weight: 4.5,
      sizeCategory: 'Medium',
      chestCm: 35.0,
      neckCm: 22.0,
      bodyLengthCm: 45.0,
      confidence: 0.95,
      boundingBox: [100, 150, 300, 400],
      imageUrl: _selectedImage!.path, // ใช้รูปที่เลือก
      thumbnailUrl: null,
      detectedAt: DateTime.now(),
    );

    setState(() {
      _detectedCat = mockCatData;
      _isProcessing = false;
    });

 
      // final detectedCat = await detectCatFromBackend(imageUrl);

      // if (detectedCat == null) {
      //   throw Exception('ไม่พบแมวในภาพ');
      // }

      // setState(() {
      //   _detectedCat = detectedCat;
      //   _isProcessing = false;
      // });

      _showSuccessMessage('วิเคราะห์ขนาดแมวสำเร็จ!');
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('เกิดข้อผิดพลาดในการวิเคราะห์: $e');
    }
  }

  void _clearData() {
    setState(() {
      _selectedImage = null;
      _detectedCat = null;
    });
    _showSuccessMessage('ลบข้อมูลแล้ว');
  }

  void _showSuccessMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(message: message),
      displayDuration: Duration(seconds: 2),
    );
  }

  void _showInfoMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(message: message),
      displayDuration: Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
      displayDuration: Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'MEOW SIZE',
          style: TextStyle(
            fontFamily: "catFont",
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? Colors.black : Colors.white,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: Column(
        children: [
          // ส่วนเนื้อหาหลัก (Scrollable)
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // เงื่อนไข: ถ้ายังไม่มีรูป แสดง Placeholder
                  if (_selectedImage == null && _detectedCat == null)
                    _buildEmptyState(isDark),

                  // เงื่อนไข: ถ้ามีรูปแต่ยังไม่ได้วิเคราะห์
                  if (_selectedImage != null && _detectedCat == null)
                    _buildImageWithAnalyzeSection(isDark),

                  // เงื่อนไข: ถ้าวิเคราะห์เสร็จแล้ว แสดงข้อมูล + สินค้า
                  if (_detectedCat != null) _buildResultSection(isDark),
                ],
              ),
            ),
          ),

          // ส่วนล่าง: ปุ่มถ่ายรูป/เลือกรูป (Fixed)
          _buildBottomButtons(isDark),
        ],
      ),
    );
  }

  // ส่วนที่ 2

  /// 1️⃣ หน้าจอเปล่า (Default - ยังไม่มีรูป)
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(height: 150),
          Container(
            height: 250,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.pets,
                  size: 80,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'ไม่พบข้อมูล',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ขนาดรูป 1280×720 ขนาดไฟล์ 200-500 KB',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[500] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2️⃣ แสดงรูปที่เลือก + ปุ่มวิเคราะห์และยกเลิก
  Widget _buildImageWithAnalyzeSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // รูปภาพใหญ่
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          SizedBox(height: 20),

          // Card ข้อมูล (ตอนยังไม่วิเคราะห์)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                // รูปย่อ
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_selectedImage!, fit: BoxFit.cover),
                  ),
                ),

                SizedBox(width: 16),

                // ข้อมูล N/A
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name:', 'N/A', isDark),
                      SizedBox(height: 10),
                      _buildInfoRow('Age:', 'N/A', isDark),
                      SizedBox(height: 10),
                      _buildInfoRow('Breed:', 'N/A', isDark),
                      SizedBox(height: 10),
                      _buildInfoRow('Size:', 'N/A', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ข้อความแจ้งเตือน
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.orange[300] : Colors.orange[700],
                  size: 20,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // ปุ่มวิเคราะห์และยกเลิก
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _analyzeCat,
                  icon: _isProcessing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(Icons.analytics),
                  label: Text(
                    _isProcessing ? 'กำลังวิเคราะห์...' : 'วิเคราะห์ข้อมูล',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _clearData,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Icon(Icons.close, size: 24),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3️⃣ แสดงผลลัพธ์การวิเคราะห์ + สินค้าแนะนำ
  Widget _buildResultSection(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card ข้อมูลแมว (มีข้อมูลจริง)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // รูปย่อ
                Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.grey[600]! : Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _detectedCat?.imageUrl != null
                        ? Image.network(
                            _detectedCat!.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                child: Icon(
                                  Icons.broken_image,
                                  size: 40,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              );
                            },
                          )
                        : Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(
                              Icons.pets,
                              size: 40,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400],
                            ),
                          ),
                  ),
                ),

                SizedBox(width: 16),

                // ข้อมูลแมว
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          'Name:', _detectedCat?.name ?? 'N/A', isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                        'Age:',
                        _detectedCat?.age != null
                            ? '${_detectedCat!.age} years'
                            : 'N/A',
                        isDark,
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          'Breed:', _detectedCat?.breed ?? 'N/A', isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          'Size:', _detectedCat?.sizeCategory ?? 'N/A', isDark),
                    ],
                  ),
                ),

                // ปุ่มแก้ไข
                IconButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true, // สำคัญมาก
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) {
                        return Container(
                          height: MediaQuery.of(context).size.height *
                              0.5, // ครึ่งจอ
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ขีดเล็ก ๆ ด้านบน (สาย UX)
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  margin: EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade400,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),

                              Text(
                                'แก้ไขข้อมูล',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              SizedBox(height: 16),

                              // เนื้อหาด้านใน
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Age',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Breed',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                decoration: InputDecoration(
                                  labelText: 'Size',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              Spacer(),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text('บันทึก'),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  icon: Icon(
                    Icons.mode_edit_outline_outlined,
                    color: Colors.blue.shade700,
                    size: 28,
                  ),
                  tooltip: 'แก้ไขข้อมูล',
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // หัวข้อสินค้าแนะนำ
          Text(
            'สินค้าแนะนำ',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),

          SizedBox(height: 12),

          // รายการสินค้า (Horizontal Scroll)
          Container(
            height: 450,
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Center(
              child: GridView.builder(
                shrinkWrap: true, // สำคัญมาก
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: _recommendedProducts.length,
                itemBuilder: (context, index) {
                  final product = _recommendedProducts[index];
                  return _buildProductCard(product, index, isDark);
                },
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Widget แสดงข้อมูล (Row)
  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ),
      ],
    );
  }

  /// Card สินค้า
  Widget _buildProductCard(
      ProductRecommendation product, int index, bool isDark) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFav = favoriteProvider.isFavorite(product.id);

        return Container(
          width: 160,
          margin: EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        product.imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(Icons.shopping_bag,
                                size: 40,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400]),
                          );
                        },
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () {
                        favoriteProvider.toggleFavorite(product);

                        // ⭐ แสดง Dialog เมื่อเพิ่มเข้า Favorite
                        if (!isFav) {
                          _showProductDialog(context, product, isDark);
                        } else {
                          _showSuccessMessage('ลบออกจากรายการโปรด');
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          color: isFav ? Colors.red : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // ข้อมูลสินค้า
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Price: ${product.price}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.orange[300] : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showInfoMessage('Coming Soon!'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text('Buy', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () =>
                              _showInfoMessage('Opening details...'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            backgroundColor:
                                isDark ? Colors.grey[700] : Colors.grey[300],
                            foregroundColor:
                                isDark ? Colors.white : Colors.black87,
                            minimumSize: Size(0, 28),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text('More', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 4️⃣ ปุ่มด้านล่าง (ถ่ายรูป/เลือกรูป)
  Widget _buildBottomButtons(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'โปรดถ่ายรูปแมวของคุณโดยให้เห็นลักษณะร่างกายชัดเจน เพื่อการวิเคราะห์ขนาดที่แม่นยำ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _takePicture,
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      'ถ่ายรูป',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: Icon(Icons.photo_library),
                    label: Text(
                      'เลือกรูป',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
  }
}
