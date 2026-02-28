import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';

part 'basket_event.dart';
part 'basket_state.dart';

class BasketBloc extends Bloc<BasketEvent, BasketState> {
  final BasketApiService _basketApi;

  BasketBloc({BasketApiService? basketApi})
      : _basketApi = basketApi ?? BasketApiService(),
        super(const BasketInitial()) {
    on<BasketLoadRequested>(_onLoadRequested);
    on<BasketQuantityUpdateRequested>(_onQuantityUpdateRequested);
    on<BasketItemRemoveRequested>(_onItemRemoveRequested);
    on<BasketClearRequested>(_onClearRequested);
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    BasketLoadRequested event,
    Emitter<BasketState> emit,
  ) async {
    emit(const BasketLoading());
    try {
      final result = await _basketApi.getBasket();
      emit(BasketLoaded(
        items: result['items'] as List<BasketItem>,
        summary: result['summary'] as BasketSummary?,
      ));
    } catch (e) {
      emit(BasketFailure('load_failed:$e'));
    }
  }

  // ── Update Quantity ────────────────────────────────────────────────────────
  Future<void> _onQuantityUpdateRequested(
    BasketQuantityUpdateRequested event,
    Emitter<BasketState> emit,
  ) async {
    final (items, summary) = _currentData;
    emit(BasketActionInProgress(items: items, summary: summary));

    try {
      await _basketApi.updateQuantity(
        clothingUuid: event.clothingUuid,
        quantity: event.newQuantity,
      );
      final result = await _basketApi.getBasket();
      emit(BasketActionSuccess(
        items: result['items'] as List<BasketItem>,
        summary: result['summary'] as BasketSummary?,
        actionType: BasketActionType.updateQuantity,
        message: 'quantity_updated',
      ));
    } catch (e) {
      emit(BasketActionFailure(
        items: items,
        summary: summary,
        message: 'quantity_failed:$e',
      ));
    }
  }

  // ── Remove Item ────────────────────────────────────────────────────────────
  Future<void> _onItemRemoveRequested(
    BasketItemRemoveRequested event,
    Emitter<BasketState> emit,
  ) async {
    final (items, summary) = _currentData;
    emit(BasketActionInProgress(items: items, summary: summary));

    try {
      await _basketApi.removeFromBasket(clothingUuid: event.clothingUuid);
      final result = await _basketApi.getBasket();
      emit(BasketActionSuccess(
        items: result['items'] as List<BasketItem>,
        summary: result['summary'] as BasketSummary?,
        actionType: BasketActionType.removeItem,
        message: 'item_removed',
      ));
    } catch (e) {
      emit(BasketActionFailure(
        items: items,
        summary: summary,
        message: 'remove_failed:$e',
      ));
    }
  }

  // ── Clear Basket ───────────────────────────────────────────────────────────
  Future<void> _onClearRequested(
    BasketClearRequested event,
    Emitter<BasketState> emit,
  ) async {
    final (items, summary) = _currentData;
    emit(BasketActionInProgress(items: items, summary: summary));

    try {
      await _basketApi.clearBasket();
      emit(const BasketActionSuccess(
        items: [],
        summary: null,
        actionType: BasketActionType.clearBasket,
        message: 'basket_cleared',
      ));
    } catch (e) {
      emit(BasketActionFailure(
        items: items,
        summary: summary,
        message: 'clear_failed:$e',
      ));
    }
  }

  // ── Helper ─────────────────────────────────────────────────────────────────
  (List<BasketItem>, BasketSummary?) get _currentData {
    final s = state;
    if (s is BasketLoaded) return (s.items, s.summary);
    if (s is BasketActionInProgress) return (s.items, s.summary);
    if (s is BasketActionSuccess) return (s.items, s.summary);
    if (s is BasketActionFailure) return (s.items, s.summary);
    return ([], null);
  }

  
}