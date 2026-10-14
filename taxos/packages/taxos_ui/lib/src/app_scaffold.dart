import 'package:flutter/material.dart';

import 'tokens.dart';

/// Scaffold on the warm ground. The app bar carries only navigation; page
/// titles are set in the body as serif headings.
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
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: t.ground,
      appBar: title == null && actions == null && leading == null && !canPop
          ? null
          : AppBar(
              title: title == null ? null : Text(title!),
              actions: actions,
              leading: leading,
            ),
      body: body,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
