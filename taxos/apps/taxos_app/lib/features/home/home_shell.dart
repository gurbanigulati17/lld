import 'package:flutter/material.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';

/// Bottom-navigation shell shared by the four top-level tabs.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const _tabs = [Routes.home, Routes.itr, Routes.gst, Routes.assistant];

  @override
  Widget build(BuildContext context) {
    final index =
        _tabs.indexWhere((t) => t == location).clamp(0, _tabs.length - 1);
    return Scaffold(
        backgroundColor: context.ui.ground,
        body: child,
        bottomNavigationBar: AppNavBar(
          index: index,
          onChanged: (i) => context.go(_tabs[i]),
          items: const [
            AppNavItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'Home'),
            AppNavItem(
                icon: Icons.description_outlined,
                selectedIcon: Icons.description,
                label: 'Return'),
            AppNavItem(
                icon: Icons.receipt_long_outlined,
                selectedIcon: Icons.receipt_long,
                label: 'GST'),
            AppNavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Ask'),
          ],
        ),
    );
  }
}
