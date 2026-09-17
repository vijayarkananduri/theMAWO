import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/services/notification_service.dart';
import 'package:mawo/theme/app_theme.dart';

class OnboardingTourScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;
  const OnboardingTourScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  final _notificationService = NotificationService();
  int _page = 0;
  String _timezone = 'Asia/Kolkata';
  bool _timezoneConfirmed = false;
  bool? _exactAlarmAllowed;

  final _steps = const [
    ('01', 'BUILD YOUR SIGNAL', 'Add one small daily habit. MAWO learns from consistency, not perfection.'),
    ('02', 'CHECK IN + EVOLVE', 'Tap a habit when it is done. Earn Fragments and watch your interface change.'),
    ('03', 'SET A REMINDER', 'Choose a time inside any habit to get a gentle nudge when it matters.'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAlarmStatus();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAlarmStatus();
  }

  Future<void> _refreshAlarmStatus() async {
    final allowed = await _notificationService.isExactAlarmAllowed();
    if (mounted) setState(() => _exactAlarmAllowed = allowed);
  }

  Future<void> _confirmTimezone(String? value) async {
    if (value == null) return;
    setState(() {
      _timezone = value;
      _timezoneConfirmed = true;
    });
    await context.read<AppState>().setTimeZone(value);
  }

  Future<void> _next() async {
    if (_page < _steps.length) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
      );
    } else if (_timezoneConfirmed && _exactAlarmAllowed == true) {
      await widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bg = dark ? AppTheme.darkBg : AppTheme.lightBg;
    final text = dark ? AppTheme.darkText : AppTheme.lightText;
    final muted = dark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MAWO // FIELD GUIDE',
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 11,
                  color: AppTheme.uiColor,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Make your habits\nalive.',
                style: TextStyle(
                  fontFamily: AppTheme.spaceGrotesk,
                  fontSize: 34,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                  color: text,
                ),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (value) => setState(() => _page = value),
                  itemCount: _steps.length + 1,
                  itemBuilder: (_, index) => index < _steps.length
                      ? _GuidePage(step: _steps[index], text: text, muted: muted)
                      : _SetupPage(
                          text: text,
                          muted: muted,
                          timezone: _timezone,
                          timezoneConfirmed: _timezoneConfirmed,
                          exactAlarmAllowed: _exactAlarmAllowed,
                          onTimezoneChanged: _confirmTimezone,
                          onOpenAlarmSettings: () async {
                            await _notificationService.openExactAlarmSettings();
                          },
                          onRefresh: _refreshAlarmStatus,
                        ),
                ),
              ),
              Row(
                children: List.generate(_steps.length + 1, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    width: index == _page ? 34 : 10,
                    height: 4,
                    color: index == _page ? AppTheme.uiColor : muted,
                  );
                }),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == _steps.length &&
                          (!_timezoneConfirmed || _exactAlarmAllowed != true)
                      ? null
                      : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.uiColor,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: muted,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    shape: const RoundedRectangleBorder(),
                  ),
                  child: Text(
                    _page == _steps.length ? 'ENABLE MAWO REMINDERS' : 'NEXT',
                    style: const TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              if (_page < _steps.length) ...[
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () async => _controller.animateToPage(
                      _steps.length,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                    ),
                    child: Text(
                      'SKIP TOUR — SET UP REMINDERS',
                      style: TextStyle(
                        fontFamily: AppTheme.spaceMono,
                        fontSize: 9,
                        color: muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GuidePage extends StatelessWidget {
  final (String, String, String) step;
  final Color text;
  final Color muted;
  const _GuidePage({required this.step, required this.text, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step.$1, style: const TextStyle(fontFamily: AppTheme.caveat, fontSize: 82, color: AppTheme.uiColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 18),
        Text(step.$2, style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 17, color: text, fontWeight: FontWeight.w700, letterSpacing: .8)),
        const SizedBox(height: 16),
        Text(step.$3, style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 17, height: 1.45, color: muted)),
      ],
    );
  }
}

class _SetupPage extends StatelessWidget {
  final Color text;
  final Color muted;
  final String timezone;
  final bool timezoneConfirmed;
  final bool? exactAlarmAllowed;
  final ValueChanged<String?> onTimezoneChanged;
  final VoidCallback onOpenAlarmSettings;
  final VoidCallback onRefresh;

  const _SetupPage({
    required this.text,
    required this.muted,
    required this.timezone,
    required this.timezoneConfirmed,
    required this.exactAlarmAllowed,
    required this.onTimezoneChanged,
    required this.onOpenAlarmSettings,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('04', style: TextStyle(fontFamily: AppTheme.caveat, fontSize: 82, color: AppTheme.uiColor, fontWeight: FontWeight.w700)),
          Text('REMINDER SETUP', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 17, color: text, fontWeight: FontWeight.w700, letterSpacing: .8)),
          const SizedBox(height: 12),
          Text('Confirm your timezone and allow exact alarms. Without both, MAWO cannot reliably trigger reminders.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 16, height: 1.4, color: muted)),
          const SizedBox(height: 24),
          Text('TIMEZONE', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: timezone,
            dropdownColor: Theme.of(context).cardColor,
            items: const [
              DropdownMenuItem(value: 'Asia/Kolkata', child: Text('Asia/Kolkata — IST (UTC+05:30)')),
              DropdownMenuItem(value: 'UTC', child: Text('UTC — Coordinated Universal Time')),
              DropdownMenuItem(value: 'Asia/Dubai', child: Text('Asia/Dubai — GST (UTC+04:00)')),
              DropdownMenuItem(value: 'Europe/London', child: Text('Europe/London')),
              DropdownMenuItem(value: 'America/New_York', child: Text('America/New_York')),
            ],
            onChanged: onTimezoneChanged,
          ),
          const SizedBox(height: 10),
          Text(timezoneConfirmed ? '✓ Timezone confirmed' : 'Select and confirm a timezone to continue.', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 9, color: timezoneConfirmed ? Colors.green : muted)),
          const SizedBox(height: 22),
          Text('ALARMS & REMINDERS', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: muted, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(exactAlarmAllowed == true ? '✓ Allowed — exact reminders can be scheduled.' : 'Not allowed — Android special access is required.', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, height: 1.5, color: exactAlarmAllowed == true ? Colors.green : Colors.orange)),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: onOpenAlarmSettings, child: const Text('OPEN ALARMS & REMINDERS SETTINGS'))),
          TextButton(onPressed: onRefresh, child: const Text('I ALLOWED IT — CHECK AGAIN')),
        ],
      ),
    );
  }
}
