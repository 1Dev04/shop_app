import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/provider/favorite_provider.dart';
import 'package:flutter_application_1/provider/language_provider.dart';

import 'dart:io';
import 'dart:async';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';
import 'package:provider/provider.dart';

import 'package:flutter_application_1/provider/theme_provider.dart';

import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

Future<String?> _getFirebaseToken() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ User not logged in');
      return null;
    }

    // ดึง ID Token จาก Firebase (จะ refresh อัตโนมัติถ้าหมดอายุ)
    final String? token = await user.getIdToken();

    print('✅ Got Firebase token: ${token?.substring(0, 20)}...');
    return token;
  } catch (e) {
    print('❌ Error getting Firebase token: $e');
    return null;
  }
}

// ฟังก์ชันสำหรับหา Base URL ที่ถูกต้องตาม Platform
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
    return 'http://localhost:8000';
  }

  if (Platform.isAndroid) {
    return 'http://10.0.2.2:8000';
  }

  return 'http://localhost:8000';
}

class _CircleHolePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.6);

    final fullPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    final holePath = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));

    final finalPath = Path.combine(
      PathOperation.difference,
      fullPath,
      holePath,
    );

    canvas.drawPath(finalPath, paint);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

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

class VisionResult {
  final bool isCat;
  final double confidence;
  final String message;

  VisionResult({
    required this.isCat,
    required this.confidence,
    required this.message,
  });

  factory VisionResult.fromJson(Map<String, dynamic> json) {
    return VisionResult(
      isCat: json['is_cat'] ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      message: json['message'] ?? '',
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
  double _progress = 0.0;
  String _progressLabel = 'Please wait...';

  CatData? _analysisCat;

  List<ProductRecommendation> _recommendedProducts = [];

  // 🎥 Camera Live Detection Variables
  CameraController? _cameraController;
  Timer? _detectTimer;

  // Cloudinary Config
  static const String cloudinaryCloudName = 'dag73dhpl';
  static const String cloudinaryUploadPreset = 'cat_img_detect';
  static const String cloudinaryFolder = 'Fetch_Img_SizeCat';

  // Python Backend URL - แก้ไขเป็น /api/vision/analyze-cat
  String get pythonBackendAnalysis => '${getBaseUrl()}/api/vision/analyze-cat';

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
    _initCamera();
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {});
        _startLiveDetect();
      }
    } catch (e) {
      print('❌ Error initializing camera: $e');
      _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
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

  // 🎥 Live Detection (mock ตอนนี้)
  void _startLiveDetect() {
    _detectTimer = Timer.periodic(
      Duration(milliseconds: 400),
      (_) async {
        if (!mounted || _cameraController == null) return;
        if (!_cameraController!.value.isInitialized) return;
        // TODO: Replace with actual backend detection
        // final catDetected = await detectCatFromLiveCamera();
      },
    );
  }

// เพิ่ม method แสดง Dialog
  void _showProductDialog(
      BuildContext context, ProductRecommendation product, bool isDark) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final languageProvider = Provider.of<LanguageProvider>(context);
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
                      languageProvider.translate(
                          en: 'Added to Favorites', th: 'เพิ่มในรายการโปรด'),
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
                    languageProvider.translate(
                        en: 'Price: ${product.price}',
                        th: 'ราคา: ${product.price}'),
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
                        child: Text(
                            languageProvider.translate(en: 'Buy', th: 'ซื้อ'),
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
                        child: Text(
                            languageProvider.translate(
                                en: 'More', th: 'เพิ่มเติม'),
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

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        File imageFile = File(image.path);
        final processedImage =
            await _validateAndCompressGalleryImage(imageFile);

        if (processedImage != null) {
          // 🔥 ปิดกล้องทันทีหลังเลือกรูป
          _detectTimer?.cancel();
          await _cameraController?.dispose();
          _cameraController = null;

          setState(() {
            _selectedImage = processedImage;
            _analysisCat = null;
          });

          _showSuccessMessage('เลือกรูปภาพสำเร็จ');
        }
      }
    } catch (e) {
      _showError('เกิดข้อผิดพลาด: $e');
    }
  }

  Future<File?> _validateAndCompressGalleryImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        _showError('รูปภาพไม่ถูกต้อง');
        return null;
      }

      // Resize to 1024x1024
      final maxSize = 1024;
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxSize : null,
          height: image.height > image.width ? maxSize : null,
        );
      }

      // Compress to JPEG (quality 70)
      final compressedBytes = img.encodeJpg(image, quality: 70);

      // Check Size (<500KB)
      if (compressedBytes.length > 500 * 1024) {
        _showError(
            'รูปใหญ่เกินไป (${(compressedBytes.length / 1024).toStringAsFixed(0)} KB)');
        return null;
      }

      // Save to Temp
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/cat_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      print(
          '✅ Gallery Image: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

      return tempFile;
    } catch (e) {
      _showError('ไม่สามารถประมวลผลรูปได้: $e');
      return null;
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
        final decodedBody = utf8.decode(response.bodyBytes);
        final jsonMap = jsonDecode(decodedBody);
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

  Future<VisionResult> analysisCatFromBackend(String imageUrl) async {
    final response = await http.post(
      Uri.parse(pythonBackendAnalysis),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'image_url': imageUrl}),
    );

    final decodedBody = utf8.decode(response.bodyBytes);
    final jsonData = jsonDecode(decodedBody);
    return VisionResult.fromJson(jsonData);
  }

  Future<void> _analyzeCat() async {
    print('\n========================================');
    print('🚀 START: _analyzeCat() called');
    print('========================================\n');

    if (_selectedImage == null) {
      print('❌ _selectedImage is null, returning...');
      return;
    }

    print('✅ _selectedImage exists: ${_selectedImage!.path}');

    setState(() {
      _isProcessing = true;
      _progress = 0.1;
      _progressLabel = 'Uploading image...';
    });

    print('📱 UI State: Processing = true, Progress = 0.1');

    try {
      // ========================================
      // STEP 1: Get Firebase Token
      // ========================================
      print('\n--- STEP 1: Getting Firebase Token ---');
      final token = await _getFirebaseToken();

      if (token == null || token.isEmpty) {
        print('❌ Firebase token is null or empty');
        setState(() => _isProcessing = false);
        _showError('กรุณาเข้าสู่ระบบก่อนใช้งาน');
        return;
      }

      print('✅ Firebase Token obtained');
      print('🔑 Token (first 30 chars): ${token.substring(0, 30)}...');
      print('🔑 Token length: ${token.length} characters');

      // ========================================
      // STEP 2: Upload to Cloudinary
      // ========================================
      print('\n--- STEP 2: Uploading to Cloudinary ---');
      final imageUrl = await _uploadToCloudinary(_selectedImage!);

      if (imageUrl == null) {
        print('❌ Cloudinary upload failed (returned null)');
        throw Exception('Upload failed');
      }

      print('✅ Cloudinary upload successful');
      print('🖼️ Image URL: $imageUrl');

      setState(() {
        _progress = 0.4;
        _progressLabel = 'Detecting cat...';
      });

      print('📱 UI State: Progress = 0.4');

// ========================================
// STEP 3: Call Backend API
// ========================================
      print('\n--- STEP 3: Calling Backend API ---');
      print('📤 Backend URL: $pythonBackendAnalysis');
      print('📤 Request Method: POST');
      print('📤 Headers:');
      print('   - Content-Type: application/json');
      print('   - Accept: application/json');
      print('   - Authorization: Bearer ${token.substring(0, 20)}...');
      print('📤 Body: {"image_url": "$imageUrl"}');

      final requestStartTime = DateTime.now();
      print('⏱️ Request started at: $requestStartTime');

// 🔥 เพิ่ม timeout 60 วินาที
      final response = await http
          .post(
        Uri.parse(pythonBackendAnalysis),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'image_url': imageUrl}),
      )
          .timeout(
        Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Backend ใช้เวลานานเกินไป (> 60 วินาที)\n\n'
              'สาเหตุที่เป็นไปได้:\n'
              '• Backend กำลังโหลด YOLO model\n'
              '• รูปภาพใหญ่เกินไป\n'
              '• Server ช้า\n\n'
              'กรุณาลองใหม่อีกครั้ง');
        },
      );

      // ========================================
      // STEP 4: Process Response
      // ========================================
      print('\n--- STEP 4: Processing Response ---');
      print('📥 HTTP Status Code: ${response.statusCode}');
      print('📥 Response Headers: ${response.headers}');

      // Decode response body
      final decodedBody = utf8.decode(response.bodyBytes);
      final bodyPreview = decodedBody.length > 500
          ? '${decodedBody.substring(0, 500)}...'
          : decodedBody;

      print('📦 Response Body (preview):');
      print(bodyPreview);
      print('📦 Response Body Length: ${decodedBody.length} characters');

      // ========================================
      // STEP 5: Check HTTP Status
      // ========================================
      print('\n--- STEP 5: Checking HTTP Status ---');

      if (response.statusCode == 401) {
        print('❌ HTTP 401: Unauthorized');
        throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }

      if (response.statusCode == 500) {
        print('❌ HTTP 500: Internal Server Error');
        print('🔍 Trying to parse error message...');

        try {
          final errorData = jsonDecode(decodedBody);
          print('✅ Successfully parsed error JSON:');
          print(errorData);

          final errorMsg = errorData['message'] ??
              errorData['detail'] ??
              errorData['error'] ??
              'Internal Server Error';

          print('❌ Backend Error Message: $errorMsg');
          throw Exception('Backend Error:\n$errorMsg');
        } catch (e) {
          if (e.toString().contains('Backend Error:')) {
            print('⚠️ Rethrowing Backend Error');
            rethrow;
          }

          print('❌ Failed to parse error JSON');
          print('📄 Raw response: $decodedBody');
          throw Exception('Backend Error 500:\n\n${bodyPreview}');
        }
      }

      if (response.statusCode != 200) {
        print('❌ HTTP ${response.statusCode}: Non-200 status');
        print('🔍 Trying to parse error message...');

        try {
          final errorData = jsonDecode(decodedBody);
          print('✅ Successfully parsed error JSON:');
          print(errorData);

          final errorMsg =
              errorData['message'] ?? errorData['detail'] ?? 'Unknown error';

          print('❌ Error Message: $errorMsg');
          throw Exception('HTTP ${response.statusCode}:\n$errorMsg');
        } catch (e) {
          if (e.toString().contains('HTTP ${response.statusCode}:')) {
            print('⚠️ Rethrowing HTTP Error');
            rethrow;
          }

          print('❌ Failed to parse error JSON');
          throw Exception('HTTP Error ${response.statusCode}:\n${bodyPreview}');
        }
      }

      // ========================================
      // STEP 6: Parse Success Response
      // ========================================
      print('\n--- STEP 6: Parsing Success Response ---');
      print('✅ HTTP 200: Success');
      print('🔍 Parsing JSON...');

      final jsonData = jsonDecode(decodedBody);
      print('✅ JSON parsed successfully');
      print('📊 Response Data:');
      print(jsonData);

      // ========================================
      // STEP 7: Check if Cat Detected
      // ========================================
      print('\n--- STEP 7: Checking Cat Detection ---');
      print('🐱 is_cat: ${jsonData['is_cat']}');

      if (jsonData['is_cat'] != true) {
        print('❌ Not a cat!');
        print('📝 Message: ${jsonData['message'] ?? 'ไม่พบแมวในภาพ'}');

        setState(() {
          _progress = 1.0;
          _isProcessing = false;
        });

        _showError('😿 ${jsonData['message'] ?? 'ไม่พบแมวในภาพ'}');
        return;
      }

      print('✅ Cat detected!');

      // ========================================
      // STEP 8: Parse Cat Data
      // ========================================
      print('\n--- STEP 8: Parsing Cat Data ---');
      print('🔍 Calling CatData.fromJson()...');

      try {
        final catData = CatData.fromJson(jsonData);
        print('✅ CatData parsed successfully:');
        print('   - Name: ${catData.name}');
        print('   - Breed: ${catData.breed}');
        print('   - Age: ${catData.age}');
        print('   - Size: ${catData.sizeCategory}');
        print('   - Confidence: ${catData.confidence}');

        setState(() {
          _progress = 1.0;
          _isProcessing = false;
          _analysisCat = catData;
        });

        print('📱 UI State: Processing = false, _analysisCat set');
        print('✅ Analysis complete!');

        _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
        _loadRecommendedProducts();

        print('\n========================================');
        print('🎉 SUCCESS: Analysis completed');
        print('========================================\n');
      } catch (e) {
        print('❌ Failed to parse CatData');
        print('❌ Error: $e');
        print('📄 JSON Data: $jsonData');
        throw Exception('Failed to parse cat data: $e');
      }
    } catch (e, stackTrace) {
      print('\n========================================');
      print('💥 ERROR OCCURRED');
      print('========================================');
      print('❌ Error Type: ${e.runtimeType}');
      print('❌ Error Message: $e');
      print('📍 Stack Trace:');
      print(stackTrace);
      print('========================================\n');

      setState(() => _isProcessing = false);

      // Format error message for user
      String errorMessage = 'วิเคราะห์ไม่สำเร็จ';

      if (e.toString().contains('Backend Error')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('HTTP')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('SocketException')) {
        errorMessage =
            'ไม่สามารถเชื่อมต่อ Backend ได้\n\nตรวจสอบ:\n• Backend ทำงานอยู่หรือไม่\n• อินเทอร์เน็ตเชื่อมต่อหรือไม่';
      } else if (e.toString().contains('Upload failed')) {
        errorMessage = 'อัปโหลดรูปภาพไม่สำเร็จ\n\nกรุณาลองอีกครั้ง';
      } else if (e.toString().contains('Failed to parse')) {
        errorMessage =
            'Backend ตอบกลับในรูปแบบที่ไม่ถูกต้อง\n\nกรุณาติดต่อผู้ดูแลระบบ';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      print('📱 Showing error to user: $errorMessage');
      _showError(errorMessage);
    }
  }

  void _clearData() {
    setState(() {
      _selectedImage = null;
      _analysisCat = null;
    });

    _showSuccessMessage('ลบข้อมูลแล้ว');

    // 🔥 เปิดกล้องใหม่
    _initCamera();
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

  // 🎥 Build Circular Overlay สำหรับ Live Detection
  Widget _buildCircularOverlay() {
    return CustomPaint(
      painter: _CircleHolePainter(),
      size: Size.infinite,
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_cameraController!), // กล้อง
        _buildCircularOverlay(), // วงกลมกลางจอ
      ],
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.white.withOpacity(0.85),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 190,
                  height: 190,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 6,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation(
                          Colors.orange,
                        ),
                      );
                    },
                  ),
                ),

                // 🔥 รูปแมวจริง
                Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: ClipOval(
                    child: _selectedImage != null
                        ? Image.file(_selectedImage!, fit: BoxFit.cover)
                        : const Icon(Icons.pets, size: 60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _progressLabel,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          languageProvider.translate(en: "MEOW SIZE", th: "วัดขนาดตัวแมว"),
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
      body: Stack(
        children: [
          Column(
            children: [
              // 🔑 Content Area
              Expanded(
                child: SingleChildScrollView(
                  physics: (_selectedImage == null && _analysisCat == null)
                      ? const NeverScrollableScrollPhysics() // 🔒 ล็อค
                      : const BouncingScrollPhysics(), // 🔓 ปลด

                  child: Column(
                    children: [
                      // หน้ากล้อง (แสดงเฉพาะตอนไม่มีรูป)
                      if (_selectedImage == null && _analysisCat == null)
                        SizedBox(
                          height: 678,
                          child: _buildCameraPreview(),
                        ),

                      // หน้าแสดงรูป + ปุ่มวิเคราะห์
                      if (_selectedImage != null && _analysisCat == null)
                        _buildImageWithAnalyzeSection(isDark),

                      // หน้าผลลัพธ์
                      if (_analysisCat != null) _buildResultSection(isDark),
                    ],
                  ),
                ),
              ),

              _buildBottomButtons(isDark),
            ],
          ),
          if (_isProcessing) _buildProcessingOverlay(),
        ],
      ),
    );
  }

  Widget _buildImageWithAnalyzeSection(bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Cat color:', th: 'สีแมว:'),
                          'N/A',
                          isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                          'N/A',
                          isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Breed:', th: 'พันธุ์:'),
                          'N/A',
                          isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(en: 'Size:', th: 'ขนาด:'),
                          'N/A',
                          isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
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
                    languageProvider.translate(
                        en: 'Please ensure that the cats shape is clearly visible for accurate measurement.',
                        th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
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
                    _isProcessing
                        ? languageProvider.translate(
                            en: 'Processing...', th: 'กำลังวิเคราะห์...')
                        : languageProvider.translate(
                            en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'),
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

  Widget _buildResultSection(bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    child: _analysisCat?.imageUrl != null
                        ? Image.network(
                            _analysisCat!.imageUrl,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Cat Color:', th: 'สีแมว:'),
                          _analysisCat?.name ?? 'N/A',
                          isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                        languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                        _analysisCat?.age != null
                            ? '${_analysisCat!.age} years'
                            : 'N/A',
                        isDark,
                      ),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Breed:', th: 'พันธุ์:'),
                          _analysisCat?.breed ?? 'N/A',
                          isDark),
                      SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(en: 'Size:', th: 'ขนาด:'),
                          _analysisCat?.sizeCategory ?? 'N/A',
                          isDark),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.5,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
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
                                    languageProvider.translate(
                                        en: 'Edit Data', th: 'แก้ไขข้อมูล'),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate(
                                          en: 'Cat Color', th: 'สีแมว'),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate(
                                          en: 'Age', th: 'อายุ'),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate(
                                          en: 'Breed', th: 'พันธุ์'),
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  TextField(
                                    decoration: InputDecoration(
                                      labelText: languageProvider.translate(
                                          en: 'Size', th: 'ขนาด'),
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
                                      child: Text(languageProvider.translate(
                                          en: 'Save', th: 'บันทึก')),
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
                      tooltip: languageProvider.translate(
                          en: 'Edit Data', th: 'แก้ไขข้อมูล'),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(languageProvider.translate(
                                en: 'Confirm Deletion', th: 'ยืนยันการลบ')),
                            content: Text(languageProvider.translate(
                                en: 'Do you want to delete this cat data?',
                                th: 'คุณต้องการลบข้อมูลแมวนี้ใช่หรือไม่?')),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(languageProvider.translate(
                                    en: 'Cancel', th: 'ยกเลิก')),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  setState(() {
                                    _analysisCat = null;
                                    _recommendedProducts = [];
                                    _selectedImage = null;
                                  });
                                  _initCamera();
                                  _showSuccessMessage(
                                      languageProvider.translate(
                                          en: 'Deleted data successfully',
                                          th: 'ลบข้อมูลแล้ว'));
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(languageProvider.translate(
                                    en: 'Delete', th: 'ลบ')),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade600,
                        size: 28,
                      ),
                      tooltip: languageProvider.translate(
                          en: 'Delete Data', th: 'ลบข้อมูล'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Text(
            languageProvider.translate(
                en: 'Recommended Products', th: 'สินค้าแนะนำ'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            height: 450,
            padding: EdgeInsets.symmetric(horizontal: 1),
            child: Center(
              child: GridView.builder(
                shrinkWrap: true,
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

  Widget _buildProductCard(
      ProductRecommendation product, int index, bool isDark) {
    return Consumer<FavoriteProvider>(
      builder: (context, favoriteProvider, child) {
        final isFav = favoriteProvider.isFavorite(product.id);
        final languageProvider = Provider.of<LanguageProvider>(context);
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

                        if (!isFav) {
                          _showProductDialog(context, product, isDark);
                        } else {
                          _showSuccessMessage(languageProvider.translate(
                              en: 'Removed from favorites',
                              th: 'ลบออกจากรายการโปรด'));
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
                      languageProvider.translate(
                          en: 'Price: ${product.price}',
                          th: 'ราคา: ${product.price}'),
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
                            onPressed: () => _showInfoMessage(
                                languageProvider.translate(
                                    en: 'Coming Soon!', th: 'เร็วๆ นี้')),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 6),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 28),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                                languageProvider.translate(
                                    en: 'Buy', th: 'ซื้อ'),
                                style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _showInfoMessage(
                              languageProvider.translate(
                                  en: 'Opening details...',
                                  th: 'กำลังเปิดรายละเอียด...')),
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
                          child: Text(
                              languageProvider.translate(
                                  en: 'More', th: 'เพิ่มเติม'),
                              style: TextStyle(fontSize: 11)),
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

  Widget _buildBottomButtons(bool isDark) {
    if (_selectedImage != null || _analysisCat != null) {
      return SizedBox.shrink();
    }
    final languageProvider = Provider.of<LanguageProvider>(context);

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
              languageProvider.translate(
                  en: 'Take a photo: Place the cat in the center of the circle and see the whole body \n Choose a photo: Use JPEG files no larger than 500KB',
                  th: 'ถ่ายรูป: วางตัวแมวให้อยู่ กลางวงกลม และเห็นทั้งตัว \n เลือกรูป: ใช้ไฟล์ JPEG ขนาดไม่เกิน 500KB'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureFromLiveCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text(
                      languageProvider.translate(
                          en: 'Take Photo', th: 'ถ่ายรูป'),
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
                      languageProvider.translate(
                          en: 'Choose Photo', th: 'เลือกรูป'),
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

  Future<void> _captureFromLiveCamera() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _showError('กล้องยังไม่พร้อม');
        return;
      }

      final XFile photo = await _cameraController!.takePicture();
      final File imageFile = File(photo.path);
      final processedImage = await _validateAndCompressGalleryImage(imageFile);

      if (processedImage != null) {
        _detectTimer?.cancel();
        await _cameraController?.dispose();
        _cameraController = null;

        setState(() {
          _selectedImage = processedImage;
          _analysisCat = null;
        });

        _showSuccessMessage('ถ่ายรูปสำเร็จ 📸');
      }
    } catch (e) {
      _showError('ถ่ายรูปไม่สำเร็จ: $e');
    }
  }
}
