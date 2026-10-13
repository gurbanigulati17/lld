import 'package:flutter/material.dart';

import 'glass_theme.dart';

enum GlassChipTone { neutral, accent, positive, negative, warning }

/// Small status pill.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    this.tone = GlassChipTone.neutral,
    this.icon,
  });

  final String label;
  final GlassChipTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.glass;
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      GlassChipTone.neutral => scheme.onSurface,
      GlassChipTone.accent => t.accent,
      GlassChipTone.positive => t.positive,
      GlassChipTone.negative => t.negative,
      GlassChipTone.warning => t.warning,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
