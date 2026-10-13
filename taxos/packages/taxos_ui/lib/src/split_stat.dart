import 'package:flutter/material.dart';

import 'tokens.dart';

class StatValue {
  const StatValue({required this.label, required this.value, this.note, this.color});
  final String label;
  final String value;
  final String? note;
  final Color? color;
}

/// Two figures side by side with a tinted vertical divider between them.
class SplitStat extends StatelessWidget {
  const SplitStat({super.key, required this.left, required this.right, this.large = true});

  final StatValue left;
  final StatValue right;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    Widget cell(StatValue v) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v.label, style: text.bodySmall?.copyWith(color: t.textMuted, fontSize: large ? 13 : 12)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                v.value,
                style: (large ? text.headlineSmall : text.titleMedium)?.copyWith(
                  color: v.color ?? t.text,
                  fontWeight: FontWeight.w600,
                  letterSpacing: large ? -0.5 : 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            if (v.note != null) ...[
              const SizedBox(height: 2),
              Text(v.note!, style: text.labelSmall?.copyWith(color: t.textMuted)),
            ],
          ],
        );
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Padding(padding: const EdgeInsets.only(right: 16), child: cell(left))),
          Container(width: 1, color: t.splitDivider),
          Expanded(child: Padding(padding: const EdgeInsets.only(left: 16), child: cell(right))),
        ],
      ),
    );
  }
}
