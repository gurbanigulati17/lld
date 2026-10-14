import 'package:flutter/material.dart';

import 'tokens.dart';

/// The small spaced capitals that label a figure ("TAX YOU WILL PAY").
class LabelBar extends StatelessWidget {
  const LabelBar(this.label, {super.key, this.secondary = false});

  final String label;

  /// Kept for older call sites; both variants render the same.
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Text(
      label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.6, color: t.textMuted),
    );
  }
}
