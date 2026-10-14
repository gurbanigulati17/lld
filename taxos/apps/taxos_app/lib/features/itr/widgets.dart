import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import 'itr_state.dart';

/// Shared layout for a return section: serif title, form rows grouped
/// into cards, and a sticky footer showing the tax as you type.
///
/// Consecutive [AmountField] and [SwitchTile] children are gathered into one
/// [FieldGroup] card, so sections read like the Evergreen designs without
/// each screen arranging its own cards.
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

  static bool _isRow(Widget w) => w is AmountField || w is SwitchTile;

  static List<Widget> group(List<Widget> children) {
    final out = <Widget>[];
    var run = <Widget>[];
    void flush() {
      if (run.isNotEmpty) out.add(FieldGroup(children: run));
      run = <Widget>[];
    }

    for (final c in children) {
      if (_isRow(c)) {
        run.add(c);
      } else {
        flush();
        out.add(c);
      }
    }
    flush();
    return out;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = group(children);
    return AppScaffold(
      actions: actions,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, Space.section),
              children: [
                PageHeading(title, subtitle: subtitle),
                const SizedBox(height: Space.gutter),
                for (var i = 0; i < blocks.length; i++) ...[
                  if (i > 0) const SizedBox(height: Space.gap),
                  blocks[i],
                ],
              ],
            ),
          ),
          const LiveLiabilityBar(),
        ],
      ),
    );
  }
}

/// Sticky footer with the current liability, updating as the user types.
class LiveLiabilityBar extends ConsumerWidget {
  const LiveLiabilityBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmp = ref.watch(comparisonProvider);
    final c = ref.watch(activeComputationProvider);
    final t = context.ui;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(Space.gutter, 0, Space.gutter, Space.gap),
      child: Surface(
        padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${c.regime == TaxRegime.newRegime ? 'New' : 'Old'} regime · updates as you type',
                    style: TextStyle(fontSize: 13, color: t.textMuted),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: Text(
                      formatInr(c.totalTaxLiability),
                      key: ValueKey(c.totalTaxLiability),
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: t.text, fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ),
                ],
              ),
            ),
            if (cmp.savings > 0) Tag(label: 'Saves ${formatInr(cmp.savings)}', tone: TagTone.positive),
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

/// Serif sub-heading inside a section.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: Space.gap, bottom: 2),
        child: Row(
          children: [
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
            if (trailing != null) trailing!,
          ],
        ),
      );
}
