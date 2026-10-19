import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/game_scaffold.dart';

class _Ripple {
  _Ripple(this.origin, this.color, this.born, this.maxRadius);

  final Offset origin;
  final Color color;
  final Duration born;
  final double maxRadius;
}

class _Star {
  _Star(this.pos, this.radius, this.phase);

  final Offset pos;
  final double radius;
  final double phase;
}

class RipplePondGame extends StatefulWidget {
  const RipplePondGame({super.key});

  @override
  State<RipplePondGame> createState() => _RipplePondGameState();
}

class _RipplePondGameState extends State<RipplePondGame>
    with SingleTickerProviderStateMixin {
  static const _life = Duration(milliseconds: 2600);
  static const _maxRipples = 80;

  final _rand = Random();
  final _ripples = <_Ripple>[];
  late final List<_Star> _stars = List.generate(
    40,
    (_) => _Star(Offset(_rand.nextDouble(), _rand.nextDouble()),
        0.6 + _rand.nextDouble() * 1.4, _rand.nextDouble() * pi * 2),
  );
  late final Ticker _ticker;
  Duration _now = Duration.zero;
  Offset? _lastDrag;
  int _touches = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      _now = elapsed;
      _ripples.removeWhere((r) => _now - r.born > _life);
      setState(() {});
    })
      ..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _add(Offset p, {double size = 1}) {
    if (_ripples.length >= _maxRipples) _ripples.removeAt(0);
    _ripples.add(_Ripple(
      p,
      CalmColors.pastels[_rand.nextInt(CalmColors.pastels.length)],
      _now,
      (90 + _rand.nextDouble() * 70) * size,
    ));
  }

  void _tap(Offset p) {
    HapticFeedback.lightImpact();
    _touches++;
    _add(p, size: 1.4);
  }

  void _drag(Offset p) {
    if (_lastDrag == null || (p - _lastDrag!).distance > 26) {
      _lastDrag = p;
      _touches++;
      _add(p, size: 0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      dark: true,
      title: 'Ripple Pond',
      subtitle: 'Tap or swipe the water',
      action: StatPill(
          dark: true, icon: Icons.water_drop_rounded, label: '$_touches'),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (d) => _tap(d.localPosition),
        onPanStart: (d) => _drag(d.localPosition),
        onPanUpdate: (d) => _drag(d.localPosition),
        onPanEnd: (_) => _lastDrag = null,
        child: CustomPaint(
          size: Size.infinite,
          painter: _PondPainter(
            ripples: _ripples,
            stars: _stars,
            now: _now,
            life: _life,
            showHint: _touches == 0,
          ),
        ),
      ),
    );
  }
}

class _PondPainter extends CustomPainter {
  _PondPainter({
    required this.ripples,
    required this.stars,
    required this.now,
    required this.life,
    required this.showHint,
  });

  final List<_Ripple> ripples;
  final List<_Star> stars;
  final Duration now;
  final Duration life;
  final bool showHint;

  @override
  void paint(Canvas canvas, Size size) {
    final t = now.inMilliseconds / 1000.0;

    // Twinkling reflections.
    for (final s in stars) {
      final a = 0.25 + 0.25 * sin(t * 1.3 + s.phase);
      canvas.drawCircle(
        Offset(s.pos.dx * size.width, s.pos.dy * size.height),
        s.radius,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }

    if (showHint) {
      final pulse = 0.5 + 0.5 * sin(t * 2);
      final c = size.center(Offset.zero);
      canvas.drawCircle(
        c,
        30 + pulse * 12,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.15 + pulse * 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tp = TextPainter(
        text: TextSpan(
          text: 'Touch anywhere',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              fontWeight: FontWeight.w600),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, c + Offset(-tp.width / 2, 60));
    }

    for (final r in ripples) {
      final p = ((now - r.born).inMilliseconds / life.inMilliseconds)
          .clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(p);
      final fade = 1 - p;

      // Glow at the touch point.
      canvas.drawCircle(
        r.origin,
        18 * (1 - eased) + 4,
        Paint()
          ..color = r.color.withValues(alpha: 0.5 * fade)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Three concentric rings trailing each other.
      for (var k = 0; k < 3; k++) {
        final radius = r.maxRadius * eased * (1 - k * 0.22);
        if (radius <= 0) continue;
        canvas.drawCircle(
          r.origin,
          radius,
          Paint()
            ..color = r.color.withValues(alpha: fade * (0.9 - k * 0.25))
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5 - k * 0.6,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PondPainter old) => true;
}
