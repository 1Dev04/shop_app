part of 'analysis_bloc.dart';

abstract class CatAnalysisEvent {}

class CatImageSelected extends CatAnalysisEvent {
  final File imageFile;
  CatImageSelected(this.imageFile);
}

// ✅ เพิ่ม measurements — รองรับกรณี user กรอกก่อนกด Analyze
class CatAnalysisStarted extends CatAnalysisEvent {
  final Map<String, dynamic>? measurements;
  CatAnalysisStarted({this.measurements});
}

class CatAnalysisReset extends CatAnalysisEvent {}

class CatDataUpdated extends CatAnalysisEvent {
  final Map<String, dynamic> updateData;
  CatDataUpdated(this.updateData);
}

class CatDataDeleted extends CatAnalysisEvent {}

class CatPreloadSuccess extends CatAnalysisEvent {
  final int catId;
  CatPreloadSuccess({required this.catId});
}