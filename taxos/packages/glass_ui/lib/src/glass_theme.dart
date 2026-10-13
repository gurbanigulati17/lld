import 'dart:ui';

import 'package:flutter/material.dart';

/// Design tokens for glass surfaces, attached to [ThemeData] as an extension.
class GlassTokens extends ThemeExtension<GlassTokens> {
  const GlassTokens({
    required this.surfaceTint,
    required this.surfaceTintStrong,
    required this.borderStart,
    required this.borderEnd,
    required this.specular,
    required this.shadow,
    required this.blurSigma,
    required this.radius,
    required this.accent,
    required this.accentSecondary,
    required this.positive,
    required this.negative,
    required this.warning,
    required this.backdropColors,
  });

  /// Tint laid over the blurred backdrop.
  final Color surfaceTint;

  /// Stronger tint for emphasised / pressed panels.
  final Color surfaceTintStrong;
  final Color borderStart;
  final Color borderEnd;

  /// Specular highlight that runs along the top edge.
  final Color specular;
  final Color shadow;
  final double blurSigma;
  final double radius;
  final Color accent;
  final Color accentSecondary;
  final Color positive;
  final Color negative;
  final Color warning;

  /// Blob colours for [LiquidBackground].
  final List<Color> backdropColors;

  static const light = GlassTokens(
    surfaceTint: Color(0x8CFFFFFF),
    surfaceTintStrong: Color(0xB3FFFFFF),
    borderStart: Color(0xCCFFFFFF),
    borderEnd: Color(0x33FFFFFF),
    specular: Color(0x99FFFFFF),
    shadow: Color(0x1F1B2A4A),
    blurSigma: 24,
    radius: 24,
    accent: Color(0xFF2F6BFF),
    accentSecondary: Color(0xFF8A5CFF),
    positive: Color(0xFF12A36B),
    negative: Color(0xFFE4455A),
    warning: Color(0xFFE09A1C),
    backdropColors: [
      Color(0xFFBFD7FF),
      Color(0xFFE3C9FF),
      Color(0xFFBFF3E6),
      Color(0xFFFFE1C9),
    ],
  );

  static const dark = GlassTokens(
    surfaceTint: Color(0x26FFFFFF),
    surfaceTintStrong: Color(0x40FFFFFF),
    borderStart: Color(0x66FFFFFF),
    borderEnd: Color(0x14FFFFFF),
    specular: Color(0x59FFFFFF),
    shadow: Color(0x66000000),
    blurSigma: 28,
    radius: 24,
    accent: Color(0xFF6D9BFF),
    accentSecondary: Color(0xFFB08CFF),
    positive: Color(0xFF3DD598),
    negative: Color(0xFFFF6B7A),
    warning: Color(0xFFFFC75A),
    backdropColors: [
      Color(0xFF1B2A6B),
      Color(0xFF4A1F7A),
      Color(0xFF0D4F5C),
      Color(0xFF5C2A1A),
    ],
  );

  @override
  GlassTokens copyWith({
    Color? surfaceTint,
    Color? surfaceTintStrong,
    Color? borderStart,
    Color? borderEnd,
    Color? specular,
    Color? shadow,
    double? blurSigma,
    double? radius,
    Color? accent,
    Color? accentSecondary,
    Color? positive,
    Color? negative,
    Color? warning,
    List<Color>? backdropColors,
  }) =>
      GlassTokens(
        surfaceTint: surfaceTint ?? this.surfaceTint,
        surfaceTintStrong: surfaceTintStrong ?? this.surfaceTintStrong,
        borderStart: borderStart ?? this.borderStart,
        borderEnd: borderEnd ?? this.borderEnd,
        specular: specular ?? this.specular,
        shadow: shadow ?? this.shadow,
        blurSigma: blurSigma ?? this.blurSigma,
        radius: radius ?? this.radius,
        accent: accent ?? this.accent,
        accentSecondary: accentSecondary ?? this.accentSecondary,
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        warning: warning ?? this.warning,
        backdropColors: backdropColors ?? this.backdropColors,
      );

  @override
  GlassTokens lerp(ThemeExtension<GlassTokens>? other, double t) {
    if (other is! GlassTokens) return this;
    return GlassTokens(
      surfaceTint: Color.lerp(surfaceTint, other.surfaceTint, t)!,
      surfaceTintStrong:
          Color.lerp(surfaceTintStrong, other.surfaceTintStrong, t)!,
      borderStart: Color.lerp(borderStart, other.borderStart, t)!,
      borderEnd: Color.lerp(borderEnd, other.borderEnd, t)!,
      specular: Color.lerp(specular, other.specular, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      blurSigma: lerpDouble(blurSigma, other.blurSigma, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSecondary: Color.lerp(accentSecondary, other.accentSecondary, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      backdropColors: [
        for (var i = 0; i < backdropColors.length; i++)
          Color.lerp(backdropColors[i],
              other.backdropColors[i % other.backdropColors.length], t)!,
      ],
    );
  }
}

extension GlassThemeX on BuildContext {
  GlassTokens get glass =>
      Theme.of(this).extension<GlassTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? GlassTokens.dark
          : GlassTokens.light);
}

/// Builds the Material theme that the glass widgets sit on.
class GlassTheme {
  const GlassTheme._();

  static ThemeData light() => _build(Brightness.light, GlassTokens.light);
  static ThemeData dark() => _build(Brightness.dark, GlassTokens.dark);

  static ThemeData _build(Brightness b, GlassTokens t) {
    final isDark = b == Brightness.dark;
    final onSurface = isDark ? const Color(0xFFF4F6FF) : const Color(0xFF101631);
    final scheme = ColorScheme.fromSeed(
      seedColor: t.accent,
      brightness: b,
      surface: isDark ? const Color(0xFF0B1022) : const Color(0xFFF3F6FF),
      onSurface: onSurface,
      primary: t.accent,
      secondary: t.accentSecondary,
      error: t.negative,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
      extensions: [t],
    );
    final text = base.textTheme.apply(
      bodyColor: onSurface,
      displayColor: onSurface,
    );
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: -1.5),
        headlineMedium: text.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: -0.8),
        titleLarge: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: DividerThemeData(
        color: onSurface.withValues(alpha: 0.08),
        space: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
