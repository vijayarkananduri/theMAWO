import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  final String name;
  final String type; // 'daily' or 'onetime'
  final String category; // 'cognitive', 'physical', 'mental', 'custom'
  final int goalMinutes;
  final NotificationSettings? notif;
  final int createdAt;

  Habit({
    String? id,
    required this.name,
    required this.type,
    required this.category,
    required this.goalMinutes,
    this.notif,
    int? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  factory Habit.fromJson(Map<String, dynamic> json) {
    return Habit(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      category: json['category'],
      goalMinutes: json['goalMinutes'],
      notif: json['notif'] != null
          ? NotificationSettings.fromJson(json['notif'])
          : null,
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'category': category,
      'goalMinutes': goalMinutes,
      'notif': notif?.toJson(),
      'createdAt': createdAt,
    };
  }
}

class NotificationSettings {
  final bool enabled;
  final String time; // HH:mm format
  final List<int> days; // 0-6 (Sunday to Saturday)
  final bool followup;

  NotificationSettings({
    required this.enabled,
    required this.time,
    required this.days,
    required this.followup,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enabled: json['enabled'] ?? false,
      time: json['time'] ?? '09:00',
      days: List<int>.from(json['days'] ?? [0, 1, 2, 3, 4, 5, 6]),
      followup: json['followup'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enabled': enabled,
      'time': time,
      'days': days,
      'followup': followup,
    };
  }
}

class Completion {
  final String id;
  final String habitId;
  final String date; // YYYY-MM-DD
  final int timestamp;

  Completion({
    String? id,
    required this.habitId,
    required this.date,
    int? timestamp,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Completion.fromJson(Map<String, dynamic> json) {
    return Completion(
      id: json['id'],
      habitId: json['habitId'],
      date: json['date'],
      timestamp: json['timestamp'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'habitId': habitId,
      'date': date,
      'timestamp': timestamp,
    };
  }
}
