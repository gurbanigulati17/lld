import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return AppScaffold(
      title: title,
      actions: actions,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  Space.gutter, 8, Space.gutter, Space.section),
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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return SafeArea(
      top: false,
      minimum:
          const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gap),
      child: Surface(
        emphasis: true,
        padding: const EdgeInsets.all(Space.card),
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
              Tag(
                label: 'Saves ${formatInr(cmp.savings)}',
                tone: TagTone.positive,
                icon: Icons.swap_horiz,
              ),
          ],
        ),
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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
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
                    [if (section != null) section!, if (note != null) note!]
                        .join(' · '),
                    style: text.bodySmall?.copyWith(color: muted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatInr(amount),
            style: style?.copyWith(
              color: color ?? (amount < 0 ? context.ui.positive : null),
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
        padding: const EdgeInsets.symmetric(vertical: Space.sm),
        child: Row(
          children: [
            Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
