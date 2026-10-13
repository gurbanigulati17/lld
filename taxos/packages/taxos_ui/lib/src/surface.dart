import 'package:flutter/material.dart';

import 'tokens.dart';

/// The card. Dark theme outlines it with a hairline and a deep shadow;
/// light theme lifts it with a soft shadow. [emphasis] strengthens the
/// border for the one card on a screen that matters most.
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.radius,
    this.onTap,
    this.emphasis = false,
    this.tint,
    this.width,
    this.height,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double? radius;
  final VoidCallback? onTap;
  final bool emphasis;

  /// Optional flat wash over the surface colour.
  final Color? tint;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final r = BorderRadius.circular(radius ?? t.radius);
    final color = Color.alphaBlend(tint ?? Colors.transparent, t.surface);

    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) {
      body = InkWell(onTap: onTap, borderRadius: r, child: body);
    }

    Widget card = Material(
      color: color,
      borderRadius: r,
      clipBehavior: clipBehavior,
      child: body,
    );

    card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: t.cardShadow,
        border: t.cardBorder == null
            ? (emphasis ? Border.all(color: t.border) : null)
            : Border.all(color: emphasis ? t.border : t.cardBorder!),
      ),
      child: card,
    );

    if (width != null || height != null) {
      card = SizedBox(width: width, height: height, child: card);
    }
    if (margin != null) card = Padding(padding: margin!, child: card);
    return card;
  }
}
