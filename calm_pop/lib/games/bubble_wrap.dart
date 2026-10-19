import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import '../widgets/game_scaffold.dart';

class BubbleWrapGame extends StatefulWidget {
  const BubbleWrapGame({super.key});

  @override
  State<BubbleWrapGame> createState() => _BubbleWrapGameState();
}

class _BubbleWrapGameState extends State<BubbleWrapGame> {
  static const _cols = 5;
  static const _rows = 8;
  static const _count = _cols * _rows;

  final _rand = Random();
  late List<bool> _popped = List.filled(_count, false);
  int _sheet = 1;
  int _totalPops = 0;
  Color _tint = CalmColors.sky;

  int get _remaining => _popped.where((p) => !p).length;

  void _pop(int i) {
    if (_popped[i]) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
    setState(() {
      _popped[i] = true;
      _totalPops++;
    });
    if (_remaining == 0) {
      Future.delayed(const Duration(milliseconds: 700), _newSheet);
    }
  }

  void _newSheet() {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _popped = List.filled(_count, false);
      _sheet++;
      _tint = CalmColors.pastels[_rand.nextInt(CalmColors.pastels.length)];
    });
  }

  @override
  Widget build(BuildContext context) {
    return GameScaffold(
      title: 'Bubble Wrap',
      subtitle: 'Sheet $_sheet · $_remaining left',
      action: IconButton(
        tooltip: 'New sheet',
        icon: const Icon(Icons.refresh_rounded, color: CalmColors.ink),
        onPressed: _newSheet,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: StatPill(
                icon: Icons.auto_awesome_rounded, label: '$_totalPops pops'),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 450),
                transitionBuilder: (child, anim) => SlideTransition(
                  position: Tween(begin: const Offset(0, 0.15), end: Offset.zero)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: _Sheet(
                  key: ValueKey(_sheet),
                  cols: _cols,
                  rows: _rows,
                  popped: _popped,
                  tint: _tint,
                  onPop: _pop,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({
    super.key,
    required this.cols,
    required this.rows,
    required this.popped,
    required this.tint,
    required this.onPop,
  });

  final int cols;
  final int rows;
  final List<bool> popped;
  final Color tint;
  final ValueChanged<int> onPop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final size = min(c.maxWidth / cols, c.maxHeight / rows);
        return Center(
          child: SizedBox(
            width: size * cols,
            height: size * rows,
            child: Wrap(
              children: [
                for (var i = 0; i < cols * rows; i++)
                  SizedBox(
                    width: size,
                    height: size,
                    child: Padding(
                      padding: EdgeInsets.all(size * 0.07),
                      child: _Bubble(
                        seed: i,
                        popped: popped[i],
                        tint: tint,
                        onPop: () => onPop(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(
      {required this.seed, required this.popped, required this.tint, required this.onPop});

  final int seed;
  final bool popped;
  final Color tint;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onPop(),
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: popped ? 1 : 0),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        builder: (context, t, _) => CustomPaint(
          painter: _BubblePainter(progress: t, tint: tint, seed: seed),
        ),
      ),
    );
  }
}

class _BubblePainter extends CustomPainter {
  _BubblePainter({required this.progress, required this.tint, required this.seed});

  final int seed;

  /// 0 = fresh bubble, 1 = fully popped.
  final double progress;
  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final p = progress.clamp(0.0, 1.2);

    if (p < 0.5) {
      // Intact (or squishing) bubble.
      final squish = 1 - p * 0.3;
      final rect = Rect.fromCircle(center: c, radius: r * squish);
      canvas.drawCircle(
        c.translate(0, r * 0.08),
        r * squish,
        Paint()
          ..color = tint.withValues(alpha: 0.35)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
      canvas.drawCircle(
        c,
        r * squish,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.35, -0.4),
            colors: [Colors.white, tint.withValues(alpha: 0.9), tint],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(rect),
      );
      canvas.drawCircle(
        c.translate(-r * 0.32, -r * 0.34),
        r * 0.18,
        Paint()..color = Colors.white.withValues(alpha: 0.85),
      );
    } else {
      // Popped: flattened, crinkled plastic.
      final paint = Paint()
        ..color = tint.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(c, r * 0.82, paint);
      final crease = Paint()
        ..color = tint.withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      final rnd = Random(seed);
      for (var k = 0; k < 4; k++) {
        final a = rnd.nextDouble() * pi * 2;
        final len = r * (0.25 + rnd.nextDouble() * 0.35);
        canvas.drawLine(c, c + Offset(cos(a), sin(a)) * len, crease);
      }
      // Burst sparkle that fades as the pop finishes.
      final burst = (1 - (p - 0.5) * 2).clamp(0.0, 1.0);
      if (burst > 0) {
        final sp = Paint()..color = tint.withValues(alpha: burst);
        for (var k = 0; k < 6; k++) {
          final a = k * pi / 3;
          canvas.drawCircle(c + Offset(cos(a), sin(a)) * r * (1.0 + (1 - burst) * 0.3),
              r * 0.08, sp);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) =>
      old.progress != progress || old.tint != tint || old.seed != seed;
}
