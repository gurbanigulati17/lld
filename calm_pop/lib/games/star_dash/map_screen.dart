import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/sfx.dart';
import '../../theme.dart';
import 'levels.dart';
import 'painter.dart';
import 'play_screen.dart';
import 'progress.dart';
import 'ships.dart';

/// Star Dash entry point: the galaxy map with every world and level.
class StarDashGame extends StatefulWidget {
  const StarDashGame({super.key});

  @override
  State<StarDashGame> createState() => _StarDashGameState();
}

class _StarDashGameState extends State<StarDashGame> {
  final _progress = DashProgress.instance;

  @override
  void initState() {
    super.initState();
    _progress.load();
    Sfx.instance.preload(const ['tap', 'start']);
  }

  Future<void> _play(LevelSpec level) async {
    HapticFeedback.lightImpact();
    Sfx.instance.play('tap');
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => DashPlayScreen(level: level)));
    if (mounted) setState(() {});
  }

  void _hangar() {
    Sfx.instance.play('tap');
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1C1640),
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const _Hangar(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0920),
      body: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: _StarsPainter())),
          SafeArea(
            child: ListenableBuilder(
              listenable: _progress,
              builder: (context, _) => CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _header(context)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: sectors.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) => _SectorCard(
                        index: i,
                        progress: _progress,
                        onPlay: _play,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final p = _progress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Back',
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              const Expanded(
                child: Text('Galaxy Map',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.star_rounded, color: CalmColors.lemon, size: 18),
                  const SizedBox(width: 4),
                  Text('${p.totalStars} / ${p.maxStars}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                ]),
              ),
              const SoundToggle(color: Colors.white),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    onTap: _hangar,
                    leading: ShipPreview(ship: p.ship, size: 44),
                    title: 'Hangar',
                    subtitle: p.ship.name,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    onTap: () => _play(endlessLevel),
                    leading: const Icon(Icons.all_inclusive_rounded, color: CalmColors.peach, size: 30),
                    title: 'Endless',
                    subtitle: 'Best ${p.endlessBest}',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.onTap, required this.leading, required this.title, required this.subtitle});

  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 44, height: 44, child: Center(child: leading)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({required this.index, required this.progress, required this.onPlay});

  final int index;
  final DashProgress progress;
  final ValueChanged<LevelSpec> onPlay;

  @override
  Widget build(BuildContext context) {
    final s = sectors[index];
    final lv = levels.where((l) => l.sector == index).toList();
    final open = progress.isUnlocked(lv.first.number);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          Positioned.fill(child: CustomPaint(painter: _SectorBackdropPainter(s))),
          Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: s.accent.withValues(alpha: open ? 0.45 : 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WORLD ${index + 1}',
                    style: TextStyle(color: s.accent, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(s.name,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
                Text(s.tagline,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 13)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (final l in lv) ...[
                      _LevelNode(level: l, progress: progress, onPlay: onPlay),
                      const SizedBox(width: 18),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({required this.level, required this.progress, required this.onPlay});

  final LevelSpec level;
  final DashProgress progress;
  final ValueChanged<LevelSpec> onPlay;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.isUnlocked(level.number);
    final stars = progress.starsFor(level.number);
    final accent = level.theme.accent;
    return Semantics(
      button: true,
      label: 'Level ${level.number}${unlocked ? '' : ' (locked)'}',
      child: GestureDetector(
        key: ValueKey('level-${level.number}'),
        onTap: unlocked ? () => onPlay(level) : null,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unlocked
                    ? RadialGradient(colors: [Colors.white, accent, Color.lerp(accent, Colors.black, 0.4)!])
                    : null,
                color: unlocked ? null : Colors.white.withValues(alpha: 0.08),
                boxShadow: unlocked ? [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 16)] : null,
              ),
              child: Center(
                child: unlocked
                    ? (level.isBoss
                        ? const Icon(Icons.whatshot_rounded, color: CalmColors.ink, size: 30)
                        : Text('${level.number}',
                            style: const TextStyle(color: CalmColors.ink, fontSize: 24, fontWeight: FontWeight.w900)))
                    : Icon(Icons.lock_rounded, color: Colors.white.withValues(alpha: 0.4)),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(Icons.star_rounded,
                      size: 15, color: i < stars ? CalmColors.lemon : Colors.white.withValues(alpha: 0.18)),
              ],
            ),
            if (level.isBoss)
              Text('BOSS',
                  style: TextStyle(
                      color: unlocked ? CalmColors.rose : Colors.white.withValues(alpha: 0.3),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _Hangar extends StatelessWidget {
  const _Hangar();

  @override
  Widget build(BuildContext context) {
    final p = DashProgress.instance;
    return ListenableBuilder(
      listenable: p,
      builder: (context, _) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hangar',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
              Text('Earn stars in the campaign to unlock new ships.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
                children: [
                  for (final s in ships) _ShipCard(ship: s, progress: p),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShipCard extends StatelessWidget {
  const _ShipCard({required this.ship, required this.progress});

  final ShipSpec ship;
  final DashProgress progress;

  @override
  Widget build(BuildContext context) {
    final unlocked = progress.shipUnlocked(ship);
    final selected = progress.ship.id == ship.id;
    return Material(
      color: Colors.white.withValues(alpha: selected ? 0.16 : 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: unlocked
            ? () {
                HapticFeedback.selectionClick();
                Sfx.instance.play('powerup', volume: 0.5);
                progress.selectShip(ship);
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? ship.colors[1] : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Expanded(child: ShipPreview(ship: ship, size: 80, locked: !unlocked)),
              Text(ship.name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                unlocked ? (selected ? 'Selected · ${ship.perk}' : ship.perk) : 'Unlock with ${ship.stars} ★',
                textAlign: TextAlign.center,
                maxLines: 2,
                style: TextStyle(
                    color: unlocked ? Colors.white.withValues(alpha: 0.7) : CalmColors.lemon, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectorBackdropPainter extends CustomPainter {
  _SectorBackdropPainter(this.sector);

  final Sector sector;

  @override
  void paint(Canvas canvas, Size size) {
    paintSectorBackdrop(canvas, size, sector, 0);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.withValues(alpha: 0.15));
  }

  @override
  bool shouldRepaint(_SectorBackdropPainter old) => old.sector != sector;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = Random(11);
    final p = Paint();
    for (var i = 0; i < 120; i++) {
      p.color = Colors.white.withValues(alpha: 0.2 + r.nextDouble() * 0.5);
      canvas.drawCircle(Offset(r.nextDouble() * size.width, r.nextDouble() * size.height), 0.5 + r.nextDouble(), p);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => false;
}
