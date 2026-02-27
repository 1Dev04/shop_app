part of 'basket_bloc.dart';

abstract class BasketEvent extends Equatable {
  const BasketEvent();

  @override
  List<Object?> get props => [];
}

/// โหลดตะกร้า
class BasketLoadRequested extends BasketEvent {
  const BasketLoadRequested();
}

/// อัปเดตจำนวน
class BasketQuantityUpdateRequested extends BasketEvent {
  final String clothingUuid;
  final int newQuantity;

  const BasketQuantityUpdateRequested({
    required this.clothingUuid,
    required this.newQuantity,
  });

  @override
  List<Object?> get props => [clothingUuid, newQuantity];
}

/// ลบรายการเดียว
class BasketItemRemoveRequested extends BasketEvent {
  final String clothingUuid;
  const BasketItemRemoveRequested(this.clothingUuid);

  @override
  List<Object?> get props => [clothingUuid];
}

/// ล้างตะกร้าทั้งหมด
class BasketClearRequested extends BasketEvent {
  const BasketClearRequested();
}