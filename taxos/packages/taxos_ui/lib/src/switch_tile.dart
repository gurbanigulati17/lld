import 'package:flutter/material.dart';

import 'surface.dart';
import 'tokens.dart';

/// Boolean row on a surface.
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    return Surface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: text.titleSmall),
                if (helper != null)
                  Text(helper!, style: text.bodySmall?.copyWith(color: t.textMuted)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
