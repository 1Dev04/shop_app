// lib/blocs/home/home_state.dart

part of 'home_bloc.dart';

abstract class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => [];
}

/// ยังไม่โหลด
class HomeInitial extends HomeState {
  const HomeInitial();
}

/// กำลังโหลด ads ครั้งแรก
class HomeLoading extends HomeState {
  const HomeLoading();
}

/// โหลด ads สำเร็จ
class HomeLoaded extends HomeState {
  final List<Map<String, dynamic>> ads;
  const HomeLoaded(this.ads);

  @override
  List<Object?> get props => [ads];
}

/// โหลด ads ล้มเหลว
class HomeFailure extends HomeState {
  final String message;
  const HomeFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// กำลังโหลด item detail
class HomeItemDetailLoading extends HomeState {
  final List<Map<String, dynamic>> ads; // ถือ ads เดิมไว้ด้วย
  const HomeItemDetailLoading(this.ads);

  @override
  List<Object?> get props => [ads];
}

/// โหลด item detail สำเร็จ — UI เปิด popup
class HomeItemDetailLoaded extends HomeState {
  final List<Map<String, dynamic>> ads;
  final Map<String, dynamic> itemDetail;

  const HomeItemDetailLoaded({required this.ads, required this.itemDetail});

  @override
  List<Object?> get props => [ads, itemDetail];
}

/// โหลด item detail ล้มเหลว
class HomeItemDetailFailure extends HomeState {
  final List<Map<String, dynamic>> ads;
  const HomeItemDetailFailure(this.ads);

  @override
  List<Object?> get props => [ads];
}

/// กำลัง add to basket
class HomeBasketActionInProgress extends HomeState {
  final List<Map<String, dynamic>> ads;
  const HomeBasketActionInProgress(this.ads);

  @override
  List<Object?> get props => [ads];
}

/// add to basket สำเร็จ
class HomeBasketActionSuccess extends HomeState {
  final List<Map<String, dynamic>> ads;
  const HomeBasketActionSuccess(this.ads);

  @override
  List<Object?> get props => [ads];
}

/// add to basket ล้มเหลว
class HomeBasketActionFailure extends HomeState {
  final List<Map<String, dynamic>> ads;
  final String message;

  const HomeBasketActionFailure({required this.ads, required this.message});

  @override
  List<Object?> get props => [ads, message];
}