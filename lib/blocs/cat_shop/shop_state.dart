part of 'shop_bloc.dart';

abstract class ShopState extends Equatable {
  const ShopState();

  @override
  List<Object?> get props => [];
}

// ── Initial ──────────────────────────────────────────────────────────────────
class ShopInitial extends ShopState {
  const ShopInitial();
}

// ── Loading ───────────────────────────────────────────────────────────────────
class ShopLoading extends ShopState {
  const ShopLoading();
}

// ── Loaded ────────────────────────────────────────────────────────────────────
class ShopLoaded extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;

  const ShopLoaded({
    required this.likeItems,
    required this.sellerItems,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems];
}

// ── Failure (โหลดครั้งแรกล้มเหลว) ───────────────────────────────────────────
class ShopFailure extends ShopState {
  final String likeError;
  final String sellerError;

  const ShopFailure({
    required this.likeError,
    required this.sellerError,
  });

  @override
  List<Object?> get props => [likeError, sellerError];
}

// ── Detail Loading ────────────────────────────────────────────────────────────
class ShopItemDetailLoading extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;

  const ShopItemDetailLoading({
    required this.likeItems,
    required this.sellerItems,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems];
}

// ── Detail Loaded ─────────────────────────────────────────────────────────────
class ShopItemDetailLoaded extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;
  final Map<String, dynamic> itemDetail;

  const ShopItemDetailLoaded({
    required this.likeItems,
    required this.sellerItems,
    required this.itemDetail,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems, itemDetail];
}

// ── Detail Failure ────────────────────────────────────────────────────────────
class ShopItemDetailFailure extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;

  const ShopItemDetailFailure({
    required this.likeItems,
    required this.sellerItems,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems];
}

// ── Basket In Progress ────────────────────────────────────────────────────────
class ShopBasketInProgress extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;
  final String uuid;

  const ShopBasketInProgress({
    required this.likeItems,
    required this.sellerItems,
    required this.uuid,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems, uuid];
}

// ── Basket Success ────────────────────────────────────────────────────────────
class ShopBasketSuccess extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;

  const ShopBasketSuccess({
    required this.likeItems,
    required this.sellerItems,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems];
}

// ── Basket Failure ────────────────────────────────────────────────────────────
class ShopBasketFailure extends ShopState {
  final List<Map<String, dynamic>> likeItems;
  final List<Map<String, dynamic>> sellerItems;
  final String errorMessage;

  const ShopBasketFailure({
    required this.likeItems,
    required this.sellerItems,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [likeItems, sellerItems, errorMessage];
}