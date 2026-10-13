import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Outlined input with the label above it.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.onSubmitted,
    this.prefix,
    this.suffix,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.autofocus = false,
    this.showLabel = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final Widget? prefix;
  final Widget? suffix;
  final bool obscureText;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool autofocus;

  /// Hide the visible label (it stays as the semantic label).
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label, style: text.labelMedium?.copyWith(color: t.textMuted)),
          const SizedBox(height: 6),
        ],
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: t.border),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 8)],
              Expanded(
                child: Semantics(
                  label: showLabel ? null : label,
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    onChanged: onChanged,
                    onSubmitted: onSubmitted,
                    obscureText: obscureText,
                    textCapitalization: textCapitalization,
                    maxLength: maxLength,
                    autofocus: autofocus,
                    style: text.bodyLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      counterText: '',
                      hintStyle: text.bodyLarge?.copyWith(color: t.textMuted),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 8), suffix!],
            ],
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: text.bodySmall?.copyWith(color: t.textMuted)),
        ],
      ],
    );
  }
}
