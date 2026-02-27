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

// สำเร็จ
class CatAnalysisSuccess extends CatAnalysisState {
  final CatData catData;
  CatAnalysisSuccess(this.catData);
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
  CatDataUpdating(this.catData);
}

// update/delete สำเร็จ
class CatDataUpdateSuccess extends CatAnalysisState {
  final CatData catData;
  final String message;
  CatDataUpdateSuccess(this.catData, this.message);
}