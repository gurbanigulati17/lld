import 'package:flutter/material.dart';

import 'tokens.dart';

enum AppButtonStyle { primary, secondary, ghost }

/// Primary is a filled block in the one strong colour; secondary is an
/// outlined surface; ghost is text only.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.style = AppButtonStyle.primary,
    this.expand = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final AppButtonStyle style;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final enabled = onPressed != null && !loading;
    final fg = switch (style) {
      AppButtonStyle.primary => t.onPrimary,
      AppButtonStyle.secondary => t.text,
      AppButtonStyle.ghost => t.text,
    };
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
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    const pad = EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    final button = switch (style) {
      AppButtonStyle.primary => Opacity(
          opacity: enabled ? 1 : 0.45,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: enabled ? onPressed : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(padding: pad, child: Center(widthFactor: expand ? null : 1, child: content)),
                ),
              ),
            ),
          ),
        ),
      AppButtonStyle.secondary => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: t.surface,
            foregroundColor: t.text,
            side: BorderSide(color: t.border),
            shape: shape,
            padding: pad,
            minimumSize: const Size(0, 48),
          ),
          child: content,
        ),
      AppButtonStyle.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          style: TextButton.styleFrom(
            foregroundColor: t.text,
            shape: shape,
            padding: pad,
            minimumSize: const Size(0, 44),
          ),
          child: content,
        ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
