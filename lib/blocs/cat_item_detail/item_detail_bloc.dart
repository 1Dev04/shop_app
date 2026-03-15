// lib/blocs/item_detail/item_detail_bloc.dart

import 'package:equatable/equatable.dart';
import 'package:flutter_application_1/api/service_fav_backet.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'item_detail_event.dart';
part 'item_detail_state.dart';

class ItemDetailBloc extends Bloc<ItemDetailEvent, ItemDetailState> {
  final FavouriteApiService _favApi;
  final BasketApiService _basketApi;

  ItemDetailBloc({
    FavouriteApiService? favApi,
    BasketApiService? basketApi,
  })  : _favApi = favApi ?? FavouriteApiService(),
        _basketApi = basketApi ?? BasketApiService(),
        super(const ItemDetailInitial()) {
    on<ItemDetailFavCheckRequested>(_onFavCheckRequested);
    on<ItemDetailFavToggleRequested>(_onFavToggleRequested);
    on<ItemDetailAddToBasketRequested>(_onAddToBasketRequested);
  }

  // ── Check favourite ───────────────────────────────────────────────────────
  Future<void> _onFavCheckRequested(
    ItemDetailFavCheckRequested event,
    Emitter<ItemDetailState> emit,
  ) async {
    try {
      final isFav = await _favApi.checkFavourite(
          clothingUuid: event.clothingUuid);
      emit(ItemDetailLoaded(isFavourite: isFav));
    } catch (_) {
      emit(const ItemDetailLoaded(isFavourite: false));
    }
  }

  // ── Toggle favourite ──────────────────────────────────────────────────────
  Future<void> _onFavToggleRequested(
    ItemDetailFavToggleRequested event,
    Emitter<ItemDetailState> emit,
  ) async {
    emit(ItemDetailActionInProgress(
        isFavourite: event.currentlyFavourite));

    try {
      if (event.currentlyFavourite) {
        await _favApi.removeFromFavourite(
            clothingUuid: event.clothingUuid);
        emit(ItemDetailFavToggleSuccess(
            isFavourite: false, message: 'removed'));
      } else {
        await _favApi.addToFavourite(clothingUuid: event.clothingUuid);
        emit(ItemDetailFavToggleSuccess(
            isFavourite: true, message: 'added'));
      }
    } catch (e) {
      emit(ItemDetailActionFailure(
        isFavourite: event.currentlyFavourite,
        message: 'fav_failed:$e',
      ));
    }
  }

  // ── Add to Basket ─────────────────────────────────────────────────────────
  Future<void> _onAddToBasketRequested(
    ItemDetailAddToBasketRequested event,
    Emitter<ItemDetailState> emit,
  ) async {
    final currentFav = _currentIsFavourite;
    emit(ItemDetailActionInProgress(isFavourite: currentFav));

    try {
      await _basketApi.addToBasket(clothingUuid: event.clothingUuid);
      emit(ItemDetailBasketSuccess(isFavourite: currentFav));
    } catch (e) {
      emit(ItemDetailActionFailure(
        isFavourite: currentFav,
        message: 'basket_failed:$e',
      ));
    }
  }

  bool get _currentIsFavourite {
    final s = state;
    if (s is ItemDetailLoaded) return s.isFavourite;
    if (s is ItemDetailActionInProgress) return s.isFavourite;
    if (s is ItemDetailFavToggleSuccess) return s.isFavourite;
    if (s is ItemDetailActionFailure) return s.isFavourite;
    if (s is ItemDetailBasketSuccess) return s.isFavourite;
    return false;
  }
}