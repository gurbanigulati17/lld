import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../audio/sfx.dart';
import '../theme.dart';

/// Fairy Glow: a little fairy shelters under a flower umbrella topped with a
/// glowing star. Slide her left and right to catch falling stars and keep the
/// lamp lit; dodge the gloom drops that dim it.
class FairyGlowGame extends StatefulWidget {
  const FairyGlowGame({super.key});

  @override
  State<FairyGlowGame> createState() => _FairyGlowGameState();
}

enum _Phase { ready, playing, over }

enum _Kind { star, firefly, gloom }

class _Item {
  _Item(this.kind, this.p, this.speed, this.phase);
  final _Kind kind;
  Offset p;
  final double speed;
  final double phase;
}

class _Sparkle {
  _Sparkle(this.p, this.v, this.color, this.size);
  Offset p;
  Offset v;
  final Color color;
  final double size;
  double life = 1;
}

class _Float {
  _Float(this.text, this.p, this.color);
  final String text;
  Offset p;
  final Color color;
  double life = 1.2;
}

class _Meadow extends ChangeNotifier {
  _Meadow() {
    final r = Random(3);
    for (var i = 0; i < 70; i++) {
      skyStars.add(Offset(r.nextDouble(), r.nextDouble() * 0.6));
      twinkle.add(r.nextDouble() * pi * 2);
    }
    for (var i = 0; i < 160; i++) {
      lavender.add((r.nextDouble(), r.nextDouble(), r.nextDouble()));
    }
  }

  final _rand = Random();
  final skyStars = <Offset>[];
  final twinkle = <double>[];
  final lavender = <(double, double, double)>[];

  Size size = Size.zero;
  _Phase phase = _Phase.ready;
  double t = 0;
  double playTime = 0;

  double fairyX = 0;
  double _targetX = 0;
  double tilt = 0;
  double oops = 0; // >0 while she's startled by a gloom drop

  double glow = 70;
  int score = 0;
  int best = 0;
  bool newBest = false;
  int chain = 0;

  final items = <_Item>[];
  final sparkles = <_Sparkle>[];
  final floats = <_Float>[];
  double _spawn = 0.6;

  double get groundY => size.height * 0.86;
  double get scale => (size.width / 400).clamp(0.75, 1.4);

  /// Centre of the glowing star on top of the umbrella.
  Offset get lamp => Offset(fairyX + 6 * scale, groundY - 226 * scale);

  void resize(Size s) {
    if (s == size) return;
    final first = size == Size.zero;
    size = s;
    if (first) fairyX = _targetX = s.width / 2;
  }

  void reset() {
    items.clear();
    sparkles.clear();
    floats.clear();
    glow = 70;
    score = 0;
    chain = 0;
    playTime = 0;
    newBest = false;
    _spawn = 0.6;
    phase = _Phase.playing;
    notifyListeners();
  }

  void slide(double dx) {
    if (phase != _Phase.playing) return;
    _targetX = (_targetX + dx * 1.2).clamp(80 * scale, size.width - 80 * scale);
  }

  void update(double dt) {
    t += dt;
    oops = max(0, oops - dt);

    // Ease the fairy toward the finger and lean into the motion.
    final prev = fairyX;
    fairyX += (_targetX - fairyX) * min(1, dt * 12);
    final v = (fairyX - prev) / max(dt, 1e-3);
    tilt += ((v / 900).clamp(-0.25, 0.25) - tilt) * min(1, dt * 8);

    for (final s in sparkles) {
      s.p += s.v * dt;
      s.v = Offset(s.v.dx * 0.96, s.v.dy * 0.96 + 30 * dt);
      s.life -= dt * 1.3;
    }
    sparkles.removeWhere((s) => s.life <= 0);
    for (final f in floats) {
      f.p = f.p.translate(0, -40 * dt);
      f.life -= dt;
    }
    floats.removeWhere((f) => f.life <= 0);

    if (phase == _Phase.playing) _play(dt);
    notifyListeners();
  }

  void _play(double dt) {
    playTime += dt;
    glow -= (3.5 + playTime * 0.04) * dt;

    _spawn -= dt;
    if (_spawn <= 0) {
      _spawn = max(0.35, 0.9 - playTime * 0.006) * (0.7 + _rand.nextDouble() * 0.6);
      final roll = _rand.nextDouble();
      final gloomChance = min(0.4, 0.15 + playTime * 0.004);
      final kind = roll < gloomChance
          ? _Kind.gloom
          : roll < gloomChance + 0.1
              ? _Kind.firefly
              : _Kind.star;
      final speed = (90 + _rand.nextDouble() * 60) * (1 + min(playTime / 120, 1.2));
      items.add(_Item(kind, Offset(30 + _rand.nextDouble() * (size.width - 60), -20), speed,
          _rand.nextDouble() * pi * 2));
    }

    final catchY = lamp.dy;
    final catchR = 62 * scale;
    for (final it in List.of(items)) {
      final sway = it.kind == _Kind.firefly ? sin(t * 3 + it.phase) * 60 : sin(t * 1.5 + it.phase) * 14;
      it.p = Offset(it.p.dx + sway * dt, it.p.dy + it.speed * dt);
      final d = (it.p - lamp).distance;
      // The petal canopy also catches things that land on it.
      final dy = it.p.dy - catchY;
      final onCanopy = (it.p.dx - lamp.dx).abs() < 85 * scale && dy > 20 * scale && dy < 60 * scale;
      if (d < catchR || onCanopy) {
        items.remove(it);
        _caught(it);
      } else if (it.p.dy > size.height + 20) {
        items.remove(it);
        if (it.kind == _Kind.star) chain = 0;
      }
    }

    glow = glow.clamp(0, 100);
    if (glow <= 0) {
      phase = _Phase.over;
      Sfx.instance.pauseMusic();
      Sfx.instance.play('gameover', volume: 0.6);
      if (score > best) {
        best = score;
        newBest = true;
      }
    }
  }

  void _caught(_Item it) {
    switch (it.kind) {
      case _Kind.star:
        HapticFeedback.lightImpact();
        chain++;
        score++;
        glow += 9;
        // Each star in a row plays the next note up the scale.
        Sfx.instance.play('drop_${min(chain - 1, 7)}', volume: 0.8);
        _burst(it.p, 12, CalmColors.lemon);
      case _Kind.firefly:
        HapticFeedback.mediumImpact();
        score += 3;
        glow += 18;
        Sfx.instance.play('sparkle');
        floats.add(_Float('+3', it.p, const Color(0xFFD8FF8A)));
        _burst(it.p, 18, const Color(0xFFD8FF8A));
      case _Kind.gloom:
        HapticFeedback.heavyImpact();
        chain = 0;
        glow -= 25;
        oops = 0.8;
        Sfx.instance.play('dim');
        floats.add(_Float('-glow', it.p, const Color(0xFF9DA8D8)));
        _burst(it.p, 14, const Color(0xFF55608F));
    }
  }

  void _burst(Offset at, int n, Color c) {
    for (var i = 0; i < n; i++) {
      final a = _rand.nextDouble() * pi * 2;
      final s = 40 + _rand.nextDouble() * 140;
      sparkles.add(_Sparkle(at, Offset(cos(a), sin(a)) * s, c, 1.5 + _rand.nextDouble() * 2.5));
    }
  }
}

class _FairyGlowGameState extends State<FairyGlowGame> with SingleTickerProviderStateMixin {
  static const _bestKey = 'fairy_glow_best';

  final _m = _Meadow();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    Sfx.instance.preload([for (var i = 0; i < 8; i++) 'drop_$i', 'sparkle', 'dim', 'gameover', 'start']);
    Sfx.instance.playMusic('music_fairy', volume: 0.4);
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    _m.best = prefs.getInt(_bestKey) ?? 0;
  }

  @override
  void dispose() {
    Sfx.instance.stopMusic();
    _ticker.dispose();
    _m.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    final wasPlaying = _m.phase == _Phase.playing;
    _m.update(dt);
    if (wasPlaying && _m.phase == _Phase.over) {
      if (_m.newBest) {
        SharedPreferences.getInstance().then((p) => p.setInt(_bestKey, _m.best));
      }
      setState(() {});
    }
  }

  void _start() {
    HapticFeedback.mediumImpact();
    Sfx.instance.play('sheet', volume: 0.6);
    Sfx.instance.playMusic('music_fairy', volume: 0.4);
    setState(_m.reset);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1A4A),
      body: LayoutBuilder(builder: (context, c) {
        _m.resize(c.biggest);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => _m.slide(d.delta.dx),
                child: CustomPaint(painter: _MeadowPainter(_m)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ListenableBuilder(
                  listenable: _m,
                  builder: (context, _) => _Hud(m: _m),
                ),
              ),
            ),
            if (_m.phase != _Phase.playing)
              Positioned.fill(child: _Overlay(m: _m, onStart: _start)),
          ],
        );
      }),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.m});

  final _Meadow m;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const Icon(Icons.star_rounded, color: CalmColors.lemon, size: 22),
          const SizedBox(width: 4),
          Text('${m.score}',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Star glow',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11)),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: m.glow / 100,
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(const Color(0xFF8C7BD8), CalmColors.lemon, m.glow / 100)!,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SoundToggle(color: Colors.white),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.m, required this.onStart});

  final _Meadow m;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ready = m.phase == _Phase.ready;
    Widget row(Widget icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(width: 26, child: Center(child: icon)),
            const SizedBox(width: 8),
            SizedBox(
                width: 170,
                child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))),
          ]),
        );
    return ColoredBox(
      color: Colors.black.withValues(alpha: ready ? 0.15 : 0.35),
      child: Align(
        alignment: const Alignment(0, -0.35),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2468).withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: CalmColors.lemon.withValues(alpha: 0.35)),
            boxShadow: [BoxShadow(color: CalmColors.lemon.withValues(alpha: 0.15), blurRadius: 30)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(ready ? 'Fairy Glow' : (m.newBest ? 'New best! ✨' : 'The night grew dark'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                ready
                    ? 'Slide the fairy to catch falling stars and keep her star lamp glowing.'
                    : 'You caught ${m.score} stars  ·  Best ${m.best}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.35),
              ),
              if (ready) ...[
                const SizedBox(height: 14),
                row(const Icon(Icons.star_rounded, color: CalmColors.lemon), 'Star: +glow'),
                row(const Icon(Icons.circle, color: Color(0xFFD8FF8A), size: 14), 'Firefly: +3 and big glow'),
                row(const Icon(Icons.water_drop_rounded, color: Color(0xFF6C77A8)), 'Gloom drop: avoid!'),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: CalmColors.lemon,
                  foregroundColor: CalmColors.ink,
                ),
                onPressed: onStart,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: Text(ready ? 'Play' : 'Play again'),
              ),
              if (ready && m.best > 0) ...[
                const SizedBox(height: 10),
                Text('Best ${m.best}', style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _MeadowPainter extends CustomPainter {
  _MeadowPainter(this.m) : super(repaint: m);

  final _Meadow m;

  static const _petal = Color(0xFF6F5BD6);
  static const _petalDeep = Color(0xFF4B3AA8);
  static const _skin = Color(0xFFFFE1CF);
  static const _hair = Color(0xFFF2D28C);
  static const _hairShade = Color(0xFFDDB46A);

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas, size);
    _field(canvas, size, back: true);
    _fairy(canvas);
    _field(canvas, size, back: false);
    _items(canvas);
    _effects(canvas);
  }

  void _sky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF14123A), Color(0xFF2A2366), Color(0xFF4A3A8C), Color(0xFF6A4FA8)],
          stops: [0, 0.45, 0.75, 1],
        ).createShader(rect),
    );
    // Moon.
    final moon = Offset(size.width * 0.8, size.height * 0.14);
    canvas.drawCircle(moon, 46, Paint()..color = const Color(0x33FFF3C4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));
    canvas.drawCircle(moon, 22, Paint()..color = const Color(0xFFFFF6DA));
    canvas.drawCircle(moon.translate(9, -5), 20, Paint()..color = const Color(0xFF1C1848));

    final p = Paint();
    for (var i = 0; i < m.skyStars.length; i++) {
      final s = m.skyStars[i];
      final a = 0.35 + 0.35 * sin(m.t * 1.4 + m.twinkle[i]);
      p.color = Colors.white.withValues(alpha: a);
      canvas.drawCircle(Offset(s.dx * size.width, s.dy * size.height), 1.2, p);
    }
    // Distant hills.
    final hills = Path()..moveTo(0, size.height * 0.74);
    for (var x = 0.0; x <= size.width; x += 20) {
      hills.lineTo(x, size.height * 0.74 - 18 * sin(x / size.width * pi * 2.2 + 0.6) - 10);
    }
    hills
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hills, Paint()..color = const Color(0xFF2B2160));
  }

  void _field(Canvas canvas, Size size, {required bool back}) {
    final top = size.height * 0.76;
    if (back) {
      canvas.drawRect(Rect.fromLTRB(0, top, size.width, size.height),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3B2B83), Color(0xFF261C5C)],
            ).createShader(Rect.fromLTRB(0, top, size.width, size.height)));
    }
    final stem = Paint()
      ..color = const Color(0xFF3E6B5A)
      ..strokeWidth = 1.4;
    final bloom = Paint();
    for (final (x, y, h) in m.lavender) {
      final isBack = y < 0.5;
      if (isBack != back) continue;
      final bx = x * size.width;
      final by = top + y * (size.height - top) + 10;
      final height = (back ? 26 : 40) + h * 22;
      final sway = sin(m.t * 1.2 + x * 9) * 4;
      final tip = Offset(bx + sway, by - height);
      canvas.drawLine(Offset(bx, by), tip, stem);
      bloom.color = Color.lerp(const Color(0xFF7D5CE0), const Color(0xFFB79CFF), h)!
          .withValues(alpha: back ? 0.75 : 1);
      for (var k = 0; k < 5; k++) {
        canvas.drawCircle(tip.translate(sin(k * 1.7) * 1.5, k * 3.2), 2.6 - k * 0.25, bloom);
      }
    }
  }

  void _fairy(Canvas canvas) {
    final s = m.scale;
    final bob = sin(m.t * 2) * 4 * s;
    final base = Offset(m.fairyX, m.groundY - 60 * s + bob);
    final glow = m.glow / 100;

    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.rotate(m.tilt);
    canvas.scale(s);

    // Warm light pooling on the meadow under the lamp.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 62), width: 200, height: 40),
      Paint()
        ..color = CalmColors.lemon.withValues(alpha: 0.12 + 0.18 * glow)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Wings (flutter).
    final flap = 0.85 + 0.15 * sin(m.t * 9);
    final wing = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xCCBFE6FF), Color(0xAAF7B8E6), Color(0x88FFF2B0)],
      ).createShader(const Rect.fromLTWH(-80, -70, 160, 110));
    final edge = Paint()
      ..color = const Color(0xFFFFF1C2).withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final side in [-1.0, 1.0]) {
      for (final (dy, w, h, ang) in [(-28.0, 62.0, 40.0, -0.5), (6.0, 44.0, 30.0, 0.35)]) {
        canvas.save();
        canvas.translate(side * 16, dy);
        canvas.scale(side * flap, 1);
        canvas.rotate(ang);
        final r = Rect.fromLTWH(0, -h / 2, w, h);
        canvas.drawOval(r, wing);
        canvas.drawOval(r, edge);
        canvas.restore();
      }
    }

    // Petal dress.
    for (var i = 0; i < 7; i++) {
      final a = -0.9 + i * 0.3;
      canvas.save();
      canvas.translate(0, 8);
      canvas.rotate(a);
      canvas.drawOval(
        const Rect.fromLTWH(-11, 0, 22, 50),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF9A86F0), _petalDeep],
          ).createShader(const Rect.fromLTWH(-11, 0, 22, 50)),
      );
      canvas.restore();
    }
    // Bodice + tiny flowers.
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -14, 26, 28), const Radius.circular(10)),
        Paint()..color = const Color(0xFF8B74E6));
    for (final x in [-9.0, 0.0, 9.0]) {
      _flower(canvas, Offset(x, -10), 3.2, Colors.white);
    }

    // Arm reaching up to the umbrella stem.
    final arm = Paint()
      ..color = _skin
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-10, -6), const Offset(4, -20), arm);
    canvas.drawLine(const Offset(10, -6), const Offset(7, -14), arm);

    // Umbrella stem.
    canvas.drawLine(
        const Offset(6, 30),
        const Offset(6, -128),
        Paint()
          ..color = const Color(0xFF3F7D55)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(const Offset(6, -18), 4.5, Paint()..color = _skin); // hand

    _head(canvas);
    _umbrella(canvas, glow);

    canvas.restore();
  }

  void _head(Canvas canvas) {
    const c = Offset(0, -46);
    // Hair behind.
    final hair = Paint()..color = _hair;
    final shade = Paint()..color = _hairShade;
    for (final (o, r) in [
      (const Offset(-26, 6), 13.0),
      (const Offset(26, 6), 13.0),
      (const Offset(-28, 22), 11.0),
      (const Offset(28, 22), 11.0),
      (const Offset(-22, 34), 9.0),
      (const Offset(22, 34), 9.0),
    ]) {
      canvas.drawCircle(c + o + const Offset(1, 2), r, shade);
      canvas.drawCircle(c + o, r, hair);
    }
    canvas.drawCircle(c, 30, hair);
    // Face.
    canvas.drawOval(Rect.fromCenter(center: c.translate(0, 6), width: 50, height: 46), Paint()..color = _skin);
    // Fringe.
    final fringe = Path()
      ..moveTo(c.dx - 27, c.dy + 2)
      ..quadraticBezierTo(c.dx - 18, c.dy - 30, c.dx + 4, c.dy - 28)
      ..quadraticBezierTo(c.dx + 26, c.dy - 26, c.dx + 27, c.dy + 2)
      ..quadraticBezierTo(c.dx + 14, c.dy - 10, c.dx + 2, c.dy - 6)
      ..quadraticBezierTo(c.dx - 12, c.dy - 12, c.dx - 27, c.dy + 2)
      ..close();
    canvas.drawPath(fringe, hair);
    // Flower crown.
    final crown = [CalmColors.sky, Colors.white, const Color(0xFF8E7BEF), Colors.white, CalmColors.sky];
    for (var i = 0; i < 5; i++) {
      final a = pi + 0.35 + i * 0.6;
      _flower(canvas, c + Offset(cos(a), sin(a)) * 27, 4.5, crown[i]);
    }

    final ink = Paint()
      ..color = const Color(0xFF5A3D3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    if (m.oops > 0) {
      // Startled: little round eyes and an "o" mouth.
      canvas.drawCircle(c.translate(-10, 8), 2.8, ink..style = PaintingStyle.fill);
      canvas.drawCircle(c.translate(10, 8), 2.8, ink);
      canvas.drawCircle(c.translate(0, 19), 2.6, ink..style = PaintingStyle.stroke);
    } else {
      // Happy closed eyes and smile.
      canvas.drawArc(Rect.fromCenter(center: c.translate(-10, 9), width: 11, height: 8), pi, pi, false, ink);
      canvas.drawArc(Rect.fromCenter(center: c.translate(10, 9), width: 11, height: 8), pi, pi, false, ink);
      canvas.drawArc(Rect.fromCenter(center: c.translate(0, 16), width: 12, height: 8), 0.2, pi - 0.4, false, ink);
    }
    final blush = Paint()
      ..color = const Color(0xFFFF9EB0).withValues(alpha: 0.55)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(c.translate(-16, 15), 5, blush);
    canvas.drawCircle(c.translate(16, 15), 5, blush);
  }

  void _umbrella(Canvas canvas, double glow) {
    const top = Offset(6, -130);
    // Star lamp sits in the flower's centre.
    final lamp = top.translate(0, -36);
    canvas.drawCircle(
      lamp,
      60 + 40 * glow,
      Paint()
        ..color = CalmColors.lemon.withValues(alpha: 0.08 + 0.3 * glow)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 26 + 20 * glow),
    );
    final star = _starPath(lamp, 34, 15, -pi / 2 + sin(m.t) * 0.05);
    canvas.drawPath(
      star,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.lerp(const Color(0xFFBFB2E6), const Color(0xFFFFFBEA), sqrt(glow))!,
          Color.lerp(const Color(0xFF8E7FC4), const Color(0xFFFFB84D), sqrt(glow))!,
        ]).createShader(Rect.fromCircle(center: lamp, radius: 34)),
    );
    // Stamen tuft.
    final stamen = Paint()
      ..color = const Color(0xFFFFE08A)
      ..strokeWidth = 1.5;
    for (var i = -4; i <= 4; i++) {
      canvas.drawLine(top.translate(i * 3.0, -2), top.translate(i * 4.0, -12 + i.abs() * 1.0), stamen);
    }

    // Drooping petals fanning out from the flower's centre, back row first.
    const deg = pi / 180;
    for (final (ang, len, w, back) in [
      (198 * deg, 70.0, 40.0, true),
      (-18 * deg, 70.0, 40.0, true),
      (172 * deg, 86.0, 46.0, false),
      (8 * deg, 86.0, 46.0, false),
      (146 * deg, 82.0, 48.0, false),
      (34 * deg, 82.0, 48.0, false),
      (122 * deg, 66.0, 44.0, false),
      (58 * deg, 66.0, 44.0, false),
    ]) {
      canvas.save();
      canvas.translate(top.dx, top.dy);
      canvas.rotate(ang);
      final r = Rect.fromLTWH(-6, -w / 2, len, w);
      canvas.drawOval(
        r,
        Paint()
          ..shader = LinearGradient(
            colors: back
                ? const [Color(0xFF5A48B8), _petalDeep]
                : const [Color(0xFFA897F5), _petal, _petalDeep],
          ).createShader(r),
      );
      canvas.drawLine(const Offset(4, 0), Offset(len - 12, 0),
          Paint()
            ..color = Colors.white.withValues(alpha: back ? 0.08 : 0.2)
            ..strokeWidth = 1.2);
      if (!back) {
        // Dew drops.
        final dew = Paint()..color = Colors.white.withValues(alpha: 0.6);
        canvas.drawCircle(Offset(len * 0.5, -w * 0.18), 2.6, dew);
        canvas.drawCircle(Offset(len * 0.75, w * 0.12), 1.9, dew);
      }
      canvas.restore();
    }
    // A dew drop dangling from a petal tip.
    final drip = top.translate(-74, 40 + sin(m.t * 2) * 2);
    canvas.drawCircle(drip, 3.4, Paint()..color = const Color(0xCCDFF3FF));
  }

  void _items(Canvas canvas) {
    for (final it in m.items) {
      switch (it.kind) {
        case _Kind.star:
          canvas.drawCircle(it.p, 16,
              Paint()
                ..color = CalmColors.lemon.withValues(alpha: 0.35)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          canvas.drawPath(_starPath(it.p, 11, 5, m.t * 1.5 + it.phase), Paint()..color = const Color(0xFFFFE7A3));
        case _Kind.firefly:
          final pulse = 0.6 + 0.4 * sin(m.t * 8 + it.phase);
          canvas.drawCircle(it.p, 14,
              Paint()
                ..color = const Color(0xFFD8FF8A).withValues(alpha: 0.5 * pulse)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
          canvas.drawCircle(it.p, 4.5, Paint()..color = const Color(0xFFF2FFC8));
          final wing = Paint()..color = Colors.white.withValues(alpha: 0.5);
          canvas.drawOval(Rect.fromCenter(center: it.p.translate(-5, -4), width: 7, height: 4), wing);
          canvas.drawOval(Rect.fromCenter(center: it.p.translate(5, -4), width: 7, height: 4), wing);
        case _Kind.gloom:
          final drop = Path()
            ..moveTo(it.p.dx, it.p.dy - 16)
            ..quadraticBezierTo(it.p.dx + 12, it.p.dy, it.p.dx, it.p.dy + 8)
            ..quadraticBezierTo(it.p.dx - 12, it.p.dy, it.p.dx, it.p.dy - 16)
            ..close();
          canvas.drawPath(drop,
              Paint()
                ..color = const Color(0xFF0E0D26).withValues(alpha: 0.6)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
          canvas.drawPath(drop, Paint()..color = const Color(0xFF4A5383));
          final face = Paint()
            ..color = const Color(0xFF1E2140)
            ..strokeWidth = 1.4
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(it.p.translate(-3, -1), 1, face);
          canvas.drawCircle(it.p.translate(3, -1), 1, face);
          canvas.drawArc(Rect.fromCenter(center: it.p.translate(0, 5), width: 6, height: 4), pi + 0.3, pi - 0.6, false, face);
      }
    }
  }

  void _effects(Canvas canvas) {
    final p = Paint();
    for (final s in m.sparkles) {
      p.color = s.color.withValues(alpha: s.life.clamp(0.0, 1.0));
      canvas.drawCircle(s.p, s.size, p);
    }
    for (final f in m.floats) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(color: f.color.withValues(alpha: f.life.clamp(0.0, 1.0)), fontWeight: FontWeight.w800, fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, f.p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _flower(Canvas canvas, Offset c, double r, Color color) {
    final p = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final a = i * 2 * pi / 5;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * r * 0.6, r * 0.55, p);
    }
    canvas.drawCircle(c, r * 0.35, Paint()..color = const Color(0xFFFFD36B));
  }

  static Path _starPath(Offset c, double outer, double inner, double rot) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = rot + i * pi / 5;
      final pt = c + Offset(cos(a), sin(a)) * r;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_MeadowPainter old) => false;
}
