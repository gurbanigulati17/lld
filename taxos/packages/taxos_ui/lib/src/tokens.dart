import 'dart:ui';

import 'package:flutter/material.dart';

/// Semantic colour and shape tokens, attached to [ThemeData] as an
/// extension. Light is "Slate", dark is "Graphite".
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
    required this.positive,
    required this.negative,
    required this.warning,
    required this.radius,
    required this.cardShadow,
    required this.cardBorder,
  });

  /// Page background.
  final Color ground;

  /// Card background.
  final Color surface;

  /// Pills, tags and inset fills.
  final Color surfaceAlt;

  /// 1px dividers.
  final Color hairline;

  /// Input and secondary-button outlines.
  final Color border;
  final Color text;
  final Color textMuted;

  /// The single strong colour: buttons, selected states.
  final Color primary;
  final Color onPrimary;
  final Color positive;
  final Color negative;
  final Color warning;
  final double radius;

  /// Light theme lifts cards with a shadow; dark theme outlines them.
  final List<BoxShadow> cardShadow;
  final Color? cardBorder;

  static const slate = UiTokens(
    ground: Color(0xFFF2F3F5),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE6E9ED),
    hairline: Color(0xFFE6E9ED),
    border: Color(0xFFD5DAE0),
    text: Color(0xFF1F2933),
    textMuted: Color(0xFF5B6673),
    primary: Color(0xFF1F2933),
    onPrimary: Color(0xFFFFFFFF),
    positive: Color(0xFF1E6E4C),
    negative: Color(0xFFA8232B),
    warning: Color(0xFF7A5200),
    radius: 12,
    cardShadow: [
      BoxShadow(color: Color(0x0F1F2933), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x0F1F2933), blurRadius: 24, offset: Offset(0, 8)),
    ],
    cardBorder: null,
  );

  static const graphite = UiTokens(
    ground: Color(0xFF121212),
    surface: Color(0xFF1C1C1E),
    surfaceAlt: Color(0xFF2A2A2A),
    hairline: Color(0xFF2E2E30),
    border: Color(0xFF3A3A3C),
    text: Color(0xFFF2F2F2),
    textMuted: Color(0xFF9A9A9A),
    primary: Color(0xFFF2F2F2),
    onPrimary: Color(0xFF121212),
    positive: Color(0xFF6FCB9B),
    negative: Color(0xFFFF8088),
    warning: Color(0xFFE6BB63),
    radius: 12,
    cardShadow: [],
    cardBorder: Color(0xFF2E2E30),
  );

  @override
  UiTokens copyWith({
    Color? ground,
    Color? surface,
    Color? surfaceAlt,
    Color? hairline,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? positive,
    Color? negative,
    Color? warning,
    double? radius,
    List<BoxShadow>? cardShadow,
    Color? cardBorder,
  }) =>
      UiTokens(
        ground: ground ?? this.ground,
        surface: surface ?? this.surface,
        surfaceAlt: surfaceAlt ?? this.surfaceAlt,
        hairline: hairline ?? this.hairline,
        border: border ?? this.border,
        text: text ?? this.text,
        textMuted: textMuted ?? this.textMuted,
        primary: primary ?? this.primary,
        onPrimary: onPrimary ?? this.onPrimary,
        positive: positive ?? this.positive,
        negative: negative ?? this.negative,
        warning: warning ?? this.warning,
        radius: radius ?? this.radius,
        cardShadow: cardShadow ?? this.cardShadow,
        cardBorder: cardBorder ?? this.cardBorder,
      );

  @override
  UiTokens lerp(ThemeExtension<UiTokens>? other, double t) {
    if (other is! UiTokens) return this;
    return UiTokens(
      ground: Color.lerp(ground, other.ground, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      hairline: Color.lerp(hairline, other.hairline, t)!,
      border: Color.lerp(border, other.border, t)!,
      text: Color.lerp(text, other.text, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
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
          ? UiTokens.graphite
          : UiTokens.slate);
}
