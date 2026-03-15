part of 'favourite_bloc.dart';

abstract class FavouriteEvent extends Equatable {
  const FavouriteEvent();

  @override
  List<Object?> get props => [];
}

/// โหลดรายการโปรด
class FavouriteLoadRequested extends FavouriteEvent {
  const FavouriteLoadRequested();
}

/// ลบออกจากรายการโปรด (จาก list หลัก)
class FavouriteRemoveRequested extends FavouriteEvent {
  final String clothingUuid;
  const FavouriteRemoveRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}

/// Toggle หัวใจใน Detail Card
class FavouriteToggleRequested extends FavouriteEvent {
  final String clothingUuid;
  final bool currentlyFavourite;

  const FavouriteToggleRequested({
    required this.clothingUuid,
    required this.currentlyFavourite,
  });

  @override
  List<Object?> get props => [clothingUuid, currentlyFavourite];
}

/// เพิ่มลงตะกร้า
class FavouriteAddToBasketRequested extends FavouriteEvent {
  final String clothingUuid;
  const FavouriteAddToBasketRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}