import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repository);

  final NotificationRepository _repository;

  Stream<List<AppNotification>> call(String userId) =>
      _repository.watchNotifications(userId);
}

class WatchUnreadNotifications {
  const WatchUnreadNotifications(this._repository);

  final NotificationRepository _repository;

  Stream<int> call(String userId) => _repository.watchUnreadCount(userId);
}

class SendNotification {
  const SendNotification(this._repository);

  final NotificationRepository _repository;

  Future<void> call(AppNotification notification) =>
      _repository.send(notification);
}

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call(AppNotification notification) =>
      _repository.markRead(notification);
}

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationRepository _repository;

  Future<void> call(String userId) => _repository.markAllRead(userId);
}
