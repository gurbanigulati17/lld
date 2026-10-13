import 'package:flutter/material.dart';

import 'tokens.dart';

/// Page ground, with an optional static radial light from the theme's
/// glow token. Both shipped themes keep the glow transparent.
class GlowBackground extends StatelessWidget {
  const GlowBackground({
    super.key,
    required this.child,
    this.alignment = const Alignment(-1.4, -0.55),
  });

  final Widget child;

  /// Where the light sits; outside [-1, 1] pushes it past the edge.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    // A box ignores its colour when it also has a gradient, so the ground
    // and the light are painted as two layers.
    return ColoredBox(
      color: t.ground,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: alignment,
            radius: 1.0,
            colors: [t.glow, t.glow.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    );
  }
}
