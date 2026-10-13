import 'dart:ui';

import 'package:flutter/material.dart';

import 'glass_performance.dart';
import 'glass_theme.dart';

/// The core liquid-glass surface.
///
/// Layers, back to front: backdrop blur → tint gradient → content →
/// specular highlight → gradient hairline border. Tapping squashes the panel
/// slightly, like pressing on a soft lens.
class GlassPanel extends StatefulWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
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

  /// Stronger tint for primary cards.
  final bool emphasis;

  /// Optional colour wash (for example the accent at low alpha).
  final Color? tint;
  final double? width;
  final double? height;
  final Clip clipBehavior;

  @override
  State<GlassPanel> createState() => _GlassPanelState();
}

class _GlassPanelState extends State<GlassPanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final t = context.glass;
    final radius = widget.radius ?? t.radius;
    final reduced = GlassPerformance.reducedOf(context);
    final border = BorderRadius.circular(radius);

    final surfaceTint = widget.emphasis ? t.surfaceTintStrong : t.surfaceTint;
    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(widget.tint ?? Colors.transparent, surfaceTint),
            Color.alphaBlend(widget.tint ?? Colors.transparent, surfaceTint)
                .withValues(alpha: surfaceTint.a * 0.75),
          ],
        ),
      ),
      child: Padding(padding: widget.padding, child: widget.child),
    );

    if (!reduced) {
      surface = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: t.blurSigma, sigmaY: t.blurSigma),
        child: surface,
      );
    } else {
      // Flat fallback: make the tint opaque enough to read on its own.
      surface = ColoredBox(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        child: surface,
      );
    }

    Widget panel = ClipRRect(
      borderRadius: border,
      clipBehavior: widget.clipBehavior,
      child: CustomPaint(
        foregroundPainter: _GlassEdgePainter(
          radius: radius,
          borderStart: t.borderStart,
          borderEnd: t.borderEnd,
          specular: t.specular,
        ),
        child: surface,
      ),
    );

    panel = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border,
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -8,
          ),
        ],
      ),
      child: panel,
    );

    if (widget.width != null || widget.height != null) {
      panel = SizedBox(width: widget.width, height: widget.height, child: panel);
    }
    if (widget.margin != null) {
      panel = Padding(padding: widget.margin!, child: panel);
    }

    if (widget.onTap == null) return panel;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: panel,
      ),
    );
  }
}

/// Paints the gradient hairline border and the top specular sheen.
class _GlassEdgePainter extends CustomPainter {
  _GlassEdgePainter({
    required this.radius,
    required this.borderStart,
    required this.borderEnd,
    required this.specular,
  });

  final double radius;
  final Color borderStart;
  final Color borderEnd;
  final Color specular;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(0.75),
      Radius.circular(radius),
    );
    // Specular highlight: a soft band hugging the top edge.
    final sheen = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [specular, specular.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.28));
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.28), sheen);
    canvas.restore();

    // Gradient hairline.
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [borderStart, borderEnd, borderStart.withValues(alpha: 0.35)],
        stops: const [0, 0.55, 1],
      ).createShader(rect);
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(_GlassEdgePainter old) =>
      old.radius != radius ||
      old.borderStart != borderStart ||
      old.borderEnd != borderEnd ||
      old.specular != specular;
}
