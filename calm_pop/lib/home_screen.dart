import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'audio/sfx.dart';
import 'games/breathe.dart';
import 'games/bubble_wrap.dart';
import 'games/fairy_glow.dart';
import 'games/fidget_spinner.dart';
import 'games/ripple_pond.dart';
import 'games/star_dash.dart';
import 'theme.dart';

class _GameInfo {
  const _GameInfo(this.title, this.blurb, this.icon, this.colors, this.builder);

  final String title;
  final String blurb;
  final IconData icon;
  final List<Color> colors;
  final WidgetBuilder builder;
}

final _games = <_GameInfo>[
  _GameInfo('Bubble Wrap', 'Pop, pop, pop. Endless sheets.',
      Icons.bubble_chart_rounded, const [CalmColors.sky, CalmColors.lavender],
      (_) => const BubbleWrapGame()),
  _GameInfo('Breathe', 'Guided breathing to slow down.', Icons.air_rounded,
      const [CalmColors.mint, CalmColors.sky], (_) => const BreatheGame()),
  _GameInfo('Ripple Pond', 'Touch the water, watch it glow.',
      Icons.water_drop_rounded, const [CalmColors.lavender, CalmColors.rose],
      (_) => const RipplePondGame()),
  _GameInfo('Fidget Spinner', 'Flick it and let it spin.',
      Icons.cyclone_rounded, const [CalmColors.peach, CalmColors.lemon],
      (_) => const FidgetSpinnerGame()),
];

const _tips = [
  'Drop your shoulders. Unclench your jaw.',
  'You don\'t have to finish everything today.',
  'Name three things you can see right now.',
  'A short pause is still progress.',
  'Sip some water — your brain will thank you.',
  'Breathe out longer than you breathe in.',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String _tip = _tips[Random().nextInt(_tips.length)];

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _nextTip() {
    HapticFeedback.selectionClick();
    Sfx.instance.play('tap');
    setState(() {
      var next = _tip;
      while (next == _tip) {
        next = _tips[Random().nextInt(_tips.length)];
      }
      _tip = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(gradient: CalmColors.background),
      child: Scaffold(
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                sliver: SliverList.list(children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('$_greeting 🌿',
                            style: text.bodyMedium?.copyWith(fontSize: 16)),
                      ),
                      const SoundToggle(color: CalmColors.ink),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('What would help\nyou unwind?', style: text.headlineMedium),
                  const SizedBox(height: 20),
                  _TipCard(tip: _tip, onTap: _nextTip),
                  const SizedBox(height: 24),
                  Text('Play a game', style: text.titleMedium),
                  const SizedBox(height: 12),
                  _FeaturedCard(
                    tag: 'ARCADE',
                    title: 'Star Dash',
                    blurb: 'Blast asteroids, grab power-ups, beat your best.',
                    icon: Icons.rocket_launch_rounded,
                    colors: const [Color(0xFF231C4D), Color(0xFF5B3F8C), Color(0xFFB77AA8)],
                    builder: (_) => const StarDashGame(),
                  ),
                  const SizedBox(height: 16),
                  _FeaturedCard(
                    tag: 'COZY',
                    title: 'Fairy Glow',
                    blurb: 'Help the little fairy catch falling stars.',
                    icon: Icons.auto_awesome_rounded,
                    colors: const [Color(0xFF2A2366), Color(0xFF6F5BD6), Color(0xFFE7B86A)],
                    builder: (_) => const FairyGlowGame(),
                  ),
                  const SizedBox(height: 24),
                  Text('Pick a calm activity', style: text.titleMedium),
                  const SizedBox(height: 12),
                ]),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                sliver: SliverGrid.builder(
                  itemCount: _games.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    mainAxisExtent: 200,
                  ),
                  itemBuilder: (context, i) => _GameCard(info: _games[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.tip, required this.onTap});

  final String tip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.75),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: CalmColors.lemon,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.spa_rounded, color: CalmColors.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    tip,
                    key: ValueKey(tip),
                    style: const TextStyle(
                        color: CalmColors.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ),
              ),
              const Icon(Icons.refresh_rounded, color: CalmColors.inkSoft, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

void _openGame(BuildContext context, WidgetBuilder builder) {
  HapticFeedback.lightImpact();
  Sfx.instance.play('tap');
  Navigator.of(context).push(PageRouteBuilder(
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, _, _) => builder(context),
    transitionsBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween(begin: 0.96, end: 1.0)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
        child: child,
      ),
    ),
  ));
}

/// Big banner for the arcade game.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.tag,
    required this.title,
    required this.blurb,
    required this.icon,
    required this.colors,
    required this.builder,
  });

  final String tag;
  final String title;
  final String blurb;
  final IconData icon;
  final List<Color> colors;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openGame(context, builder),
      child: Container(
        constraints: const BoxConstraints(minHeight: 150),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          boxShadow: [
            BoxShadow(
              color: colors[1].withValues(alpha: 0.45),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CalmColors.lemon,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(tag,
                        style: TextStyle(
                            color: CalmColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1)),
                  ),
                  const SizedBox(height: 10),
                  Text(title,
                      style: TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(blurb,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: Colors.white, size: 34),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameCard extends StatefulWidget {
  const _GameCard({required this.info});

  final _GameInfo info;

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  void _open() => _openGame(context, widget.info.builder);

  @override
  Widget build(BuildContext context) {
    final info = widget.info;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _open,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: info.colors,
            ),
            boxShadow: [
              BoxShadow(
                color: info.colors.last.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(info.icon, color: CalmColors.ink, size: 28),
              ),
              const Spacer(),
              Text(info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: CalmColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(info.blurb,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: CalmColors.ink.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}
