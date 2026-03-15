part of 'history_bloc.dart';

abstract class CatHistoryState extends Equatable {
  const CatHistoryState();

  @override
  List<Object?> get props => [];
}

/// กำลังโหลดครั้งแรก
class CatHistoryInitial extends CatHistoryState {
  const CatHistoryInitial();
}

/// กำลังโหลดข้อมูล
class CatHistoryLoading extends CatHistoryState {
  const CatHistoryLoading();
}

/// โหลดสำเร็จ
class CatHistoryLoaded extends CatHistoryState {
  final List<CatRecord> cats;

  const CatHistoryLoaded(this.cats);

  /// คัดลอก state พร้อมแก้รายการ (ใช้ตอน update/delete แบบ optimistic)
  CatHistoryLoaded copyWith({List<CatRecord>? cats}) =>
      CatHistoryLoaded(cats ?? this.cats);

  @override
  List<Object?> get props => [cats];
}

/// โหลดล้มเหลว
class CatHistoryFailure extends CatHistoryState {
  final String message;
  const CatHistoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// กำลังประมวลผล action (delete / update) — แสดง loading overlay บน list เดิม
class CatHistoryActionInProgress extends CatHistoryState {
  final List<CatRecord> cats;
  const CatHistoryActionInProgress(this.cats);

  @override
  List<Object?> get props => [cats];
}

/// action สำเร็จ — ถือ message + รายการล่าสุด
class CatHistoryActionSuccess extends CatHistoryState {
  final List<CatRecord> cats;
  final String message;

  const CatHistoryActionSuccess({required this.cats, required this.message});

  @override
  List<Object?> get props => [cats, message];
}

/// action ล้มเหลว — ถือ error + รายการเดิม (UI กลับแสดงได้)
class CatHistoryActionFailure extends CatHistoryState {
  final List<CatRecord> cats;
  final String message;

  const CatHistoryActionFailure({required this.cats, required this.message});

  @override
  List<Object?> get props => [cats, message];
}