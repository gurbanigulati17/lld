import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import 'itr_state.dart';

/// Shared layout for a wizard section: glass app bar, scrollable fields,
/// and a sticky footer with the live liability so every keystroke shows
/// its effect.
class SectionScaffold extends ConsumerWidget {
  const SectionScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.actions,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return GlassScaffold(
      title: title,
      actions: actions,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
                16,
                24,
              ),
              children: [
                if (subtitle != null) ...[
                  Text(subtitle!, style: TextStyle(color: muted)),
                  const SizedBox(height: 16),
                ],
                for (final c in children) ...[c, const SizedBox(height: 12)],
              ],
            ),
          ),
          const LiveLiabilityBar(),
        ],
      ),
    );
  }
}

/// Sticky footer with the current best-regime liability.
class LiveLiabilityBar extends ConsumerWidget {
  const LiveLiabilityBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmp = ref.watch(comparisonProvider);
    final c = ref.watch(activeComputationProvider);
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: GlassPanel(
        emphasis: true,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.regime == TaxRegime.newRegime ? 'New' : 'Old'} regime · live',
                    style: text.labelMedium?.copyWith(color: muted),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      formatInr(c.totalTaxLiability),
                      key: ValueKey(c.totalTaxLiability),
                      style: text.titleLarge,
                    ),
                  ),
                ],
              ),
            ),
            if (cmp.savings > 0)
              GlassChip(
                label: 'Saves ${formatInr(cmp.savings)}',
                tone: GlassChipTone.positive,
                icon: Icons.auto_awesome,
              ),
          ],
        ),
      ),
    );
  }
}

/// Toggle row for booleans on glass.
class GlassSwitchTile extends StatelessWidget {
  const GlassSwitchTile({
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
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return GlassPanel(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleSmall),
                if (helper != null)
                  Text(helper!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A row of label + amount inside a breakdown.
class AmountRow extends StatelessWidget {
  const AmountRow({
    super.key,
    required this.label,
    required this.amount,
    this.section,
    this.note,
    this.bold = false,
    this.color,
  });

  final String label;
  final int amount;
  final String? section;
  final String? note;
  final bool bold;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final style = bold ? text.titleMedium : text.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: style),
                if (section != null || note != null)
                  Text(
                    [if (section != null) section!, if (note != null) note!].join(' · '),
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatInr(amount),
            style: style?.copyWith(
              color: color ?? (amount < 0 ? context.glass.positive : null),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
