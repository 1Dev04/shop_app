part of 'detect_bloc.dart';

// ── Result Model ──────────────────────────────────────────────────────────────
class DetectCatResult {
  final bool   passed;
  final bool   isCat;
  final bool   isSingle;
  final bool   isRealPhoto;
  final String reason;
  final double confidence;
  final String message;

  const DetectCatResult({
    required this.passed,
    required this.isCat,
    required this.isSingle,
    required this.isRealPhoto,
    required this.reason,
    required this.confidence,
    required this.message,
  });

  factory DetectCatResult.fromJson(Map<String, dynamic> j) => DetectCatResult(
        passed:      j['passed']        as bool,
        isCat:       j['is_cat']        as bool,
        isSingle:    j['is_single']     as bool,
        isRealPhoto: j['is_real_photo'] as bool,
        reason:      j['reason']        as String,
        confidence:  (j['confidence']   as num).toDouble(),
        message:     j['message']       as String,
      );

  @override
  String toString() =>
      'DetectCatResult(passed=$passed reason=$reason conf=${confidence.toStringAsFixed(2)})';
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class DetectCatState {}

class DetectCatInitial   extends DetectCatState {}
class DetectCatLoading   extends DetectCatState {}

class DetectCatSuccess extends DetectCatState {
  final DetectCatResult result;
  DetectCatSuccess(this.result);
}

class DetectCatRejected extends DetectCatState {
  final DetectCatResult result;
  DetectCatRejected(this.result);
}

class DetectCatQuotaExceeded extends DetectCatState {}

class DetectCatFailure extends DetectCatState {
  final String error;
  DetectCatFailure(this.error);
}