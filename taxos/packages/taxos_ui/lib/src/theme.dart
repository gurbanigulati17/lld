import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material theme that the TaxOS widgets sit on.
class AppTheme {
  const AppTheme._();

  /// Bundled typeface; the package prefix is how Flutter addresses a font
  /// shipped inside a library package.
  static const fontFamily = 'packages/taxos_ui/PublicSans';

  static ThemeData light() => _build(Brightness.light, UiTokens.slate);
  static ThemeData dark() => _build(Brightness.dark, UiTokens.graphite);

  static ThemeData _build(Brightness b, UiTokens t) {
    final scheme = ColorScheme(
      brightness: b,
      primary: t.primary,
      onPrimary: t.onPrimary,
      secondary: t.primary,
      onSecondary: t.onPrimary,
      error: t.negative,
      onError: Colors.white,
      surface: t.surface,
      onSurface: t.text,
      outline: t.border,
      outlineVariant: t.hairline,
      surfaceContainerHighest: t.surfaceAlt,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: t.ground,
      canvasColor: t.surface,
      splashFactory: InkRipple.splashFactory,
      extensions: [t],
    );
    final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text);
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: text.displayLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        headlineMedium: text.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleLarge: text.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
        titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        bodyMedium: text.bodyMedium?.copyWith(height: 1.4),
        bodySmall: text.bodySmall?.copyWith(height: 1.35),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.ground,
        foregroundColor: t.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(color: t.hairline, space: 1, thickness: 1),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.onPrimary : t.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? t.primary : t.surfaceAlt,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.hairline),
        ),
      ),
      datePickerTheme: DatePickerThemeData(backgroundColor: t.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.primary,
        contentTextStyle: text.bodyMedium?.copyWith(color: t.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
