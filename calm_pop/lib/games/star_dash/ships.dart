import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';

enum ShotPattern { single, twin, spread }

class ShipSpec {
  const ShipSpec({
    required this.id,
    required this.name,
    required this.perk,
    required this.stars,
    required this.colors,
    required this.pattern,
    this.fireEvery = 0.2,
    this.handling = 1.0,
    this.startShield = 0,
  });

  final String id;
  final String name;
  final String perk;

  /// Total stars needed to unlock.
  final int stars;

  /// Light, mid and dark body colours.
  final List<Color> colors;
  final ShotPattern pattern;
  final double fireEvery;
  final double handling;
  final double startShield;
}

const ships = <ShipSpec>[
  ShipSpec(
    id: 'lumi',
    name: 'Lumi',
    perk: 'Trusty starter ship',
    stars: 0,
    colors: [Colors.white, CalmColors.lavender, Color(0xFF7D6FD6)],
    pattern: ShotPattern.single,
  ),
  ShipSpec(
    id: 'zephyr',
    name: 'Zephyr',
    perk: 'Fires faster, steers quicker',
    stars: 8,
    colors: [Color(0xFFE8FFF7), CalmColors.mint, Color(0xFF2E9C86)],
    pattern: ShotPattern.single,
    fireEvery: 0.13,
    handling: 1.25,
  ),
  ShipSpec(
    id: 'nova',
    name: 'Nova',
    perk: 'Twin cannons',
    stars: 16,
    colors: [Color(0xFFFFF6DA), CalmColors.lemon, Color(0xFFE08A3C)],
    pattern: ShotPattern.twin,
    fireEvery: 0.18,
  ),
  ShipSpec(
    id: 'aurora',
    name: 'Aurora',
    perk: 'Spread shot + starting shield',
    stars: 24,
    colors: [Color(0xFFFFEAF2), CalmColors.rose, Color(0xFFC2507E)],
    pattern: ShotPattern.spread,
    fireEvery: 0.2,
    startShield: 5,
  ),
];

ShipSpec shipById(String id) => ships.firstWhere((s) => s.id == id, orElse: () => ships.first);

/// Draws a ship centred at [p] with nominal radius [r].
void paintShip(Canvas canvas, Offset p, double r, ShipSpec s, {double flame = 1}) {
  final fl = (10 + Random().nextDouble() * 8) * flame;
  final flamePaint = Paint()
    ..color = CalmColors.peach
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  void engine(double x) => canvas.drawPath(
      Path()
        ..moveTo(p.dx + x - 6, p.dy + r * 0.6)
        ..lineTo(p.dx + x, p.dy + r * 0.6 + fl)
        ..lineTo(p.dx + x + 6, p.dy + r * 0.6)
        ..close(),
      flamePaint);

  final body = Path();
  switch (s.id) {
    case 'zephyr':
      engine(0);
      body
        ..moveTo(p.dx, p.dy - r * 1.4)
        ..lineTo(p.dx + r * 0.3, p.dy - r * 0.2)
        ..lineTo(p.dx + r * 1.15, p.dy + r * 0.9)
        ..lineTo(p.dx + r * 0.25, p.dy + r * 0.5)
        ..lineTo(p.dx - r * 0.25, p.dy + r * 0.5)
        ..lineTo(p.dx - r * 1.15, p.dy + r * 0.9)
        ..lineTo(p.dx - r * 0.3, p.dy - r * 0.2)
        ..close();
    case 'nova':
      engine(-r * 0.7);
      engine(r * 0.7);
      body
        ..moveTo(p.dx, p.dy - r * 1.1)
        ..quadraticBezierTo(p.dx + r * 0.4, p.dy - r * 0.6, p.dx + r * 0.45, p.dy - r * 0.1)
        ..lineTo(p.dx + r * 1.2, p.dy + r * 0.1)
        ..lineTo(p.dx + r * 1.2, p.dy + r * 0.7)
        ..lineTo(p.dx - r * 1.2, p.dy + r * 0.7)
        ..lineTo(p.dx - r * 1.2, p.dy + r * 0.1)
        ..lineTo(p.dx - r * 0.45, p.dy - r * 0.1)
        ..quadraticBezierTo(p.dx - r * 0.4, p.dy - r * 0.6, p.dx, p.dy - r * 1.1)
        ..close();
    case 'aurora':
      engine(0);
      body
        ..addOval(Rect.fromCenter(center: p.translate(0, -r * 0.1), width: r * 1.1, height: r * 2.2))
        ..addPolygon([
          p.translate(-r * 0.4, 0),
          p.translate(-r * 1.25, r * 0.55),
          p.translate(-r * 0.4, r * 0.7),
        ], true)
        ..addPolygon([
          p.translate(r * 0.4, 0),
          p.translate(r * 1.25, r * 0.55),
          p.translate(r * 0.4, r * 0.7),
        ], true);
    default:
      engine(0);
      body
        ..moveTo(p.dx, p.dy - r * 1.2)
        ..quadraticBezierTo(p.dx + r * 0.5, p.dy - r * 0.2, p.dx + r, p.dy + r * 0.7)
        ..lineTo(p.dx + r * 0.35, p.dy + r * 0.45)
        ..lineTo(p.dx - r * 0.35, p.dy + r * 0.45)
        ..lineTo(p.dx - r, p.dy + r * 0.7)
        ..quadraticBezierTo(p.dx - r * 0.5, p.dy - r * 0.2, p.dx, p.dy - r * 1.2)
        ..close();
  }

  canvas.drawPath(
      body,
      Paint()
        ..color = s.colors[1].withValues(alpha: 0.6)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: s.colors,
        ).createShader(Rect.fromCircle(center: p, radius: r * 1.3)));
  if (s.id == 'aurora') {
    canvas.drawCircle(
        p.translate(0, r * 0.2),
        r * 1.0,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }
  // Cockpit.
  canvas.drawOval(Rect.fromCenter(center: p.translate(0, -r * 0.3), width: r * 0.5, height: r * 0.8),
      Paint()..color = CalmColors.sky);
  canvas.drawCircle(p.translate(-r * 0.08, -r * 0.45), r * 0.1, Paint()..color = Colors.white.withValues(alpha: 0.8));
}

/// Widget preview of a ship, used in the hangar and on the map.
class ShipPreview extends StatelessWidget {
  const ShipPreview({super.key, required this.ship, this.size = 64, this.locked = false});

  final ShipSpec ship;
  final double size;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: locked ? 0.35 : 1,
      child: CustomPaint(size: Size.square(size), painter: _ShipPreviewPainter(ship)),
    );
  }
}

class _ShipPreviewPainter extends CustomPainter {
  _ShipPreviewPainter(this.ship);

  final ShipSpec ship;

  @override
  void paint(Canvas canvas, Size size) {
    paintShip(canvas, size.center(Offset(0, -size.height * 0.05)), size.shortestSide * 0.28, ship, flame: 0.7);
  }

  @override
  bool shouldRepaint(_ShipPreviewPainter old) => old.ship != ship;
}
