import 'package:flutter/material.dart';

import 'surface.dart';
import 'tokens.dart';

/// KPI tile: small caption, big tabular number, optional trailing tag.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.caption,
    required this.value,
    this.trailing,
    this.onTap,
    this.valueColor,
    this.icon,
  });

  final String caption;
  final String value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? valueColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    return Surface(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: t.textMuted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  caption,
                  style: text.labelMedium?.copyWith(color: t.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: text.titleLarge?.copyWith(color: valueColor, fontSize: 22)),
          ),
        ],
      ),
    );
  }
}
