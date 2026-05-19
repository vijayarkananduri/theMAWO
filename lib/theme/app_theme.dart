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
