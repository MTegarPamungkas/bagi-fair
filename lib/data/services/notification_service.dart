import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around local notifications.
///
/// Local notifications are the honest, working half of the reminder story:
/// the app schedules/displays them on device. Server-pushed FCM requires a
/// Firebase project and is documented as a follow-up in DECISIONS.md.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
        macOS: DarwinInitializationSettings(),
      );
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (error, stack) {
      debugPrint('Local notifications unavailable: $error');
      debugPrintStack(stackTrace: stack);
    }
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_ready) await init();
    if (!_ready) return;
    try {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'bagi_fair_reminders',
          'Pengingat Bagi Fair',
          channelDescription: 'Pengingat pelunasan dan aktivitas grup',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
      await _plugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (error) {
      debugPrint('Could not show local notification: $error');
    }
  }
}
