import 'package:flutter/material.dart';
import 'package:mawo/theme/app_theme.dart';

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
    ('01', 'BUILD YOUR SIGNAL', 'Add one small daily habit. MAWO learns from consistency, not perfection.'),
    ('02', 'CHECK IN + EVOLVE', 'Tap a habit when it is done. Earn Fragments and watch your interface change.'),
    ('03', 'SET A REMINDER', 'Choose a time inside any habit to get a gentle nudge when it matters.'),
  ];
  Future<void> _next() async {
    if (_page < _steps.length - 1) {
      await _controller.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
    } else {
      await widget.onComplete?.call();
    }
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
      body: SafeArea(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('MAWO // FIELD GUIDE', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, color: AppTheme.uiColor, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Text('Make your habits\nalive.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 34, height: 1.05, fontWeight: FontWeight.w700, color: text)),
          const SizedBox(height: 28),
          Expanded(child: PageView.builder(
            controller: _controller,
            onPageChanged: (value) => setState(() => _page = value),
            itemCount: _steps.length,
            itemBuilder: (_, index) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_steps[index].$1, style: const TextStyle(fontFamily: AppTheme.caveat, fontSize: 82, color: AppTheme.uiColor, fontWeight: FontWeight.w700)),
              const SizedBox(height: 18),
              Text(_steps[index].$2, style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 17, color: text, fontWeight: FontWeight.w700, letterSpacing: .8)),
              const SizedBox(height: 16),
              Text(_steps[index].$3, style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 17, height: 1.45, color: muted)),
            ]),
          )),
          Row(children: List.generate(_steps.length, (index) => AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.only(right: 8), width: index == _page ? 34 : 10, height: 4, color: index == _page ? AppTheme.uiColor : muted))),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _next, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.uiColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 17), shape: const RoundedRectangleBorder()), child: Text(_page == _steps.length - 1 ? 'START MAWO' : 'NEXT', style: const TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)))),
          const SizedBox(height: 10),
          Center(child: TextButton(onPressed: () async => widget.onComplete?.call(), child: Text('SKIP TOUR', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 9, color: muted, letterSpacing: 1)))),
        ]),
      )),
    );
  }
}
