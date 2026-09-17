import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/screens/boot_screen.dart';
import 'package:mawo/screens/home_screen.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService();
  await notificationService.initializeNotifications();

  final appState = AppState();
  await appState.loadData();
  await notificationService.rescheduleHabits(appState.habits);

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
          home: BootScreen(
            onComplete: () => _navigatorKey.currentState?.pushReplacementNamed('/home'),
          ),
          routes: {
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
