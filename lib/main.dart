import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/screens/boot_screen.dart';
import 'package:mawo/screens/home_screen.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/services/notification_service.dart';
import 'package:mawo/screens/onboarding_tour_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  // Notification permissions and exact-alarm support vary by Android version.
  // They must never prevent Flutter from rendering the app on a cold start.
  try {
    await notificationService.initializeNotifications();
  } catch (e) {
    debugPrint('MAWO notification initialization skipped: $e');
  }

  final appState = AppState();
  try {
    await appState.loadData();
  } catch (e) {
    debugPrint('MAWO data restore skipped: $e');
  }

  runApp(
    ChangeNotifierProvider<AppState>(
      create: (_) => appState,
      child: const MAWOApp(),
    ),
  );
}

class MAWOApp extends StatefulWidget {
  const MAWOApp({Key? key}) : super(key: key);

  @override
  State<MAWOApp> createState() => _MAWOAppState();
}

class _MAWOAppState extends State<MAWOApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isDark = appState.settings['isDark'] ?? true;
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'MAWO — Your Habits, Alive.',
          debugShowCheckedModeBanner: false,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          home: !appState.hasSeenIntro
              ? BootScreen(
                  hapticsEnabled: appState.hapticsEnabled,
                  onComplete: () async {
                    await appState.completeOnboarding();
                    if (mounted) {
                      _navigatorKey.currentState?.pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => OnboardingTourScreen(
                            onComplete: () async {
                              await appState.completeTour();
                              if (mounted) {
                                _navigatorKey.currentState?.pushReplacementNamed('/home');
                              }
                            },
                          ),
                        ),
                      );
                    }
                  },
                )
              : !appState.hasSeenTour
                  ? OnboardingTourScreen(
                      onComplete: () async {
                        await appState.completeTour();
                        if (mounted) {
                          _navigatorKey.currentState?.pushReplacementNamed('/home');
                        }
                      },
                    )
                  : const HomeScreen(),
          routes: {
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
