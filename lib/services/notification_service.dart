import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initializeNotifications() async {
    tz.initializeTimeZones();
    // MAWO currently ships with the creator's deployment timezone. This keeps
    // scheduled reminders aligned with the device used for the release build.
    try { tz.setLocalLocation(tz.getLocation('Asia/Kolkata')); } catch (_) {}
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );
    await _notificationsPlugin.initialize(initializationSettings);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_habits',
      'Habit Reminders',
      description: 'Scheduled reminders for your MAWO habits',
      importance: Importance.high,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_general',
      'General Notifications',
      description: 'Standard MAWO notifications',
      importance: Importance.max,
    ));
    await _requestNotificationPermission();
    await _requestExactAlarmPermission();
  }

  Future<void> _requestNotificationPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('Notification permission unavailable: $e');
    }
  }

  Future<void> _requestExactAlarmPermission() async {
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final canSchedule = await androidPlugin?.canScheduleExactNotifications();
      if (canSchedule == false) await androidPlugin?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission unavailable: $e');
    }
  }

  Future<void> showNotification({required String title, required String body, required int id}) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'mawo_general',
        'General Notifications',
        channelDescription: 'Standard MAWO notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(id, title, body, details);
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
    if (parsed == null || (!isOneTime && days.isEmpty)) return;
    final hour = parsed.$1;
    final minute = parsed.$2;
    final now = tz.TZDateTime.now(tz.local);
    final baseId = habitId.hashCode.abs();
    final scheduleDays = isOneTime ? [0] : days;

    for (final day in scheduleDays) {
      final flutterDay = day == 0 ? 7 : day;
      var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (!isOneTime) {
        while (scheduledDate.weekday != flutterDay) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(Duration(days: isOneTime ? 1 : 7));
      }

      await _notificationsPlugin.zonedSchedule(
        baseId + day,
        'MAWO // Habit Alert',
        'Time for $habitName${goalMinutes > 0 ? ' ($goalMinutes min goal)' : ''}',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'mawo_habits',
            'Habit Reminders',
            channelDescription: 'Scheduled reminders for your habits',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: isOneTime ? null : DateTimeComponents.dayOfWeekAndTime,
      );
      debugPrint('MAWO reminder scheduled: $habitName at $scheduledDate; one-time=$isOneTime');
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

  Future<void> scheduleEndOfDayReminder({required String time}) async {
    await _notificationsPlugin.cancel(9001);
    final parsed = _parseTime(time);
    if (parsed == null) return;
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, parsed.$1, parsed.$2);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    await _notificationsPlugin.zonedSchedule(
      9001,
      'MAWO // Daily Check-in',
      'Your habits are still waiting for you. Close the loop before the day ends.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('mawo_general', 'General Notifications', channelDescription: 'Standard MAWO notifications', importance: Importance.max, priority: Priority.high),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelEndOfDayReminder() async {
    await _notificationsPlugin.cancel(9001);
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    final baseId = habitId.hashCode.abs();
    for (var i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
