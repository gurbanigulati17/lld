import 'package:flutter/material.dart';

import 'tokens.dart';

/// Scaffold on the ground colour with a flat app bar separated by a
/// hairline. Nothing floats and nothing extends behind anything, so the
/// keyboard, the input bars and the tab bar never overlap.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  final Widget body;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Scaffold(
      backgroundColor: t.ground,
      appBar: title == null && actions == null && leading == null
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              actions: actions,
              leading: leading,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(height: 1, color: t.hairline),
              ),
            ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
