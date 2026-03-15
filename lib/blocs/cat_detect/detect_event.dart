part of 'detect_bloc.dart';

abstract class DetectCatEvent {}

/// ส่ง File มา → bloc จะ base64 แล้ว POST ไปหลังบ้าน
class DetectCatStarted extends DetectCatEvent {
  final File imageFile;
  DetectCatStarted(this.imageFile);
}

/// Reset กลับ initial
class DetectCatReset extends DetectCatEvent {}