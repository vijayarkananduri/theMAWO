import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter/services.dart';

class NotificationService {
  static const bool enabled = true;
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  static const int _endOfDayNotificationId = 900000001;
  static const int _testNotificationId = 900000002;
  static const int _createdNotificationId = 900000003;
  static const MethodChannel _permissions = MethodChannel('mawo/permissions');

  void setTimeZone(String location) {
    if (!enabled) return;
    try {
      tz.setLocalLocation(tz.getLocation(location));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<bool> isExactAlarmAllowed() async {
    if (!enabled) return false;
    return await _permissions.invokeMethod<bool>('isExactAlarmAllowed') ?? false;
  }

  Future<void> openExactAlarmSettings() async {
    if (!enabled) return;
    await _permissions.invokeMethod<bool>('openExactAlarmSettings');
  }

  Future<bool> requestNotificationPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? true;
  }

  Future<void> initializeNotifications({String location = 'UTC'}) async {
    if (!enabled || _initialized) return;
    tz.initializeTimeZones();
    setTimeZone(location);

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_habits', 'Habit Reminders',
      description: 'Scheduled reminders for your habits',
      importance: Importance.max,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'mawo_general', 'General Notifications',
      description: 'Standard MAWO notifications',
      importance: Importance.max,
    ));
    await requestNotificationPermission();
    _initialized = true;
  }

  Future<void> showHabitCreatedNotification(String habitName) async {
    if (!enabled) return;
    if (!_initialized) await initializeNotifications();
    await _plugin.show(
      _createdNotificationId,
      'MAWO // Habit created',
      '$habitName is now part of your signal.',
      _details('mawo_general', 'General Notifications'),
    );
  }

  Future<void> showTestNotification() async {
    if (!enabled) return;
    if (!_initialized) await initializeNotifications();
    await _plugin.show(
      _testNotificationId,
      'MAWO // Notification test',
      'Notifications are working on this device.',
      _details('mawo_general', 'General Notifications'),
    );
  }

  Future<void> scheduleTestNotification() async {
    if (!enabled) return;
    if (!_initialized) await initializeNotifications();
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 2));
    await _plugin.zonedSchedule(
      _testNotificationId,
      'MAWO // Scheduled test',
      'Scheduled reminders are working on this device.',
      scheduled,
      _details('mawo_general', 'General Notifications'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> scheduleNotification({
    required String habitId,
    required String habitName,
    required String time,
    required List<int> days,
    required bool followup,
    required int goalMinutes,
    required String category,
    DateTime? oneTimeDate,
    Duration? delay,
    bool isOneTime = false,
  }) async {
    if (!enabled) return;
    if (!_initialized) await initializeNotifications();
    final exact = await isExactAlarmAllowed();
    if (!exact) throw StateError('Exact alarms are not enabled for MAWO.');
    final parts = time.split(':');
    if (parts.length != 2) throw const FormatException('Notification time must be HH:mm');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw const FormatException('Notification time must be HH:mm');
    }

    final now = tz.TZDateTime.now(tz.local);
    final target = delay != null
        ? now.add(delay)
        : isOneTime && oneTimeDate != null
            ? tz.TZDateTime(tz.local, oneTimeDate.year, oneTimeDate.month, oneTimeDate.day, hour, minute)
            : _nextWeeklyDate(now, hour, minute, days);
    if (!target.isAfter(now)) throw StateError('Reminder time must be in the future.');

    final baseId = _stableId(habitId);
    await _plugin.zonedSchedule(
      baseId,
      _titleFor(category, isOneTime),
      _bodyFor(category, habitName, goalMinutes),
      target,
      _details('mawo_habits', 'Habit Reminders'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: isOneTime ? null : DateTimeComponents.dayOfWeekAndTime,
    );
    if (followup && !isOneTime) {
      final followupTarget = target.add(const Duration(minutes: 30));
      await _plugin.zonedSchedule(
        baseId + 1,
        'MAWO // Follow-up signal',
        'Your $habitName signal is still open.',
        followupTarget,
        _details('mawo_habits', 'Habit Reminders'),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> scheduleEndOfDayReminder({required String time}) async {
    if (!enabled) return;
    if (!_initialized) await initializeNotifications();
    final exact = await isExactAlarmAllowed();
    if (!exact) throw StateError('Exact alarms are not enabled for MAWO.');
    final parts = time.split(':');
    if (parts.length != 2) throw const FormatException('Notification time must be HH:mm');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null || hour > 23 || minute > 59) {
      throw const FormatException('Notification time must be HH:mm');
    }
    final now = tz.TZDateTime.now(tz.local);
    var target = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) target = target.add(const Duration(days: 1));
    await _plugin.zonedSchedule(
      _endOfDayNotificationId,
      'MAWO // Daily reflection',
      'Take a moment to check in with your habits.',
      target,
      _details('mawo_general', 'General Notifications'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelEndOfDayReminder() async {
    if (!enabled) return;
    await _plugin.cancel(_endOfDayNotificationId);
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    if (!enabled) return;
    final baseId = _stableId(habitId);
    await _plugin.cancel(baseId);
    await _plugin.cancel(baseId + 1);
  }

  int _stableId(String value) {
    var hash = 0x811c9dc5;
    for (final code in value.codeUnits) {
      hash ^= code;
      hash = (hash * 16777619) & 0x7fffffff;
    }
    return (hash % 800000000) + 1000;
  }

  tz.TZDateTime _nextWeeklyDate(tz.TZDateTime now, int hour, int minute, List<int> days) {
    final selected = days.isEmpty ? <int>[now.weekday % 7] : days;
    for (var offset = 0; offset <= 7; offset++) {
      final candidate = now.add(Duration(days: offset));
      final weekday = candidate.weekday == DateTime.sunday ? 0 : candidate.weekday;
      if (selected.contains(weekday)) {
        final date = tz.TZDateTime(tz.local, candidate.year, candidate.month, candidate.day, hour, minute);
        if (date.isAfter(now)) return date;
      }
    }
    return tz.TZDateTime(tz.local, now.year, now.month, now.day + 7, hour, minute);
  }

  NotificationDetails _details(String channelId, String channelName) => NotificationDetails(
        android: AndroidNotificationDetails(
          channelId, channelName,
          channelDescription: channelName,
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      );

  String _titleFor(String category, bool oneTime) {
    final prefix = oneTime ? 'One-time signal' : 'Habit signal';
    switch (category.toLowerCase()) {
      case 'cognitive': return 'MAWO // $prefix · Focus';
      case 'physical': return 'MAWO // $prefix · Move';
      case 'mental': return 'MAWO // $prefix · Reset';
      default: return 'MAWO // $prefix';
    }
  }

  String _bodyFor(String category, String habitName, int goalMinutes) {
    final suffix = goalMinutes > 0 ? ' · $goalMinutes min goal' : '';
    switch (category.toLowerCase()) {
      case 'cognitive': return 'Make space for $habitName$suffix.';
      case 'physical': return 'Give your body a signal: $habitName$suffix.';
      case 'mental': return 'Take a moment for $habitName$suffix.';
      default: return 'Time for $habitName$suffix.';
    }
  }
}
