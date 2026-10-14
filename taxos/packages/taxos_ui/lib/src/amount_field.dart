import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

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

  static int parse(String text) => int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) return const TextEditingValue();
    final formatted = format(int.parse(raw));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// A rupee field laid out as a row: the label (and optional helper) on the
/// left, a pill-shaped input on the right. Rows sit inside a [FieldGroup].
class AmountField extends StatefulWidget {
  const AmountField({
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
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.value == 0 ? '' : IndianAmountFormatter.format(widget.value),
  );
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(AmountField old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && IndianAmountFormatter.parse(_ctrl.text) != widget.value) {
      _ctrl.text = widget.value == 0 ? '' : IndianAmountFormatter.format(widget.value);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final focused = _focus.hasFocus;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label, style: TextStyle(fontSize: 16, color: t.text)),
                if (widget.helper != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(widget.helper!, style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.3)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 148,
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: t.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: focused ? t.primary : t.border, width: focused ? 1.5 : 1),
            ),
            child: Row(
              children: [
                Text('₹', style: TextStyle(fontSize: 16, color: t.textMuted)),
                const SizedBox(width: 4),
                Expanded(
                  child: Semantics(
                    label: widget.label,
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textAlign: TextAlign.center,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      inputFormatters: const [IndianAmountFormatter()],
                      style: TextStyle(
                        fontSize: 16,
                        color: t.text,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        hintText: widget.hint,
                        hintStyle: TextStyle(fontSize: 16, color: t.textMuted.withValues(alpha: 0.6)),
                      ),
                      onChanged: (s) => widget.onChanged(IndianAmountFormatter.parse(s)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
