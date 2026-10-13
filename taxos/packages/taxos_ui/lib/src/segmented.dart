import 'package:flutter/material.dart';

import 'tokens.dart';

/// Segmented control: inset track, sliding solid thumb in the primary
/// colour.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.values,
    required this.labels,
    required this.selected,
    required this.onChanged,
  }) : assert(values.length == labels.length);

  final List<T> values;
  final List<String> labels;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final idx = values.indexOf(selected);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / values.length;
          return SizedBox(
            height: 38,
            child: Stack(
              children: [
                if (idx >= 0)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    left: w * idx,
                    top: 0,
                    bottom: 0,
                    width: w,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: t.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    for (var i = 0; i < values.length; i++)
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onChanged(values[i]),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 160),
                              style: Theme.of(context).textTheme.labelLarge!.copyWith(
                                    color: i == idx ? t.onAccentGradient : t.text,
                                  ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
