import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_panel.dart';

/// A labelled text field on a glass surface.
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelMedium?.copyWith(color: muted)),
          const SizedBox(height: 4),
          Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  inputFormatters: inputFormatters,
                  onChanged: onChanged,
                  obscureText: obscureText,
                  textCapitalization: textCapitalization,
                  maxLength: maxLength,
                  autofocus: autofocus,
                  style: text.titleMedium,
                  decoration: InputDecoration(
                    hintText: hint,
                    counterText: '',
                    hintStyle: text.titleMedium?.copyWith(color: muted),
                  ),
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 8), suffix!],
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: text.bodySmall?.copyWith(color: muted)),
          ],
        ],
      ),
    );
  }
}
