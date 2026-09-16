import 'package:flutter/material.dart';
import 'package:mawo/theme/app_theme.dart';
import 'package:mawo/services/feedback_service.dart';

class BootScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final bool hapticsEnabled;

  const BootScreen({
    Key? key,
    required this.onComplete,
    this.hapticsEnabled = true,
  }) : super(key: key);

  @override
  State<BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<BootScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _aliveController;
  late AnimationController _contentController;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _textController = AnimationController(
      duration: const Duration(milliseconds: 1900),
      vsync: this,
    );

    _aliveController = AnimationController(
      duration: const Duration(milliseconds: 360),
      vsync: this,
    );

    _contentController = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    await _textController.forward();
    await Future.delayed(const Duration(milliseconds: 80));
    await _aliveController.forward();
    await Future.delayed(const Duration(milliseconds: 160));
    _contentController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _aliveController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppTheme.darkBg : AppTheme.lightBg;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final muteColor = isDark ? AppTheme.darkMuted : AppTheme.lightMuted;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
              ),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
                    .animate(
                  CurvedAnimation(parent: _logoController, curve: Curves.easeOut),
                ),
                child: const Text(
                  'MAWO',
                  style: TextStyle(
                    fontFamily: AppTheme.spaceMono,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.uiColor,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Typing animation for "Let's make your habits,"
            TypingAnimation(
              text: "Let's make your habits,",
              textController: _textController,
              textColor: textColor,
              hapticsEnabled: widget.hapticsEnabled,
            ),

            const SizedBox(height: 20),

            // "alive." with stroke animation
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: _aliveController, curve: Curves.easeInOut),
              ),
              child: const Text(
                'alive.',
                style: TextStyle(
                  fontFamily: AppTheme.caveat,
                  fontSize: 64,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.uiColor,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Description
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
              ),
              child: Text(
                '// Complete habits → earn Fragments.\n// Fragments evolve your interface.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.spaceMono,
                  fontSize: 11,
                  color: muteColor,
                  height: 1.9,
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Begin Button
            FadeTransition(
              opacity: Tween<double>(begin: 0, end: 1).animate(
                CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
              ),
              child: GestureDetector(
                onTap: widget.onComplete,
                child: Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: AppTheme.uiColor,
                  ),
                  child: const Text(
                    'BEGIN',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.spaceMono,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class TypingAnimation extends StatefulWidget {
  final String text;
  final AnimationController textController;
  final Color textColor;
  final bool hapticsEnabled;

  const TypingAnimation({
    Key? key,
    required this.text,
    required this.textController,
    required this.textColor,
    this.hapticsEnabled = true,
  }) : super(key: key);

  @override
  State<TypingAnimation> createState() => _TypingAnimationState();
}

class _TypingAnimationState extends State<TypingAnimation> {
  int _displayedChars = 0;

  @override
  void initState() {
    super.initState();
    widget.textController.addListener(_updateText);
  }

  void _updateText() {
    final next = (widget.textController.value * widget.text.length).round();
    if (next != _displayedChars && next > 0) {
      if (widget.hapticsEnabled) FeedbackService.selection(enabled: true);
      setState(() => _displayedChars = next);
    }
  }

  @override
  void dispose() {
    widget.textController.removeListener(_updateText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Center(
        child: Text(
          widget.text.substring(0, _displayedChars),
          style: TextStyle(
            fontFamily: AppTheme.spaceGrotesk,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: widget.textColor,
            letterSpacing: -0.02,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
