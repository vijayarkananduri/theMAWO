import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
        final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
        final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
        final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;
        final dimColor = isDark ? AppTheme.darkDim : AppTheme.lightDim;
        final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

        // Chart data
        final days = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];
        final d7 = <String>[];
        for (int i = 6; i >= 0; i--) {
          final d = DateTime.now().subtract(Duration(days: i));
          d7.add(d.toString().split(' ')[0]);
        }
        final counts =
            d7.map((d) => appState.completions.where((c) => c.date == d).length)
                .toList();
        final max = counts.isEmpty || counts.every((c) => c == 0)
            ? 1
            : counts.reduce((a, b) => a > b ? a : b);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'ANALYTICS',
              style: TextStyle(
                fontFamily: AppTheme.spaceMono,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
            backgroundColor: bgColor,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 7-Day Chart
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    color: surfaceColor,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '7-DAY COMPLETION //',
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 9,
                          color: AppTheme.uiColor,
                          letterSpacing: 0.14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 80,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(7, (i) {
                            final h = (counts[i] / max * 60).toInt();
                            return Expanded(
                              child: Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    height: h.toDouble().clamp(3, 60).toDouble(),
                                    color: AppTheme.uiColor,
                                  ),
                                  Text(
                                    days[DateTime.parse(d7[i]).weekday % 7],
                                    style: TextStyle(
                                      fontFamily: AppTheme.spaceMono,
                                      fontSize: 8,
                                      color: dimColor,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Weekly message
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                    color: surfaceColor,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Hey ${appState.user['name'].isEmpty ? 'there' : appState.user['name']}!\n\n// ${_getWeeklyMessage(appState)}',
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 11,
                      color: muteColor,
                      height: 1.85,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatMini(
                      value: appState.totalCompletions.toString(),
                      label: 'TOTAL COMPLETIONS',
                    ),
                    _StatMini(
                      value: appState.badges.length.toString(),
                      label: 'BADGES EARNED',
                    ),
                    _StatMini(
                      value: appState.longestStreak.toString(),
                      label: 'LONGEST STREAK',
                    ),
                    _StatMini(
                      value: appState.daysActive.toString(),
                      label: 'DAYS ACTIVE',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getWeeklyMessage(AppState appState) {
    final dh = appState.habits.where((h) => h.type == 'daily').toList();
    final dids = appState.getTodayCompletions().map((c) => c.habitId).toSet();
    final done = dh.where((h) => dids.contains(h.id)).length;

    if (done == 0) return 'No completions yet.\n// Every journey starts with one step.';
    if (done == dh.length && dh.isNotEmpty) {
      return 'All $done/${dh.length} done.\n// System at 100%. You showed up.';
    }
    return '$done of ${dh.length} done today.\n// Keep going.';
  }
}

class _StatMini extends StatelessWidget {
  final String value;
  final String label;

  const _StatMini({Key? key, required this.value, required this.label})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        color: surfaceColor,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontFamily: AppTheme.spaceMono,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.uiColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTheme.spaceMono,
              fontSize: 8,
              color: muteColor,
              letterSpacing: 0.08,
            ),
          ),
        ],
      ),
    );
  }
}
