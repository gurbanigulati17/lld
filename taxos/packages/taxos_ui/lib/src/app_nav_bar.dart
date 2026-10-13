import 'package:flutter/material.dart';

import 'tokens.dart';

class AppNavItem {
  const AppNavItem({required this.icon, required this.label, this.selectedIcon});
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// Opaque bottom tab bar with a hairline on top. Sits in the scaffold's
/// bottomNavigationBar slot so the body never renders behind it.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.items,
    required this.index,
    required this.onChanged,
  });

  final List<AppNavItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Color.alphaBlend(t.surface.withValues(alpha: 0.6), t.ground),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: t.hairline))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () => onChanged(i),
                      child: Semantics(
                        selected: i == index,
                        button: true,
                        label: items[i].label,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              i == index ? (items[i].selectedIcon ?? items[i].icon) : items[i].icon,
                              size: 22,
                              color: i == index ? t.primary : t.textMuted,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              items[i].label,
                              style: text.labelSmall?.copyWith(
                                color: i == index ? t.primary : t.textMuted,
                                fontWeight: i == index ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
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
