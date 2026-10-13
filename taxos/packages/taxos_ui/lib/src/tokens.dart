import 'dart:ui';

import 'package:flutter/material.dart';

/// Semantic colour and shape tokens, attached to [ThemeData] as an
/// extension. Dark is "Copper Noir" (the default), light is "Copper Light".
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
    required this.accentGradient,
    required this.onAccentGradient,
    required this.secondaryGradient,
    required this.onSecondaryGradient,
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

  /// Inset fills, neutral chips, segmented track.
  final Color surfaceAlt;

  /// 1px dividers.
  final Color hairline;

  /// Input and secondary-button outlines.
  final Color border;
  final Color text;
  final Color textMuted;

  /// The accent: highlighted numbers, selected states, solid fills.
  final Color primary;
  final Color onPrimary;

  /// Primary buttons and the headline label bar.
  final List<Color> accentGradient;
  final Color onAccentGradient;

  /// Secondary label bars (the "silver" bar).
  final List<Color> secondaryGradient;
  final Color onSecondaryGradient;

  /// Soft radial light behind the content.
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

  LinearGradient get accent => LinearGradient(colors: accentGradient);
  LinearGradient get secondary => LinearGradient(colors: secondaryGradient);

  static const copperNoir = UiTokens(
    ground: Color(0xFF0E0E0F),
    surface: Color(0xFF1A1A1B),
    surfaceAlt: Color(0xFF2A2A2C),
    hairline: Color(0xFF262628),
    border: Color(0xFF34343A),
    text: Color(0xFFF5F2EF),
    textMuted: Color(0xFFA29C97),
    primary: Color(0xFFEFA283),
    onPrimary: Color(0xFF1E0F09),
    accentGradient: [Color(0xFFE07B5A), Color(0xFFF2B8A2)],
    onAccentGradient: Color(0xFF1E0F09),
    secondaryGradient: [Color(0xFFE9E6E3), Color(0xFF9C9893)],
    onSecondaryGradient: Color(0xFF141414),
    glow: Color(0x42E07B5A),
    splitDivider: Color(0xFF5A3427),
    positive: Color(0xFF6BD6A6),
    onPositive: Color(0xFF062A1B),
    negative: Color(0xFFE5484D),
    onNegative: Color(0xFFFFFFFF),
    warning: Color(0xFFF2C46D),
    onWarning: Color(0xFF2A1B00),
    radius: 18,
    cardShadow: [
      BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 16), spreadRadius: -12),
    ],
    cardBorder: Color(0xFF2A2A2C),
  );

  static const copperLight = UiTokens(
    ground: Color(0xFFFAF6F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF2EAE4),
    hairline: Color(0xFFEFE6DF),
    border: Color(0xFFE2D5CA),
    text: Color(0xFF1F1A17),
    textMuted: Color(0xFF6E6259),
    primary: Color(0xFFB4552F),
    onPrimary: Color(0xFFFFFFFF),
    accentGradient: [Color(0xFFA94E2A), Color(0xFFC9643F)],
    onAccentGradient: Color(0xFFFFFFFF),
    secondaryGradient: [Color(0xFF3A3330), Color(0xFF6E6259)],
    onSecondaryGradient: Color(0xFFFFFFFF),
    glow: Color(0x24E07B5A),
    splitDivider: Color(0xFFEBC9B8),
    positive: Color(0xFF1E7A50),
    onPositive: Color(0xFFFFFFFF),
    negative: Color(0xFFC8302F),
    onNegative: Color(0xFFFFFFFF),
    warning: Color(0xFFF2C46D),
    onWarning: Color(0xFF2A1B00),
    radius: 18,
    cardShadow: [
      BoxShadow(color: Color(0x141F1A17), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x141F1A17), blurRadius: 24, offset: Offset(0, 10), spreadRadius: -6),
    ],
    cardBorder: null,
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
        accentGradient: accentGradient,
        onAccentGradient: onAccentGradient,
        secondaryGradient: secondaryGradient,
        onSecondaryGradient: onSecondaryGradient,
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
    List<Color> g(List<Color> a, List<Color> b) =>
        [for (var i = 0; i < a.length; i++) c(a[i], b[i % b.length])];
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
      accentGradient: g(accentGradient, other.accentGradient),
      onAccentGradient: c(onAccentGradient, other.onAccentGradient),
      secondaryGradient: g(secondaryGradient, other.secondaryGradient),
      onSecondaryGradient: c(onSecondaryGradient, other.onSecondaryGradient),
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
      (Theme.of(this).brightness == Brightness.dark
          ? UiTokens.copperNoir
          : UiTokens.copperLight);
}
