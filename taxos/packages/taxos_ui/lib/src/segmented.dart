import 'package:flutter/material.dart';

import 'tokens.dart';

/// Text tabs with a green underline under the selected one.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
    this.center = true,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.hairline))),
      child: Row(
        mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          for (var i = 0; i < values.length; i++)
            Semantics(
              selected: values[i] == selected,
              button: true,
              child: InkWell(
                onTap: () => onChanged(values[i]),
                child: Container(
                  constraints: const BoxConstraints(minWidth: 64, minHeight: 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: values[i] == selected ? t.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: values[i] == selected ? FontWeight.w700 : FontWeight.w400,
                      color: values[i] == selected ? t.text : t.textMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
