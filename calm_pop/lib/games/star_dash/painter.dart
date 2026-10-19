import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme.dart';
import 'levels.dart';
import 'ships.dart';
import 'world.dart';

/// Paints a sector backdrop: sky gradient, drifting nebula, a big planet.
void paintSectorBackdrop(Canvas canvas, Size size, Sector theme, double clock) {
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: theme.sky,
      ).createShader(rect),
  );
  for (var i = 0; i < 3; i++) {
    final c = theme.nebula[i % theme.nebula.length];
    final center = Offset(
      size.width * (0.2 + 0.6 * ((i * 0.37 + clock * 0.01) % 1)),
      size.height * (0.25 + 0.25 * i) + sin(clock * 0.2 + i) * 30,
    );
    canvas.drawCircle(
      center,
      size.width * (0.35 + 0.1 * i),
      Paint()
        ..color = c.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );
  }
  // Planet peeking in from the side.
  final pc = Offset(size.width * 1.02, size.height * 0.62);
  final pr = size.width * 0.32;
  if (theme.ringed) {
    final ring = Paint()
      ..color = theme.planet.first.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.save();
    canvas.translate(pc.dx, pc.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: pr * 3.2, height: pr * 0.7), ring);
    canvas.restore();
  }
  canvas.drawCircle(
    pc,
    pr,
    Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.6, -0.5),
        colors: [theme.planet.first.withValues(alpha: 0.55), theme.planet.last.withValues(alpha: 0.45)],
      ).createShader(Rect.fromCircle(center: pc, radius: pr)),
  );
}

class DashPainter extends CustomPainter {
  DashPainter(this.world) : super(repaint: world);

  final DashWorld world;

  @override
  void paint(Canvas canvas, Size size) {
    final w = world;
    paintSectorBackdrop(canvas, size, w.theme, w.clock);

    if (w.shake > 0) {
      final r = Random();
      canvas.translate((r.nextDouble() - 0.5) * 12 * w.shake, (r.nextDouble() - 0.5) * 12 * w.shake);
    }

    final starPaint = Paint();
    for (final s in w.bg) {
      starPaint.color = Color.lerp(Colors.white, w.theme.accent, 0.3)!.withValues(alpha: 0.25 + s.depth * 0.6);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), 0.6 + s.depth * 1.4, starPaint);
    }

    for (final p in w.pickups) {
      _pickup(canvas, p);
    }
    for (final e in w.enemies) {
      switch (e.kind) {
        case Foe.rock:
          _rock(canvas, e);
        case Foe.comet:
          _comet(canvas, e);
        case Foe.ufo:
          _ufo(canvas, e, w);
        case Foe.mine:
          _mine(canvas, e, w);
      }
    }
    final b = w.boss;
    if (b != null) _boss(canvas, size, b, w);

    // Enemy shots.
    for (final s in w.shots) {
      canvas.drawCircle(s.p, s.r * 1.9,
          Paint()
            ..color = s.color.withValues(alpha: 0.45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      canvas.drawCircle(s.p, s.r, Paint()..color = s.color);
      canvas.drawCircle(s.p, s.r * 0.45, Paint()..color = Colors.white);
    }

    // Player bullets.
    final glow = Paint()
      ..color = w.ship.colors[1].withValues(alpha: 0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint()..color = Colors.white;
    for (final bl in w.bullets) {
      canvas.save();
      canvas.translate(bl.p.dx, bl.p.dy);
      canvas.rotate(atan2(bl.v.dx, -bl.v.dy));
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 4, height: 14),
          const Radius.circular(2));
      canvas.drawRRect(rect.inflate(2), glow);
      canvas.drawRRect(rect, core);
      canvas.restore();
    }

    final blink = w.invuln > 0 && (w.invuln * 10).floor().isEven;
    if (w.phase != DashPhase.lost && !blink) {
      paintShip(canvas, w.player, DashWorld.playerRadius, w.ship);
      if (w.shield > 0) {
        final fade = w.shield < 1.5 && (w.shield * 8).floor().isEven ? 0.3 : 1.0;
        canvas.drawCircle(w.player, DashWorld.playerRadius * 1.8,
            Paint()..color = CalmColors.sky.withValues(alpha: 0.22 * fade));
        canvas.drawCircle(
            w.player,
            DashWorld.playerRadius * 1.8,
            Paint()
              ..color = CalmColors.sky.withValues(alpha: 0.9 * fade)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2);
      }
    }

    for (final wv in w.waves) {
      final r = wv.maxR * Curves.easeOut.transform(wv.t);
      canvas.drawCircle(
          wv.p,
          r,
          Paint()
            ..color = wv.color.withValues(alpha: (1 - wv.t) * 0.8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6 * (1 - wv.t) + 1);
    }

    final pp = Paint();
    for (final p in w.particles) {
      pp.color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0));
      canvas.drawCircle(p.p, p.size, pp);
    }

    for (final f in w.floats) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
            color: f.color.withValues(alpha: f.life.clamp(0.0, 1.0)),
            fontWeight: FontWeight.w900,
            fontSize: f.big ? 24 : 16,
            shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, f.p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _pickup(Canvas canvas, Pickup p) {
    final c = DashWorld.pickupColor(p.kind);
    final pulse = 1 + sin(p.t * 6) * 0.1;
    canvas.drawCircle(p.p, 20 * pulse,
        Paint()
          ..color = c.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawCircle(p.p, 15, Paint()..color = c);
    final icon = DashWorld.pickupIcon(p.kind);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 18, color: CalmColors.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, p.p - Offset(tp.width / 2, tp.height / 2));
  }

  void _rock(Canvas canvas, Enemy r) {
    final path = Path();
    for (var i = 0; i < r.shape.length; i++) {
      final a = r.rot + i * 2 * pi / r.shape.length;
      final pt = r.p + Offset(cos(a), sin(a)) * r.r * r.shape[i];
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    final base = Color.lerp(r.color, Colors.white, r.flash * 0.7)!;
    canvas.drawPath(
        path,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: [Color.lerp(base, Colors.white, 0.3)!, base, Color.lerp(base, Colors.black, 0.35)!],
          ).createShader(Rect.fromCircle(center: r.p, radius: r.r)));
    canvas.drawCircle(r.p + Offset(cos(r.rot), sin(r.rot)) * r.r * 0.3, r.r * 0.18,
        Paint()..color = Colors.black.withValues(alpha: 0.18));
  }

  void _comet(Canvas canvas, Enemy e) {
    final dir = e.v / e.v.distance;
    for (var i = 8; i >= 1; i--) {
      canvas.drawCircle(
          e.p - dir * (i * 7.0),
          e.r * (1 - i / 10),
          Paint()
            ..color = const Color(0xFF9FE8FF).withValues(alpha: 0.5 * (1 - i / 9))
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
    }
    canvas.drawCircle(e.p, e.r * 1.8,
        Paint()
          ..color = const Color(0xFFBFF3FF).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawCircle(e.p, e.r, Paint()..color = Color.lerp(const Color(0xFFDFF8FF), Colors.white, e.flash)!);
  }

  void _ufo(Canvas canvas, Enemy e, DashWorld w) {
    final p = e.p;
    final c = Color.lerp(e.color, Colors.white, e.flash * 0.7)!;
    // Glass dome with a tiny alien inside.
    canvas.drawArc(Rect.fromCenter(center: p.translate(0, -2), width: 26, height: 26), pi, pi, true,
        Paint()..color = const Color(0xAA9FE8FF));
    canvas.drawCircle(p.translate(0, -4), 6, Paint()..color = const Color(0xFF7BE07B));
    final look = (w.player - p);
    final lookDir = look / max(look.distance, 1) * 1.4;
    canvas.drawCircle(p.translate(-2.2, -5) + lookDir, 1.4, Paint()..color = Colors.black);
    canvas.drawCircle(p.translate(2.2, -5) + lookDir, 1.4, Paint()..color = Colors.black);
    // Saucer.
    final saucer = Rect.fromCenter(center: p.translate(0, 4), width: e.r * 2.4, height: 14);
    canvas.drawOval(saucer,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(c, Colors.white, 0.3)!, c, Color.lerp(c, Colors.black, 0.4)!],
          ).createShader(saucer));
    for (var i = -2; i <= 2; i++) {
      final on = ((e.t * 4).floor() + i) % 3 == 0;
      canvas.drawCircle(p.translate(i * 9.0, 5), 2,
          Paint()..color = on ? CalmColors.lemon : Colors.white.withValues(alpha: 0.4));
    }
    canvas.drawOval(Rect.fromCenter(center: p.translate(0, 14), width: 22, height: 6),
        Paint()
          ..color = const Color(0xFF9FE8FF).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
  }

  void _mine(Canvas canvas, Enemy e, DashWorld w) {
    final p = e.p;
    final near = (w.player - p).distance < 170;
    final spike = Paint()
      ..color = const Color(0xFF6E2A28)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = e.rot + i * pi / 4;
      canvas.drawLine(p + Offset(cos(a), sin(a)) * e.r * 0.8, p + Offset(cos(a), sin(a)) * e.r * 1.35, spike);
    }
    canvas.drawCircle(
        p,
        e.r,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.3, -0.4),
            colors: [Color(0xFFB0504A), Color(0xFF5A1E1C)],
          ).createShader(Rect.fromCircle(center: p, radius: e.r)));
    final blink = (sin(e.t * (near ? 18 : 5)) > 0);
    canvas.drawCircle(p, 4.5, Paint()..color = blink ? const Color(0xFFFF4A3D) : const Color(0xFF4A1210));
    if (blink) {
      canvas.drawCircle(p, 10,
          Paint()
            ..color = const Color(0xFFFF4A3D).withValues(alpha: 0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
  }

  void _boss(Canvas canvas, Size size, Boss b, DashWorld w) {
    // Laser beam (telegraph line while charging, then the beam itself).
    if (b.beamCharge > 0) {
      final a = (sin(w.clock * 30) > 0) ? 0.8 : 0.3;
      canvas.drawLine(Offset(b.beamX, b.p.dy), Offset(b.beamX, size.height),
          Paint()
            ..color = const Color(0xFFFF4A6E).withValues(alpha: a)
            ..strokeWidth = 2);
      canvas.drawCircle(b.p.translate(0, b.height / 2), 8 + (1.1 - b.beamCharge) * 14,
          Paint()
            ..color = const Color(0xFFFF7AD9).withValues(alpha: 0.6)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
    if (b.beamOn > 0) {
      final rect = Rect.fromLTRB(b.beamX - 24, b.p.dy, b.beamX + 24, size.height);
      canvas.drawRect(rect.inflate(14),
          Paint()
            ..color = const Color(0xFFFF4AD0).withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16));
      canvas.drawRect(rect, Paint()..color = const Color(0xFFFF7AD9).withValues(alpha: 0.85));
      canvas.drawRect(Rect.fromLTRB(b.beamX - 8, b.p.dy, b.beamX + 8, size.height), Paint()..color = Colors.white);
    }

    final shakeX = b.dying > 0 ? (Random().nextDouble() - 0.5) * 8 : 0.0;
    final p = b.p.translate(shakeX, 0);
    final flash = b.flash * 0.6;

    if (b.kind == 1) {
      // Grumbo: a chubby giant saucer with one big googly eye.
      final hull = Color.lerp(const Color(0xFF55C79A), Colors.white, flash)!;
      canvas.drawCircle(p.translate(0, -8), 40, Paint()..color = const Color(0x889FE8FF));
      canvas.drawCircle(p.translate(0, -10), 22, Paint()..color = Colors.white);
      final look = w.player - p;
      final pupil = p.translate(0, -10) + look / max(look.distance, 1) * 9;
      canvas.drawCircle(pupil, 9, Paint()..color = const Color(0xFF2A1F4A));
      canvas.drawCircle(pupil.translate(-3, -3), 3, Paint()..color = Colors.white);
      final saucer = Rect.fromCenter(center: p.translate(0, 18), width: b.width, height: 40);
      canvas.drawOval(saucer,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color.lerp(hull, Colors.white, 0.35)!, hull, Color.lerp(hull, Colors.black, 0.45)!],
            ).createShader(saucer));
      for (var i = -3; i <= 3; i++) {
        final on = ((w.clock * 5).floor() + i) % 2 == 0;
        canvas.drawCircle(p.translate(i * 18.0, 20), 4,
            Paint()..color = on ? const Color(0xFFFF9EE6) : Colors.white.withValues(alpha: 0.4));
      }
      return;
    }

    // Mothership Omega.
    final stageColor = [const Color(0xFFFFD36B), const Color(0xFFFF9A4A), const Color(0xFFFF4A6E)][b.stage - 1];
    final hullC = Color.lerp(const Color(0xFF3B3355), Colors.white, flash)!;
    final hw = b.width / 2;
    final hh = b.height / 2;
    final hull = Path()
      ..moveTo(p.dx - hw, p.dy - hh * 0.2)
      ..lineTo(p.dx - hw * 0.6, p.dy - hh)
      ..lineTo(p.dx + hw * 0.6, p.dy - hh)
      ..lineTo(p.dx + hw, p.dy - hh * 0.2)
      ..lineTo(p.dx + hw * 0.7, p.dy + hh * 0.6)
      ..lineTo(p.dx + hw * 0.2, p.dy + hh)
      ..lineTo(p.dx - hw * 0.2, p.dy + hh)
      ..lineTo(p.dx - hw * 0.7, p.dy + hh * 0.6)
      ..close();
    canvas.drawPath(hull,
        Paint()
          ..color = stageColor.withValues(alpha: 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    canvas.drawPath(
        hull,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.lerp(hullC, Colors.white, 0.25)!, hullC, Color.lerp(hullC, Colors.black, 0.5)!],
          ).createShader(Rect.fromCenter(center: p, width: b.width, height: b.height)));
    // Side cannons.
    for (final s in [-1.0, 1.0]) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(s * hw * 0.78, hh * 0.35), width: 18, height: 30),
              const Radius.circular(6)),
          Paint()..color = const Color(0xFF2A2440));
      canvas.drawCircle(p.translate(s * hw * 0.78, hh * 0.35 + 14), 4, Paint()..color = stageColor);
    }
    // Panel lines.
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1.5;
    canvas.drawLine(p.translate(-hw * 0.6, -hh * 0.4), p.translate(hw * 0.6, -hh * 0.4), line);
    canvas.drawLine(p.translate(-hw * 0.75, hh * 0.2), p.translate(hw * 0.75, hh * 0.2), line);
    // Glowing core / eye.
    final pulse = 1 + sin(w.clock * (2 + b.stage * 2)) * 0.12;
    canvas.drawCircle(p, 26 * pulse,
        Paint()
          ..color = stageColor.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
    canvas.drawCircle(p, 18, Paint()..color = stageColor);
    final look = w.player - p;
    final pupil = p + look / max(look.distance, 1) * 6;
    canvas.drawOval(Rect.fromCenter(center: pupil, width: 8, height: 16), Paint()..color = const Color(0xFF1A0F1F));
  }

  @override
  bool shouldRepaint(DashPainter old) => false;
}
