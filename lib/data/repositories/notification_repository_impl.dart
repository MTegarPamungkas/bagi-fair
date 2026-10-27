import 'package:bagi_fair/data/datasources/local_store.dart';
import 'package:bagi_fair/domain/entities/app_notification.dart';
import 'package:bagi_fair/domain/entities/outbox_item.dart';
import 'package:bagi_fair/domain/repositories/mutation_queue.dart';
import 'package:bagi_fair/domain/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._store, this._queue);

  final LocalStore _store;
  final MutationQueue _queue;

  @override
  Stream<List<AppNotification>> watchNotifications(String userId) {
    return _store.watch('notifications').map((rows) {
      final notifications = <AppNotification>[];
      for (final row in rows) {
        if (row['user_id'] != userId) continue;
        notifications.add(AppNotification.fromJson(row));
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return notifications;
    });
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return watchNotifications(userId)
        .map((items) => items.where((item) => item.isUnread).length);
  }

  @override
  Future<void> send(AppNotification notification) async {
    final row = notification.toJson();
    await _store.put('notifications', row, pending: !_queue.isDemo);
    await _queue.enqueue(
      table: 'notifications',
      rowId: notification.id,
      operation: OutboxOperation.insert,
      payload: row,
    );
  }

  @override
  Future<void> markRead(AppNotification notification) async {
    if (notification.readAt != null) return;
    final updated = AppNotification(
      id: notification.id,
      userId: notification.userId,
      groupId: notification.groupId,
      kind: notification.kind,
      title: notification.title,
      body: notification.body,
      actorId: notification.actorId,
      actorName: notification.actorName,
      payload: notification.payload,
      createdAt: notification.createdAt,
      readAt: DateTime.now(),
    );
    final row = updated.toJson();
    await _store.put('notifications', row, pending: !_queue.isDemo);
    // Mark-as-read is an UPDATE, never an upsert: the notification belongs to
    // us but its actor is a friend, so an INSERT policy check would reject it.
    await _queue.enqueue(
      table: 'notifications',
      rowId: updated.id,
      operation: OutboxOperation.patch,
      payload: {
        'read_at': updated.readAt!.toUtc().toIso8601String(),
      },
    );
  }

  @override
  Future<void> markAllRead(String userId) async {
    for (final row in _store.all('notifications')) {
      if (row['user_id'] != userId || row['read_at'] != null) continue;
      await markRead(AppNotification.fromJson(row));
    }
  }
}
