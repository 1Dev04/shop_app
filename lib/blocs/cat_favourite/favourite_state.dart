part of 'favourite_bloc.dart';

abstract class FavouriteState extends Equatable {
  const FavouriteState();

  @override
  List<Object?> get props => [];
}

/// ยังไม่เริ่มโหลด
class FavouriteInitial extends FavouriteState {
  const FavouriteInitial();
}

/// กำลังโหลดรายการครั้งแรก
class FavouriteLoading extends FavouriteState {
  const FavouriteLoading();
}

/// โหลดสำเร็จ
class FavouriteLoaded extends FavouriteState {
  final List<FavouriteItem> items;
  const FavouriteLoaded(this.items);

  @override
  List<Object?> get props => [items];
}

/// โหลดล้มเหลว
class FavouriteFailure extends FavouriteState {
  final String message;
  const FavouriteFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// กำลังดำเนิน action (remove / toggle / addToBasket) — ถือ list เดิมไว้
class FavouriteActionInProgress extends FavouriteState {
  final List<FavouriteItem> items;
  const FavouriteActionInProgress(this.items);

  @override
  List<Object?> get props => [items];
}

/// Action สำเร็จ
class FavouriteActionSuccess extends FavouriteState {
  final List<FavouriteItem> items;
  final FavouriteActionType actionType;
  final String message;

  const FavouriteActionSuccess({
    required this.items,
    required this.actionType,
    required this.message,
  });

  @override
  List<Object?> get props => [items, actionType, message];
}

/// Action ล้มเหลว
class FavouriteActionFailure extends FavouriteState {
  final List<FavouriteItem> items;
  final String message;

  const FavouriteActionFailure({
    required this.items,
    required this.message,
  });

  @override
  List<Object?> get props => [items, message];
}

/// Toggle สำเร็จ (แยกออกมาเพื่อให้ Detail Card อัปเดต isFavourite ได้)
class FavouriteToggleSuccess extends FavouriteState {
  final List<FavouriteItem> items;
  final bool isFavourite;
  final String message;

  const FavouriteToggleSuccess({
    required this.items,
    required this.isFavourite,
    required this.message,
  });

  @override
  List<Object?> get props => [items, isFavourite, message];
}

enum FavouriteActionType { remove, addToBasket }