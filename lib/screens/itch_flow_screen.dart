import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mawo/providers/app_state.dart';
import 'package:mawo/services/feedback_service.dart';
import 'package:mawo/theme/app_theme.dart';

class ItchFlowScreen extends StatefulWidget {
  const ItchFlowScreen({super.key});

  @override
  State<ItchFlowScreen> createState() => _ItchFlowScreenState();
}

class _ItchFlowScreenState extends State<ItchFlowScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  String? _intensity;
  String? _activity;
  String? _feeling;
  Timer? _timer;
  int _seconds = 90;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  final _activities = const [
    ('Water', 'A glass, right now.', Icons.water_drop_outlined),
    ('Walk', 'Two minutes outside.', Icons.directions_walk_outlined),
    ('Breathe', 'Slow the wave down.', Icons.air_outlined),
    ('Read', 'One page is enough.', Icons.menu_book_outlined),
  ];

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  void _chooseIntensity(String value) {
    FeedbackService.selection(enabled: context.read<AppState>().hapticsEnabled);
    setState(() {
      _intensity = value;
      _step = 1;
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() {
          _seconds = 0;
          _step = 2;
        });
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _skipSurf() {
    _timer?.cancel();
    setState(() {
      _seconds = 0;
      _step = 2;
    });
  }

  void _finish() async {
    _timer?.cancel();
    await context.read<AppState>().logItchEpisode(
          intensity: _intensity ?? 'mild',
          activity: _activity ?? 'none',
          feeling: _feeling ?? 'same',
          surfCompleted: _seconds == 0,
        );
    if (!mounted) return;
    setState(() => _step = 4);
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? AppTheme.darkBg : AppTheme.lightBg;
    final text = dark ? AppTheme.darkText : AppTheme.lightText;
    final muted = dark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _GrainPainter(dark: dark))),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('INTERRUPTION // ${_step + 1}/5', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 10, color: AppTheme.uiColor, letterSpacing: 1.2)),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: muted)),
                    ],
                  ),
                  const SizedBox(height: 34),
                  Expanded(child: _content(text, muted, dark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(Color text, Color muted, bool dark) {
    switch (_step) {
      case 0:
        return _IntensityStep(text: text, muted: muted, onChoose: _chooseIntensity);
      case 1:
        return _SurfStep(seconds: _seconds, pulse: _pulse, text: text, muted: muted, onSkip: _skipSurf);
      case 2:
        return _ActivityStep(items: _activities, text: text, muted: muted, onChoose: (value) => setState(() { _activity = value; _step = 3; }));
      case 3:
        return _FeelingStep(text: text, muted: muted, onChoose: (value) { _feeling = value; _finish(); });
      default:
        return _DoneStep(text: text, onDone: () => Navigator.pop(context));
    }
  }
}

class _IntensityStep extends StatelessWidget {
  final Color text;
  final Color muted;
  final ValueChanged<String> onChoose;
  const _IntensityStep({required this.text, required this.muted, required this.onChoose});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Catch it early.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 38, fontWeight: FontWeight.w700, color: text, height: 1.0)),
    const SizedBox(height: 14),
    Text('How strong is the itch right now?', style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 16, color: muted)),
    const Spacer(),
    ...['Mild', 'Strong', 'Urgent'].map((label) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _Choice(label: label, icon: label == 'Urgent' ? Icons.bolt : Icons.circle_outlined, onTap: () => onChoose(label.toLowerCase()), text: text))),
    const SizedBox(height: 22),
    Text('No judgment. Just a signal.', style: TextStyle(fontFamily: AppTheme.spaceMono, fontSize: 11, color: muted)),
  ]);
}

class _SurfStep extends StatelessWidget {
  final int seconds;
  final Animation<double> pulse;
  final Color text;
  final Color muted;
  final VoidCallback onSkip;
  const _SurfStep({required this.seconds, required this.pulse, required this.text, required this.muted, required this.onSkip});
  @override
  Widget build(BuildContext context) => Column(children: [
    const Spacer(),
    AnimatedBuilder(animation: pulse, builder: (context, child) => Container(width: 190 + pulse.value * 22, height: 190 + pulse.value * 22, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.uiColor.withOpacity(.08), border: Border.all(color: AppTheme.uiColor.withOpacity(.75), width: 1.5), boxShadow: [BoxShadow(color: AppTheme.uiColor.withOpacity(.22), blurRadius: 34 + pulse.value * 20)]), child: child), child: Center(child: Text(seconds.toString().padLeft(2, '0'), style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 52, fontWeight: FontWeight.w700, color: text)))),
    const SizedBox(height: 34),
    Text('Ride the wave.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 30, fontWeight: FontWeight.w700, color: text)),
    const SizedBox(height: 10),
    Text('It peaks and passes. Breathe with the glow.', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 15, color: muted)),
    const Spacer(),
    TextButton(onPressed: onSkip, child: Text('SKIP SURF', style: TextStyle(fontFamily: AppTheme.spaceMono, color: muted, letterSpacing: 1.4, fontSize: 10))),
  ]);
}

class _ActivityStep extends StatelessWidget {
  final List<(String, String, IconData)> items;
  final Color text;
  final Color muted;
  final ValueChanged<String> onChoose;
  const _ActivityStep({required this.items, required this.text, required this.muted, required this.onChoose});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('One small action.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 36, fontWeight: FontWeight.w700, color: text)),
    const SizedBox(height: 10),
    Text('Choose what feels kindest, not hardest.', style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 15, color: muted)),
    const SizedBox(height: 28),
    ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _ActionCard(item: item, text: text, muted: muted, onTap: () => onChoose(item.$1)))),
  ]);
}

class _ActionCard extends StatelessWidget {
  final (String, String, IconData) item;
  final Color text;
  final Color muted;
  final VoidCallback onTap;
  const _ActionCard({required this.item, required this.text, required this.muted, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(18), child: Container(padding: const EdgeInsets.all(17), decoration: BoxDecoration(color: AppTheme.uiColor.withOpacity(.06), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.uiColor.withOpacity(.25))), child: Row(children: [Icon(item.$3, color: AppTheme.uiColor), const SizedBox(width: 14), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.$1, style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontWeight: FontWeight.w700, fontSize: 17, color: text)), Text(item.$2, style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 12, color: muted))]), const Spacer(), Icon(Icons.arrow_forward, size: 17, color: muted)])));
}

class _FeelingStep extends StatelessWidget {
  final Color text;
  final Color muted;
  final ValueChanged<String> onChoose;
  const _FeelingStep({required this.text, required this.muted, required this.onChoose});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Check back in.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 38, fontWeight: FontWeight.w700, color: text)),
    const SizedBox(height: 12),
    Text('How do you feel now?', style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 16, color: muted)),
    const Spacer(),
    ...['Calm', 'Satisfied', 'Same', 'Restless', 'Worse'].map((label) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _Choice(label: label, icon: Icons.arrow_outward, onTap: () => onChoose(label.toLowerCase()), text: text))),
  ]);
}

class _DoneStep extends StatelessWidget {
  final Color text;
  final VoidCallback onDone;
  const _DoneStep({required this.text, required this.onDone});
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Container(width: 84, height: 84, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.uiColor, boxShadow: [BoxShadow(color: AppTheme.uiColor.withOpacity(.45), blurRadius: 30)]), child: const Icon(Icons.check, color: Colors.black, size: 42)), const SizedBox(height: 28), Text('Nice interruption.', style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 30, fontWeight: FontWeight.w700, color: text)), const SizedBox(height: 10), Text('That is one moment you chose differently.', textAlign: TextAlign.center, style: TextStyle(fontFamily: AppTheme.poppins, fontSize: 15, color: text.withOpacity(.65))), const SizedBox(height: 40), ElevatedButton(onPressed: onDone, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.uiColor, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16)), child: const Text('BACK HOME', style: TextStyle(fontFamily: AppTheme.spaceMono, fontWeight: FontWeight.w700, letterSpacing: 1.2)))]));
}

class _Choice extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color text;
  const _Choice({required this.label, required this.icon, required this.onTap, required this.text});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15), child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), decoration: BoxDecoration(color: AppTheme.uiColor.withOpacity(.07), borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.uiColor.withOpacity(.3))), child: Row(children: [Icon(icon, color: AppTheme.uiColor, size: 19), const SizedBox(width: 12), Text(label, style: TextStyle(fontFamily: AppTheme.spaceGrotesk, fontSize: 17, fontWeight: FontWeight.w700, color: text)), const Spacer(), const Icon(Icons.arrow_forward, color: AppTheme.uiColor, size: 18)])));
}

class _GrainPainter extends CustomPainter {
  final bool dark;
  _GrainPainter({required this.dark});
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(7);
    final paint = Paint()..color = (dark ? Colors.white : Colors.black).withOpacity(.025);
    for (var i = 0; i < size.width * size.height / 260; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height), random.nextDouble() * 1.2, paint);
    }
  }
  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) => oldDelegate.dark != dark;
}
