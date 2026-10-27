import 'package:bagi_fair/domain/entities/app_notification.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotification>> watchNotifications(String userId);

  Stream<int> watchUnreadCount(String userId);

  Future<void> send(AppNotification notification);

  Future<void> markRead(AppNotification notification);

  Future<void> markAllRead(String userId);
}
