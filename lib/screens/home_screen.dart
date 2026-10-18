import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/models/habit.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/screens/habits_screen.dart';
import 'package:mawo/screens/logs_screen.dart';
import 'package:mawo/screens/badges_screen.dart';
import 'package:mawo/screens/stats_screen.dart';
import 'package:mawo/screens/settings_screen.dart';
import 'package:mawo/services/feedback_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const HabitsScreen(),
    const LogsScreen(),
    const BadgesScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLevel = context.watch<AppState>().level;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1500),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween<double>(begin: 1.0, end: 1.02).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: KeyedSubtree(
          key: ValueKey('level-$currentLevel-$_currentIndex'),
          child: _currentIndex == 0
              ? HomeContent(onAddHabit: () => setState(() => _currentIndex = 1))
              : _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            FeedbackService.selection(
              enabled: context.read<AppState>().hapticsEnabled,
            );
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: bgColor,
          selectedItemColor: AppTheme.uiColor,
          unselectedItemColor: isDark ? AppTheme.darkMuted : AppTheme.lightMuted,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          selectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 9,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_outlined),
              activeIcon: Icon(Icons.list),
              label: 'HABITS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'LOGS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_outlined),
              activeIcon: Icon(Icons.emoji_events),
              label: 'BADGES',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'STATS',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'SETTINGS',
            ),
          ],
        ),
      ),
    );
  }
}

class HomeContent extends StatelessWidget {
  final VoidCallback? onAddHabit;
  const HomeContent({Key? key, this.onAddHabit}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final visual = MawoVisualState(phase: appState.phaseIndex, level: appState.level, dark: isDark);
        final bgColor = visual.background;
        final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (notification) {
            if (notification.scrollDelta != null &&
                notification.scrollDelta!.abs() > 18) {
              FeedbackService.selection(enabled: appState.hapticsEnabled);
            }
            return false;
          },
          child: CustomScrollView(
            slivers: [
            SliverAppBar(
              title: const Text(
                'MAWO',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              backgroundColor: bgColor,
              floating: true,
              snap: true,
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      _dayGreeting(appState),
                      style: TextStyle(
                        fontFamily: AppTheme.spaceMono,
                        fontSize: 10,
                        color: muteColor,
                        letterSpacing: 0.07,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phase Card
                    PhaseCard(appState: appState),
                    const SizedBox(height: 20),

                    // Home Glyph
                    GlyphStrip(appState: appState),
                    const SizedBox(height: 20),

                    // Stats Row
                    StatsRow(appState: appState),
                    const SizedBox(height: 20),

                    // Daily Habits
                    HabitsList(appState: appState, type: 'daily', onAddHabit: onAddHabit),
                    const SizedBox(height: 20),

                    // One-time Tasks
                    HabitsList(appState: appState, type: 'onetime', onAddHabit: onAddHabit),
                  ],
                ),
              ),
            ),
            ],
          ),
        );
      },
    );
  }

  String _dayGreeting(AppState appState) {
    final hour = DateTime.now().hour;
    final period = hour < 12
        ? 'GOOD MORNING'
        : hour < 18
            ? 'GOOD AFTERNOON'
            : 'GOOD EVENING';
    final name = (appState.user['name'] as String? ?? '').trim();
    return name.isEmpty
        ? '// $period. Let\'s make your habits alive.'
        : '// $period, ${name.toUpperCase()}. Let\'s make your habits alive.';
  }
}

class PhaseCard extends StatelessWidget {
  final AppState appState;

  const PhaseCard({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visual = MawoVisualState(phase: appState.phaseIndex, level: appState.level, dark: isDark);
    final borderColor = visual.accent.withOpacity(0.35);
    final surfaceColor = visual.surface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
    final dimColor = isDark ? AppTheme.darkDim : AppTheme.lightDim;

    final phaseNames = ['Fresh Soul', 'Warm Ember', 'Radiant Core', 'Deep Aura', 'Eclipse King'];
    final phases = List.generate(5, (i) => {'num': i + 1, 'name': phaseNames[i], 'min': appState.phaseThresholds[i]});

    int currentPhaseIdx = 0;
    for (int i = phases.length - 1; i >= 0; i--) {
      if (appState.totalFragments >= (phases[i]['min'] as int)) {
        currentPhaseIdx = i;
        break;
      }
    }

    final phase = phases[currentPhaseIdx];
    final nextPhase =
        currentPhaseIdx < phases.length - 1 ? phases[currentPhaseIdx + 1] : null;

    double progress = nextPhase != null
        ? (appState.totalFragments - (phase['min'] as int)) /
            ((nextPhase['min'] as int) - (phase['min'] as int))
        : 1.0;
    progress = progress.clamp(0.0, 1.0).toDouble();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: surfaceColor,
        borderRadius: BorderRadius.circular(visual.radius),
        boxShadow: visual.shadows,
        gradient: LinearGradient(
          begin: visual.warmthOrigin,
          end: Alignment(-visual.warmthOrigin.x, -visual.warmthOrigin.y),
          colors: [visual.accent.withOpacity(0.12), surfaceColor, surfaceColor],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PHASE 0${phase['num']} //',
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 9,
                      color: visual.accent,
                      letterSpacing: 0.12,
                    ),
                  ),
                  Text(
                    phase['name'] as String,
                    style: TextStyle(
                      fontFamily: AppTheme.spaceGrotesk,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    appState.totalFragments.toString(),
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: visual.accent,
                    ),
                  ),
                  Text(
                    'fragments',
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 9,
                      color: muteColor,
                    ),
                  ),
                  Text(
                    '${appState.totalXP} XP',
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 9,
                      color: muteColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppTheme.darkDim : AppTheme.lightDim,
              valueColor: AlwaysStoppedAnimation<Color>(visual.accent),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nextPhase != null
                    ? '${appState.totalFragments} / ${nextPhase['min']} to ${nextPhase['name']}'
                    : 'MAX PHASE REACHED',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 8,
                  color: dimColor,
                  letterSpacing: 0.06,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 8,
                  color: dimColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class GlyphStrip extends StatelessWidget {
  final AppState appState;

  const GlyphStrip({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    final habits = appState.habits.where((h) => h.type == 'daily').toList();
    final itemCount = habits.isNotEmpty ? habits.length : 24;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              habits.isNotEmpty ? 'HABIT GLYPHS //' : 'PHASE INTENSITY //',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontSize: 9,
                color: muteColor,
                letterSpacing: 0.1,
              ),
            ),
            Text(
              '${appState.getTodayCompletions().where((c) => habits.any((h) => h.id == c.habitId)).length} / ${habits.length} done',
              style: const TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontSize: 9,
                color: AppTheme.uiColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(itemCount, (i) {
            bool isDone = false;
            if (habits.isNotEmpty) {
              isDone = appState.isCompletedToday(habits[i].id);
            } else {
              isDone = i < appState.totalFragments;
            }

            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: isDone ? AppTheme.uiColor : Colors.transparent,
                border: Border.all(
                  color: isDone ? AppTheme.uiColor : borderColor,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: habits.isNotEmpty
                  ? Center(
                      child: Text(
                        habits[i].name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                          color: isDone ? Colors.black : borderColor,
                        ),
                      ),
                    )
                  : null,
            );
          }),
        ),
      ],
    );
  }
}

class StatsRow extends StatelessWidget {
  final AppState appState;

  const StatsRow({Key? key, required this.appState}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: surfaceColor,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              value: appState.totalFragments.toString(),
              label: 'Fragments',
            ),
          ),
          Container(width: 1, height: 60, color: borderColor),
          Expanded(
            child: _StatCell(
              value: appState
                  .getTodayCompletions()
                  .length
                  .toString(),
              label: 'Today',
            ),
          ),
          Container(width: 1, height: 60, color: borderColor),
          Expanded(
            child: _StatCell(
              value: appState.totalCompletions.toString(),
              label: 'Data Collected',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({
    Key? key,
    required this.value,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.spaceMono,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.uiColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.spaceMono,
              fontSize: 7,
              color: muteColor,
              letterSpacing: 0.08,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
        ],
      ),
    );
  }
}

class HabitsList extends StatelessWidget {
  final AppState appState;
  final String type;
  final VoidCallback? onAddHabit;

  const HabitsList({
    Key? key,
    required this.appState,
    required this.type,
    this.onAddHabit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
    final habits = appState.habits.where((h) => h.type == type).toList();

    if (habits.isEmpty && type == 'onetime') return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type == 'daily' ? 'DAILY HABITS //' : 'ONE-TIME TASKS //',
          style: TextStyle(
            fontFamily: AppTheme.spaceMono,
            fontSize: 9,
            color: muteColor,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 12),
        if (habits.isEmpty)
          GestureDetector(
            onTap: onAddHabit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.uiColor.withOpacity(0.55)),
                color: AppTheme.uiColor.withOpacity(0.05),
              ),
              child: const Column(
                children: [
                  Icon(Icons.add, color: AppTheme.uiColor, size: 22),
                  SizedBox(height: 8),
                  Text('TAP TO ADD A HABIT', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: AppTheme.uiColor, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: habits.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) => HabitItem(
              habit: habits[index],
              isCompleted: appState.isCompletedToday(habits[index].id),
              onToggle: () => appState.toggleHabit(habits[index].id, type),
            ),
          ),
      ],
    );
  }
}

class HabitItem extends StatefulWidget {
  final Habit habit;
  final bool isCompleted;
  final CompletionResult Function() onToggle;

  const HabitItem({
    Key? key,
    required this.habit,
    required this.isCompleted,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<HabitItem> createState() => _HabitItemState();
}

class _HabitItemState extends State<HabitItem> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    final result = widget.onToggle();
    final appState = context.read<AppState>();
    await FeedbackService.selection(enabled: appState.hapticsEnabled);
    if (result.completed) {
      if (appState.completionFxEnabled) _controller.forward(from: 0);
      await FeedbackService.completion(enabled: appState.hapticsEnabled);
      if (result.badgeUnlocked || result.phaseChanged || result.dailyCycleComplete) {
        await FeedbackService.milestone(enabled: appState.hapticsEnabled);
      }
      if (!mounted || !appState.completionFxEnabled) return;
      final message = result.phaseChanged
          ? '// Phase shifted. The world is changing.'
          : result.badgeUnlocked
              ? '// New mark acquired: ${result.badgeId}'
              : result.dailyCycleComplete
                  ? '// Daily cycle complete. All signals received.'
                  : '+1 fragment  ·  +${result.xpDelta} XP  // warmth growing';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1800),
          action: SnackBarAction(label: 'UNDO', onPressed: _handleToggle),
        ),
      );
    } else {
      await FeedbackService.warning(enabled: appState.hapticsEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final appState = context.read<AppState>();
    final visual = MawoVisualState(phase: appState.phaseIndex, level: appState.level, dark: isDark);
    final borderColor = visual.accent.withOpacity(0.35);
    final surfaceColor = visual.surface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return GestureDetector(
      onTap: _handleToggle,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1, end: 1.025).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
        ),
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.isCompleted ? Color.alphaBlend(AppTheme.uiColor.withOpacity(0.08), surfaceColor) : surfaceColor,
          border: Border.all(
            color: widget.isCompleted ? AppTheme.uiColor : borderColor,
            width: widget.isCompleted ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(visual.radius),
          boxShadow: widget.isCompleted ? [BoxShadow(color: visual.accent.withOpacity(0.32), blurRadius: 12)] : visual.shadows,
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: widget.isCompleted ? AppTheme.uiColor : Colors.transparent,
                border: Border.all(
                  color: widget.isCompleted ? AppTheme.uiColor : borderColor,
                ),
              ),
              child: widget.isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.habit.name.toUpperCase(),
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: widget.isCompleted ? visual.accent : textColor,
                      decoration: widget.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  if (widget.habit.goalMinutes > 0)
                    Text(
                      'GOAL: ${widget.habit.goalMinutes} MIN',
                      style: TextStyle(
                        fontFamily: AppTheme.spaceMono,
                        fontSize: 8,
                        color: muteColor,
                      ),
                    ),
                ],
              ),
            ),
            if (widget.isCompleted)
              Text(
                '+1 ◆',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 10,
                  color: visual.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }
}
