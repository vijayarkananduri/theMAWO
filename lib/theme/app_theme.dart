import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Font families
  static const String spaceMono = 'SpaceMono';
  static const String spaceGrotesk = 'SpaceGrotesk';
  static const String caveat = 'Caveat';

  // UI accent color (Orange from reference)
  static const Color uiColor = Color(0xFFE8850A);

  // Dark theme colors (from reference :root)
  static const Color darkBg = Color(0xFF0C0B09);
  static const Color darkBg1 = Color(0xFF111009);
  static const Color darkBg2 = Color(0xFF161410);
  static const Color darkSurface = Color(0xFF1C1916);
  static const Color darkBorder = Color(0xFF272320);
  static const Color darkText = Color(0xFFEDE8E0);
  static const Color darkMuted = Color(0xFF6B6058);
  static const Color darkDim = Color(0xFF3A3530);
  static const Color darkS2 = Color(0xFF242018);
  static const Color darkErr = Color(0xFFFF3B30);

  // Light theme colors (from reference [data-theme="light"])
  static const Color lightBg = Color(0xFFF5EEDB);
  static const Color lightBg1 = Color(0xFFEDE5CC);
  static const Color lightBg2 = Color(0xFFE8DFC6);
  static const Color lightSurface = Color(0xFFFDF6E8);
  static const Color lightBorder = Color(0xFFD4C9B0);
  static const Color lightText = Color(0xFF18150F);
  static const Color lightMuted = Color(0xFF7A7166);
  static const Color lightDim = Color(0xFFB8A88A);
  static const Color lightS2 = Color(0xFFF0E8D2);
  static const Color lightErr = Color(0xFFCC2A20);

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkBg,
        colorScheme: const ColorScheme.dark(
          primary: uiColor,
          secondary: uiColor,
          surface: darkSurface,
          onSurface: darkText,
          background: darkBg,
          onBackground: darkText,
          error: darkErr,
          outline: darkBorder,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: darkText,
          displayColor: darkText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: darkBg,
          foregroundColor: darkText,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: darkSurface,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: darkBorder,
          thickness: 1,
        ),
        useMaterial3: true,
      );

  static ThemeData get light => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: lightBg,
        colorScheme: const ColorScheme.light(
          primary: uiColor,
          secondary: uiColor,
          surface: lightSurface,
          onSurface: lightText,
          background: lightBg,
          onBackground: lightText,
          error: lightErr,
          outline: lightBorder,
        ),
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.light().textTheme,
        ).apply(
          bodyColor: lightText,
          displayColor: lightText,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: lightBg,
          foregroundColor: lightText,
          elevation: 0,
        ),
        cardTheme: const CardTheme(
          color: lightSurface,
          elevation: 0,
        ),
        dividerTheme: const DividerThemeData(
          color: lightBorder,
          thickness: 1,
        ),
        useMaterial3: true,
      );
}


class MawoVisualState {
  final int phase;
  final int level;
  final bool dark;
  const MawoVisualState({required this.phase, required this.level, required this.dark});

  double get radius => [4.0, 5.5, 7.0, 8.5, 10.0, 11.5, 13.0, 14.5, 16.0, 18.0][(level - 1).clamp(0, 9).toInt()];
  double get shadowDepth => [0.0, 2.0, 4.0, 6.0, 8.0, 10.0, 13.0, 16.0, 20.0, 24.0][(level - 1).clamp(0, 9).toInt()];
  Alignment get warmthOrigin => const [Alignment.topCenter, Alignment.bottomCenter, Alignment.topLeft, Alignment.centerRight, Alignment.center][phase.clamp(0, 4).toInt()];

  Color get background => dark ? [const Color(0xFF0A0A0A), const Color(0xFF0C0806), const Color(0xFF100A05), const Color(0xFF130A04), const Color(0xFF170A02)][phase.clamp(0, 4).toInt()] : [const Color(0xFFF0EAD6), const Color(0xFFF2E8D0), const Color(0xFFF4E6C4), const Color(0xFFF6E2B6), const Color(0xFFF8DE9E)][phase.clamp(0, 4).toInt()];
  Color get surface => dark ? [const Color(0xFF111111), const Color(0xFF16100A), const Color(0xFF1A1108), const Color(0xFF1E1207), const Color(0xFF241505)][phase.clamp(0, 4).toInt()] : [const Color(0xFFF8F3E4), const Color(0xFFFAF3DC), const Color(0xFFFCF0C8), const Color(0xFFFCEAB8), const Color(0xFFFDE8A8)][phase.clamp(0, 4).toInt()];
  Color get accent => dark ? [const Color(0xFF888888), const Color(0xFFFF6A00), const Color(0xFFFF8533), const Color(0xFFFFA340), const Color(0xFFFFB627)][phase.clamp(0, 4).toInt()] : [const Color(0xFF8A8266), const Color(0xFFFF8533), const Color(0xFFFF9A40), const Color(0xFFFFB066), const Color(0xFFFFC552)][phase.clamp(0, 4).toInt()];
  List<BoxShadow> get shadows => shadowDepth == 0 ? const [] : [BoxShadow(color: accent.withOpacity(0.18), blurRadius: shadowDepth, offset: Offset(0, shadowDepth / 3))];
}
