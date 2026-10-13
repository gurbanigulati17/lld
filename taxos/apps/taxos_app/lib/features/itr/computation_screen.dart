import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../app/router.dart';
import 'itr_state.dart';
import 'widgets.dart';

/// Full breakdown: regime comparison, every line item with its section,
/// warnings, and the plain-English explanation.
class ComputationScreen extends ConsumerWidget {
  const ComputationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmp = ref.watch(comparisonProvider);
    final selected = ref.watch(selectedRegimeProvider);
    final c = ref.watch(activeComputationProvider);
    final form = ref.watch(formRecommendationProvider);
    final t = context.glass;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final explanation = const ExplanationBuilder().explain(c);

    final groups = <LineGroup, List<LineItem>>{};
    for (final l in c.lineItems) {
      groups.putIfAbsent(l.group, () => []).add(l);
    }

    return GlassScaffold(
      title: 'Computation',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + kToolbarHeight + 8, 16, 32),
        children: [
          GlassSegmented<TaxRegime?>(
            values: const [null, TaxRegime.oldRegime, TaxRegime.newRegime],
            labels: const ['Best', 'Old', 'New'],
            selected: selected,
            onChanged: (v) => ref.read(selectedRegimeProvider.notifier).state = v,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _RegimeCard(
                  title: 'Old regime',
                  computation: cmp.oldRegime,
                  recommended: cmp.recommended == TaxRegime.oldRegime,
                  active: c.regime == TaxRegime.oldRegime,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _RegimeCard(
                  title: 'New regime',
                  computation: cmp.newRegime,
                  recommended: cmp.recommended == TaxRegime.newRegime,
                  active: c.regime == TaxRegime.newRegime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassPanel(
            emphasis: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.isRefund ? 'Refund due' : 'Tax payable', style: text.labelLarge?.copyWith(color: muted))),
                    GlassChip(label: form.form.label, tone: GlassChipTone.accent),
                  ],
                ),
                Text(
                  formatInr(c.isRefund ? c.refundDue : c.netPayable),
                  style: text.displayLarge?.copyWith(fontSize: 40, color: c.isRefund ? t.positive : null),
                ),
                const SizedBox(height: 10),
                for (final line in explanation)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(line, style: text.bodyMedium),
                  ),
              ],
            ),
          ),
          if (c.warnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            GlassPanel(
              tint: t.warning.withValues(alpha: 0.12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.warning_amber_rounded, color: t.warning),
                    const SizedBox(width: 8),
                    Text('Things to know', style: text.titleSmall),
                  ]),
                  const SizedBox(height: 8),
                  for (final w in c.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• $w', style: text.bodySmall),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text('Line by line', style: text.titleMedium),
          const SizedBox(height: 6),
          Text('Every amount carries its statutory section so you can check it against Form 16, AIS, or the ITD utility.',
              style: text.bodySmall?.copyWith(color: muted)),
          const SizedBox(height: 12),
          for (final g in LineGroup.values)
            if (groups[g] case final items?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_groupTitle(g), style: text.titleSmall?.copyWith(color: muted)),
                      const SizedBox(height: 4),
                      for (final l in items)
                        AmountRow(
                          label: l.label,
                          amount: l.amount,
                          section: l.section,
                          note: l.note,
                          bold: l.code == 'TI' || l.code == 'GTI' || l.code == 'TAX.TOTAL' || l.code.startsWith('NET.'),
                        ),
                    ],
                  ),
                ),
              ),
          Text('Why this form', style: text.titleMedium),
          const SizedBox(height: 8),
          GlassPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(form.form.label, style: text.titleSmall),
                const SizedBox(height: 6),
                for (final r in form.reasons)
                  Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $r', style: text.bodySmall)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            label: 'Continue to filing',
            icon: Icons.send_outlined,
            expand: true,
            onPressed: () => context.push(Routes.filing),
          ),
        ],
      ),
    );
  }

  static String _groupTitle(LineGroup g) => switch (g) {
        LineGroup.salary => 'Salary',
        LineGroup.houseProperty => 'House property',
        LineGroup.capitalGains => 'Capital gains',
        LineGroup.business => 'Business / profession',
        LineGroup.otherSources => 'Other sources',
        LineGroup.deductions => 'Deductions',
        LineGroup.tax => 'Tax',
        LineGroup.credits => 'Taxes already paid',
        LineGroup.interest => 'Interest',
        LineGroup.other => 'Totals',
      };
}

class _RegimeCard extends StatelessWidget {
  const _RegimeCard({
    required this.title,
    required this.computation,
    required this.recommended,
    required this.active,
  });

  final String title;
  final ItrComputation computation;
  final bool recommended;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = context.glass;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    return GlassPanel(
      emphasis: active,
      tint: active ? t.accent.withValues(alpha: 0.10) : null,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title, style: text.labelLarge?.copyWith(color: muted))),
              if (recommended) Icon(Icons.auto_awesome, size: 16, color: t.positive),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(child: Text(formatInr(computation.totalTaxLiability), style: text.titleLarge)),
          Text('${computation.effectiveRatePercent}% effective', style: text.bodySmall?.copyWith(color: muted)),
        ],
      ),
    );
  }
}
