import 'dart:ui';

import 'package:flutter/material.dart';

/// Semantic colour and shape tokens, attached to [ThemeData] as an
/// extension. Light is "Trust Blue" (the default), dark is "Soft Night".
///
/// Both avoid pure black and pure white text, saturated gradients and
/// glows, so long sessions stay easy on the eyes.
class UiTokens extends ThemeExtension<UiTokens> {
  const UiTokens({
    required this.ground,
    required this.surface,
    required this.surfaceAlt,
    required this.hairline,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.tint,
    required this.onTint,
    required this.glow,
    required this.splitDivider,
    required this.positive,
    required this.onPositive,
    required this.negative,
    required this.onNegative,
    required this.warning,
    required this.onWarning,
    required this.radius,
    required this.cardShadow,
    required this.cardBorder,
  });

  /// Page background.
  final Color ground;

  /// Card background.
  final Color surface;

  /// Inset fills, neutral pills, segmented track.
  final Color surfaceAlt;

  /// 1px dividers.
  final Color hairline;

  /// Input and secondary-button outlines.
  final Color border;
  final Color text;
  final Color textMuted;

  /// The one accent: buttons, selected states, headline figures.
  final Color primary;
  final Color onPrimary;

  /// Soft accent wash for label bars and icon wells.
  final Color tint;
  final Color onTint;

  /// Optional radial light behind pages; transparent in both themes.
  final Color glow;

  /// Vertical divider inside a split stat.
  final Color splitDivider;
  final Color positive;
  final Color onPositive;
  final Color negative;
  final Color onNegative;
  final Color warning;
  final Color onWarning;
  final double radius;
  final List<BoxShadow> cardShadow;
  final Color? cardBorder;

  static const trustBlue = UiTokens(
    ground: Color(0xFFF5F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEEF2F8),
    hairline: Color(0xFFE8EDF4),
    border: Color(0xFFD8E0EB),
    text: Color(0xFF1B2A41),
    textMuted: Color(0xFF5F6B7E),
    primary: Color(0xFF2F6FED),
    onPrimary: Color(0xFFFFFFFF),
    tint: Color(0xFFE8F0FE),
    onTint: Color(0xFF1E4FC2),
    glow: Color(0x002F6FED),
    splitDivider: Color(0xFFE1E7F0),
    positive: Color(0xFF12805C),
    onPositive: Color(0xFFFFFFFF),
    negative: Color(0xFFCF3B3B),
    onNegative: Color(0xFFFFFFFF),
    warning: Color(0xFFF5C451),
    onWarning: Color(0xFF3D2800),
    radius: 16,
    cardShadow: [
      BoxShadow(color: Color(0x0D1B2A41), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F1B2A41), blurRadius: 16, offset: Offset(0, 6), spreadRadius: -4),
    ],
    cardBorder: Color(0xFFE8EDF4),
  );

  static const softNight = UiTokens(
    ground: Color(0xFF141922),
    surface: Color(0xFF1C2330),
    surfaceAlt: Color(0xFF262F3F),
    hairline: Color(0xFF2A3344),
    border: Color(0xFF364154),
    text: Color(0xFFE4E9F2),
    textMuted: Color(0xFF9AA5B8),
    primary: Color(0xFF8AB0FF),
    onPrimary: Color(0xFF0F1A33),
    tint: Color(0xFF23324F),
    onTint: Color(0xFFB9CDFF),
    glow: Color(0x008AB0FF),
    splitDivider: Color(0xFF2F3A4E),
    positive: Color(0xFF6FCF9F),
    onPositive: Color(0xFF0B2A1C),
    negative: Color(0xFFF08080),
    onNegative: Color(0xFF2A0B0B),
    warning: Color(0xFFE9C46A),
    onWarning: Color(0xFF2A1D00),
    radius: 16,
    cardShadow: [],
    cardBorder: Color(0xFF262F3F),
  );

  @override
  UiTokens copyWith({Color? primary, Color? ground, Color? surface}) => UiTokens(
        ground: ground ?? this.ground,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt,
        hairline: hairline,
        border: border,
        text: text,
        textMuted: textMuted,
        primary: primary ?? this.primary,
        onPrimary: onPrimary,
        tint: tint,
        onTint: onTint,
        glow: glow,
        splitDivider: splitDivider,
        positive: positive,
        onPositive: onPositive,
        negative: negative,
        onNegative: onNegative,
        warning: warning,
        onWarning: onWarning,
        radius: radius,
        cardShadow: cardShadow,
        cardBorder: cardBorder,
      );

  @override
  UiTokens lerp(ThemeExtension<UiTokens>? other, double t) {
    if (other is! UiTokens) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return UiTokens(
      ground: c(ground, other.ground),
      surface: c(surface, other.surface),
      surfaceAlt: c(surfaceAlt, other.surfaceAlt),
      hairline: c(hairline, other.hairline),
      border: c(border, other.border),
      text: c(text, other.text),
      textMuted: c(textMuted, other.textMuted),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      tint: c(tint, other.tint),
      onTint: c(onTint, other.onTint),
      glow: c(glow, other.glow),
      splitDivider: c(splitDivider, other.splitDivider),
      positive: c(positive, other.positive),
      onPositive: c(onPositive, other.onPositive),
      negative: c(negative, other.negative),
      onNegative: c(onNegative, other.onNegative),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      radius: lerpDouble(radius, other.radius, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t),
    );
  }
}

extension UiThemeX on BuildContext {
  UiTokens get ui =>
      Theme.of(this).extension<UiTokens>() ??
      (Theme.of(this).brightness == Brightness.dark ? UiTokens.softNight : UiTokens.trustBlue);
}
