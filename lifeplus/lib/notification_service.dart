import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    // Native Android notifications are configured separately.
    // Keep Chrome testing working without initializing the Android plugin.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    if (_initialized) return;

    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {},
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    _initialized = true;
  }

  static int _notificationId(String key) {
    // Create a consistent notification ID from a Firestore document ID.
    int id = 0x811c9dc5;

    for (final unit in key.codeUnits) {
      id = ((id ^ unit) * 0x01000193) & 0x7fffffff;
    }

    return id == 0 ? 1 : id;
  }

  static Future<void> scheduleReminder({
    required String reminderId,
    required String title,
    required String type,
    required DateTime reminderAt,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await initialize();

    if (!_initialized || !reminderAt.isAfter(DateTime.now())) {
      return;
    }

    final notificationTitle = type == 'Medicine'
        ? 'Medicine Reminder'
        : type == 'Checkup'
        ? 'Checkup Reminder'
        : 'LifePlus Reminder';

    await _plugin.zonedSchedule(
      id: _notificationId(reminderId),
      title: notificationTitle,
      body: title,
      scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'lifeplus_reminders',
          'LifePlus Reminders',
          channelDescription: 'Medicine and checkup reminders',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await initialize();

    await _plugin.cancel(id: _notificationId(reminderId));
  }
}
