part of 'analysis_bloc.dart';

abstract class CatAnalysisState {}

class CatAnalysisInitial extends CatAnalysisState {}

class CatImageReady extends CatAnalysisState {
  final dynamic imageFile; // ✅
  CatImageReady(this.imageFile);
}

class CatAnalysisUploading extends CatAnalysisState {
  final dynamic imageFile; // ✅
  CatAnalysisUploading(this.imageFile);
}

class CatAnalysisAnalyzing extends CatAnalysisState {
  final dynamic imageFile; // ✅
  CatAnalysisAnalyzing(this.imageFile);
}

class CatAnalysisSuccess extends CatAnalysisState {
  final CatData catData;
  final List<Map<String, dynamic>> recommendations;
  CatAnalysisSuccess(this.catData, {this.recommendations = const []});
}

class CatAnalysisNotFound extends CatAnalysisState {
  final String message;
  CatAnalysisNotFound(this.message);
}

class CatAnalysisQuotaExceeded extends CatAnalysisState {}

class CatAnalysisFailure extends CatAnalysisState {
  final String error;
  CatAnalysisFailure(this.error);
}

class CatDataUpdating extends CatAnalysisState {
  final CatData catData;
  final List<Map<String, dynamic>> recommendations;
  CatDataUpdating(this.catData, {this.recommendations = const []});
}

class CatDataUpdateSuccess extends CatAnalysisState {
  final CatData catData;
  final String message;
  final List<Map<String, dynamic>> recommendations;
  CatDataUpdateSuccess(this.catData, this.message,
      {this.recommendations = const []});
}