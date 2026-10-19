import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../audio/sfx.dart';
import '../theme.dart';
import '../widgets/game_scaffold.dart';

class _Phase {
  const _Phase(this.label, this.seconds, this.scale);

  final String label;
  final int seconds;

  /// Target circle size at the end of this phase (0..1).
  final double scale;
}

class _Pattern {
  const _Pattern(this.name, this.description, this.phases);

  final String name;
  final String description;
  final List<_Phase> phases;
}

const _patterns = [
  _Pattern('Calm', 'In 4 · Out 6', [
    _Phase('Breathe in', 4, 1),
    _Phase('Breathe out', 6, 0),
  ]),
  _Pattern('Box', '4 · 4 · 4 · 4', [
    _Phase('Breathe in', 4, 1),
    _Phase('Hold', 4, 1),
    _Phase('Breathe out', 4, 0),
    _Phase('Hold', 4, 0),
  ]),
  _Pattern('Relax', '4 · 7 · 8', [
    _Phase('Breathe in', 4, 1),
    _Phase('Hold', 7, 1),
    _Phase('Breathe out', 8, 0),
  ]),
];

class BreatheGame extends StatefulWidget {
  const BreatheGame({super.key});

  @override
  State<BreatheGame> createState() => _BreatheGameState();
}

class _BreatheGameState extends State<BreatheGame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _size =
      AnimationController(vsync: this, value: 0);
  Timer? _ticker;

  _Pattern _pattern = _patterns.first;
  bool _running = false;
  int _phaseIndex = 0;
  int _secondsLeft = 0;
  int _cycles = 0;

  _Phase get _phase => _pattern.phases[_phaseIndex];

  @override
  void initState() {
    super.initState();
    Sfx.instance.preload(const ['breathe_in', 'breathe_out', 'breathe_hold']);
    Sfx.instance.playMusic('music_calm', volume: 0.35);
  }

  @override
  void dispose() {
    Sfx.instance.stopMusic();
    _ticker?.cancel();
    _size.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _phaseIndex = 0;
      _cycles = 0;
    });
    _enterPhase();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    _size.animateTo(0,
        duration: const Duration(milliseconds: 800), curve: Curves.easeOut);
    setState(() => _running = false);
  }

  void _enterPhase() {
    HapticFeedback.selectionClick();
    Sfx.instance.play(switch (_phase.label) {
      'Breathe in' => 'breathe_in',
      'Breathe out' => 'breathe_out',
      _ => 'breathe_hold',
    });
    _secondsLeft = _phase.seconds;
    _size.animateTo(_phase.scale,
        duration: Duration(seconds: _phase.seconds),
        curve: Curves.easeInOutSine);
  }

  void _tick() {
    setState(() {
      _secondsLeft--;
      if (_secondsLeft <= 0) {
        _phaseIndex = (_phaseIndex + 1) % _pattern.phases.length;
        if (_phaseIndex == 0) _cycles++;
        _enterPhase();
      }
    });
  }

  void _choose(_Pattern p) {
    if (_running) _stop();
    setState(() => _pattern = p);
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Breathe',
      subtitle: _running ? '$_cycles breaths completed' : 'Follow the circle',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final p in _patterns)
                ChoiceChip(
                  label: Text('${p.name}  ${p.description}'),
                  selected: p == _pattern,
                  onSelected: (_) => _choose(p),
                  showCheckmark: false,
                  selectedColor: CalmColors.mint,
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  labelStyle: const TextStyle(
                      color: CalmColors.ink, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          Expanded(
            child: LayoutBuilder(builder: (context, c) {
              final maxD = c.biggest.shortestSide * 0.85;
              return AnimatedBuilder(
                animation: _size,
                builder: (context, _) {
                  final d = maxD * (0.45 + 0.55 * _size.value);
                  return Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft halo rings.
                        for (var k = 3; k >= 1; k--)
                          Container(
                            width: d + k * 26 * _size.value,
                            height: d + k * 26 * _size.value,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: CalmColors.mint.withValues(alpha: 0.12),
                            ),
                          ),
                        Container(
                          width: d,
                          height: d,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [Colors.white, CalmColors.mint, CalmColors.sky],
                              stops: [0.0, 0.6, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: CalmColors.sky.withValues(alpha: 0.6),
                                blurRadius: 40,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _running ? _phase.label : 'Ready?',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: CalmColors.ink),
                              ),
                              if (_running)
                                Text('$_secondsLeft',
                                    style: const TextStyle(
                                        fontSize: 42,
                                        fontWeight: FontWeight.w300,
                                        color: CalmColors.ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: FilledButton.icon(
              onPressed: _running ? _stop : _start,
              icon: Icon(_running ? Icons.pause_rounded : Icons.play_arrow_rounded),
              label: Text(_running ? 'Pause' : 'Start breathing'),
            ),
          ),
        ],
      ),
    );
  }
}
