import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class OtherSourcesSection extends ConsumerWidget {
  const OtherSourcesSection({super.key});

  void _set(
          WidgetRef ref, OtherSourcesIncome Function(OtherSourcesIncome) fn) =>
      ref
          .read(itrDraftProvider.notifier)
          .update((d) => d.copyWith(otherSources: fn(d.otherSources)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final o = ref.watch(itrDraftProvider.select((d) => d.otherSources));
    final d = ref.watch(itrDraftProvider);
    return SectionScaffold(
      title: 'Other sources',
      subtitle:
          'From AIS / Form 26AS. Savings interest gets s.80TTA (₹10,000) or s.80TTB (₹50,000 for seniors) in the old regime.',
      children: [
        AmountField(
          label: 'Savings account interest',
          value: o.savingsInterest,
          onChanged: (v) => _set(ref, (o) => _copy(o, savingsInterest: v)),
        ),
        AmountField(
          label: 'Fixed / recurring deposit interest',
          value: o.fixedDepositInterest,
          onChanged: (v) => _set(ref, (o) => _copy(o, fixedDepositInterest: v)),
        ),
        AmountField(
          label: 'Dividends',
          value: o.dividends,
          onChanged: (v) => _set(ref, (o) => _copy(o, dividends: v)),
        ),
        AmountField(
          label: 'Family pension',
          value: o.familyPension,
          onChanged: (v) => _set(ref, (o) => _copy(o, familyPension: v)),
        ),
        AmountField(
          label: 'Any other income',
          value: o.other,
          onChanged: (v) => _set(ref, (o) => _copy(o, other: v)),
        ),
        const SectionHeader('Exempt and special'),
        AmountField(
          label: 'Agricultural income',
          helper: 'Exempt, but above ₹5,000 it raises the rate on other income',
          value: d.agriculturalIncome,
          onChanged: (v) => ref
              .read(itrDraftProvider.notifier)
              .update((d) => d.copyWith(agriculturalIncome: v)),
        ),
        SwitchTile(
          label: 'Foreign assets or income',
          helper: 'Requires Schedule FA (ITR-2/3)',
          value: d.hasForeignAssetsOrIncome,
          onChanged: (v) => ref
              .read(itrDraftProvider.notifier)
              .update((d) => d.copyWith(hasForeignAssetsOrIncome: v)),
        ),
        SwitchTile(
          label: 'Director or unlisted shares',
          value: d.isDirectorOrHoldsUnlistedShares,
          onChanged: (v) => ref
              .read(itrDraftProvider.notifier)
              .update((d) => d.copyWith(isDirectorOrHoldsUnlistedShares: v)),
        ),
      ],
    );
  }

  static OtherSourcesIncome _copy(
    OtherSourcesIncome o, {
    int? savingsInterest,
    int? fixedDepositInterest,
    int? dividends,
    int? familyPension,
    int? other,
  }) =>
      OtherSourcesIncome(
        savingsInterest: savingsInterest ?? o.savingsInterest,
        fixedDepositInterest: fixedDepositInterest ?? o.fixedDepositInterest,
        dividends: dividends ?? o.dividends,
        familyPension: familyPension ?? o.familyPension,
        other: other ?? o.other,
      );
}
