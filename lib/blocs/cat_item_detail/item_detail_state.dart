// lib/blocs/item_detail/item_detail_state.dart

part of 'item_detail_bloc.dart';

abstract class ItemDetailState extends Equatable {
  const ItemDetailState();

  @override
  List<Object?> get props => [];
}

class ItemDetailInitial extends ItemDetailState {
  const ItemDetailInitial();
}

/// โหลด fav status สำเร็จ
class ItemDetailLoaded extends ItemDetailState {
  final bool isFavourite;
  const ItemDetailLoaded({required this.isFavourite});

  @override
  List<Object?> get props => [isFavourite];
}

/// กำลังดำเนิน action
class ItemDetailActionInProgress extends ItemDetailState {
  final bool isFavourite;
  const ItemDetailActionInProgress({required this.isFavourite});

  @override
  List<Object?> get props => [isFavourite];
}

/// Toggle fav สำเร็จ
class ItemDetailFavToggleSuccess extends ItemDetailState {
  final bool isFavourite;
  final String message; // 'added' | 'removed'

  const ItemDetailFavToggleSuccess({
    required this.isFavourite,
    required this.message,
  });

  @override
  List<Object?> get props => [isFavourite, message];
}

/// Add to basket สำเร็จ — ส่ง signal ให้ปิด card
class ItemDetailBasketSuccess extends ItemDetailState {
  final bool isFavourite;
  const ItemDetailBasketSuccess({required this.isFavourite});

  @override
  List<Object?> get props => [isFavourite];
}

/// action ล้มเหลว
class ItemDetailActionFailure extends ItemDetailState {
  final bool isFavourite;
  final String message;

  const ItemDetailActionFailure({
    required this.isFavourite,
    required this.message,
  });

  @override
  List<Object?> get props => [isFavourite, message];
}