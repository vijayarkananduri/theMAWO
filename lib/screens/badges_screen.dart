import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({Key? key}) : super(key: key);

  static const List<Map<String, dynamic>> badges = [
    {
      'id': 'first',
      'sym': '◆',
      'name': 'First Spark',
      'desc': 'Complete your first habit'
    },
    {
      'id': 'week',
      'sym': '▲',
      'name': 'Week Warrior',
      'desc': '7-day streak'
    },
    {
      'id': 'f100',
      'sym': '⬡',
      'name': 'Frag Hunter',
      'desc': 'Earn 100 fragments'
    },
    {
      'id': 'ph2',
      'sym': '▶',
      'name': 'Phase Shifter',
      'desc': 'Reach Warm Ember'
    },
    {
      'id': 'ph3',
      'sym': '✦',
      'name': 'Radiant',
      'desc': 'Reach Radiant Core'
    },
    {
      'id': 'ph4',
      'sym': '◉',
      'name': 'Deep Aura',
      'desc': 'Reach Deep Aura'
    },
    {
      'id': 'ph5',
      'sym': '●',
      'name': 'Eclipse King',
      'desc': 'Reach Eclipse King'
    },
    {
      'id': 'thirty',
      'sym': '▣',
      'name': 'Dedicated',
      'desc': 'Active 30 days'
    },
  ];

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

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'BADGES',
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
                Text(
                  '// Complete habits consistently to unlock.\n// Every milestone has a mark.',
                  style: TextStyle(
                    fontFamily: AppTheme.spaceMono,
                    fontSize: 10,
                    color: muteColor,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: badges.map((badge) {
                    final earned = appState.badges.contains(badge['id']);
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: earned ? AppTheme.uiColor : borderColor,
                        ),
                        color: surfaceColor,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            badge['sym'],
                            style: TextStyle(
                              fontFamily: AppTheme.spaceMono,
                              fontSize: 22,
                              color: earned
                                  ? AppTheme.uiColor
                                  : dimColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            badge['name'].toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.spaceMono,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge['desc'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: AppTheme.spaceMono,
                              fontSize: 8,
                              color: muteColor,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (earned)
                            const Text(
                              '✓ EARNED',
                              style: TextStyle(
                                fontFamily: AppTheme.spaceMono,
                                fontSize: 8,
                                color: AppTheme.uiColor,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else
                            Text(
                              '// LOCKED',
                              style: TextStyle(
                                fontFamily: AppTheme.spaceMono,
                                fontSize: 8,
                                color: dimColor,
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
