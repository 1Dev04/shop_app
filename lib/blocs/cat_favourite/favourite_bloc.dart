import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';

part 'favourite_event.dart';
part 'favourite_state.dart';

class FavouriteBloc extends Bloc<FavouriteEvent, FavouriteState> {
  final FavouriteApiService _favApi;
  final BasketApiService _basketApi;

  FavouriteBloc({
    FavouriteApiService? favApi,
    BasketApiService? basketApi,
  })  : _favApi = favApi ?? FavouriteApiService(),
        _basketApi = basketApi ?? BasketApiService(),
        super(const FavouriteInitial()) {
    on<FavouriteLoadRequested>(_onLoadRequested);
    on<FavouriteRemoveRequested>(_onRemoveRequested);
    on<FavouriteToggleRequested>(_onToggleRequested);
    on<FavouriteAddToBasketRequested>(_onAddToBasketRequested);
  }

  // ── Load ───────────────────────────────────────────────────────────────────
  Future<void> _onLoadRequested(
    FavouriteLoadRequested event,
    Emitter<FavouriteState> emit,
  ) async {
    emit(const FavouriteLoading());
    try {
      final items = await _favApi.getFavourites();
      emit(FavouriteLoaded(items));
    } catch (e) {
      emit(FavouriteFailure('Failed to load favourites: $e'));
    }
  }

  // ── Remove (จาก list หลัก) ────────────────────────────────────────────────
  Future<void> _onRemoveRequested(
    FavouriteRemoveRequested event,
    Emitter<FavouriteState> emit,
  ) async {
    final current = _currentItems;
    emit(FavouriteActionInProgress(current));

    try {
      await _favApi.removeFromFavourite(clothingUuid: event.clothingUuid);
      final updated =
          current.where((i) => i.clothingUuid != event.clothingUuid).toList();
      emit(FavouriteActionSuccess(
        items: updated,
        actionType: FavouriteActionType.remove,
        message: 'removed',
      ));
    } catch (e) {
      emit(FavouriteActionFailure(
        items: current,
        message: 'remove_failed',
      ));
    }
  }

  // ── Toggle (หัวใจใน Detail Card) ──────────────────────────────────────────
  Future<void> _onToggleRequested(
    FavouriteToggleRequested event,
    Emitter<FavouriteState> emit,
  ) async {
    final current = _currentItems;
    emit(FavouriteActionInProgress(current));

    try {
      if (event.currentlyFavourite) {
        await _favApi.removeFromFavourite(clothingUuid: event.clothingUuid);
        final updated = current
            .where((i) => i.clothingUuid != event.clothingUuid)
            .toList();
        emit(FavouriteToggleSuccess(
          items: updated,
          isFavourite: false,
          message: 'removed',
        ));
      } else {
        await _favApi.addToFavourite(clothingUuid: event.clothingUuid);
        emit(FavouriteToggleSuccess(
          items: current,
          isFavourite: true,
          message: 'added',
        ));
      }
    } catch (e) {
      emit(FavouriteActionFailure(
        items: current,
        message: 'toggle_failed:$e',
      ));
    }
  }

  // ── Add to Basket ─────────────────────────────────────────────────────────
  Future<void> _onAddToBasketRequested(
    FavouriteAddToBasketRequested event,
    Emitter<FavouriteState> emit,
  ) async {
    final current = _currentItems;
    emit(FavouriteActionInProgress(current));

    try {
      await _basketApi.addToBasket(clothingUuid: event.clothingUuid);
      emit(FavouriteActionSuccess(
        items: current,
        actionType: FavouriteActionType.addToBasket,
        message: 'basket_added',
      ));
    } catch (e) {
      emit(FavouriteActionFailure(
        items: current,
        message: 'basket_failed:$e',
      ));
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  List<FavouriteItem> get _currentItems {
    final s = state;
    if (s is FavouriteLoaded) return s.items;
    if (s is FavouriteActionInProgress) return s.items;
    if (s is FavouriteActionSuccess) return s.items;
    if (s is FavouriteActionFailure) return s.items;
    if (s is FavouriteToggleSuccess) return s.items;
    return [];
  }


  
}

