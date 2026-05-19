import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({Key? key}) : super(key: key);

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

        final sorted = [...appState.completions]
          ..sort((a, b) => b.date.compareTo(a.date));

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'LOGS',
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
          body: sorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '[ ]',
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 18,
                          color: dimColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'NO COMPLETIONS YET',
                        style: TextStyle(
                          fontFamily: AppTheme.spaceMono,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: muteColor,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: sorted.length,
                  itemBuilder: (context, index) {
                    final completion = sorted[index];
                    final habit = appState.habits.firstWhere(
                      (h) => h.id == completion.habitId,
                      orElse: () => throw Exception('Habit not found'),
                    );

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: borderColor),
                        color: surfaceColor,
                      ),
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                habit.name.toUpperCase(),
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${completion.date} · ${habit.category.toUpperCase()}',
                                style: TextStyle(
                                  fontFamily: AppTheme.spaceMono,
                                  fontSize: 9,
                                  color: muteColor,
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            '+1 ◆',
                            style: TextStyle(
                              fontFamily: AppTheme.spaceMono,
                              fontSize: 11,
                              color: AppTheme.uiColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
