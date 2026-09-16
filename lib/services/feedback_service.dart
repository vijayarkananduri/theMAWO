import 'package:flutter/services.dart';

/// Small, centralized feedback vocabulary so haptics remain meaningful and
/// can be disabled globally without changing individual widgets.
class FeedbackService {
  const FeedbackService._();

  static Future<void> selection({required bool enabled}) async {
    if (enabled) await HapticFeedback.selectionClick();
  }

  static Future<void> completion({required bool enabled}) async {
    if (enabled) await HapticFeedback.lightImpact();
  }

  static Future<void> milestone({required bool enabled}) async {
    if (enabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> warning({required bool enabled}) async {
    if (enabled) await HapticFeedback.heavyImpact();
  }
}

class CompletionResult {
  final bool completed;
  final int fragmentsDelta;
  final int xpDelta;
  final int currentStreak;
  final bool badgeUnlocked;
  final bool phaseChanged;
  final bool dailyCycleComplete;
  final String? badgeId;

  const CompletionResult({
    required this.completed,
    required this.fragmentsDelta,
    required this.xpDelta,
    required this.currentStreak,
    required this.badgeUnlocked,
    required this.phaseChanged,
    required this.dailyCycleComplete,
    this.badgeId,
  });
}
