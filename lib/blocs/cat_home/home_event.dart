// lib/blocs/home/home_event.dart

part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// โหลด advertisements
class HomeAdsLoadRequested extends HomeEvent {
  const HomeAdsLoadRequested();
}

/// โหลด item detail (เปิด popup)
class HomeItemDetailRequested extends HomeEvent {
  final int itemId;
  const HomeItemDetailRequested(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// เพิ่มลงตะกร้าจาก homepage card
class HomeAddToBasketRequested extends HomeEvent {
  final String clothingUuid;
  const HomeAddToBasketRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}