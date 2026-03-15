// lib/blocs/item_detail/item_detail_event.dart

part of 'item_detail_bloc.dart';

abstract class ItemDetailEvent extends Equatable {
  const ItemDetailEvent();

  @override
  List<Object?> get props => [];
}

/// ตรวจสอบสถานะ favourite ตอนเปิด card
class ItemDetailFavCheckRequested extends ItemDetailEvent {
  final String clothingUuid;
  const ItemDetailFavCheckRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}

/// Toggle favourite
class ItemDetailFavToggleRequested extends ItemDetailEvent {
  final String clothingUuid;
  final bool currentlyFavourite;

  const ItemDetailFavToggleRequested({
    required this.clothingUuid,
    required this.currentlyFavourite,
  });

  @override
  List<Object?> get props => [clothingUuid, currentlyFavourite];
}

/// เพิ่มลงตะกร้าจาก detail card
class ItemDetailAddToBasketRequested extends ItemDetailEvent {
  final String clothingUuid;
  const ItemDetailAddToBasketRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}