part of 'analysis_bloc.dart';

abstract class CatAnalysisEvent {}

// ถ่ายรูปหรือเลือกรูปสำเร็จ → พร้อมวิเคราะห์
class CatImageSelected extends CatAnalysisEvent {
  final File imageFile;
  CatImageSelected(this.imageFile);
}

// กดปุ่ม Analyze
class CatAnalysisStarted extends CatAnalysisEvent {}

// กดปุ่ม X / ล้างข้อมูล
class CatAnalysisReset extends CatAnalysisEvent {}

// แก้ไขข้อมูลแมว
class CatDataUpdated extends CatAnalysisEvent {
  final Map<String, dynamic> updateData;
  CatDataUpdated(this.updateData);
}

// ลบข้อมูลแมว
class CatDataDeleted extends CatAnalysisEvent {}


class CatPreloadSuccess extends CatAnalysisEvent {
  final int catId;
  CatPreloadSuccess({required this.catId});
}