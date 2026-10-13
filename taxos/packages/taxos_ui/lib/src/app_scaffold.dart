import 'package:flutter/material.dart';

import 'glow_background.dart';
import 'tokens.dart';

/// Scaffold on the glowing ground with a transparent app bar separated by
/// a hairline. Only the app bar overlays the glow; the body, the input
/// bars and the tab bar never overlap each other.
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
    return GlowBackground(
      child: Scaffold(
      backgroundColor: Colors.transparent,
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
      ),
    );
  }
}
