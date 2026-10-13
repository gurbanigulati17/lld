import 'package:flutter/material.dart';

import 'glass_panel.dart';

/// KPI tile: small caption, big number, optional trailing chip.
class GlassStat extends StatelessWidget {
  const GlassStat({
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
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.62);
    return GlassPanel(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: muted),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(
                  caption,
                  style: text.labelMedium?.copyWith(color: muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: text.headlineMedium?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}
