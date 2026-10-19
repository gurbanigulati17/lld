import 'package:flutter/material.dart';

import '../theme.dart';

/// Common shell for every mini game: gradient background, back button,
/// title and an optional trailing action.
class GameScaffold extends StatelessWidget {
  const GameScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
    this.dark = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? action;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : CalmColors.ink;
    return Container(
      decoration: BoxDecoration(
        gradient: dark
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF242150), CalmColors.night],
              )
            : CalmColors.background,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Back',
                      icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(color: fg)),
                          if (subtitle != null)
                            Text(subtitle!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                        color: fg.withValues(alpha: 0.65))),
                        ],
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small rounded pill used for counters and stats.
class StatPill extends StatelessWidget {
  const StatPill({super.key, required this.icon, required this.label, this.dark = false});

  final IconData icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : CalmColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
