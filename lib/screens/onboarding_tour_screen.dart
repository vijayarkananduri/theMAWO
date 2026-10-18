import 'package:flutter/material.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/services/feedback_service.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:provider/provider.dart';

class OnboardingTourScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;
  const OnboardingTourScreen({Key? key, this.onComplete}) : super(key: key);

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen> {
  final _controller = PageController();
  int _page = 0;

  final _steps = const [
    ('01', 'TAP THE ITCH', 'When the urge shows up, log it without judgment. The point is not perfection — it is creating one clear moment between feeling and action.'),
    ('02', 'SURF THE WAVE', 'Breathe with a gentle 90-second timer. The peak passes. You can skip the timer whenever you need to.'),
    ('03', 'PICK ONE SMALL ACTION', 'Choose water, a walk, breathing, reading, or another habit that feels kind and doable right now.'),
    ('04', 'SEE YOUR MOMENTUM', 'MAWO keeps your data on-device and turns completed interruptions into evidence of growth, never a grade.'),
  ];

  Future<void> _next() async {
    await FeedbackService.selection(enabled: true);
    if (_page < _steps.length - 1) {
      await _controller.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    } else {
      await _calibrateClock();
    }
  }

  Future<void> _calibrateClock() async {
      final now = DateTime.now();
      final date = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 365)),
        lastDate: now.add(const Duration(days: 365)),
      );
      if (date == null || !mounted) return;
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now));
      if (time == null || !mounted) return;
      await context.read<AppState>().calibrateClock(
        DateTime(date.year, date.month, date.day, time.hour, time.minute),
      );
      await widget.onComplete?.call();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

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
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('MAWO // FIELD GUIDE', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, color: AppTheme.uiColor, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            Text('Make your habits\nalive.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 34, height: 1.05, fontWeight: FontWeight.w700, color: text)),
            const SizedBox(height: 28),
            Expanded(child: PageView.builder(controller: _controller, physics: const NeverScrollableScrollPhysics(), onPageChanged: (value) { FeedbackService.selection(enabled: true); setState(() => _page = value); }, itemCount: _steps.length, itemBuilder: (_, index) => _GuidePage(step: _steps[index], text: text, muted: muted))),
            Row(children: List.generate(_steps.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.only(right: 8), width: index == _page ? 34 : 10, height: 4, color: index == _page ? AppTheme.uiColor : muted))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.uiColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 17), shape: const RoundedRectangleBorder()), child: Text(_page == _steps.length - 1 ? 'START CHECKING IN' : 'NEXT', style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
            if (_page < _steps.length - 1) ...[const SizedBox(height: 10), Center(child: TextButton(onPressed: _calibrateClock, child: Text('SKIP TOUR', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 9, color: muted, letterSpacing: 1))))],
          ]),
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
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(step.$1, style: const TextStyle(fontFamily: AppTheme.caveat, fontSize: 82, color: AppTheme.uiColor, fontWeight: FontWeight.w700)),
    const SizedBox(height: 18),
    Text(step.$2, style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 17, color: text, fontWeight: FontWeight.w700, letterSpacing: .8)),
    const SizedBox(height: 16),
    Text(step.$3, style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 17, height: 1.45, color: muted)),
  ]);
}
