part of 'history_bloc.dart';

abstract class CatHistoryEvent extends Equatable {
  const CatHistoryEvent();

  @override
  List<Object?> get props => [];
}

/// โหลดรายการแมวทั้งหมด
class CatHistoryLoadRequested extends CatHistoryEvent {
  const CatHistoryLoadRequested();
}

/// ลบแมว
class CatHistoryDeleteRequested extends CatHistoryEvent {
  final CatRecord cat;
  const CatHistoryDeleteRequested(this.cat);

  @override
  List<Object?> get props => [cat];
}

/// แก้ไขข้อมูลแมว
class CatHistoryUpdateRequested extends CatHistoryEvent {
  final int catId;
  final Map<String, dynamic> updateData;

  const CatHistoryUpdateRequested({
    required this.catId,
    required this.updateData,
  });

  @override
  List<Object?> get props => [catId, updateData];
}