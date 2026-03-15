part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

// โหลดข้อมูลครั้งแรก
class NotificationLoadRequested extends NotificationEvent {
  const NotificationLoadRequested();
}

// รีเฟรช
class NotificationRefreshRequested extends NotificationEvent {
  const NotificationRefreshRequested();
}

// โหลด detail ของ message
class NotificationMessageDetailRequested extends NotificationEvent {
  final String id;
  const NotificationMessageDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// โหลด detail ของ news
class NotificationNewsDetailRequested extends NotificationEvent {
  final String id;
  const NotificationNewsDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}

// เพิ่มลงตะกร้า (จากหน้า list)
class NotificationAddToBasketRequested extends NotificationEvent {
  final String uuid;
  const NotificationAddToBasketRequested(this.uuid);

  @override
  List<Object?> get props => [uuid];
}