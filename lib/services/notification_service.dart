import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initializeNotifications() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_habits',
      'Habit Reminders',
      description: 'Scheduled reminders for your habits',
      importance: Importance.max,
    ));

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_general',
      'General Notifications',
      description: 'Standard MAWO notifications',
      importance: Importance.max,
    ));

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();
    _initialized = true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    required int id,
  }) async {
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'mawo_general',
          'General Notifications',
          channelDescription: 'Standard MAWO notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> scheduleNotification({
    required String habitId,
    required String habitName,
    required String time,
    required List<int> days,
    required bool followup,
    required int goalMinutes,
  }) async {
    if (!_initialized) await initializeNotifications();

    final parts = time.split(':');
    if (parts.length != 2) throw FormatException('Notification time must be HH:mm');

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);

    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw FormatException('Notification time must be HH:mm');
    }

    final now = DateTime.now();
    final baseId = habitId.hashCode.abs() % 100000000;

    for (final day in days.toSet()) {
      final flutterDay = day == 0 ? DateTime.sunday : day;
      var localDate = DateTime(now.year, now.month, now.day, hour, minute);

      while (localDate.weekday != flutterDay) {
        localDate = localDate.add(const Duration(days: 1));
      }

      if (!localDate.isAfter(now)) {
        localDate = localDate.add(const Duration(days: 7));
      }

      await _plugin.zonedSchedule(
        baseId + day,
        'MAWO // Habit Alert',
        'Time for $habitName ($goalMinutes min goal)',
        tz.TZDateTime.from(localDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mawo_habits',
            'Habit Reminders',
            channelDescription: 'Scheduled reminders for your habits',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    final baseId = habitId.hashCode.abs() % 100000000;
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(baseId + i);
    }
  }

  Future<void> rescheduleHabits(Iterable<dynamic> habits) async {
    for (final habit in habits) {
      await cancelHabitNotifications(habit.id as String);
      final notification = habit.notif;
      if (notification != null && notification.enabled == true && notification.days.isNotEmpty) {
        await scheduleNotification(
          habitId: habit.id as String,
          habitName: habit.name as String,
          time: notification.time as String,
          days: List<int>.from(notification.days as List),
          followup: notification.followup == true,
          goalMinutes: habit.goalMinutes as int,
        );
      }
    }
  }
}
