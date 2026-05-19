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
  }) async {
    // Parse HH:mm
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    
    // Generate a unique ID for this habit's notification
    final int baseId = habitId.hashCode.abs();

    for (int day in days) {
      // flutter_local_notifications uses 1=Monday...7=Sunday
      // Our model uses 0=Sunday...6=Saturday
      int flutterDay = day == 0 ? 7 : day;

      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the time has already passed today, schedule for next occurrence
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // We use matchDateTimeComponents to make it weekly
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
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelHabitNotifications(String habitId) async {
    final int baseId = habitId.hashCode.abs();
    for (int i = 0; i < 7; i++) {
      await _notificationsPlugin.cancel(baseId + i);
    }
  }
}
