import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/api/service_cat_api.dart';

part 'history_event.dart';
part 'history_state.dart';

class CatHistoryBloc extends Bloc<CatHistoryEvent, CatHistoryState> {
  final CatApiService _catApi;

  CatHistoryBloc({CatApiService? catApi})
      : _catApi = catApi ?? CatApiService(),
        super(const CatHistoryInitial()) {
    on<CatHistoryLoadRequested>(_onLoadRequested);
    on<CatHistoryDeleteRequested>(_onDeleteRequested);
    on<CatHistoryUpdateRequested>(_onUpdateRequested);
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    CatHistoryLoadRequested event,
    Emitter<CatHistoryState> emit,
  ) async {
    emit(const CatHistoryLoading());
    try {
      final cats = await _catApi.getUserCats();
      emit(CatHistoryLoaded(cats));
    } catch (e) {
      emit(CatHistoryFailure(_cleanError(e)));
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────
  Future<void> _onDeleteRequested(
    CatHistoryDeleteRequested event,
    Emitter<CatHistoryState> emit,
  ) async {
    final currentCats = _currentCats;
    emit(CatHistoryActionInProgress(currentCats));

    try {
      await _catApi.deleteCat(event.cat.id);
      final updated = currentCats.where((c) => c.id != event.cat.id).toList();
      emit(CatHistoryActionSuccess(
        cats: updated,
        message: 'ลบข้อมูลแมวแล้ว',
      ));
    } catch (e) {
      emit(CatHistoryActionFailure(
        cats: currentCats,
        message: _cleanError(e),
      ));
    }
  }

  // ── Update ─────────────────────────────────────────────────────────────────
  Future<void> _onUpdateRequested(
    CatHistoryUpdateRequested event,
    Emitter<CatHistoryState> emit,
  ) async {
    final currentCats = _currentCats;
    emit(CatHistoryActionInProgress(currentCats));

    try {
      final updated = await _catApi.updateCat(event.catId, event.updateData);
      final newList = currentCats
          .map((c) => c.id == event.catId ? updated : c)
          .toList();
      emit(CatHistoryActionSuccess(
        cats: newList,
        message: 'บันทึกข้อมูลแมวแล้ว ✅',
      ));
    } catch (e) {
      emit(CatHistoryActionFailure(
        cats: currentCats,
        message: _cleanError(e),
      ));
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// ดึง cats จาก state ปัจจุบัน (รองรับทุก state ที่มี list)
  List<CatRecord> get _currentCats {
    final s = state;
    if (s is CatHistoryLoaded) return s.cats;
    if (s is CatHistoryActionInProgress) return s.cats;
    if (s is CatHistoryActionSuccess) return s.cats;
    if (s is CatHistoryActionFailure) return s.cats;
    return [];
  }

  String _cleanError(Object e) =>
      e.toString().replaceAll('Exception: ', '');
}