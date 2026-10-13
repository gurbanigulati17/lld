import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class DeductionsSection extends ConsumerWidget {
  const DeductionsSection({super.key});

  void _set(WidgetRef ref, Deductions Function(Deductions) fn) =>
      ref.read(itrDraftProvider.notifier).update((d) => d.copyWith(deductions: fn(d.deductions)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = ref.watch(itrDraftProvider.select((x) => x.deductions));
    final cmp = ref.watch(comparisonProvider);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return SectionScaffold(
      title: 'Deductions',
      subtitle: 'Chapter VI-A applies in the old regime only (employer NPS is the exception). Enter what you paid; the engine applies the caps.',
      children: [
        GlassPanel(
          radius: 18,
          child: Row(
            children: [
              Icon(Icons.info_outline, color: context.glass.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Old regime allows ${formatInr(cmp.oldRegime.chapterVIADeductions)} of deductions. '
                  '${cmp.recommended == TaxRegime.newRegime ? 'Even so, the new regime is cheaper for you.' : 'That makes the old regime cheaper for you.'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ),
            ],
          ),
        ),
        GlassAmountField(
          label: '80C investments',
          helper: 'PPF, ELSS, EPF, LIC, tuition, home-loan principal · cap ₹1,50,000',
          value: d.section80C,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80C: v)),
        ),
        GlassAmountField(
          label: '80CCD(1B) NPS self-contribution',
          helper: 'Cap ₹50,000 over and above 80C',
          value: d.section80CCD1B,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80CCD1B: v)),
        ),
        GlassAmountField(
          label: '80D health insurance (self & family)',
          helper: 'Cap ₹25,000 (₹50,000 if you are 60+)',
          value: d.section80D,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80D: v)),
        ),
        GlassAmountField(
          label: '80D health insurance (parents)',
          value: d.section80DParents,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80DParents: v)),
        ),
        GlassSwitchTile(
          label: 'Parents are senior citizens',
          helper: 'Raises the parents cap to ₹50,000',
          value: d.parentsAreSenior,
          onChanged: (v) => _set(ref, (d) => _copy(d, parentsAreSenior: v)),
        ),
        GlassAmountField(
          label: '80E education loan interest',
          value: d.section80E,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80E: v)),
        ),
        GlassAmountField(
          label: '80G donations (eligible amount)',
          value: d.section80G,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80G: v)),
        ),
        GlassAmountField(
          label: '80EEA affordable housing interest',
          helper: 'Cap ₹1,50,000',
          value: d.section80EEA,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80EEA: v)),
        ),
        GlassAmountField(
          label: '80U disability',
          helper: '₹75,000 or ₹1,25,000',
          value: d.section80U,
          onChanged: (v) => _set(ref, (d) => _copy(d, section80U: v)),
        ),
      ],
    );
  }

  static Deductions _copy(
    Deductions d, {
    int? section80C,
    int? section80CCD1B,
    int? section80D,
    int? section80DParents,
    bool? parentsAreSenior,
    int? section80E,
    int? section80G,
    int? section80EEA,
    int? section80U,
  }) =>
      Deductions(
        section80C: section80C ?? d.section80C,
        section80CCD1B: section80CCD1B ?? d.section80CCD1B,
        section80D: section80D ?? d.section80D,
        section80DParents: section80DParents ?? d.section80DParents,
        parentsAreSenior: parentsAreSenior ?? d.parentsAreSenior,
        section80E: section80E ?? d.section80E,
        section80G: section80G ?? d.section80G,
        section80EEA: section80EEA ?? d.section80EEA,
        section80U: section80U ?? d.section80U,
      );
}
