part of 'shop_bloc.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

// โหลดข้อมูลครั้งแรก
class ShopLoadRequested extends ShopEvent {
  const ShopLoadRequested();
}

// ดู detail
class ShopItemDetailRequested extends ShopEvent {
  final int itemId;
  const ShopItemDetailRequested(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

// เพิ่มลงตะกร้า (จากหน้า list)
class ShopAddToBasketRequested extends ShopEvent {
  final String uuid;
  const ShopAddToBasketRequested(this.uuid);

  @override
  List<Object?> get props => [uuid];
}