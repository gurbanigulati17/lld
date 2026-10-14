import 'package:flutter/material.dart';

import 'tokens.dart';

/// Builds the Material theme for Evergreen.
class AppTheme {
  const AppTheme._();

  /// Bundled faces; the package prefix is how Flutter addresses fonts that
  /// ship inside a library package.
  static const sans = 'packages/taxos_ui/SourceSans3';
  static const serif = 'packages/taxos_ui/SourceSerif4';

  static ThemeData light() => _build(UiTokens.evergreen);

  static ThemeData _build(UiTokens t) {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: t.primary,
      onPrimary: t.onPrimary,
      secondary: t.heading,
      onSecondary: Colors.white,
      error: t.negative,
      onError: t.onNegative,
      surface: t.surface,
      onSurface: t.text,
      outline: t.border,
      outlineVariant: t.hairline,
      surfaceContainerHighest: t.surfaceAlt,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      fontFamily: sans,
      scaffoldBackgroundColor: t.ground,
      canvasColor: t.surface,
      splashFactory: InkRipple.splashFactory,
      extensions: [t],
    );
    const tabular = [FontFeature.tabularFigures()];
    TextStyle display(double size, {double height = 1.15}) => TextStyle(
          fontFamily: serif,
          fontSize: size,
          fontWeight: FontWeight.w600,
          height: height,
          color: t.heading,
          letterSpacing: -0.2,
        );
    final text = base.textTheme.apply(bodyColor: t.text, displayColor: t.text);
    return base.copyWith(
      textTheme: text.copyWith(
        displayLarge: display(44),
        displayMedium: display(38),
        displaySmall: display(34),
        headlineLarge: display(32),
        headlineMedium: display(30),
        headlineSmall: display(26),
        titleLarge: display(22, height: 1.2),
        titleMedium: text.titleMedium?.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
        titleSmall: text.titleSmall?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: text.bodyLarge?.copyWith(fontSize: 17, height: 1.4, fontFeatures: tabular),
        bodyMedium: text.bodyMedium?.copyWith(fontSize: 16, height: 1.4, fontFeatures: tabular),
        bodySmall: text.bodySmall?.copyWith(fontSize: 14, height: 1.4, color: t.textMuted),
        labelLarge: text.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        labelMedium: text.labelMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
        labelSmall: text.labelSmall?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: t.ground,
        foregroundColor: t.textMuted,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: display(22),
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
          (s) => s.contains(WidgetState.selected) ? t.primary : t.border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: t.ground,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: t.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      datePickerTheme: DatePickerThemeData(backgroundColor: t.surface),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: t.text,
        contentTextStyle: TextStyle(fontFamily: sans, fontSize: 15, color: t.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
