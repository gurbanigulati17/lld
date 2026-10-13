import 'package:flutter/material.dart';

import 'tokens.dart';

/// The soft label strip that heads a card ("ESTIMATED TAX · NEW REGIME").
/// It spans the card's content width, so it lines up with the figures
/// below it. [secondary] uses the neutral fill for a supporting card.
class LabelBar extends StatelessWidget {
  const LabelBar(this.label, {super.key, this.secondary = false});

  final String label;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: secondary ? t.surfaceAlt : t.tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: secondary ? t.textMuted : t.onTint,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
        ),
      ),
    );
  }
}
