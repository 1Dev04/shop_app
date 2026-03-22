part of 'detect_bloc.dart';

abstract class DetectCatEvent {}

/// ส่ง XFile มา → รองรับทั้ง Mobile และ Web
class DetectCatStarted extends DetectCatEvent {
  final dynamic imageFile; // ✅ dynamic รองรับทั้ง File (mobile) และ XFile (web)
  DetectCatStarted(this.imageFile);
}

/// Reset กลับ initial
class DetectCatReset extends DetectCatEvent {}