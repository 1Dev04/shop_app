part of 'analysis_bloc.dart';

abstract class CatAnalysisEvent {}

class CatImageSelected extends CatAnalysisEvent {
  final dynamic imageFile; // ✅ dynamic รองรับทั้ง File และ XFile
  CatImageSelected(this.imageFile);
}

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