import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:mawo/models/habit.dart';
import 'package:mawo/services/notification_service.dart';
import 'package:mawo/services/feedback_service.dart';

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal();

  List<Habit> habits = [];
  List<Completion> completions = [];
  Map<String, dynamic> user = {'name': '', 'createdAt': DateTime.now().millisecondsSinceEpoch};
  Map<String, dynamic> settings = {
    'eodEnabled': false,
    'eodTime': '21:00',
    'isDark': true,
    'timezone': 'UTC',
    'clockReference': null,
    'clockDeviceMillis': null,
    'hapticsEnabled': true,
    'completionFxEnabled': true,
  };
  int totalFragments = 0;
  int totalXP = 0;
  int level = 1;
  List<String> badges = [];
  int totalCompletions = 0;
  int longestStreak = 0;
  int daysActive = 0;
  late SharedPreferences _prefs;
  bool hasSeenIntro = false;
  bool hasSeenTour = false;

  bool get onboardingComplete => hasSeenIntro && hasSeenTour;

  List<int> get phaseThresholds {
    final habits = this.habits.where((h) => h.type == 'daily').length;
    if (habits == 0) return [0, 1, 2, 3, 4];
    return List.generate(5, (index) => index == 0 ? 0 : habits * 30 * (index * (index + 1) ~/ 2));
  }
  bool get hapticsEnabled => settings['hapticsEnabled'] ?? true;
  bool get completionFxEnabled => settings['completionFxEnabled'] ?? true;

  int get phaseIndex {
    for (var i = phaseThresholds.length - 1; i >= 0; i--) {
      if (totalFragments >= phaseThresholds[i]) return i;
    }
    return 0;
  }

  Future<void> loadData() async {
    _prefs = await SharedPreferences.getInstance();
    hasSeenIntro = _prefs.getBool('mawo_intro_seen') ?? false;
    hasSeenTour = _prefs.getBool('mawo_tour_seen') ?? false;
    final json = _prefs.getString('mawo_data');
    if (json != null) {
      try {
        final data = jsonDecode(json);
        habits = (data['habits'] as List).map((h) => Habit.fromJson(h)).toList();
        completions = (data['completions'] as List).map((c) => Completion.fromJson(c)).toList();
        user = data['user'] ?? user;
        settings = {...settings, ...Map<String, dynamic>.from(data['settings'] ?? {})};
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
    final notificationService = NotificationService();
    await notificationService.initializeNotifications(location: settings['timezone'] ?? 'UTC');
    try {
      await rescheduleAllNotifications();
      if (settings['eodEnabled'] == true) {
        await notificationService.scheduleEndOfDayReminder(time: settings['eodTime'] ?? '21:00');
      }
    } catch (e) {
      debugPrint('Notification restore skipped: $e');
    }
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    hasSeenIntro = true;
    await _prefs.setBool('mawo_intro_seen', true);
    notifyListeners();
  }

  Future<void> completeTour() async {
    hasSeenTour = true;
    await _prefs.setBool('mawo_tour_seen', true);
    notifyListeners();
  }

  Future<void> rescheduleAllNotifications() async {
    if (!NotificationService.enabled) return;
    final service = NotificationService();
    for (final habit in habits) {
      try {
        await service.cancelHabitNotifications(habit.id);
        if (habit.notif?.enabled == true) {
        final oneTimeDate = habit.type == 'onetime' && habit.notif!.date != null
            ? DateTime.tryParse(habit.notif!.date!)
            : null;
        final scheduledDelay = _delayUntilReminder(habit);
        await service.scheduleNotification(
          habitId: habit.id,
          habitName: habit.name,
          time: habit.notif!.time,
          days: habit.notif!.days,
          followup: habit.notif!.followup,
          goalMinutes: habit.goalMinutes,
          category: habit.category,
          oneTimeDate: oneTimeDate,
          delay: scheduledDelay,
          isOneTime: habit.type == 'onetime',
        );
        }
      } catch (e) {
        debugPrint('Reminder restore failed for ${habit.name}: $e');
      }
    }
  }

  String exportData() => jsonEncode({
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
      });

  Future<void> importData(String json) async {
    try {
      final data = jsonDecode(json);
      habits = (data['habits'] as List).map((h) => Habit.fromJson(h)).toList();
      completions = (data['completions'] as List).map((c) => Completion.fromJson(c)).toList();
      user = data['user'] ?? user;
      settings = {...settings, ...Map<String, dynamic>.from(data['settings'] ?? {})};
      totalFragments = data['tf'] ?? 0;
      totalXP = data['xp'] ?? 0;
      level = data['level'] ?? 1;
      badges = List<String>.from(data['badges'] ?? []);
      totalCompletions = data['tc'] ?? 0;
      longestStreak = data['ls'] ?? 0;
      daysActive = data['da'] ?? 0;
      await saveData();
      await rescheduleAllNotifications();
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
  bool isCompletedToday(String habitId) => completions.any((c) => c.habitId == habitId && c.date == today);
  List<Completion> getTodayCompletions() => completions.where((c) => c.date == today).toList();

  void setUserName(String name) { user['name'] = name; saveData(); notifyListeners(); }
  Future<void> setEODSettings(bool enabled, [String? time]) async {
    settings['eodEnabled'] = enabled;
    if (time != null) settings['eodTime'] = time;
    final service = NotificationService();
    try {
      if (enabled) {
        await service.scheduleEndOfDayReminder(time: settings['eodTime']);
      } else {
        await service.cancelEndOfDayReminder();
      }
    } catch (e) {
      debugPrint('End-of-day reminder update failed: $e');
      rethrow;
    }
    await saveData();
    notifyListeners();
  }
  Future<void> setTimeZone(String location) async {
    settings['timezone'] = location;
    NotificationService().setTimeZone(location);
    await rescheduleAllNotifications();
    await saveData();
    notifyListeners();
  }
  void toggleTheme() { settings['isDark'] = !(settings['isDark'] ?? true); saveData(); notifyListeners(); }
  void setFeedbackSettings({bool? haptics, bool? completionFx}) { if (haptics != null) settings['hapticsEnabled'] = haptics; if (completionFx != null) settings['completionFxEnabled'] = completionFx; saveData(); notifyListeners(); }

  Future<void> eraseAllData() async {
    for (final habit in habits) {
      await NotificationService().cancelHabitNotifications(habit.id);
    }
    await NotificationService().cancelEndOfDayReminder();
    habits = [];
    completions = [];
    user = {'name': '', 'createdAt': DateTime.now().millisecondsSinceEpoch};
    settings = {'eodEnabled': false, 'eodTime': '21:00', 'isDark': true, 'timezone': 'UTC', 'clockReference': null, 'clockDeviceMillis': null, 'hapticsEnabled': true, 'completionFxEnabled': true};
    totalFragments = 0; totalXP = 0; level = 1; badges = []; totalCompletions = 0; longestStreak = 0; daysActive = 0;
    await _prefs.remove('mawo_data');
    notifyListeners();
  }

  CompletionResult toggleHabit(String habitId, String type) {
    final wasCompleted = isCompletedToday(habitId);
    final previousPhase = phaseIndex;
    var xpDelta = 0;
    String? badgeId;
    if (wasCompleted) {
      completions.removeWhere((c) => c.habitId == habitId && c.date == today);
      totalFragments = (totalFragments - 1).clamp(0, double.infinity).toInt();
      xpDelta = -(type == 'daily' ? 2 : 1);
      totalXP = (totalXP + xpDelta).clamp(0, double.infinity).toInt();
      totalCompletions = (totalCompletions - 1).clamp(0, double.infinity).toInt();
    } else {
      completions.add(Completion(habitId: habitId, date: today));
      totalFragments++;
      xpDelta = type == 'daily' ? 2 : 1;
      if (getStreak(habitId) >= 3) xpDelta++;
      totalXP += xpDelta;
      totalCompletions++;
    }
    level = ((totalXP ~/ 100) + 1).clamp(1, 10).toInt();
    longestStreak = getMaxStreak();
    daysActive = getActiveDays();
    if (!wasCompleted) badgeId = _awardBadgeIfNeeded();
    saveData();
    notifyListeners();
    final dailyHabits = habits.where((h) => h.type == 'daily').toList();
    return CompletionResult(
      completed: !wasCompleted,
      fragmentsDelta: wasCompleted ? -1 : 1,
      xpDelta: xpDelta,
      currentStreak: getStreak(habitId),
      badgeUnlocked: badgeId != null,
      badgeId: badgeId,
      phaseChanged: phaseIndex != previousPhase,
      dailyCycleComplete: dailyHabits.isNotEmpty && dailyHabits.every((h) => isCompletedToday(h.id)),
    );
  }

  String? _awardBadgeIfNeeded() {
    final candidates = <String>[];
    if (totalCompletions >= 1) candidates.add('first');
    if (longestStreak >= 7) candidates.add('week');
    if (totalFragments >= 100) candidates.add('f100');
    if (phaseIndex >= 1) candidates.add('ph2');
    if (phaseIndex >= 2) candidates.add('ph3');
    if (phaseIndex >= 3) candidates.add('ph4');
    if (phaseIndex >= 4) candidates.add('ph5');
    if (daysActive >= 30) candidates.add('thirty');
    for (final id in candidates) { if (!badges.contains(id)) { badges.add(id); return id; } }
    return null;
  }

  int getStreak(String habitId) {
    final dates = completions.where((c) => c.habitId == habitId).map((c) => c.date).toSet().toList()..sort((a, b) => b.compareTo(a));
    if (dates.isEmpty) return 0;
    var streak = 0;
    var checkDate = DateTime.parse(today);
    for (final dateStr in dates) {
      final date = DateTime.parse(dateStr);
      if (date.year == checkDate.year && date.month == checkDate.month && date.day == checkDate.day) { streak++; checkDate = checkDate.subtract(const Duration(days: 1)); } else { break; }
    }
    return streak;
  }

  int getMaxStreak() => habits.isEmpty ? 0 : habits.map((h) => getStreak(h.id)).reduce((a, b) => a > b ? a : b);
  int getActiveDays() => completions.map((c) => c.date).toSet().length;
  void addHabit(Habit habit) {
    habits.add(habit);
    _updateHabitNotifications(habit);
    saveData();
    notifyListeners();
  }
  void updateHabit(String id, Habit updated) { final index = habits.indexWhere((h) => h.id == id); if (index != -1) { habits[index] = updated; _updateHabitNotifications(updated); saveData(); notifyListeners(); } }
  void deleteHabit(String id) {
    NotificationService().cancelHabitNotifications(id);
    habits.removeWhere((h) => h.id == id);
    completions.removeWhere((c) => c.habitId == id);
    saveData();
    notifyListeners();
  }
  Future<void> _updateHabitNotifications(Habit habit) async {
    if (!NotificationService.enabled) return;
    final ns = NotificationService();
    try {
      await ns.cancelHabitNotifications(habit.id);
      if (habit.notif?.enabled == true) {
      DateTime? oneTimeDate;
      if (habit.type == 'onetime' && habit.notif!.date != null) {
        oneTimeDate = DateTime.tryParse(habit.notif!.date!);
      }
      await ns.scheduleNotification(
        habitId: habit.id,
        habitName: habit.name,
        time: habit.notif!.time,
        days: habit.notif!.days,
        followup: habit.notif!.followup,
        goalMinutes: habit.goalMinutes,
        category: habit.category,
        oneTimeDate: oneTimeDate,
        delay: _delayUntilReminder(habit),
        isOneTime: habit.type == 'onetime',
      );
      }
    } catch (e) {
      debugPrint('Reminder scheduling failed for ${habit.name}: $e');
    }
  }

  Duration? _delayUntilReminder(Habit habit) {
    final calibrated = calibratedClock;
    if (calibrated == null || habit.notif == null) return null;
    final parts = habit.notif!.time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    DateTime target;
    if (habit.type == 'onetime' && habit.notif!.date != null) {
      final date = DateTime.tryParse(habit.notif!.date!);
      if (date == null) return null;
      target = DateTime(date.year, date.month, date.day, hour, minute);
    } else {
      target = calibrated;
      for (var offset = 0; offset <= 7; offset++) {
        final candidate = calibrated.add(Duration(days: offset));
        final sundayBased = candidate.weekday == DateTime.sunday ? 0 : candidate.weekday;
        if (habit.notif!.days.contains(sundayBased)) {
          final possible = DateTime(candidate.year, candidate.month, candidate.day, hour, minute);
          if (possible.isAfter(calibrated)) { target = possible; break; }
        }
      }
    }
    final delay = target.difference(calibrated);
    return delay.isNegative ? null : delay;
  }

  Future<void> calibrateClock(DateTime userNow) async {
    settings['clockReference'] = userNow.toIso8601String();
    settings['clockDeviceMillis'] = DateTime.now().millisecondsSinceEpoch;
    await saveData();
    notifyListeners();
  }

  DateTime? get calibratedClock {
    final reference = settings['clockReference'];
    final deviceMillis = settings['clockDeviceMillis'];
    if (reference is! String || deviceMillis is! int) return null;
    final base = DateTime.tryParse(reference);
    if (base == null) return null;
    final elapsed = DateTime.now().millisecondsSinceEpoch - deviceMillis;
    return base.add(Duration(milliseconds: elapsed));
  }

  Future<void> notifyHabitCreated(Habit habit) async {
    await NotificationService().showHabitCreatedNotification(habit.name);
  }
}
