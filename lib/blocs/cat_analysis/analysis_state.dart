part of 'analysis_bloc.dart';

abstract class CatAnalysisState {}

// หน้าแรก — แสดงกล้อง
class CatAnalysisInitial extends CatAnalysisState {}

// เลือกรูปได้แล้ว รอกด Analyze
class CatImageReady extends CatAnalysisState {
  final File imageFile;
  CatImageReady(this.imageFile);
}

// กำลัง upload
class CatAnalysisUploading extends CatAnalysisState {
  final File imageFile;
  CatAnalysisUploading(this.imageFile);
}

// กำลัง analyze
class CatAnalysisAnalyzing extends CatAnalysisState {
  final File imageFile;
  CatAnalysisAnalyzing(this.imageFile);
}

// สำเร็จ — พร้อม recommendations จาก backend
class CatAnalysisSuccess extends CatAnalysisState {
  final CatData catData;
  // ✅ recommendations มาจาก vision.py โดยตรง ไม่ต้อง call เพิ่ม
  final List<Map<String, dynamic>> recommendations;

  CatAnalysisSuccess(this.catData, {this.recommendations = const []});
}

// ไม่พบแมว
class CatAnalysisNotFound extends CatAnalysisState {
  final String message;
  CatAnalysisNotFound(this.message);
}

// Quota หมด
class CatAnalysisQuotaExceeded extends CatAnalysisState {}

// Error ทั่วไป
class CatAnalysisFailure extends CatAnalysisState {
  final String error;
  CatAnalysisFailure(this.error);
}

// กำลัง update/delete
class CatDataUpdating extends CatAnalysisState {
  final CatData catData;
  final List<Map<String, dynamic>> recommendations;
  CatDataUpdating(this.catData, {this.recommendations = const []});
}

// update/delete สำเร็จ
class CatDataUpdateSuccess extends CatAnalysisState {
  final CatData catData;
  final String message;
  final List<Map<String, dynamic>> recommendations;
  CatDataUpdateSuccess(this.catData, this.message,
      {this.recommendations = const []});
}