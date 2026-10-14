import 'package:flutter/material.dart';

import 'space.dart';
import 'surface.dart';
import 'tokens.dart';

/// A card that stacks form rows with hairlines between them, like the
/// contribution editor in the Evergreen designs.
class FieldGroup extends StatelessWidget {
  const FieldGroup({super.key, required this.children, this.header});

  final List<Widget> children;

  /// Optional summary shown above the rows (for example a big figure).
  final Widget? header;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0 || header != null) rows.add(Divider(height: 1, color: t.hairline));
      rows.add(children[i]);
    }
    return Surface(
      padding: const EdgeInsets.fromLTRB(Space.gutter, 6, Space.gutter, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (header != null) Padding(padding: const EdgeInsets.only(top: 14, bottom: 14), child: header!),
          ...rows,
        ],
      ),
    );
  }
}
