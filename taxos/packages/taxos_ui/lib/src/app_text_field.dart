import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Text input with the label above it, on a rounded white field.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.helper,
    this.errorText,
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
    this.textAlign = TextAlign.start,
    this.large = false,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? helper;
  final String? errorText;
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
  final bool showLabel;
  final TextAlign textAlign;

  /// Bigger type for one-field screens such as phone and OTP.
  final bool large;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final style = TextStyle(
      fontSize: large ? 22 : 17,
      letterSpacing: large ? 1.5 : 0,
      color: t.text,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label, style: TextStyle(fontSize: 15, color: t.textMuted)),
          const SizedBox(height: 8),
        ],
        Container(
          height: large ? 60 : 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: errorText != null ? t.negative : t.border),
          ),
          child: Row(
            children: [
              if (prefix != null) ...[prefix!, const SizedBox(width: 10)],
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
                    textAlign: textAlign,
                    autofillHints: autofillHints,
                    style: style,
                    decoration: InputDecoration(
                      hintText: hint,
                      counterText: '',
                      hintStyle: style.copyWith(color: t.textMuted.withValues(alpha: 0.7)),
                    ),
                  ),
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 8), suffix!],
            ],
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(errorText!, style: TextStyle(fontSize: 14, color: t.negative)),
        ] else if (helper != null) ...[
          const SizedBox(height: 6),
          Text(helper!, style: TextStyle(fontSize: 14, color: t.textMuted)),
        ],
      ],
    );
  }
}
