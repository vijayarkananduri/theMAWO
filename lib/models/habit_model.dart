import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  final String name;
  final String type; // 'daily' or 'onetime'
  final String category; // 'cognitive', 'physical', 'mental', 'custom'
  final int goalMinutes;
  final DateTime createdAt;
  final NotificationSettings? notif;

  Habit({
    String? id,
    required this.name,
    required this.type,
    required this.category,
    required this.goalMinutes,
    DateTime? createdAt,
    this.notif,
  })
      : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'category': category,
        'goalMinutes': goalMinutes,
        'createdAt': createdAt.toIso8601String(),
        'notif': notif?.toJson(),
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        category: json['category'],
        goalMinutes: json['goalMinutes'],
        createdAt: DateTime.parse(json['createdAt']),
        notif: json['notif'] != null
            ? NotificationSettings.fromJson(json['notif'])
            : null,
      );
}

class NotificationSettings {
  final bool enabled;
  final String time; // HH:mm format
  final List<int> days; // 0-6 (Sun-Sat)
  final bool followup;

  NotificationSettings({
    required this.enabled,
    required this.time,
    required this.days,
    required this.followup,
  });

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'time': time,
        'days': days,
        'followup': followup,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: json['enabled'] ?? false,
        time: json['time'] ?? '09:00',
        days: List<int>.from(json['days'] ?? [0, 1, 2, 3, 4, 5, 6]),
        followup: json['followup'] ?? false,
      );
}

class Completion {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD

  Completion({
    String? id,
    required this.habitId,
    String? date,
  })
      : id = id ?? const Uuid().v4(),
        date = date ?? DateTime.now().toString().split('T')[0];

  Map<String, dynamic> toJson() => {
        'id': id,
        'hid': habitId,
        'date': date,
      };

  factory Completion.fromJson(Map<String, dynamic> json) => Completion(
        id: json['id'],
        habitId: json['hid'],
        date: json['date'],
      );
}
