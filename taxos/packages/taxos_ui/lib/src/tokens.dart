import 'dart:ui';

import 'package:flutter/material.dart';

/// Semantic colours and shape for the Evergreen theme, attached to
/// [ThemeData] as an extension.
class UiTokens extends ThemeExtension<UiTokens> {
  const UiTokens({
    required this.ground,
    required this.surface,
    required this.surfaceAlt,
    required this.hairline,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.heading,
    required this.primary,
    required this.onPrimary,
    required this.tint,
    required this.onTint,
    required this.info,
    required this.chartPrimary,
    required this.chartSecondary,
    required this.track,
    required this.splitDivider,
    required this.positive,
    required this.onPositive,
    required this.negative,
    required this.onNegative,
    required this.warning,
    required this.onWarning,
    required this.radius,
    required this.cardShadow,
  });

  /// Warm off-white page background.
  final Color ground;

  /// Card background.
  final Color surface;

  /// Neutral pills and inset fills.
  final Color surfaceAlt;

  /// 1px dividers inside cards.
  final Color hairline;

  /// Input and outlined-button borders.
  final Color border;
  final Color text;
  final Color textMuted;

  /// Forest green for serif headings and emphasised figures.
  final Color heading;

  /// The green pill button and selected states.
  final Color primary;
  final Color onPrimary;

  /// Pale mint wells behind icons, and soft tags.
  final Color tint;
  final Color onTint;

  /// Information icons and notices.
  final Color info;

  /// Progress bars and charts.
  final Color chartPrimary;
  final Color chartSecondary;
  final Color track;
  final Color splitDivider;
  final Color positive;
  final Color onPositive;
  final Color negative;
  final Color onNegative;
  final Color warning;
  final Color onWarning;
  final double radius;
  final List<BoxShadow> cardShadow;

  static const evergreen = UiTokens(
    ground: Color(0xFFF7F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1EFE9),
    hairline: Color(0xFFECEAE4),
    border: Color(0xFFDEDBD3),
    text: Color(0xFF2B2B2B),
    textMuted: Color(0xFF65655F),
    heading: Color(0xFF1F4D2B),
    primary: Color(0xFF3B7A2C),
    onPrimary: Color(0xFFFFFFFF),
    tint: Color(0xFFDCEFD8),
    onTint: Color(0xFF1F4D2B),
    info: Color(0xFF2C5BA8),
    chartPrimary: Color(0xFF1F3A5F),
    chartSecondary: Color(0xFF3B82C4),
    track: Color(0xFFECEAE4),
    splitDivider: Color(0xFFECEAE4),
    positive: Color(0xFF2B7A30),
    onPositive: Color(0xFFFFFFFF),
    negative: Color(0xFFB3261E),
    onNegative: Color(0xFFFFFFFF),
    warning: Color(0xFFF5D27A),
    onWarning: Color(0xFF3F2C00),
    radius: 20,
    cardShadow: [
      BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F000000), blurRadius: 24, offset: Offset(0, 8)),
    ],
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
        heading: heading,
        primary: primary ?? this.primary,
        onPrimary: onPrimary,
        tint: tint,
        onTint: onTint,
        info: info,
        chartPrimary: chartPrimary,
        chartSecondary: chartSecondary,
        track: track,
        splitDivider: splitDivider,
        positive: positive,
        onPositive: onPositive,
        negative: negative,
        onNegative: onNegative,
        warning: warning,
        onWarning: onWarning,
        radius: radius,
        cardShadow: cardShadow,
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
      heading: c(heading, other.heading),
      primary: c(primary, other.primary),
      onPrimary: c(onPrimary, other.onPrimary),
      tint: c(tint, other.tint),
      onTint: c(onTint, other.onTint),
      info: c(info, other.info),
      chartPrimary: c(chartPrimary, other.chartPrimary),
      chartSecondary: c(chartSecondary, other.chartSecondary),
      track: c(track, other.track),
      splitDivider: c(splitDivider, other.splitDivider),
      positive: c(positive, other.positive),
      onPositive: c(onPositive, other.onPositive),
      negative: c(negative, other.negative),
      onNegative: c(onNegative, other.onNegative),
      warning: c(warning, other.warning),
      onWarning: c(onWarning, other.onWarning),
      radius: lerpDouble(radius, other.radius, t)!,
      cardShadow: t < 0.5 ? cardShadow : other.cardShadow,
    );
  }
}

extension UiThemeX on BuildContext {
  UiTokens get ui => Theme.of(this).extension<UiTokens>() ?? UiTokens.evergreen;
}
