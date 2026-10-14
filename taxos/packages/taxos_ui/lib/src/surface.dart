import 'package:flutter/material.dart';

import 'space.dart';
import 'tokens.dart';

/// The card: white, rounded, softly shadowed. [flat] swaps the shadow for a
/// hairline border, for secondary cards such as "next steps".
class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Space.gutter),
    this.margin,
    this.radius,
    this.onTap,
    this.flat = false,
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
  final bool flat;

  /// Kept for call sites that mark the primary card; Evergreen draws every
  /// card the same, so this only adds a hairline.
  final bool emphasis;
  final Color? tint;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final r = BorderRadius.circular(radius ?? (flat ? 16 : t.radius));
    Widget body = Padding(padding: padding, child: child);
    if (onTap != null) body = InkWell(onTap: onTap, borderRadius: r, child: body);
    Widget card = Material(
      color: tint ?? t.surface,
      borderRadius: r,
      clipBehavior: clipBehavior,
      child: body,
    );
    card = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: flat ? null : t.cardShadow,
        border: flat || emphasis ? Border.all(color: t.hairline) : null,
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
