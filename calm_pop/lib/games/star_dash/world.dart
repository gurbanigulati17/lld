import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/sfx.dart';
import '../../theme.dart';
import 'levels.dart';
import 'ships.dart';

enum DashPhase { ready, playing, paused, won, lost }

enum PickupKind { star, heart, shield, rapid, bomb }

class Bullet {
  Bullet(this.p, this.v);
  Offset p;
  final Offset v;
}

class Enemy {
  Enemy(this.kind, this.p, this.v, this.r, this.hp, this.color)
      : maxHp = hp,
        baseX = p.dx;
  final Foe kind;
  Offset p;
  Offset v;
  final double r;
  int hp;
  final int maxHp;
  final Color color;
  double baseX;
  double rot = 0;
  double spin = 0;
  List<double> shape = const [];
  double flash = 0;
  double t = 0;
  double fireCd = 2;
  double hoverY = 0;
}

class EnemyShot {
  EnemyShot(this.p, this.v, {this.r = 6, this.color = const Color(0xFFFF7AD9)});
  Offset p;
  final Offset v;
  final double r;
  final Color color;
}

class Pickup {
  Pickup(this.kind, this.p);
  final PickupKind kind;
  Offset p;
  double t = 0;
}

class Particle {
  Particle(this.p, this.v, this.life, this.color, this.size);
  Offset p;
  Offset v;
  double life;
  final Color color;
  final double size;
}

class Shockwave {
  Shockwave(this.p, this.maxR, this.color);
  final Offset p;
  final double maxR;
  final Color color;
  double t = 0;
}

class FloatText {
  FloatText(this.text, this.p, this.color, {this.big = false});
  final String text;
  Offset p;
  final Color color;
  final bool big;
  double life = 1.2;
}

class BgStar {
  BgStar(this.x, this.y, this.depth);
  double x;
  double y;
  final double depth;
}

class Boss {
  Boss(this.kind, this.p, this.maxHp) : hp = maxHp;
  final int kind; // 1 = Grumbo, 2 = Omega
  Offset p;
  final double maxHp;
  double hp;
  double t = 0;
  double flash = 0;
  bool entering = true;
  double fireCd = 2;
  double ringCd = 5;
  double minionCd = 6;
  double beamCd = 3;
  double beamCharge = 0;
  double beamOn = 0;
  double beamX = 0;
  double dying = 0;

  String get name => kind == 1 ? 'Grumbo' : 'Mothership Omega';
  double get width => kind == 1 ? 150 : 220;
  double get height => kind == 1 ? 70 : 96;
  double get fraction => (hp / maxHp).clamp(0.0, 1.0);
  int get stage => kind == 1 ? 1 : (fraction > 0.66 ? 1 : (fraction > 0.33 ? 2 : 3));
  bool contains(Offset q) =>
      (q.dx - p.dx).abs() < width / 2 && (q.dy - p.dy).abs() < height / 2;
}

/// All mutable game state plus the simulation step for one level.
class DashWorld extends ChangeNotifier {
  DashWorld(this.level, this.ship) {
    for (var i = 0; i < 90; i++) {
      bg.add(BgStar(_rand.nextDouble(), _rand.nextDouble(), 0.2 + _rand.nextDouble() * 0.8));
    }
  }

  static const playerRadius = 18.0;
  static const maxLives = 5;
  static const introTime = 2.4;

  final LevelSpec level;
  final ShipSpec ship;
  final _rand = Random();
  Size size = Size.zero;

  DashPhase phase = DashPhase.ready;
  Offset player = Offset.zero;
  final bullets = <Bullet>[];
  final enemies = <Enemy>[];
  final shots = <EnemyShot>[];
  final pickups = <Pickup>[];
  final particles = <Particle>[];
  final waves = <Shockwave>[];
  final floats = <FloatText>[];
  final bg = <BgStar>[];
  Boss? boss;

  int score = 0;
  int lives = 3;
  int livesLost = 0;
  int kills = 0;
  int collected = 0;
  int combo = 0;
  double time = 0; // seconds since the level started
  double clock = 0; // always ticking, for animation
  double invuln = 0;
  double shield = 0;
  double rapid = 0;
  double shake = 0;
  double warning = 0;
  double _fireCd = 0;
  double _spawnCd = 0;
  double _pickupCd = 6;
  double _winDelay = -1;

  Sector get theme => level.theme;
  bool get inIntro => phase == DashPhase.playing && time < introTime;

  int get stars => livesLost == 0 ? 3 : (livesLost == 1 ? 2 : 1);

  double get progress {
    final double raw = switch (level.goal) {
      Goal.destroy => kills / level.target,
      Goal.survive => max(0.0, time - introTime) / level.target,
      Goal.collect => collected / level.target,
      Goal.boss => boss == null ? 0.0 : 1 - boss!.fraction,
      Goal.endless => 0.0,
    };
    return raw.clamp(0.0, 1.0);
  }

  String get progressText => switch (level.goal) {
        Goal.destroy => '$kills / ${level.target} ${level.foeName}',
        Goal.survive => '${max(0, level.target - (time - introTime).floor()).clamp(0, level.target)}s to go',
        Goal.collect => '$collected / ${level.target} star crystals',
        Goal.boss => boss == null ? 'Boss incoming…' : (boss!.kind == 2 ? 'Phase ${boss!.stage} of 3' : 'Boss fight!'),
        Goal.endless => 'Wave $wave',
      };

  int get wave => 1 + (time / 20).floor();
  double get _endlessScale => 1 + min(time / 90, 1.6);

  void resize(Size s) {
    if (s == size) return;
    final first = size == Size.zero;
    size = s;
    if (first || phase == DashPhase.ready) player = Offset(s.width / 2, s.height * 0.8);
  }

  void start() {
    bullets.clear();
    enemies.clear();
    shots.clear();
    pickups.clear();
    particles.clear();
    waves.clear();
    floats.clear();
    boss = null;
    score = 0;
    lives = 3;
    livesLost = 0;
    kills = 0;
    collected = 0;
    combo = 0;
    time = 0;
    invuln = 1.2;
    shield = ship.startShield;
    rapid = 0;
    shake = 0;
    warning = 0;
    _fireCd = 0;
    _spawnCd = introTime;
    _pickupCd = level.goal == Goal.collect ? introTime + 1 : 6;
    _winDelay = -1;
    player = Offset(size.width / 2, size.height * 0.8);
    phase = DashPhase.playing;
    notifyListeners();
  }

  void steer(Offset delta) {
    if (phase != DashPhase.playing) return;
    final k = 1.3 * ship.handling;
    player = Offset(
      (player.dx + delta.dx * k).clamp(playerRadius, size.width - playerRadius),
      (player.dy + delta.dy * k).clamp(size.height * 0.35, size.height - playerRadius - 8),
    );
  }

  // ------------------------------------------------------------------ update

  void update(double dt) {
    clock += dt;
    final drift = phase == DashPhase.playing ? 0.12 * level.speed : 0.04;
    for (final s in bg) {
      s.y += drift * s.depth * dt;
      if (s.y > 1) {
        s.y -= 1;
        s.x = _rand.nextDouble();
      }
    }
    _updateFx(dt);

    if (phase != DashPhase.playing) {
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
    _updateBoss(dt);
    _collide();
    _checkGoal(dt);
    notifyListeners();
  }

  void _fire(double dt) {
    _fireCd -= dt;
    if (_fireCd > 0) return;
    _fireCd = ship.fireEvery * (rapid > 0 ? 0.55 : 1);
    final nose = player.translate(0, -playerRadius);
    void shoot(Offset at, double angle) => bullets.add(Bullet(at, Offset(sin(angle), -cos(angle)) * 760));
    switch (ship.pattern) {
      case ShotPattern.single:
        shoot(nose, 0);
      case ShotPattern.twin:
        shoot(nose.translate(-9, 8), 0);
        shoot(nose.translate(9, 8), 0);
      case ShotPattern.spread:
        shoot(nose, 0);
        shoot(nose.translate(-6, 6), -0.16);
        shoot(nose.translate(6, 6), 0.16);
    }
    if (rapid > 0) {
      shoot(nose.translate(-12, 8), -0.28);
      shoot(nose.translate(12, 8), 0.28);
    }
    Sfx.instance.play('laser', volume: 0.2, minGapMs: 80);
  }

  void _spawn(double dt) {
    if (time < introTime) return;

    // Boss levels: siren, then the boss arrives.
    if (level.isBoss) {
      if (boss == null && warning == 0) {
        warning = 2.6;
        Sfx.instance.play('warning');
        Sfx.instance.playMusic('music_boss', volume: 0.5);
      }
      if (warning > 0) {
        warning -= dt;
        if (warning <= 0) {
          warning = -1;
          boss = Boss(level.boss, Offset(size.width / 2, -60), level.boss == 1 ? 70 : 190);
        }
      }
    } else {
      _spawnCd -= dt;
      if (_spawnCd <= 0) {
        final ramp = level.goal == Goal.endless ? max(0.35, 1 - time * 0.008) : max(0.7, 1 - time * 0.004);
        _spawnCd = level.spawnEvery * ramp * (0.7 + _rand.nextDouble() * 0.6);
        _spawnFoe(_pickFoe());
      }
    }

    _pickupCd -= dt;
    if (_pickupCd <= 0) {
      final collecting = level.goal == Goal.collect;
      _pickupCd = collecting ? 1.6 + _rand.nextDouble() * 1.2 : 5 + _rand.nextDouble() * 5;
      final roll = _rand.nextDouble();
      final kind = collecting && roll < 0.7
          ? PickupKind.star
          : roll < 0.3
              ? PickupKind.star
              : roll < 0.5
                  ? PickupKind.rapid
                  : roll < 0.68
                      ? PickupKind.shield
                      : roll < 0.85
                          ? PickupKind.bomb
                          : PickupKind.heart;
      pickups.add(Pickup(kind, Offset(30 + _rand.nextDouble() * (size.width - 60), -20)));
    }
  }

  Foe _pickFoe() {
    var mix = level.mix;
    if (level.goal == Goal.endless) {
      mix = {
        Foe.rock: 1,
        if (time > 30) Foe.comet: 0.35,
        if (time > 60) Foe.ufo: 0.25,
        if (time > 90) Foe.mine: 0.3,
      };
    }
    final total = mix.values.fold(0.0, (a, b) => a + b);
    var roll = _rand.nextDouble() * total;
    for (final e in mix.entries) {
      roll -= e.value;
      if (roll <= 0) return e.key;
    }
    return mix.keys.first;
  }

  double get _speed => level.goal == Goal.endless ? _endlessScale : level.speed;

  void _spawnFoe(Foe kind, {Offset? at}) {
    final w = size.width;
    switch (kind) {
      case Foe.rock:
        final big = _rand.nextDouble() < 0.35;
        final r = big ? 30.0 + _rand.nextDouble() * 10 : 14.0 + _rand.nextDouble() * 10;
        _addRock(Offset(r + _rand.nextDouble() * (w - 2 * r), -r),
            Offset((_rand.nextDouble() - 0.5) * 60, (110 + _rand.nextDouble() * 80) * _speed), r);
      case Foe.comet:
        final x = _rand.nextDouble() * w;
        final target = Offset(player.dx + (_rand.nextDouble() - 0.5) * 160, size.height);
        final dir = (target - Offset(x, -20));
        final v = dir / dir.distance * (300 + _rand.nextDouble() * 80) * _speed;
        enemies.add(Enemy(Foe.comet, Offset(x, -20), v, 11, 1, const Color(0xFFBFF3FF)));
      case Foe.ufo:
        final e = Enemy(Foe.ufo, at ?? Offset(40 + _rand.nextDouble() * (w - 80), -24), Offset.zero, 22, 3,
            theme.accent)
          ..hoverY = size.height * (0.12 + _rand.nextDouble() * 0.25)
          ..fireCd = 1 + _rand.nextDouble() * 1.5
          ..t = _rand.nextDouble() * 6;
        enemies.add(e);
      case Foe.mine:
        enemies.add(Enemy(Foe.mine, Offset(30 + _rand.nextDouble() * (w - 60), -20),
            Offset(0, (55 + _rand.nextDouble() * 25) * _speed), 16, 1, const Color(0xFFE0483E))
          ..t = _rand.nextDouble() * 6);
    }
  }

  void _addRock(Offset p, Offset v, double r) {
    final e = Enemy(Foe.rock, p, v, r, r > 28 ? 4 : (r > 20 ? 2 : 1),
        theme.rockColors[_rand.nextInt(theme.rockColors.length)])
      ..spin = (_rand.nextDouble() - 0.5) * 3
      ..shape = List.generate(9, (_) => 0.75 + _rand.nextDouble() * 0.3);
    enemies.add(e);
  }

  void _move(double dt) {
    for (final b in bullets) {
      b.p += b.v * dt;
    }
    bullets.removeWhere((b) => b.p.dy < -20 || b.p.dx < -20 || b.p.dx > size.width + 20);

    for (final e in enemies) {
      e.t += dt;
      e.flash = max(0, e.flash - dt * 6);
      switch (e.kind) {
        case Foe.rock:
          e.p += e.v * dt;
          e.rot += e.spin * dt;
          if (e.p.dx < e.r || e.p.dx > size.width - e.r) {
            e.v = Offset(-e.v.dx, e.v.dy);
            e.p = Offset(e.p.dx.clamp(e.r, size.width - e.r), e.p.dy);
          }
        case Foe.comet:
          e.p += e.v * dt;
          if (_rand.nextDouble() < 0.6) {
            particles.add(Particle(e.p, -e.v * 0.1 + Offset(_rand.nextDouble() * 20 - 10, 0), 0.4,
                const Color(0xFF9FE8FF), 2 + _rand.nextDouble() * 2));
          }
        case Foe.ufo:
          final leaving = e.t > 11;
          final y = leaving ? e.p.dy + 140 * dt : e.p.dy + (e.hoverY - e.p.dy) * min(1, dt * 2);
          final x = (e.baseX + sin(e.t * 1.3) * 70).clamp(e.r, size.width - e.r);
          e.p = Offset(x, y);
          e.fireCd -= dt;
          if (e.fireCd <= 0 && e.p.dy > 0 && !leaving) {
            e.fireCd = 1.6 + _rand.nextDouble() * 1.4;
            _aimedShot(e.p.translate(0, 12), 230);
          }
        case Foe.mine:
          final toPlayer = player - e.p;
          final d = toPlayer.distance;
          var v = e.v;
          if (d < 170) v += toPlayer / d * 70;
          e.p += Offset(v.dx + sin(e.t * 2) * 20, v.dy) * dt;
          e.rot += dt * 0.8;
      }
    }
    enemies.removeWhere((e) {
      final gone = e.p.dy - e.r > size.height + 30 || e.p.dx < -60 || e.p.dx > size.width + 60;
      if (gone && e.kind == Foe.rock) combo = 0;
      return gone;
    });

    for (final s in shots) {
      s.p += s.v * dt;
    }
    shots.removeWhere((s) =>
        s.p.dy > size.height + 20 || s.p.dy < -40 || s.p.dx < -20 || s.p.dx > size.width + 20);

    for (final p in pickups) {
      p.t += dt;
      p.p = Offset(p.p.dx + sin(p.t * 3) * 30 * dt, p.p.dy + 120 * dt);
    }
    pickups.removeWhere((p) => p.p.dy > size.height + 20);
  }

  void _aimedShot(Offset from, double speed, {double spread = 0, Color? color}) {
    final d = player - from;
    final a = atan2(d.dy, d.dx) + spread;
    shots.add(EnemyShot(from, Offset(cos(a), sin(a)) * speed, color: color ?? const Color(0xFFFF7AD9)));
    Sfx.instance.play('enemy_shot', volume: 0.35, minGapMs: 90);
  }

  void _fan(Offset from, int n, double arc, double speed, Color color, {double center = pi / 2}) {
    for (var i = 0; i < n; i++) {
      final a = center + (n == 1 ? 0 : -arc / 2 + arc * i / (n - 1));
      shots.add(EnemyShot(from, Offset(cos(a), sin(a)) * speed, r: 7, color: color));
    }
    Sfx.instance.play('enemy_shot', volume: 0.45, minGapMs: 60);
  }

  // -------------------------------------------------------------------- boss

  void _updateBoss(double dt) {
    final b = boss;
    if (b == null) return;
    b.t += dt;
    b.flash = max(0, b.flash - dt * 5);

    if (b.dying > 0) {
      b.dying -= dt;
      if (_rand.nextDouble() < 0.35) {
        final at = b.p + Offset((_rand.nextDouble() - 0.5) * b.width, (_rand.nextDouble() - 0.5) * b.height);
        _burst(at, 14, [CalmColors.lemon, CalmColors.peach, Colors.white][_rand.nextInt(3)], 220, 4);
        Sfx.instance.play('explode_small', minGapMs: 120);
        shake = 0.6;
      }
      if (b.dying <= 0) {
        _burst(b.p, 90, CalmColors.lemon, 360, 5);
        waves.add(Shockwave(b.p, size.width, CalmColors.lemon));
        Sfx.instance.play('explode_big');
        boss = null;
        _winDelay = 1.2;
      }
      return;
    }

    final targetY = size.height * (b.kind == 1 ? 0.2 : 0.18);
    if (b.entering) {
      b.p = b.p.translate(0, 80 * dt);
      if (b.p.dy >= targetY) b.entering = false;
      return;
    }
    final swing = b.kind == 1 ? 0.32 : (b.stage == 3 ? 0.36 : 0.28);
    final x = size.width / 2 + sin(b.t * (b.kind == 1 ? 0.8 : 0.6 + b.stage * 0.1)) * size.width * swing;
    final half = min(b.width / 2, size.width / 2);
    b.p = Offset(x.clamp(half, size.width - half), targetY + sin(b.t * 1.7) * 10);

    final mouth = b.p.translate(0, b.height / 2);
    b.fireCd -= dt;
    b.ringCd -= dt;

    if (b.kind == 1) {
      if (b.fireCd <= 0) {
        b.fireCd = 1.3;
        _fan(mouth, 5, 1.0, 200, const Color(0xFF8FFFC9));
      }
      if (b.ringCd <= 0) {
        b.ringCd = 5;
        _fan(b.p, 12, 2 * pi * 11 / 12, 160, const Color(0xFFFF9EE6));
      }
      return;
    }

    // Mothership Omega gets nastier as it loses health.
    final stage = b.stage;
    if (b.fireCd <= 0) {
      b.fireCd = stage == 1 ? 1.0 : (stage == 2 ? 1.2 : 0.85);
      for (final s in [-0.13, 0.0, 0.13]) {
        _aimedShot(mouth, 250, spread: s, color: const Color(0xFFFFC46B));
      }
    }
    if (b.ringCd <= 0) {
      b.ringCd = stage == 1 ? 6 : 4;
      _fan(b.p, stage == 1 ? 12 : 16, 2 * pi * 15 / 16, 150, const Color(0xFFFF7AD9));
    }
    if (stage >= 2) {
      b.minionCd -= dt;
      if (b.minionCd <= 0) {
        b.minionCd = 7;
        _spawnFoe(Foe.ufo, at: b.p.translate(-b.width / 2, 0));
        _spawnFoe(Foe.ufo, at: b.p.translate(b.width / 2, 0));
      }
    }
    if (stage == 3) {
      if (b.beamOn > 0) {
        b.beamOn -= dt;
      } else if (b.beamCharge > 0) {
        b.beamCharge -= dt;
        if (b.beamCharge <= 0) {
          b.beamOn = 0.9;
          shake = 0.5;
          Sfx.instance.play('beam');
        }
      } else {
        b.beamCd -= dt;
        if (b.beamCd <= 0) {
          b.beamCd = 3.5;
          b.beamCharge = 1.1;
          b.beamX = player.dx;
          Sfx.instance.play('beam_charge');
        }
      }
    }
  }

  // --------------------------------------------------------------- collisions

  void _collide() {
    for (final b in List.of(bullets)) {
      var used = false;
      for (final e in List.of(enemies)) {
        if (e.hp <= 0) continue;
        if ((b.p - e.p).distance < e.r + 2) {
          used = true;
          e.hp--;
          e.flash = 1;
          _burst(b.p, 3, Colors.white, 120, 2);
          if (e.hp <= 0) {
            _destroy(e);
          } else {
            Sfx.instance.play('spin_tick', volume: 0.45, minGapMs: 40);
          }
          break;
        }
      }
      final bs = boss;
      if (!used && bs != null && bs.dying <= 0 && bs.contains(b.p)) {
        used = true;
        _damageBoss(1);
        _burst(b.p, 3, Colors.white, 120, 2);
      }
      if (used) bullets.remove(b);
    }
    enemies.removeWhere((e) => e.hp <= 0);

    bool vulnerable() => invuln <= 0 && shield <= 0 && phase == DashPhase.playing;
    for (final e in List.of(enemies)) {
      if (e.hp <= 0) continue;
      if ((e.p - player).distance < e.r + playerRadius * 0.8) {
        if (shield > 0) {
          _destroy(e);
        } else if (invuln <= 0) {
          _hit();
          e.hp = 0;
          if (e.kind == Foe.mine) _mineBlast(e.p, hurtPlayer: false);
          _burst(e.p, 18, e.color, 220, 4);
        }
      }
    }
    enemies.removeWhere((e) => e.hp <= 0);

    shots.removeWhere((s) {
      if ((s.p - player).distance > s.r + playerRadius * 0.7) return false;
      if (shield > 0) {
        _burst(s.p, 6, CalmColors.sky, 100, 2);
        return true;
      }
      if (vulnerable()) {
        _hit();
        return true;
      }
      return false;
    });

    final b = boss;
    if (b != null && b.dying <= 0) {
      if (vulnerable() && b.contains(player)) _hit();
      if (b.beamOn > 0 && vulnerable() && (player.dx - b.beamX).abs() < 24) _hit();
    }

    pickups.removeWhere((p) {
      if ((p.p - player).distance > 32) return false;
      _collect(p);
      return true;
    });
  }

  void _destroy(Enemy e) {
    if (e.hp < 0) return;
    e.hp = -1;
    HapticFeedback.lightImpact();
    kills++;
    combo++;
    final base = switch (e.kind) {
      Foe.rock => e.r > 28 ? 30 : (e.r > 20 ? 20 : 10),
      Foe.comet => 25,
      Foe.ufo => 50,
      Foe.mine => 20,
    };
    final int points = base * min(1 + combo ~/ 5, 5);
    score += points;
    floats.add(FloatText('+$points', e.p, CalmColors.lemon));
    _burst(e.p, (e.r * 0.8).round(), e.color, 200, 4);
    switch (e.kind) {
      case Foe.rock:
        Sfx.instance.play(e.r > 28 ? 'explode_big' : 'explode_small', volume: e.r > 20 ? 1 : 0.75);
        if (e.r > 28) {
          for (final dir in [-1.0, 1.0]) {
            _addRock(e.p.translate(dir * 10, 0), Offset(dir * 90, e.v.dy * 0.9), e.r * 0.5);
          }
        }
      case Foe.mine:
        _mineBlast(e.p, hurtPlayer: false);
      case Foe.ufo:
        Sfx.instance.play('explode_big', volume: 0.8);
        _burst(e.p, 10, const Color(0xFF9FE8FF), 160, 3);
      case Foe.comet:
        Sfx.instance.play('explode_small', volume: 0.7);
    }
  }

  /// Mines explode in a ring that destroys anything nearby (chain reactions!).
  void _mineBlast(Offset at, {required bool hurtPlayer}) {
    const radius = 95.0;
    Sfx.instance.play('explode_big');
    shake = max(shake, 0.5);
    waves.add(Shockwave(at, radius, const Color(0xFFFF7A45)));
    _burst(at, 30, const Color(0xFFFFB36B), 260, 4);
    for (final e in List.of(enemies)) {
      if (e.hp > 0 && (e.p - at).distance < radius + e.r) _destroy(e);
    }
    if (hurtPlayer && (player - at).distance < radius && invuln <= 0 && shield <= 0) _hit();
  }

  void _damageBoss(double amount) {
    final b = boss!;
    final before = b.stage;
    b.hp -= amount;
    b.flash = 1;
    score += 5;
    Sfx.instance.play('spin_tick', volume: 0.5, minGapMs: 50);
    if (b.stage != before && b.hp > 0) {
      floats.add(FloatText('${b.name} is angry!', b.p.translate(0, b.height), CalmColors.rose, big: true));
      shake = 0.8;
      Sfx.instance.play('warning', volume: 0.6);
    }
    if (b.hp <= 0) {
      b.hp = 0;
      b.dying = 2.2;
      b.beamOn = 0;
      b.beamCharge = 0;
      shots.clear();
      score += b.kind == 1 ? 1500 : 5000;
      floats.add(FloatText(b.kind == 1 ? '+1500' : '+5000', b.p, CalmColors.lemon, big: true));
      Sfx.instance.pauseMusic();
    }
  }

  void _hit() {
    if (phase != DashPhase.playing) return;
    HapticFeedback.heavyImpact();
    lives--;
    livesLost++;
    combo = 0;
    invuln = 1.8;
    shake = 1;
    Sfx.instance.play('hit');
    _burst(player, 24, CalmColors.rose, 260, 4);
    if (lives <= 0) {
      phase = DashPhase.lost;
      Sfx.instance.pauseMusic();
      Sfx.instance.play('gameover');
      _burst(player, 60, CalmColors.lemon, 320, 5);
    }
  }

  void _collect(Pickup p) {
    HapticFeedback.mediumImpact();
    Sfx.instance.play(p.kind == PickupKind.star ? 'coin' : 'powerup');
    switch (p.kind) {
      case PickupKind.star:
        score += 50;
        collected++;
        floats.add(FloatText(level.goal == Goal.collect ? '$collected / ${level.target}' : '+50', p.p,
            CalmColors.lemon));
      case PickupKind.heart:
        lives = min(lives + 1, maxLives);
        floats.add(FloatText('+1 life', p.p, CalmColors.rose));
      case PickupKind.shield:
        shield = 6;
        floats.add(FloatText('Shield!', p.p, CalmColors.sky));
      case PickupKind.rapid:
        rapid = 7;
        floats.add(FloatText('Power shot!', p.p, CalmColors.mint));
      case PickupKind.bomb:
        _megaBomb();
    }
    _burst(p.p, 14, pickupColor(p.kind), 160, 3);
  }

  void _megaBomb() {
    floats.add(FloatText('MEGA BOMB!', player.translate(0, -50), CalmColors.peach, big: true));
    waves.add(Shockwave(player, size.longestSide, CalmColors.peach));
    shake = 1;
    Sfx.instance.play('explode_big');
    for (final e in List.of(enemies)) {
      if (e.hp > 0 && e.p.dy > -10) _destroy(e);
    }
    enemies.removeWhere((e) => e.hp <= 0);
    shots.clear();
    final b = boss;
    if (b != null && b.dying <= 0 && !b.entering) _damageBoss(b.maxHp * 0.08);
  }

  void _checkGoal(double dt) {
    if (phase != DashPhase.playing) return;
    if (_winDelay > 0) {
      _winDelay -= dt;
      if (_winDelay <= 0) _win();
      return;
    }
    final done = switch (level.goal) {
      Goal.destroy => kills >= level.target,
      Goal.survive => time - introTime >= level.target,
      Goal.collect => collected >= level.target,
      Goal.boss => false, // handled when the boss finishes exploding
      Goal.endless => false,
    };
    if (done) {
      _winDelay = 0.8;
      floats.add(FloatText('Goal complete!', Offset(size.width / 2, size.height * 0.45), CalmColors.mint, big: true));
    }
  }

  void _win() {
    phase = DashPhase.won;
    shots.clear();
    for (final e in enemies) {
      _burst(e.p, 8, e.color, 140, 3);
    }
    enemies.clear();
    Sfx.instance.pauseMusic();
    Sfx.instance.play('victory');
  }

  // ------------------------------------------------------------------- fx

  void _burst(Offset at, int n, Color color, double speed, double size) {
    for (var i = 0; i < n; i++) {
      final a = _rand.nextDouble() * pi * 2;
      final s = speed * (0.3 + _rand.nextDouble() * 0.7);
      particles.add(Particle(at, Offset(cos(a), sin(a)) * s, 0.5 + _rand.nextDouble() * 0.5, color,
          size * (0.5 + _rand.nextDouble())));
    }
    if (particles.length > 500) particles.removeRange(0, particles.length - 500);
  }

  void _updateFx(double dt) {
    final damp = pow(0.15, dt).toDouble();
    for (final p in particles) {
      p.p += p.v * dt;
      p.v *= damp;
      p.life -= dt;
    }
    particles.removeWhere((p) => p.life <= 0);
    for (final w in waves) {
      w.t += dt * 1.8;
    }
    waves.removeWhere((w) => w.t >= 1);
    for (final f in floats) {
      f.p = f.p.translate(0, -45 * dt);
      f.life -= dt;
    }
    floats.removeWhere((f) => f.life <= 0);
  }

  static Color pickupColor(PickupKind k) => switch (k) {
        PickupKind.star => CalmColors.lemon,
        PickupKind.heart => CalmColors.rose,
        PickupKind.shield => CalmColors.sky,
        PickupKind.rapid => CalmColors.mint,
        PickupKind.bomb => CalmColors.peach,
      };

  static IconData pickupIcon(PickupKind k) => switch (k) {
        PickupKind.star => Icons.star_rounded,
        PickupKind.heart => Icons.favorite_rounded,
        PickupKind.shield => Icons.shield_rounded,
        PickupKind.rapid => Icons.bolt_rounded,
        PickupKind.bomb => Icons.flare_rounded,
      };
}
