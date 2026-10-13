import 'package:flutter/material.dart';

import 'glass_panel.dart';
import 'glass_theme.dart';

enum GlassButtonStyle { primary, secondary, ghost }

/// Pill button on a glass surface. Primary buttons carry the accent wash.
class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = GlassButtonStyle.primary,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final GlassButtonStyle style;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.glass;
    final scheme = Theme.of(context).colorScheme;
    final enabled = onPressed != null && !loading;
    final primary = style == GlassButtonStyle.primary;
    final fg = primary ? Colors.white : scheme.onSurface;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (icon != null || loading) const SizedBox(width: 10),
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: fg,
                fontSize: 15,
              ),
        ),
      ],
    );

    if (style == GlassButtonStyle.ghost) {
      return TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: const StadiumBorder(),
        ),
        child: content,
      );
    }

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: GlassPanel(
        onTap: enabled ? onPressed : null,
        radius: 999,
        emphasis: !primary,
        tint: primary ? t.accent.withValues(alpha: 0.85) : null,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        child: content,
      ),
    );
  }
}
