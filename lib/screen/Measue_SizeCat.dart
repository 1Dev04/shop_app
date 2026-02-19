import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
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

// ✅ ML Kit
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

Future<String?> _getFirebaseToken() async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return await user.getIdToken();
  } catch (e) {
    return null;
  }
}

String getBaseUrl() {
  const String env = String.fromEnvironment('ENV', defaultValue: 'local');
  if (env == 'prod') return 'https://catshop-backend-9pzq.onrender.com';
  if (env == 'prod-v2') return 'https://catshop-backend-v2.onrender.com';
  if (kIsWeb) return 'http://localhost:10000';
  if (Platform.isAndroid) return 'http://10.0.2.2:10000';
  return 'http://localhost:10000';
}

// ✅ วาดวงกลม รับสีจากภายนอก
class _CircleHolePainter extends CustomPainter {
  final Color circleColor;

  _CircleHolePainter({this.circleColor = Colors.white});

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

    // ✅ สีวงเปลี่ยนได้ตามสถานะ
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = circleColor,
    );
  }

  @override
  bool shouldRepaint(covariant _CircleHolePainter old) =>
      old.circleColor != circleColor;
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

class MeasureSizeCat extends StatefulWidget {
  const MeasureSizeCat({super.key});

  @override
  State<MeasureSizeCat> createState() => _MeasureSizeCatState();
}

class _MeasureSizeCatState extends State<MeasureSizeCat> {
  final ImagePicker _picker = ImagePicker();
  final FavouriteApiService _favouriteApi = FavouriteApiService();
  final BasketApiService _basketApi = BasketApiService();

  File? _selectedImage;
  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressLabel = 'Please wait...';

  CatData? _analysisCat;
  List<Map<String, dynamic>> _recommendedProducts = [];

  CameraController? _cameraController;
  Timer? _detectTimer;

  // ✅ ML Kit Image Labeler
  late ImageLabeler _imageLabeler;

  // ✅ state สีวงกลม: null=ขาว, true=เขียว, false=แดง
  bool? _isCatDetected;

  // ✅ ป้องกัน detect ซ้อน
  bool _isDetecting = false;

  static const String cloudinaryCloudName = 'dag73dhpl';
  static const String cloudinaryUploadPreset = 'cat_img_detect';
  static const String cloudinaryFolder = 'Fetch_Img_SizeCat';

  // ✅ label ที่ ML Kit จะบอกว่าเป็นแมว
  static const List<String> _catLabels = [
    'cat',
    'tabby',
    'kitten',
    'persian cat',
    'siamese cat',
    'british shorthair',
    'maine coon',
    'bengal cat',
    'ragdoll',
    'feline',
  ];

  String get pythonBackendAnalysis => '${getBaseUrl()}/api/vision/analyze-cat';

  // ✅ คืนสีวงตามสถานะ
  Color get _circleColor {
    if (_isCatDetected == null) return Colors.white;
    return _isCatDetected! ? Colors.green : Colors.red;
  }

  @override
  void initState() {
    super.initState();
    _loadRecommendedProducts();
    _initMLKit();
    _initCamera();
  }

  @override
  void dispose() {
    _detectTimer?.cancel();
    _cameraController?.dispose();
    _imageLabeler.close();
    super.dispose();
  }

  // ✅ STEP 1: เริ่มต้น ML Kit
  void _initMLKit() {
    final options = ImageLabelerOptions(confidenceThreshold: 0.55);
    _imageLabeler = ImageLabeler(options: options);
    print('✅ ML Kit ImageLabeler initialized');
  }

  // ✅ STEP 2: ตรวจแมวด้วย ML Kit (เร็วมาก ~50-150ms)
  static const List<String> _dogLabels = [
    'dog',
    'puppy',
    'canine',
    'hound',
    'labrador',
    'poodle',
    'bulldog',
    'beagle',
    'husky',
    'golden retriever',
    'german shepherd',
    'dachshund',
    'chihuahua',
    'pomeranian',
    'corgi',
    'shih tzu',
  ];

  Future<bool> _detectCatWithMLKit(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final labels = await _imageLabeler.processImage(inputImage);

      bool foundCat = false;

      for (final label in labels) {
        final labelText = label.label.toLowerCase();
        final confidence = label.confidence;

        print(
            '🔍 ML Kit: "$labelText" confidence=${confidence.toStringAsFixed(2)}');

        // ✅ เจอหมาก่อน → false ทันที ไม่ต้องเช็คต่อ
        for (final dogLabel in _dogLabels) {
          if (labelText.contains(dogLabel) && confidence >= 0.4) {
            print('🐶 พบหมา! reject ทันที label="$labelText"');
            return false;
          }
        }

        // เช็คแมว
        for (final catLabel in _catLabels) {
          if (labelText.contains(catLabel) && confidence >= 0.55) {
            print('🐱 พบแมว! label="$labelText" confidence=$confidence');
            foundCat = true;
          }
        }
      }

      return foundCat;
    } catch (e) {
      print('❌ ML Kit error: $e');
      return false;
    }
  }

  void _initCamera() async {
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
        _startLiveDetect(); // ✅ เริ่ม live detect
      }
    } catch (e) {
      print('❌ Camera error: $e');
      _showError('เปิดกล้องไม่สำเร็จ: $e');
    }
  }

  // ✅ STEP 3: Live detect ทุก 500ms ด้วย ML Kit
  void _startLiveDetect() {
    _detectTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted) return;
      if (_cameraController == null) return;
      if (!_cameraController!.value.isInitialized) return;
      if (_isDetecting || _isProcessing) return;

      _isDetecting = true;

      try {
        // ถ่ายภาพชั่วคราว
        final XFile photo = await _cameraController!.takePicture();

        // ตรวจแมวด้วย ML Kit
        final isCat = await _detectCatWithMLKit(photo.path);

        // ลบไฟล์ชั่วคราว
        try {
          await File(photo.path).delete();
        } catch (_) {}

        if (mounted) {
          setState(() => _isCatDetected = isCat);
        }
      } catch (e) {
        // กล้องยุ่งอยู่ ข้ามรอบนี้ไป
      } finally {
        _isDetecting = false;
      }
    });
  }

  void _loadRecommendedProducts() {
    setState(() {
      _recommendedProducts = [
        {
          'id': '1',
          'name': 'Cat Clothing Set A',
          'price': '\$25',
          'imageUrl':
              'https://via.placeholder.com/150/FF6347/FFFFFF?text=Product+1',
        },
        {
          'id': '2',
          'name': 'Cute Cat Sweater',
          'price': '\$30',
          'imageUrl':
              'https://via.placeholder.com/150/4682B4/FFFFFF?text=Product+2',
        },
        {
          'id': '3',
          'name': 'Winter Cat Outfit',
          'price': '\$28',
          'imageUrl':
              'https://via.placeholder.com/150/32CD32/FFFFFF?text=Product+3',
        },
        {
          'id': '4',
          'name': 'Premium Cat Dress',
          'price': '\$35',
          'imageUrl':
              'https://via.placeholder.com/150/FFD700/FFFFFF?text=Product+4',
        },
      ];
    });
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
        // ✅ ตรวจด้วย ML Kit ก่อน
        setState(() {
          _isProcessing = true;
          _progressLabel = 'กำลังตรวจสอบภาพ...';
          _progress = 0.2;
        });

        final isCat = await _detectCatWithMLKit(image.path);

        setState(() => _isCatDetected = isCat);

        if (!isCat) {
          setState(() => _isProcessing = false);
          _showError('😿 ไม่พบแมวในภาพที่เลือก กรุณาเลือกรูปแมว');

          // วงแดง 2 วิ แล้วกลับขาว
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) setState(() => _isCatDetected = null);
          return;
        }

        File imageFile = File(image.path);
        final processedImage =
            await _validateAndCompressGalleryImage(imageFile);

        if (processedImage != null) {
          _detectTimer?.cancel();
          await _cameraController?.dispose();
          _cameraController = null;

          setState(() {
            _selectedImage = processedImage;
            _analysisCat = null;
            _isProcessing = false;
          });

          _showSuccessMessage('พบแมว! เลือกรูปภาพสำเร็จ 🐱');
        } else {
          setState(() => _isProcessing = false);
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
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

      final maxSize = 1024;
      if (image.width > maxSize || image.height > maxSize) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxSize : null,
          height: image.height > image.width ? maxSize : null,
        );
      }

      final compressedBytes = img.encodeJpg(image, quality: 70);

      if (compressedBytes.length > 500 * 1024) {
        _showError(
            'รูปใหญ่เกินไป (${(compressedBytes.length / 1024).toStringAsFixed(0)} KB)');
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/cat_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(compressedBytes);

      return tempFile;
    } catch (e) {
      _showError('ไม่สามารถประมวลผลรูปได้: $e');
      return null;
    }
  }

  Future<String?> _uploadToCloudinary(File imageFile) async {
    try {
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
        return jsonMap['secure_url'];
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Cloudinary error: $e');
      return null;
    }
  }

  Future<void> _analyzeCat() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
      _progress = 0.1;
      _progressLabel = 'Uploading image...';
    });

    try {
      final token = await _getFirebaseToken();

      if (token == null || token.isEmpty) {
        setState(() => _isProcessing = false);
        _showError('กรุณาเข้าสู่ระบบก่อนใช้งาน');
        return;
      }

      final imageUrl = await _uploadToCloudinary(_selectedImage!);

      if (imageUrl == null) throw Exception('Upload failed');

      setState(() {
        _progress = 0.4;
        _progressLabel = 'Detecting cat...';
      });

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
        const Duration(seconds: 60),
        onTimeout: () {
          throw TimeoutException('Backend ใช้เวลานานเกินไป (> 60 วินาที)');
        },
      );

      final decodedBody = utf8.decode(response.bodyBytes);

      if (response.statusCode == 401) {
        throw Exception('Session หมดอายุ กรุณาเข้าสู่ระบบใหม่');
      }

      if (response.statusCode == 500) {
        try {
          final errorData = jsonDecode(decodedBody);
          final errorMsg = errorData['message'] ??
              errorData['detail'] ??
              errorData['error'] ??
              'Internal Server Error';
          throw Exception('Backend Error:\n$errorMsg');
        } catch (e) {
          if (e.toString().contains('Backend Error:')) rethrow;
          throw Exception('Backend Error 500');
        }
      }

      if (response.statusCode != 200) {
        try {
          final errorData = jsonDecode(decodedBody);
          final errorMsg =
              errorData['message'] ?? errorData['detail'] ?? 'Unknown error';
          throw Exception('HTTP ${response.statusCode}:\n$errorMsg');
        } catch (e) {
          if (e.toString().contains('HTTP ${response.statusCode}:')) rethrow;
          throw Exception('HTTP Error ${response.statusCode}');
        }
      }

      final jsonData = jsonDecode(decodedBody);

      if (jsonData['is_cat'] != true) {
        setState(() {
          _progress = 1.0;
          _isProcessing = false;
        });
        _showError('😿 ${jsonData['message'] ?? 'ไม่พบแมวในภาพ'}');
        return;
      }

      final catData = CatData.fromJson(jsonData);

      setState(() {
        _progress = 1.0;
        _isProcessing = false;
        _analysisCat = catData;
      });

      _showSuccessMessage('วิเคราะห์สำเร็จ 🐱');
      _loadRecommendedProducts();
    } catch (e) {
      setState(() => _isProcessing = false);

      String errorMessage = 'วิเคราะห์ไม่สำเร็จ';
      if (e.toString().contains('Backend Error')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('HTTP')) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else if (e.toString().contains('SocketException')) {
        errorMessage = 'ไม่สามารถเชื่อมต่อ Backend ได้';
      } else if (e.toString().contains('Upload failed')) {
        errorMessage = 'อัปโหลดรูปภาพไม่สำเร็จ';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      _showError(errorMessage);
    }
  }

  // ✅ STEP 4: ถ่ายรูป + ตรวจ ML Kit แล้วเปลี่ยนสีวง
  Future<void> _captureFromLiveCamera() async {
    try {
      if (_cameraController == null ||
          !_cameraController!.value.isInitialized) {
        _showError('กล้องยังไม่พร้อม');
        return;
      }

      // หยุด live detect ชั่วคราว
      _detectTimer?.cancel();
      _isDetecting = false;

      final XFile photo = await _cameraController!.takePicture();

      // ✅ ตรวจด้วย ML Kit ก่อน (เร็วมาก ไม่ต้อง upload)
      final isCat = await _detectCatWithMLKit(photo.path);

      setState(() => _isCatDetected = isCat);

      if (!isCat) {
        _showError('😿 ไม่พบแมวในภาพ ลองถ่ายใหม่อีกครั้ง');

        // วงแดง 2 วิ แล้วกลับขาว แล้วเริ่ม live ใหม่
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          setState(() => _isCatDetected = null);
          _startLiveDetect();
        }
        return;
      }

      // ✅ พบแมว! วงเขียว แล้วค่อยไปหน้าถัดไป
      await Future.delayed(const Duration(milliseconds: 400));

      final File imageFile = File(photo.path);
      final processedImage = await _validateAndCompressGalleryImage(imageFile);

      if (processedImage != null) {
        await _cameraController?.dispose();
        _cameraController = null;

        setState(() {
          _selectedImage = processedImage;
          _analysisCat = null;
        });

        _showSuccessMessage('พบแมว! ถ่ายรูปสำเร็จ 🐱');
      } else {
        // compress ไม่สำเร็จ กลับไป live
        setState(() => _isCatDetected = null);
        _startLiveDetect();
      }
    } catch (e) {
      setState(() => _isCatDetected = null);
      _showError('ถ่ายรูปไม่สำเร็จ: $e');
      _startLiveDetect();
    }
  }

  void _clearData() {
    setState(() {
      _selectedImage = null;
      _analysisCat = null;
      _isCatDetected = null;
    });
    _showSuccessMessage('ลบข้อมูลแล้ว');
    _initCamera();
  }

  void _showSuccessMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.success(message: message),
      displayDuration: const Duration(seconds: 2),
    );
  }

  void _showInfoMessage(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.info(message: message),
      displayDuration: const Duration(seconds: 2),
    );
  }

  void _showError(String message) {
    showTopSnackBar(
      Overlay.of(context),
      CustomSnackBar.error(message: message),
      displayDuration: const Duration(seconds: 3),
    );
  }

  // ✅ ส่งสีวงเข้า painter
  Widget _buildCircularOverlay() {
    return CustomPaint(
      painter: _CircleHolePainter(circleColor: _circleColor),
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
        CameraPreview(_cameraController!),
        _buildCircularOverlay(),

        // ✅ แสดง label สถานะ บนกล้อง
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _isCatDetected == null
                    ? Colors.black45
                    : _isCatDetected!
                        ? Colors.green.withOpacity(0.8)
                        : Colors.red.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _isCatDetected == null
                    ? '🔍 กำลังมองหาแมว...'
                    : _isCatDetected!
                        ? '🐱 พบแมวแล้ว! กดถ่ายรูปได้เลย'
                        : '❌ ไม่พบแมว ปรับมุมกล้องใหม่',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
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
                        valueColor: const AlwaysStoppedAnimation(Colors.orange),
                      );
                    },
                  ),
                ),
                Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10)
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
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              _progressLabel,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
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
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: (_selectedImage == null && _analysisCat == null)
                      ? const NeverScrollableScrollPhysics()
                      : const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      if (_selectedImage == null && _analysisCat == null)
                        SizedBox(
                          height: 678,
                          child: _buildCameraPreview(),
                        ),
                      if (_selectedImage != null && _analysisCat == null)
                        _buildImageWithAnalyzeSection(isDark),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
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
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
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
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Cat color:', th: 'สีแมว:'),
                          'N/A',
                          isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                          'N/A',
                          isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Breed:', th: 'พันธุ์:'),
                          'N/A',
                          isDark),
                      const SizedBox(height: 10),
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: isDark ? Colors.orange[300] : Colors.orange[700],
                    size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    languageProvider.translate(
                        en: 'Please ensure that the cats shape is clearly visible for accurate measurement.',
                        th: 'โปรดมั่นใจว่ามองเห็นรูปร่างของแมวชัดเจน เพื่อความแม่นยำในการวัดขนาด'),
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _analyzeCat,
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
                      : const Icon(Icons.analytics),
                  label: Text(
                    _isProcessing
                        ? languageProvider.translate(
                            en: 'Processing...', th: 'กำลังวิเคราะห์...')
                        : languageProvider.translate(
                            en: 'Analyze Data', th: 'วิเคราะห์ข้อมูล'),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _clearData,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.close, size: 24),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
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
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[200],
                              child: Icon(Icons.broken_image,
                                  size: 40,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400]),
                            ),
                          )
                        : Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: Icon(Icons.pets,
                                size: 40,
                                color: isDark
                                    ? Colors.grey[600]
                                    : Colors.grey[400]),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Cat Color:', th: 'สีแมว:'),
                          _analysisCat?.name ?? 'N/A',
                          isDark),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                        languageProvider.translate(en: 'Age:', th: 'อายุ:'),
                        _analysisCat?.age != null
                            ? '${_analysisCat!.age} years'
                            : 'N/A',
                        isDark,
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(
                          languageProvider.translate(
                              en: 'Breed:', th: 'พันธุ์:'),
                          _analysisCat?.breed ?? 'N/A',
                          isDark),
                      const SizedBox(height: 10),
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
                          shape: const RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.vertical(top: Radius.circular(20)),
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
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade400,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    languageProvider.translate(
                                        en: 'Edit Data', th: 'แก้ไขข้อมูล'),
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                      decoration: InputDecoration(
                                          labelText: languageProvider.translate(
                                              en: 'Cat Color', th: 'สีแมว'),
                                          border: const OutlineInputBorder())),
                                  const SizedBox(height: 8),
                                  TextField(
                                      decoration: InputDecoration(
                                          labelText: languageProvider.translate(
                                              en: 'Age', th: 'อายุ'),
                                          border: const OutlineInputBorder())),
                                  const SizedBox(height: 8),
                                  TextField(
                                      decoration: InputDecoration(
                                          labelText: languageProvider.translate(
                                              en: 'Breed', th: 'พันธุ์'),
                                          border: const OutlineInputBorder())),
                                  const SizedBox(height: 8),
                                  TextField(
                                      decoration: InputDecoration(
                                          labelText: languageProvider.translate(
                                              en: 'Size', th: 'ขนาด'),
                                          border: const OutlineInputBorder())),
                                  const Spacer(),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => Navigator.pop(context),
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
                      icon: Icon(Icons.mode_edit_outline_outlined,
                          color: Colors.blue.shade700, size: 28),
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
                                    _isCatDetected = null;
                                  });
                                  _initCamera();
                                  _showSuccessMessage(
                                      languageProvider.translate(
                                          en: 'Deleted data successfully',
                                          th: 'ลบข้อมูลแล้ว'));
                                },
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.red),
                                child: Text(languageProvider.translate(
                                    en: 'Delete', th: 'ลบ')),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red.shade600, size: 28),
                      tooltip: languageProvider.translate(
                          en: 'Delete Data', th: 'ลบข้อมูล'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            languageProvider.translate(
                en: 'Recommended Products', th: 'สินค้าแนะนำ'),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 450,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white60 : Colors.black54)),
        ),
      ],
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> product, int index, bool isDark) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return FutureBuilder<bool>(
      future: _favouriteApi.checkFavourite(clothingUuid: product['id']),
      builder: (context, snapshot) {
        final isFav = snapshot.data ?? false;

        return Container(
          width: 160,
          margin: const EdgeInsets.only(right: 12),
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
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(14)),
                      child: Image.network(
                        product['imageUrl'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(Icons.shopping_bag,
                              size: 40,
                              color:
                                  isDark ? Colors.grey[600] : Colors.grey[400]),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () async {
                        if (isFav) {
                          await _favouriteApi.removeFromFavourite(
                              clothingUuid: product['id']);
                          _showSuccessMessage(languageProvider.translate(
                              en: 'Removed from favourites',
                              th: 'ลบออกจากรายการโปรดแล้ว'));
                        } else {
                          await _favouriteApi.addToFavourite(
                              clothingUuid: product['id']);
                          _showSuccessMessage(languageProvider.translate(
                              en: 'Added to favourites!',
                              th: 'เพิ่มลงรายการโปรดแล้ว!'));
                        }
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
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
                      product['name'],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      languageProvider.translate(
                          en: 'Price: ${product['price']}',
                          th: 'ราคา: ${product['price']}'),
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark ? Colors.orange[300] : Colors.orange[700],
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _basketApi.addToBasket(
                                    clothingUuid: product['id']);
                                _showSuccessMessage(languageProvider.translate(
                                    en: 'Added to cart!',
                                    th: 'เพิ่มลงตะกร้าแล้ว!'));
                              } catch (e) {
                                _showError(languageProvider.translate(
                                    en: 'Failed to add to cart',
                                    th: 'เพิ่มลงตะกร้าไม่สำเร็จ'));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 28),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                                languageProvider.translate(
                                    en: 'Buy', th: 'ซื้อ'),
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () => _showInfoMessage(
                              languageProvider.translate(
                                  en: 'Opening details...',
                                  th: 'กำลังเปิดรายละเอียด...')),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 6, horizontal: 8),
                            backgroundColor:
                                isDark ? Colors.grey[700] : Colors.grey[300],
                            foregroundColor:
                                isDark ? Colors.white : Colors.black87,
                            minimumSize: const Size(0, 28),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                              languageProvider.translate(
                                  en: 'More', th: 'เพิ่มเติม'),
                              style: const TextStyle(fontSize: 11)),
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
      return const SizedBox.shrink();
    }
    final languageProvider = Provider.of<LanguageProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))
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
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _captureFromLiveCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                      languageProvider.translate(
                          en: 'Take Photo', th: 'ถ่ายรูป'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(
                      languageProvider.translate(
                          en: 'Choose Photo', th: 'เลือกรูป'),
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
