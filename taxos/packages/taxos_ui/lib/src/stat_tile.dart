import 'package:flutter/material.dart';

import 'evergreen_widgets.dart';
import 'surface.dart';
import 'tokens.dart';

/// Small card: mint icon well, caption, figure.
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
    return Surface(
      flat: true,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[IconWell(icon: icon!), const SizedBox(height: 10)],
          Row(
            children: [
              Expanded(
                child: Text(caption, style: TextStyle(fontSize: 15, color: t.textMuted), overflow: TextOverflow.ellipsis),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: valueColor ?? t.text,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
