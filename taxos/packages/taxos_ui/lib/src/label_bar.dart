import 'package:flutter/material.dart';

import 'tokens.dart';

/// The gradient label strip that heads a card ("ESTIMATED TAX · NEW
/// REGIME"). [secondary] uses the neutral silver gradient for the card
/// that supports the headline one.
class LabelBar extends StatelessWidget {
  const LabelBar(this.label, {super.key, this.secondary = false, this.dense = false});

  final String label;
  final bool secondary;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: secondary ? t.secondary : t.accent,
        borderRadius: BorderRadius.circular(dense ? 8 : 10),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dense ? 12 : 14, vertical: dense ? 6 : 8),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: secondary ? t.onSecondaryGradient : t.onAccentGradient,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                fontSize: dense ? 12 : 14,
              ),
        ),
      ),
    );
  }
}
