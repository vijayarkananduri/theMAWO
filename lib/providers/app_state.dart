import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mawo/models/habit.dart';
import 'package:mawo/services/notification_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();

  factory AppState() {
    return _instance;
  }

  AppState._internal();

  // State
  List<Habit> habits = [];
  List<Completion> completions = [];
  Map<String, dynamic> user = {'name': '', 'createdAt': DateTime.now().millisecondsSinceEpoch};
  Map<String, dynamic> settings = {
    'eodEnabled': false,
    'eodTime': '21:00',
    'isDark': true,
  };
  int totalFragments = 0;
  int totalXP = 0;
  int level = 1;
  List<String> badges = [];
  int totalCompletions = 0;
  int longestStreak = 0;
  int daysActive = 0;

  late SharedPreferences _prefs;

  Future<void> loadData() async {
    _prefs = await SharedPreferences.getInstance();
    final json = _prefs.getString('mawo_data');
    if (json != null) {
      try {
        final data = jsonDecode(json);
        habits = (data['habits'] as List)
            .map((h) => Habit.fromJson(h))
            .toList();
        completions = (data['completions'] as List)
            .map((c) => Completion.fromJson(c))
            .toList();
        user = data['user'] ?? user;
        settings = Map<String, dynamic>.from(data['settings'] ?? settings);
        totalFragments = data['tf'] ?? 0;
        totalXP = data['xp'] ?? 0;
        level = data['level'] ?? 1;
        badges = List<String>.from(data['badges'] ?? []);
        totalCompletions = data['tc'] ?? 0;
        longestStreak = data['ls'] ?? 0;
        daysActive = data['da'] ?? 0;
      } catch (e) {
        debugPrint('Error loading data: $e');
      }
    }
    notifyListeners();
  }

  String exportData() {
    final data = {
      'habits': habits.map((h) => h.toJson()).toList(),
      'completions': completions.map((c) => c.toJson()).toList(),
      'user': user,
      'settings': settings,
      'tf': totalFragments,
      'xp': totalXP,
      'level': level,
      'badges': badges,
      'tc': totalCompletions,
      'ls': longestStreak,
      'da': daysActive,
    };
    return jsonEncode(data);
  }

  Future<void> importData(String json) async {
    try {
      final data = jsonDecode(json);
      habits = (data['habits'] as List).map((h) => Habit.fromJson(h)).toList();
      completions = (data['completions'] as List).map((c) => Completion.fromJson(c)).toList();
      user = data['user'] ?? user;
      settings = Map<String, dynamic>.from(data['settings'] ?? settings);
      totalFragments = data['tf'] ?? 0;
      totalXP = data['xp'] ?? 0;
      level = data['level'] ?? 1;
      badges = List<String>.from(data['badges'] ?? []);
      totalCompletions = data['tc'] ?? 0;
      longestStreak = data['ls'] ?? 0;
      daysActive = data['da'] ?? 0;
      await saveData();
      notifyListeners();
    } catch (e) {
      debugPrint('Error importing data: $e');
      rethrow;
    }
  }

  Future<void> saveData() async {
    await _prefs.setString('mawo_data', exportData());
  }

  String get today => DateTime.now().toString().split(' ')[0];

  bool isCompletedToday(String habitId) {
    return completions.any((c) => c.habitId == habitId && c.date == today);
  }

  List<Completion> getTodayCompletions() {
    return completions.where((c) => c.date == today).toList();
  }

  void setUserName(String name) {
    user['name'] = name;
    saveData();
    notifyListeners();
  }

  void setEODSettings(bool enabled, [String? time]) {
    settings['eodEnabled'] = enabled;
    if (time != null) settings['eodTime'] = time;
    saveData();
    notifyListeners();
  }

  void toggleTheme() {
    settings['isDark'] = !(settings['isDark'] ?? true);
    saveData();
    notifyListeners();
  }

  Future<void> eraseAllData() async {
    habits = [];
    completions = [];
    user = {'name': '', 'createdAt': DateTime.now().millisecondsSinceEpoch};
    settings = {'eodEnabled': false, 'eodTime': '21:00'};
    totalFragments = 0;
    totalXP = 0;
    level = 1;
    badges = [];
    totalCompletions = 0;
    longestStreak = 0;
    daysActive = 0;
    await _prefs.remove('mawo_data');
    notifyListeners();
  }

  void toggleHabit(String habitId, String type) {
    final completed = isCompletedToday(habitId);

    if (completed) {
      completions.removeWhere((c) => c.habitId == habitId && c.date == today);
      totalFragments = (totalFragments - 1).clamp(0, double.infinity).toInt();
      totalXP = (totalXP - (type == 'daily' ? 2 : 1)).clamp(0, double.infinity).toInt();
      totalCompletions = (totalCompletions - 1).clamp(0, double.infinity).toInt();
    } else {
      completions.add(Completion(habitId: habitId, date: today));
      totalFragments++;
      totalXP += type == 'daily' ? 2 : 1;
      if (getStreak(habitId) >= 3) totalXP++;
      totalCompletions++;
    }

    level = (totalXP / 50).toInt() + 1;
    longestStreak = getMaxStreak();
    daysActive = getActiveDays();

    saveData();
    notifyListeners();
  }

  int getStreak(String habitId) {
    final dates = <String>{};
    for (final c in completions) {
      if (c.habitId == habitId) dates.add(c.date);
    }

    final sortedDates = dates.toList()..sort((a, b) => b.compareTo(a));
    if (sortedDates.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime.parse(today);

    for (final dateStr in sortedDates) {
      final date = DateTime.parse(dateStr);
      if (date.year == checkDate.year &&
          date.month == checkDate.month &&
          date.day == checkDate.day) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int getMaxStreak() {
    return habits.isEmpty
        ? 0
        : habits.map((h) => getStreak(h.id)).reduce((a, b) => a > b ? a : b);
  }

  int getActiveDays() {
    return completions.map((c) => c.date).toSet().length;
  }

  void addHabit(Habit habit) {
    habits.add(habit);
    _updateHabitNotifications(habit);
    saveData();
    notifyListeners();
  }

  void updateHabit(String id, Habit updated) {
    final index = habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      habits[index] = updated;
      _updateHabitNotifications(updated);
      saveData();
      notifyListeners();
    }
  }

  void deleteHabit(String id) {
    habits.removeWhere((h) => h.id == id);
    completions.removeWhere((c) => c.habitId == id);
    NotificationService().cancelHabitNotifications(id);
    saveData();
    notifyListeners();
  }

  void _updateHabitNotifications(Habit habit) {
    final ns = NotificationService();
    ns.cancelHabitNotifications(habit.id);
    
    if (habit.notif != null && habit.notif!.enabled) {
      ns.scheduleNotification(
        habitId: habit.id,
        habitName: habit.name,
        time: habit.notif!.time,
        days: habit.notif!.days,
        followup: habit.notif!.followup,
        goalMinutes: habit.goalMinutes,
      );
    }
  }
}
