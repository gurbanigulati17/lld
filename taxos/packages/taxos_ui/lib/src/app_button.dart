import 'package:flutter/material.dart';

import 'tokens.dart';

enum AppButtonStyle { primary, secondary, ghost }

/// Pill buttons. Primary is the green pill; secondary is outlined; ghost is
/// text only.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.expand = false,
    this.loading = false,
    this.destructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool expand;
  final bool loading;

  /// Red text for sign out and deletes (secondary and ghost only).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final enabled = onPressed != null && !loading;
    final fg = switch (style) {
      AppButtonStyle.primary => t.onPrimary,
      _ => destructive ? t.negative : t.text,
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, size: 20, color: fg),
        if (icon != null || loading) const SizedBox(width: 10),
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: fg),
          ),
        ),
      ],
    );
    const shape = StadiumBorder();
    const pad = EdgeInsets.symmetric(horizontal: 32, vertical: 14);
    final button = switch (style) {
      AppButtonStyle.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: t.primary,
            foregroundColor: t.onPrimary,
            disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
            disabledForegroundColor: t.onPrimary,
            shape: shape,
            padding: pad,
            minimumSize: const Size(200, 50),
            elevation: 0,
          ),
          child: content,
        ),
      AppButtonStyle.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: t.surface,
            foregroundColor: fg,
            side: BorderSide(color: t.border),
            shape: shape,
            padding: pad,
            minimumSize: const Size(200, 50),
          ),
          child: content,
        ),
      AppButtonStyle.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: fg,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            minimumSize: const Size(0, 44),
          ),
          child: content,
        ),
    };
    if (expand) return SizedBox(width: double.infinity, child: button);
    return Center(child: button);
  }
}
