import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../audio/sfx.dart';
import '../../theme.dart';
import 'levels.dart';
import 'painter.dart';
import 'progress.dart';
import 'world.dart';

/// Plays one campaign level (or endless mode when [level] is [endlessLevel]).
class DashPlayScreen extends StatefulWidget {
  const DashPlayScreen({super.key, required this.level});

  final LevelSpec level;

  @override
  State<DashPlayScreen> createState() => _DashPlayScreenState();
}

class _DashPlayScreenState extends State<DashPlayScreen> with SingleTickerProviderStateMixin {
  late final DashWorld _world = DashWorld(widget.level, DashProgress.instance.ship);
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _improved = false;

  LevelSpec get level => widget.level;
  bool get endless => level.goal == Goal.endless;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    Sfx.instance.preload(const [
      'laser', 'explode_small', 'explode_big', 'hit', 'coin', 'powerup', 'start', 'gameover', 'spin_tick',
      'enemy_shot', 'warning', 'victory', 'beam', 'beam_charge',
    ]);
  }

  @override
  void dispose() {
    Sfx.instance.stopMusic();
    _ticker.dispose();
    _world.dispose();
    super.dispose();
  }

  void _tick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 30);
    _last = elapsed;
    final before = _world.phase;
    _world.update(dt);
    if (before == DashPhase.playing && _world.phase != DashPhase.playing) _finished();
  }

  Future<void> _finished() async {
    if (_world.phase == DashPhase.won) {
      _improved = await DashProgress.instance.record(level.number, _world.stars);
    } else if (endless) {
      await DashProgress.instance.recordEndless(_world.score);
    }
    if (mounted) setState(() {});
  }

  void _start() {
    HapticFeedback.mediumImpact();
    Sfx.instance.play('start');
    if (!level.isBoss) Sfx.instance.playMusic('music_dash', volume: 0.45);
    _improved = false;
    setState(_world.start);
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    Sfx.instance.play('tap');
    setState(() {
      _world.phase = _world.phase == DashPhase.paused ? DashPhase.playing : DashPhase.paused;
    });
    if (_world.phase == DashPhase.paused) {
      Sfx.instance.pauseMusic();
    } else {
      final bossMusic = level.isBoss && (_world.boss != null || _world.warning != 0);
      if (bossMusic || !level.isBoss) {
        Sfx.instance.playMusic(bossMusic ? 'music_boss' : 'music_dash', volume: bossMusic ? 0.5 : 0.45);
      }
    }
  }

  void _next() {
    final i = levels.indexOf(level);
    if (i < 0 || i + 1 >= levels.length) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DashPlayScreen(level: levels[i + 1])),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: level.theme.sky.first,
      body: LayoutBuilder(builder: (context, c) {
        _world.resize(c.biggest);
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) => _world.steer(d.delta),
                child: CustomPaint(painter: DashPainter(_world)),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: ListenableBuilder(
                  listenable: _world,
                  builder: (context, _) => _Hud(world: _world, onPause: _togglePause),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _world,
                  builder: (context, _) => _Banners(world: _world),
                ),
              ),
            ),
            if (_world.phase != DashPhase.playing)
              Positioned.fill(
                child: _Overlay(
                  world: _world,
                  improved: _improved,
                  onStart: _start,
                  onResume: _togglePause,
                  onNext: _next,
                  onMap: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.world, required this.onPause});

  final DashWorld world;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final w = world;
    final boss = w.boss;
    final dim = Colors.white.withValues(alpha: 0.7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${w.score}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
                    Text(
                      '${w.progressText}${w.combo >= 5 ? '  ·  x${min(1 + w.combo ~/ 5, 5)}' : ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < DashWorld.maxLives; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(Icons.favorite_rounded,
                      size: 16, color: i < w.lives ? CalmColors.rose : Colors.white.withValues(alpha: 0.15)),
                ),
              const SoundToggle(color: Colors.white),
              if (w.phase == DashPhase.playing)
                IconButton(
                  tooltip: 'Pause',
                  icon: const Icon(Icons.pause_circle_rounded, color: Colors.white, size: 28),
                  onPressed: onPause,
                ),
            ],
          ),
          if (boss != null)
            _Bar(label: boss.name, value: boss.fraction, color: CalmColors.rose)
          else if (w.level.goal != Goal.endless && w.level.goal != Goal.boss)
            _Bar(value: w.progress, color: w.theme.accent),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({this.label, required this.value, required this.color});

  final String? label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 10, 0),
      child: Row(
        children: [
          if (label != null) ...[
            Text(label!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: label != null ? 9 : 5,
                backgroundColor: Colors.white.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Level intro card and the boss warning siren banner.
class _Banners extends StatelessWidget {
  const _Banners({required this.world});

  final DashWorld world;

  @override
  Widget build(BuildContext context) {
    final w = world;
    if (w.inIntro) {
      final t = w.time / DashWorld.introTime;
      final opacity = t < 0.15 ? t / 0.15 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);
      final endless = w.level.goal == Goal.endless;
      return Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(endless ? 'ENDLESS' : 'WORLD ${w.level.sector + 1} · ${w.theme.name.toUpperCase()}',
                  style: TextStyle(
                      color: w.theme.accent, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(endless ? 'How far can you go?' : 'Level ${w.level.number}',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(w.level.goalText,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 16)),
            ],
          ),
        ),
      );
    }
    if (w.warning > 0) {
      final on = (w.clock * 4).floor().isEven;
      return Center(
        child: AnimatedOpacity(
          opacity: on ? 1 : 0.35,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            color: const Color(0xFFFF4A6E).withValues(alpha: 0.25),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('⚠  WARNING  ⚠',
                    style: TextStyle(
                        color: Color(0xFFFF8FA8), fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 3)),
                SizedBox(height: 4),
                Text('BOSS APPROACHING',
                    style: TextStyle(color: Colors.white, fontSize: 14, letterSpacing: 4, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({
    required this.world,
    required this.improved,
    required this.onStart,
    required this.onResume,
    required this.onNext,
    required this.onMap,
  });

  final DashWorld world;
  final bool improved;
  final VoidCallback onStart;
  final VoidCallback onResume;
  final VoidCallback onNext;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final w = world;
    final lvl = w.level;
    final endless = lvl.goal == Goal.endless;
    final last = lvl.number == levels.last.number;

    late final String title;
    late final String subtitle;
    Widget? extra;
    final buttons = <Widget>[];

    FilledButton primary(String text, IconData icon, VoidCallback onTap) => FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: CalmColors.lemon, foregroundColor: CalmColors.ink),
          onPressed: onTap,
          icon: Icon(icon),
          label: Text(text),
        );
    Widget secondary(String text, VoidCallback onTap) => TextButton(
          onPressed: onTap,
          child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        );

    switch (w.phase) {
      case DashPhase.ready:
        title = endless ? 'Endless Mode' : 'Level ${lvl.number}';
        subtitle = endless
            ? 'Every enemy, faster and faster. Drag to fly, your ship fires on its own.'
            : '${w.theme.name}\n${lvl.goalText}';
        extra = const _Legend();
        buttons.add(primary('Launch', Icons.rocket_launch_rounded, onStart));
      case DashPhase.paused:
        title = 'Paused';
        subtitle = 'Take a breath.';
        buttons
          ..add(primary('Resume', Icons.play_arrow_rounded, onResume))
          ..add(secondary('Galaxy map', onMap));
      case DashPhase.won:
        title = last ? 'You saved the galaxy!' : 'Level complete!';
        subtitle = 'Score ${w.score}${improved ? '  ·  New record!' : ''}';
        extra = _StarRow(stars: w.stars);
        buttons
          ..add(primary(last ? 'Back to map' : 'Next level', Icons.arrow_forward_rounded, last ? onMap : onNext))
          ..add(secondary('Replay', onStart));
        if (!last) buttons.add(secondary('Galaxy map', onMap));
      case DashPhase.lost:
        title = endless ? 'Game over' : 'Ship down!';
        subtitle = endless
            ? 'Score ${w.score}  ·  Best ${DashProgress.instance.endlessBest}'
            : 'So close. ${w.progressText}';
        buttons
          ..add(primary('Try again', Icons.replay_rounded, onStart))
          ..add(secondary('Galaxy map', onMap));
      case DashPhase.playing:
        return const SizedBox.shrink();
    }

    return ColoredBox(
      color: Colors.black.withValues(alpha: w.phase == DashPhase.ready ? 0.25 : 0.5),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 28),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
            decoration: BoxDecoration(
              color: Color.lerp(w.theme.sky[1], Colors.black, 0.2)!.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: w.theme.accent.withValues(alpha: 0.35)),
              boxShadow: [BoxShadow(color: w.theme.accent.withValues(alpha: 0.2), blurRadius: 30)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 15, height: 1.4)),
                if (extra != null) ...[const SizedBox(height: 16), extra],
                const SizedBox(height: 20),
                for (final b in buttons) ...[b, const SizedBox(height: 4)],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  const _StarRow({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 400 + i * 250),
            curve: Curves.elasticOut,
            builder: (context, t, child) => Transform.scale(scale: i < stars ? t : 1, child: child),
            child: Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 12 : 0, left: 4, right: 4),
              child: Icon(Icons.star_rounded,
                  size: i == 1 ? 56 : 44,
                  color: i < stars ? CalmColors.lemon : Colors.white.withValues(alpha: 0.18)),
            ),
          ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color color, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              SizedBox(width: 150, child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
            ],
          ),
        );
    return Column(
      children: [
        item(Icons.star_rounded, CalmColors.lemon, 'Star crystal: +50'),
        item(Icons.bolt_rounded, CalmColors.mint, 'Power shot'),
        item(Icons.shield_rounded, CalmColors.sky, 'Shield'),
        item(Icons.flare_rounded, CalmColors.peach, 'Mega bomb'),
        item(Icons.favorite_rounded, CalmColors.rose, 'Extra life'),
      ],
    );
  }
}
