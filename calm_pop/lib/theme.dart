import 'package:flutter/material.dart';

/// Soft pastel palette shared across the app.
class CalmColors {
  static const ink = Color(0xFF2E2A4A);
  static const inkSoft = Color(0xFF6B6789);
  static const lavender = Color(0xFFB8A9FF);
  static const mint = Color(0xFF8FDFC4);
  static const peach = Color(0xFFFFBFA0);
  static const sky = Color(0xFF9FD3FF);
  static const rose = Color(0xFFFFA9C6);
  static const lemon = Color(0xFFFFE29A);
  static const night = Color(0xFF1B1A33);

  static const pastels = [lavender, mint, peach, sky, rose, lemon];

  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF6F3FF), Color(0xFFEAF7FF), Color(0xFFFFF4EE)],
  );
}

ThemeData buildCalmTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: CalmColors.lavender,
    brightness: Brightness.light,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w800,
        color: CalmColors.ink,
        letterSpacing: -0.5,
      ),
      titleLarge: TextStyle(fontWeight: FontWeight.w700, color: CalmColors.ink),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, color: CalmColors.ink),
      bodyMedium: TextStyle(color: CalmColors.inkSoft, height: 1.35),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: CalmColors.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
  );
}
