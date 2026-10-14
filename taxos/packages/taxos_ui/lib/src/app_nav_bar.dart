import 'package:flutter/material.dart';

import 'tokens.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.selectedIcon});
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// White bottom tab bar; the selected tab is forest green.
class AppNavBar extends StatelessWidget {
  const AppNavBar({super.key, required this.items, required this.index, required this.onChanged});

  final List<AppNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Material(
      color: t.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.hairline))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onChanged(i),
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: items[i].label,
                        child: ExcludeSemantics(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                i == index ? (items[i].selectedIcon ?? items[i].icon) : items[i].icon,
                                size: 24,
                                color: i == index ? t.heading : t.textMuted,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                items[i].label,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: i == index ? t.heading : t.textMuted,
                                  fontWeight: i == index ? FontWeight.w700 : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
