import 'package:flutter/material.dart';

import 'tokens.dart';

enum TagTone { neutral, primary, positive, negative, warning }

/// Small rounded status label. Urgent tones are solid so they read at a
/// glance; neutral and primary are soft.
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
      TagTone.primary => (t.tint, t.onTint),
      TagTone.positive => (t.positive, t.onPositive),
      TagTone.negative => (t.negative, t.onNegative),
      TagTone.warning => (t.warning, t.onWarning),
    };
    return DecoratedBox(
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}
