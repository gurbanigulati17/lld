import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_text_field.dart';

/// Formats digits into Indian grouping (12,34,567) as the user types.
class IndianAmountFormatter extends TextInputFormatter {
  const IndianAmountFormatter();

  static String format(int value) {
    final digits = value.abs().toString();
    if (digits.length <= 3) return digits;
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    return '${parts.join(',')},$last3';
  }

  static int parse(String text) =>
      int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return const TextEditingValue();
    final formatted = format(int.parse(raw));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Rupee input with Indian digit grouping and a ₹ prefix.
class GlassAmountField extends StatefulWidget {
  const GlassAmountField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
    this.hint = '0',
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? helper;
  final String hint;

  @override
  State<GlassAmountField> createState() => _GlassAmountFieldState();
}

class _GlassAmountFieldState extends State<GlassAmountField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.value == 0 ? '' : IndianAmountFormatter.format(widget.value),
  );

  @override
  void didUpdateWidget(GlassAmountField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value &&
        IndianAmountFormatter.parse(_ctrl.text) != widget.value) {
      _ctrl.text =
          widget.value == 0 ? '' : IndianAmountFormatter.format(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassTextField(
      label: widget.label,
      controller: _ctrl,
      hint: widget.hint,
      helper: widget.helper,
      keyboardType: const TextInputType.numberWithOptions(decimal: false),
      inputFormatters: const [IndianAmountFormatter()],
      prefix: Text('₹', style: Theme.of(context).textTheme.titleMedium),
      onChanged: (s) => widget.onChanged(IndianAmountFormatter.parse(s)),
    );
  }
}
