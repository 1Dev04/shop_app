part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

// ── Initial ──────────────────────────────────────────────────────────────────
class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

// ── Loading (โหลดครั้งแรก) ──────────────────────────────────────────────────
class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

// ── Loaded ───────────────────────────────────────────────────────────────────
class NotificationLoaded extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;

  const NotificationLoaded({
    required this.messages,
    required this.news,
  });

  @override
  List<Object?> get props => [messages, news];
}

// ── Failure (โหลดครั้งแรกล้มเหลว) ──────────────────────────────────────────
class NotificationFailure extends NotificationState {
  final String message;
  const NotificationFailure(this.message);

  @override
  List<Object?> get props => [message];
}

// ── Detail Loading ───────────────────────────────────────────────────────────
class NotificationDetailLoading extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;

  const NotificationDetailLoading({
    required this.messages,
    required this.news,
  });

  @override
  List<Object?> get props => [messages, news];
}

// ── Detail Loaded ────────────────────────────────────────────────────────────
class NotificationDetailLoaded extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;
  final dynamic itemDetail; // NotificationItemMess หรือ NotificationItemNews

  const NotificationDetailLoaded({
    required this.messages,
    required this.news,
    required this.itemDetail,
  });

  @override
  List<Object?> get props => [messages, news, itemDetail];
}

// ── Detail Failure ───────────────────────────────────────────────────────────
class NotificationDetailFailure extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;
  final String errorMessage;

  const NotificationDetailFailure({
    required this.messages,
    required this.news,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [messages, news, errorMessage];
}

// ── Basket In Progress ───────────────────────────────────────────────────────
class NotificationBasketInProgress extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;
  final String uuid; // uuid ที่กำลัง add

  const NotificationBasketInProgress({
    required this.messages,
    required this.news,
    required this.uuid,
  });

  @override
  List<Object?> get props => [messages, news, uuid];
}

// ── Basket Success ───────────────────────────────────────────────────────────
class NotificationBasketSuccess extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;

  const NotificationBasketSuccess({
    required this.messages,
    required this.news,
  });

  @override
  List<Object?> get props => [messages, news];
}

// ── Basket Failure ───────────────────────────────────────────────────────────
class NotificationBasketFailure extends NotificationState {
  final List<NotificationItemMess> messages;
  final List<NotificationItemNews> news;
  final String errorMessage;

  const NotificationBasketFailure({
    required this.messages,
    required this.news,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [messages, news, errorMessage];
}