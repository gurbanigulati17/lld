import 'package:flutter/material.dart';

import 'tokens.dart';

enum TagTone { neutral, primary, positive, negative, warning }

/// Small status label. Neutral and primary are monochrome; the other three
/// are the only places colour appears in the app.
class Tag extends StatelessWidget {
  const Tag({super.key, required this.label, this.tone = TagTone.neutral, this.icon});

  final String label;
  final TagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final (Color bg, Color fg) = switch (tone) {
      TagTone.neutral => (t.surfaceAlt, t.text),
      TagTone.primary => (t.primary, t.onPrimary),
      TagTone.positive => (t.positive.withValues(alpha: 0.14), t.positive),
      TagTone.negative => (t.negative.withValues(alpha: 0.14), t.negative),
      TagTone.warning => (t.warning.withValues(alpha: 0.16), t.warning),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: fg),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
