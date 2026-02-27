part of 'basket_bloc.dart';

abstract class BasketState extends Equatable {
  const BasketState();

  @override
  List<Object?> get props => [];
}

/// ยังไม่เริ่ม
class BasketInitial extends BasketState {
  const BasketInitial();
}

/// กำลังโหลดครั้งแรก
class BasketLoading extends BasketState {
  const BasketLoading();
}

/// โหลดสำเร็จ
class BasketLoaded extends BasketState {
  final List<BasketItem> items;
  final BasketSummary? summary;

  const BasketLoaded({required this.items, required this.summary});

  @override
  List<Object?> get props => [items, summary];
}

/// โหลดล้มเหลว
class BasketFailure extends BasketState {
  final String message;
  const BasketFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// กำลังดำเนิน action — ถือ data เดิมไว้แสดง UI ต่อได้
class BasketActionInProgress extends BasketState {
  final List<BasketItem> items;
  final BasketSummary? summary;

  const BasketActionInProgress({required this.items, required this.summary});

  @override
  List<Object?> get props => [items, summary];
}

/// action สำเร็จ
class BasketActionSuccess extends BasketState {
  final List<BasketItem> items;
  final BasketSummary? summary;
  final BasketActionType actionType;
  final String message;

  const BasketActionSuccess({
    required this.items,
    required this.summary,
    required this.actionType,
    required this.message,
  });

  @override
  List<Object?> get props => [items, summary, actionType, message];
}

/// action ล้มเหลว
class BasketActionFailure extends BasketState {
  final List<BasketItem> items;
  final BasketSummary? summary;
  final String message;

  const BasketActionFailure({
    required this.items,
    required this.summary,
    required this.message,
  });

  @override
  List<Object?> get props => [items, summary, message];
}

enum BasketActionType { updateQuantity, removeItem, clearBasket }