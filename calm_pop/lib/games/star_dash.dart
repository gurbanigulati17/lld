import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';

/// Star Dash: an arcade space shooter. Drag to steer, the ship fires on its
/// own, blast asteroids and grab power-ups while the pace slowly ramps up.
class StarDashGame extends StatefulWidget {
  const StarDashGame({super.key});

  @override
  State<StarDashGame> createState() => _StarDashGameState();
}

enum _Phase { ready, playing, paused, over }

enum _PickupKind { star, heart, shield, rapid }

class _Bullet {
  _Bullet(this.p);
  Offset p;
}

class _Rock {
  _Rock(this.p, this.v, this.r, this.hp, this.spin, this.shape, this.color);
  Offset p;
  Offset v;
  final double r;
  int hp;
  double rot = 0;
  final double spin;
  final List<double> shape;
  final Color color;
  double flash = 0;
}

class _Pickup {
  _Pickup(this.kind, this.p);
  final _PickupKind kind;
  Offset p;
  double t = 0;
}

class _Particle {
  _Particle(this.p, this.v, this.life, this.color, this.size);
  Offset p;
  Offset v;
  double life;
  final double maxLife = 1;
  final Color color;
  final double size;
}

class _BgStar {
  _BgStar(this.x, this.y, this.depth);
  double x;
  double y;
  final double depth;
}

class _FloatText {
  _FloatText(this.text, this.p, this.color);
  final String text;
  Offset p;
  final Color color;
  double life = 1;
}

/// All mutable game state plus the simulation step. Notifies listeners every
/// frame so the painter and HUD redraw.
class _World extends ChangeNotifier {
  _World() {
    for (var i = 0; i < 90; i++) {
      bg.add(_BgStar(_rand.nextDouble(), _rand.nextDouble(), 0.2 + _rand.nextDouble() * 0.8));
    }
  }

  static const playerRadius = 18.0;
  static const maxLives = 5;

  final _rand = Random();
  Size size = Size.zero;

  _Phase phase = _Phase.ready;
  Offset player = Offset.zero;
  final bullets = <_Bullet>[];
  final rocks = <_Rock>[];
  final pickups = <_Pickup>[];
  final particles = <_Particle>[];
  final floats = <_FloatText>[];
  final bg = <_BgStar>[];

  int score = 0;
  int best = 0;
  bool newBest = false;
  int lives = 3;
  int combo = 0;
  double time = 0;
  double invuln = 0;
  double shield = 0;
  double rapid = 0;
  double shake = 0;
  double _fireCooldown = 0;
  double _spawnCooldown = 0.8;
  double _pickupCooldown = 6;

  int get level => 1 + (time / 20).floor();
  double get _speedScale => 1 + min(time / 90, 1.6);

  void resize(Size s) {
    if (s == size) return;
    final first = size == Size.zero;
    size = s;
    if (first || phase == _Phase.ready) {
      player = Offset(s.width / 2, s.height * 0.8);
    }
  }

  void reset() {
    bullets.clear();
    rocks.clear();
    pickups.clear();
    particles.clear();
    floats.clear();
    score = 0;
    lives = 3;
    combo = 0;
    time = 0;
    invuln = 1.2;
    shield = 0;
    rapid = 0;
    shake = 0;
    newBest = false;
    _fireCooldown = 0;
    _spawnCooldown = 0.8;
    _pickupCooldown = 6;
    player = Offset(size.width / 2, size.height * 0.8);
    phase = _Phase.playing;
    notifyListeners();
  }

  void steer(Offset delta) {
    if (phase != _Phase.playing) return;
    player = Offset(
      (player.dx + delta.dx * 1.3).clamp(playerRadius, size.width - playerRadius),
      (player.dy + delta.dy * 1.3).clamp(size.height * 0.35, size.height - playerRadius - 8),
    );
  }

  void update(double dt) {
    // Background stars always drift so menus feel alive.
    final drift = phase == _Phase.playing ? 0.12 * _speedScale : 0.04;
    for (final s in bg) {
      s.y += drift * s.depth * dt;
      if (s.y > 1) {
        s.y -= 1;
        s.x = _rand.nextDouble();
      }
    }
    _updateParticles(dt);

    if (phase != _Phase.playing) {
      notifyListeners();
      return;
    }

    time += dt;
    invuln = max(0, invuln - dt);
    shield = max(0, shield - dt);
    rapid = max(0, rapid - dt);
    shake = max(0, shake - dt * 3);

    _fire(dt);
    _spawn(dt);
    _move(dt);
    _collide();
    notifyListeners();
  }

  void _fire(double dt) {
    _fireCooldown -= dt;
    if (_fireCooldown > 0) return;
    _fireCooldown = rapid > 0 ? 0.08 : 0.2;
    final nose = player.translate(0, -playerRadius);
    bullets.add(_Bullet(nose));
    if (rapid > 0) {
      bullets.add(_Bullet(nose.translate(-10, 6)));
      bullets.add(_Bullet(nose.translate(10, 6)));
    }
  }

  void _spawn(double dt) {
    _spawnCooldown -= dt;
    if (_spawnCooldown <= 0) {
      _spawnCooldown = max(0.28, 1.0 - time * 0.008) * (0.7 + _rand.nextDouble() * 0.6);
      final big = _rand.nextDouble() < 0.35;
      final r = big ? 30.0 + _rand.nextDouble() * 10 : 14.0 + _rand.nextDouble() * 10;
      final speed = (110 + _rand.nextDouble() * 80) * _speedScale;
      _addRock(
        Offset(r + _rand.nextDouble() * (size.width - 2 * r), -r),
        Offset((_rand.nextDouble() - 0.5) * 60, speed),
        r,
      );
    }

    _pickupCooldown -= dt;
    if (_pickupCooldown <= 0) {
      _pickupCooldown = 5 + _rand.nextDouble() * 5;
      final roll = _rand.nextDouble();
      final kind = roll < 0.45
          ? _PickupKind.star
          : roll < 0.65
              ? _PickupKind.rapid
              : roll < 0.85
                  ? _PickupKind.shield
                  : _PickupKind.heart;
      pickups.add(_Pickup(kind, Offset(30 + _rand.nextDouble() * (size.width - 60), -20)));
    }
  }

  void _addRock(Offset p, Offset v, double r) {
    final points = 9;
    rocks.add(_Rock(
      p,
      v,
      r,
      r > 28 ? 4 : (r > 20 ? 2 : 1),
      (_rand.nextDouble() - 0.5) * 3,
      List.generate(points, (_) => 0.75 + _rand.nextDouble() * 0.3),
      [const Color(0xFF8E86B8), const Color(0xFF7A9CC2), const Color(0xFFB48AA8)][_rand.nextInt(3)],
    ));
  }

  void _move(double dt) {
    for (final b in bullets) {
      b.p = b.p.translate(0, -760 * dt);
    }
    bullets.removeWhere((b) => b.p.dy < -10);

    for (final r in rocks) {
      r.p += r.v * dt;
      r.rot += r.spin * dt;
      r.flash = max(0, r.flash - dt * 6);
      if (r.p.dx < r.r || r.p.dx > size.width - r.r) {
        r.v = Offset(-r.v.dx, r.v.dy);
        r.p = Offset(r.p.dx.clamp(r.r, size.width - r.r), r.p.dy);
      }
    }
    rocks.removeWhere((r) {
      final gone = r.p.dy - r.r > size.height;
      if (gone) combo = 0;
      return gone;
    });

    for (final p in pickups) {
      p.t += dt;
      p.p = Offset(p.p.dx + sin(p.t * 3) * 30 * dt, p.p.dy + 120 * dt);
    }
    pickups.removeWhere((p) => p.p.dy > size.height + 20);
  }

  void _collide() {
    // Bullets vs rocks.
    for (final b in List.of(bullets)) {
      for (final r in List.of(rocks)) {
        if (r.hp <= 0) continue;
        if ((b.p - r.p).distance < r.r) {
          bullets.remove(b);
          r.hp--;
          r.flash = 1;
          _burst(b.p, 4, Colors.white, 120, 2);
          if (r.hp <= 0) _destroyRock(r);
          break;
        }
      }
    }
    rocks.removeWhere((r) => r.hp <= 0);

    // Rocks vs player.
    for (final r in List.of(rocks)) {
      if ((r.p - player).distance < r.r + playerRadius * 0.8) {
        if (shield > 0) {
          r.hp = 0;
          _destroyRock(r);
        } else if (invuln <= 0) {
          _hit();
          r.hp = 0;
          _burst(r.p, 18, r.color, 220, 4);
        }
      }
    }
    rocks.removeWhere((r) => r.hp <= 0);

    // Pickups vs player.
    pickups.removeWhere((p) {
      if ((p.p - player).distance > 32) return false;
      _collect(p);
      return true;
    });
  }

  void _destroyRock(_Rock r) {
    HapticFeedback.lightImpact();
    combo++;
    final int points = (r.r > 28 ? 30 : (r.r > 20 ? 20 : 10)) * min(1 + combo ~/ 5, 5);
    score += points;
    floats.add(_FloatText('+$points', r.p, CalmColors.lemon));
    _burst(r.p, (r.r * 0.8).round(), r.color, 200, 4);
    _burst(r.p, 6, CalmColors.peach, 140, 3);
    if (r.r > 28) {
      for (final dir in [-1.0, 1.0]) {
        _addRock(r.p.translate(dir * 10, 0), Offset(dir * 90, r.v.dy * 0.9), r.r * 0.5);
      }
    }
  }

  void _hit() {
    HapticFeedback.heavyImpact();
    lives--;
    combo = 0;
    invuln = 1.8;
    shake = 1;
    _burst(player, 24, CalmColors.rose, 260, 4);
    if (lives <= 0) {
      phase = _Phase.over;
      _burst(player, 60, CalmColors.lemon, 320, 5);
      if (score > best) {
        best = score;
        newBest = true;
      }
    }
  }

  void _collect(_Pickup p) {
    HapticFeedback.mediumImpact();
    switch (p.kind) {
      case _PickupKind.star:
        score += 50;
        floats.add(_FloatText('+50', p.p, CalmColors.lemon));
      case _PickupKind.heart:
        lives = min(lives + 1, maxLives);
        floats.add(_FloatText('+1 life', p.p, CalmColors.rose));
      case _PickupKind.shield:
        shield = 6;
        floats.add(_FloatText('Shield!', p.p, CalmColors.sky));
      case _PickupKind.rapid:
        rapid = 7;
        floats.add(_FloatText('Triple shot!', p.p, CalmColors.mint));
    }
    _burst(p.p, 14, pickupColor(p.kind), 160, 3);
  }

  void _burst(Offset at, int n, Color color, double speed, double size) {
    for (var i = 0; i < n; i++) {
      final a = _rand.nextDouble() * pi * 2;
      final s = speed * (0.3 + _rand.nextDouble() * 0.7);
      particles.add(_Particle(at, Offset(cos(a), sin(a)) * s,
          0.5 + _rand.nextDouble() * 0.5, color, size * (0.5 + _rand.nextDouble())));
    }
    if (particles.length > 400) particles.removeRange(0, particles.length - 400);
  }

  void _updateParticles(double dt) {
    for (final p in particles) {
      p.p += p.v * dt;
      p.v *= pow(0.15, dt).toDouble();
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final f in floats) {
      f.p = f.p.translate(0, -50 * dt);
      f.life -= dt;
    }
    floats.removeWhere((f) => f.life <= 0);
  }

  static Color pickupColor(_PickupKind k) => switch (k) {
        _PickupKind.star => CalmColors.lemon,
        _PickupKind.heart => CalmColors.rose,
        _PickupKind.shield => CalmColors.sky,
        _PickupKind.rapid => CalmColors.mint,
      };
}

class _StarDashGameState extends State<StarDashGame> with SingleTickerProviderStateMixin {
  static const _bestKey = 'star_dash_best';

  final _world = _World();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    _world.best = prefs.getInt(_bestKey) ?? 0;
  }

  Future<void> _saveBest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_bestKey, _world.best);
  }

  @override
  void dispose() {
    _ticker.dispose();
    _world.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    final wasPlaying = _world.phase == _Phase.playing;
    _world.update(dt);
    if (wasPlaying && _world.phase == _Phase.over) {
      if (_world.newBest) _saveBest();
      setState(() {});
    }
  }

  void _start() {
    HapticFeedback.mediumImpact();
    setState(_world.reset);
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      _world.phase = _world.phase == _Phase.paused ? _Phase.playing : _Phase.paused;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0E0B26), Color(0xFF231C4D), Color(0xFF3A2559)],
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          child: LayoutBuilder(builder: (context, c) {
            _world.resize(c.biggest);
            return Stack(
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => _world.steer(d.delta),
                    child: CustomPaint(painter: _DashPainter(_world)),
                  ),
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ListenableBuilder(
                  listenable: _world,
                  builder: (context, _) => _Hud(
                    world: _world,
                    onBack: () => Navigator.of(context).maybePop(),
                    onPause: _togglePause,
                  ),
                ),
                ),
                if (_world.phase != _Phase.playing)
                  Positioned.fill(
                    child: _Overlay(world: _world, onStart: _start, onResume: _togglePause),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.world, required this.onBack, required this.onPause});

  final _World world;
  final VoidCallback onBack;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: onBack,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${world.score}', style: label.copyWith(fontSize: 24)),
                Text('Level ${world.level}${world.combo >= 5 ? '  ·  x${min(1 + world.combo ~/ 5, 5)} combo' : ''}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
              ],
            ),
          ),
          for (var i = 0; i < _World.maxLives; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                Icons.favorite_rounded,
                size: 18,
                color: i < world.lives ? CalmColors.rose : Colors.white.withValues(alpha: 0.15),
              ),
            ),
          if (world.phase == _Phase.playing)
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause_circle_rounded, color: Colors.white, size: 30),
              onPressed: onPause,
            ),
        ],
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.world, required this.onStart, required this.onResume});

  final _World world;
  final VoidCallback onStart;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final (title, subtitle, button, action) = switch (world.phase) {
      _Phase.ready => ('Star Dash', 'Drag anywhere to fly. Your ship fires on its own.', 'Play', onStart),
      _Phase.paused => ('Paused', 'Take a breath.', 'Resume', onResume),
      _ => (
          world.newBest ? 'New best!' : 'Game over',
          'Score ${world.score}  ·  Best ${world.best}',
          'Play again',
          onStart,
        ),
    };
    return ColoredBox(
      color: Colors.black.withValues(alpha: world.phase == _Phase.ready ? 0.2 : 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2357).withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15)),
              if (world.phase == _Phase.ready) ...[
                const SizedBox(height: 18),
                const _Legend(),
              ],
              const SizedBox(height: 22),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: CalmColors.lemon,
                  foregroundColor: CalmColors.ink,
                ),
                onPressed: action,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(button),
              ),
              if (world.phase == _Phase.ready && world.best > 0) ...[
                const SizedBox(height: 12),
                Text('Best ${world.best}',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6))),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              SizedBox(
                width: 150,
                child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        );
    return Column(
      children: [
        item(Icons.star_rounded, CalmColors.lemon, '+50 points'),
        item(Icons.bolt_rounded, CalmColors.mint, 'Triple shot'),
        item(Icons.shield_rounded, CalmColors.sky, 'Shield'),
        item(Icons.favorite_rounded, CalmColors.rose, 'Extra life'),
      ],
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.world) : super(repaint: world);

  final _World world;

  @override
  void paint(Canvas canvas, Size size) {
    final w = world;
    if (w.shake > 0) {
      final r = Random();
      canvas.translate((r.nextDouble() - 0.5) * 12 * w.shake, (r.nextDouble() - 0.5) * 12 * w.shake);
    }

    // Parallax star field.
    final starPaint = Paint();
    for (final s in w.bg) {
      starPaint.color = Colors.white.withValues(alpha: 0.25 + s.depth * 0.6);
      canvas.drawCircle(Offset(s.x * size.width, s.y * size.height), 0.6 + s.depth * 1.4, starPaint);
    }

    // Pickups.
    for (final p in w.pickups) {
      final c = _World.pickupColor(p.kind);
      final pulse = 1 + sin(p.t * 6) * 0.1;
      canvas.drawCircle(p.p, 20 * pulse,
          Paint()
            ..color = c.withValues(alpha: 0.35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
      canvas.drawCircle(p.p, 15, Paint()..color = c);
      _icon(canvas, p.p, switch (p.kind) {
        _PickupKind.star => Icons.star_rounded,
        _PickupKind.heart => Icons.favorite_rounded,
        _PickupKind.shield => Icons.shield_rounded,
        _PickupKind.rapid => Icons.bolt_rounded,
      });
    }

    // Rocks.
    for (final r in w.rocks) {
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

    // Bullets.
    final glow = Paint()
      ..color = CalmColors.mint.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final core = Paint()..color = Colors.white;
    for (final b in w.bullets) {
      final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: b.p, width: 4, height: 14), const Radius.circular(2));
      canvas.drawRRect(rect.inflate(2), glow);
      canvas.drawRRect(rect, core);
    }

    // Player ship (hidden after game over, blinks while invulnerable).
    final blink = w.invuln > 0 && (w.invuln * 10).floor().isEven;
    if (w.phase != _Phase.over && !blink) _ship(canvas, w);

    // Particles.
    final pp = Paint();
    for (final p in w.particles) {
      pp.color = p.color.withValues(alpha: (p.life / p.maxLife).clamp(0.0, 1.0));
      canvas.drawCircle(p.p, p.size, pp);
    }

    // Floating score text.
    for (final f in w.floats) {
      final tp = TextPainter(
        text: TextSpan(
          text: f.text,
          style: TextStyle(
              color: f.color.withValues(alpha: f.life.clamp(0.0, 1.0)),
              fontWeight: FontWeight.w900,
              fontSize: 16),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, f.p - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _ship(Canvas canvas, _World w) {
    final p = w.player;
    const r = _World.playerRadius;

    // Engine flame.
    final flame = 10 + Random().nextDouble() * 8;
    canvas.drawPath(
        Path()
          ..moveTo(p.dx - 7, p.dy + r * 0.6)
          ..lineTo(p.dx, p.dy + r * 0.6 + flame)
          ..lineTo(p.dx + 7, p.dy + r * 0.6)
          ..close(),
        Paint()
          ..color = CalmColors.peach
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    final body = Path()
      ..moveTo(p.dx, p.dy - r * 1.2)
      ..quadraticBezierTo(p.dx + r * 0.5, p.dy - r * 0.2, p.dx + r, p.dy + r * 0.7)
      ..lineTo(p.dx + r * 0.35, p.dy + r * 0.45)
      ..lineTo(p.dx - r * 0.35, p.dy + r * 0.45)
      ..lineTo(p.dx - r, p.dy + r * 0.7)
      ..quadraticBezierTo(p.dx - r * 0.5, p.dy - r * 0.2, p.dx, p.dy - r * 1.2)
      ..close();
    canvas.drawPath(
        body,
        Paint()
          ..color = CalmColors.lavender.withValues(alpha: 0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    canvas.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, CalmColors.lavender, Color(0xFF7D6FD6)],
          ).createShader(Rect.fromCircle(center: p, radius: r * 1.2)));
    canvas.drawOval(Rect.fromCenter(center: p.translate(0, -r * 0.25), width: 9, height: 14),
        Paint()..color = CalmColors.sky);

    if (w.shield > 0) {
      final fade = w.shield < 1.5 && (w.shield * 8).floor().isEven ? 0.3 : 1.0;
      canvas.drawCircle(
          p,
          r * 1.7,
          Paint()
            ..color = CalmColors.sky.withValues(alpha: 0.25 * fade)
            ..style = PaintingStyle.fill);
      canvas.drawCircle(
          p,
          r * 1.7,
          Paint()
            ..color = CalmColors.sky.withValues(alpha: 0.9 * fade)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
  }

  void _icon(Canvas canvas, Offset at, IconData icon) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: 18, color: CalmColors.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}
