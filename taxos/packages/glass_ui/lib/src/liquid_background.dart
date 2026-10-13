import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'glass_performance.dart';
import 'glass_theme.dart';

/// Slowly drifting colour blobs that glass panels refract.
///
/// The motion is driven by one ticker with sinusoids of different periods,
/// so it never repeats visibly and costs one repaint per frame of a single
/// gradient painter. Honour reduced motion: the blobs freeze in place.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key, this.child, this.speed = 1});

  final Widget? child;
  final double speed;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.glass;
    final reduced = GlassPerformance.reducedOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? const Color(0xFF070B1A) : const Color(0xFFEEF2FF);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: base),
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, _) => CustomPaint(
              painter: _BlobPainter(
                t: reduced ? 0.37 : _ctrl.value * widget.speed,
                colors: tokens.backdropColors,
                dark: isDark,
              ),
            ),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({required this.t, required this.colors, required this.dark});

  final double t;
  final List<Color> colors;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = t * 2 * math.pi;
    for (var i = 0; i < colors.length; i++) {
      final k = i + 1;
      final cx = size.width *
          (0.5 + 0.42 * math.sin(phase * (0.6 + 0.17 * k) + k * 1.9));
      final cy = size.height *
          (0.5 + 0.40 * math.cos(phase * (0.5 + 0.13 * k) + k * 0.7));
      final r = size.shortestSide * (0.55 + 0.12 * math.sin(phase * 0.9 + k));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            colors[i].withValues(alpha: dark ? 0.85 : 0.95),
            colors[i].withValues(alpha: 0),
          ],
        ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      canvas.drawCircle(Offset(cx, cy), r, paint);
    }
  }

  @override
  bool shouldRepaint(_BlobPainter old) =>
      old.t != t || old.colors != colors || old.dark != dark;
}
