import 'package:flutter/material.dart';

import 'tokens.dart';

/// A yes/no row. Place it inside a [FieldGroup].
class SwitchTile extends StatelessWidget {
  const SwitchTile({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.helper,
  });

  final String label;
  final String? helper;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return MergeSemantics(
      child: InkWell(
        onTap: () => onChanged(!value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 16, color: t.text)),
                    if (helper != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(helper!, style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.3)),
                      ),
                  ],
                ),
              ),
              Switch.adaptive(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
