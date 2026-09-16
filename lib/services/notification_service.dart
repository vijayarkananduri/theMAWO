import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();
    
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
    );

    // Request runtime permission for Android 13+
    await _requestNotificationPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mawo_general',
      'General Notifications',
      channelDescription: 'Standard MAWO notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }

  Future<void> scheduleNotification({
    required String habitId,
    required String habitName,
    required String time,
    required List<int> days,
    required bool followup,
    required int goalMinutes,
    required bool isOneTime,
  }) async {
    final parsed = _parseTime(time);
    if (parsed == null) return;
    final hour = parsed.$1;
    final minute = parsed.$2;

    final now = tz.TZDateTime.now(tz.local);
    
    // Generate a unique ID for this habit's notification
    final int baseId = habitId.hashCode.abs();

    if (days.isEmpty) return;

    // One-time tasks use only the first selected day and do not repeat.
    final scheduleDays = isOneTime ? [0] : days;
    for (int day in scheduleDays) {
      // flutter_local_notifications uses 1=Monday...7=Sunday
      // Our model uses 0=Sunday...6=Saturday
      int flutterDay = day == 0 ? 7 : day;

      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

      if (!isOneTime) {
        while (scheduledDate.weekday != flutterDay) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(Duration(days: isOneTime ? 1 : 7));
      }

      final repeatsWeekly = !isOneTime;
      await _notificationsPlugin.zonedSchedule(
        baseId + day, // Unique ID per day per habit
        'MAWO // Habit Alert',
        'Time for $habitName ($goalMinutes min goal)',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mawo_habits',
            'Habit Reminders',
            channelDescription: 'Scheduled reminders for your habits',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: repeatsWeekly
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
      );
    }
  }

  (int, int)? _parseTime(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null || hour > 23 || minute > 59) return null;
    return (hour, minute);
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    final int baseId = habitId.hashCode.abs();
    for (int i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
