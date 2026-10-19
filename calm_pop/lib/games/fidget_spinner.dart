import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../audio/sfx.dart';
import '../theme.dart';
import '../widgets/game_scaffold.dart';

class FidgetSpinnerGame extends StatefulWidget {
  const FidgetSpinnerGame({super.key});

  @override
  State<FidgetSpinnerGame> createState() => _FidgetSpinnerGameState();
}

class _FidgetSpinnerGameState extends State<FidgetSpinnerGame>
    with SingleTickerProviderStateMixin {
  /// Fraction of angular velocity kept per second while coasting.
  static const _friction = 0.72;
  static const _maxVelocity = 60.0; // rad/s

  late final Ticker _ticker;
  Duration _last = Duration.zero;

  double _angle = 0;
  double _velocity = 0; // rad/s
  double _bestRpm = 0;
  int _spins = 0;
  double _spinAccumulator = 0;
  bool _dragging = false;
  double? _prevTouchAngle;
  final _dragClock = Stopwatch();
  Offset _center = Offset.zero;
  int _colorIndex = 0;

  double get _rpm => _velocity.abs() * 60 / (2 * pi);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
    Sfx.instance.preload(const ['spin_tick', 'whoosh']);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.1) return;
    if (_dragging) {
      // The finger drives the angle directly while touching.
      setState(() {});
      return;
    }
    _velocity *= pow(_friction, dt);
    if (_velocity.abs() < 0.05) _velocity = 0;
    final delta = _velocity * dt;
    _angle += delta;
    _spinAccumulator += delta.abs();
    if (_spinAccumulator >= 2 * pi) {
      _spinAccumulator -= 2 * pi;
      _spins++;
      if (_rpm < 200) HapticFeedback.selectionClick();
      Sfx.instance.play('spin_tick', volume: 0.6, minGapMs: 45);
    }
    _bestRpm = max(_bestRpm, _rpm);
    if (_velocity != 0) setState(() {});
  }

  double _touchAngle(Offset p) => atan2(p.dy - _center.dy, p.dx - _center.dx);

  void _panStart(DragStartDetails d) {
    HapticFeedback.lightImpact();
    _dragging = true;
    _prevTouchAngle = _touchAngle(d.localPosition);
    _velocity = 0;
    _dragClock
      ..reset()
      ..start();
  }

  void _panUpdate(DragUpdateDetails d) {
    final a = _touchAngle(d.localPosition);
    var diff = a - (_prevTouchAngle ?? a);
    if (diff > pi) diff -= 2 * pi;
    if (diff < -pi) diff += 2 * pi;
    _prevTouchAngle = a;
    _angle += diff;
    _spinAccumulator += diff.abs();
    // Blend in the finger's speed so a flick carries momentum.
    final dt = max(_dragClock.elapsedMicroseconds / 1e6, 1 / 240);
    _dragClock
      ..reset()
      ..start();
    final instant = diff / dt;
    _velocity = (_velocity * 0.6 + instant * 0.4).clamp(-_maxVelocity, _maxVelocity);
  }

  void _panEnd(DragEndDetails d) {
    _dragging = false;
    _dragClock.stop();
    _prevTouchAngle = null;
    // Add a boost from the fling velocity, tangential to the touch point.
    final v = d.velocity.pixelsPerSecond;
    final boost = v.distance / 120;
    if (boost > 0.5) {
      Sfx.instance.play('whoosh', volume: (boost / 15).clamp(0.3, 1.0));
      _velocity = (_velocity + _velocity.sign * boost)
          .clamp(-_maxVelocity, _maxVelocity);
    }
  }

  void _changeColor() {
    HapticFeedback.selectionClick();
    Sfx.instance.play('tap');
    setState(() => _colorIndex = (_colorIndex + 1) % CalmColors.pastels.length);
  }

  @override
  Widget build(BuildContext context) {
    final color = CalmColors.pastels[_colorIndex];
    return GameScaffold(
      title: 'Fidget Spinner',
      subtitle: 'Swipe around the spinner to flick it',
      action: IconButton(
        tooltip: 'Change color',
        icon: Icon(Icons.palette_rounded, color: CalmColors.ink),
        onPressed: _changeColor,
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              StatPill(icon: Icons.speed_rounded, label: '${_rpm.round()} rpm'),
              StatPill(icon: Icons.loop_rounded, label: '$_spins spins'),
              StatPill(icon: Icons.emoji_events_rounded, label: 'best ${_bestRpm.round()}'),
            ],
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              _center = c.biggest.center(Offset.zero);
              final d = c.biggest.shortestSide * 0.85;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: _panStart,
                onPanUpdate: _panUpdate,
                onPanEnd: _panEnd,
                child: Center(
                  child: Transform.rotate(
                    angle: _angle,
                    child: CustomPaint(
                      size: Size.square(d),
                      painter: _SpinnerPainter(color: color, blur: _rpm),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SpinnerPainter extends CustomPainter {
  _SpinnerPainter({required this.color, required this.blur});

  final Color color;
  final double blur;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final lobeR = r * 0.3;
    final armLen = r * 0.62;
    final darker = Color.lerp(color, CalmColors.ink, 0.25)!;

    // Shadow.
    canvas.drawCircle(
      c.translate(0, 10),
      r * 0.6,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Body: three lobes joined to the hub, merged into one solid shape.
    var body = Path()..addOval(Rect.fromCircle(center: c, radius: r * 0.32));
    for (var k = 0; k < 3; k++) {
      final a = k * 2 * pi / 3 - pi / 2;
      final lc = c + Offset(cos(a), sin(a)) * armLen;
      final perp = Offset(-sin(a), cos(a)) * lobeR * 0.75;
      final lobe = Path()..addOval(Rect.fromCircle(center: lc, radius: lobeR));
      final arm = Path()
        ..addPolygon([c + perp, lc + perp, lc - perp, c - perp], true);
      body = Path.combine(PathOperation.union, body, lobe);
      body = Path.combine(PathOperation.union, body, arm);
    }
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(color, Colors.white, 0.35)!, color, darker],
      ).createShader(Rect.fromCircle(center: c, radius: r));
    canvas.drawPath(body, bodyPaint);

    // Weights in each lobe.
    for (var k = 0; k < 3; k++) {
      final a = k * 2 * pi / 3 - pi / 2;
      final lc = c + Offset(cos(a), sin(a)) * armLen;
      canvas.drawCircle(lc, lobeR * 0.62, Paint()..color = Colors.white.withValues(alpha: 0.9));
      canvas.drawCircle(lc, lobeR * 0.42, Paint()..color = darker.withValues(alpha: 0.5));
      canvas.drawCircle(lc.translate(-lobeR * 0.15, -lobeR * 0.15), lobeR * 0.12,
          Paint()..color = Colors.white);
    }

    // Center bearing.
    canvas.drawCircle(c, r * 0.17, Paint()..color = Colors.white);
    canvas.drawCircle(c, r * 0.11, Paint()..color = CalmColors.ink.withValues(alpha: 0.8));
    canvas.drawCircle(c.translate(-r * 0.03, -r * 0.03), r * 0.03,
        Paint()..color = Colors.white.withValues(alpha: 0.8));

    // Motion streaks when spinning fast.
    if (blur > 120) {
      final strength = ((blur - 120) / 600).clamp(0.0, 0.5);
      canvas.drawCircle(
        c,
        armLen,
        Paint()
          ..color = color.withValues(alpha: strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = lobeR * 1.6
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
  }

  @override
  bool shouldRepaint(_SpinnerPainter old) =>
      old.color != color || old.blur != blur;
}
