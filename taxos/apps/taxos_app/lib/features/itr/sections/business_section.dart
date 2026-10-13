import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class BusinessSection extends ConsumerWidget {
  const BusinessSection({super.key});

  void _set(WidgetRef ref, BusinessIncome b) => ref
      .read(itrDraftProvider.notifier)
      .update((d) => d.copyWith(business: b));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final b = ref.watch(itrDraftProvider.select((d) => d.business));
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return SectionScaffold(
      title: 'Business / profession',
      subtitle:
          'Freelancers and consultants usually qualify for presumptive taxation: no books, 50% of receipts (s.44ADA) or 8% / 6% of turnover (s.44AD).',
      actions: [
        if (b != null)
          IconButton(
            tooltip: 'Remove business income',
            onPressed: () => ref
                .read(itrDraftProvider.notifier)
                .update((d) => d.copyWith(clearBusiness: true)),
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      children: [
        Segmented<BusinessIncomeKind?>(
          values: const [
            null,
            BusinessIncomeKind.presumptive44ADA,
            BusinessIncomeKind.presumptive44AD,
            BusinessIncomeKind.regular
          ],
          labels: const ['None', '44ADA', '44AD', 'Books'],
          selected: b?.kind,
          onChanged: (k) {
            if (k == null) {
              ref
                  .read(itrDraftProvider.notifier)
                  .update((d) => d.copyWith(clearBusiness: true));
            } else {
              _set(ref, BusinessIncome(kind: k));
            }
          },
        ),
        if (b == null)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text('No business or professional income.',
                style: TextStyle(color: muted)),
          ),
        if (b?.kind == BusinessIncomeKind.presumptive44ADA) ...[
          AmountField(
            label: 'Gross professional receipts',
            helper: 'Up to ₹50L (₹75L if 95%+ digital)',
            value: b!.grossReceipts,
            onChanged: (v) => _set(
                ref,
                BusinessIncome(
                    kind: b.kind,
                    grossReceipts: v,
                    declaredProfit: b.declaredProfit)),
          ),
          AmountField(
            label: 'Declare higher profit (optional)',
            helper: 'Engine uses the higher of 50% and this',
            value: b.declaredProfit ?? 0,
            onChanged: (v) => _set(
                ref,
                BusinessIncome(
                    kind: b.kind,
                    grossReceipts: b.grossReceipts,
                    declaredProfit: v == 0 ? null : v)),
          ),
        ],
        if (b?.kind == BusinessIncomeKind.presumptive44AD) ...[
          AmountField(
            label: 'Total turnover',
            helper: 'Up to ₹2 crore (₹3 crore if 95%+ digital)',
            value: b!.turnover,
            onChanged: (v) => _set(
                ref,
                BusinessIncome(
                    kind: b.kind,
                    turnover: v,
                    digitalTurnover: b.digitalTurnover,
                    declaredProfit: b.declaredProfit)),
          ),
          AmountField(
            label: 'Of which received digitally',
            helper: 'Deemed at 6% instead of 8%',
            value: b.digitalTurnover,
            onChanged: (v) => _set(
                ref,
                BusinessIncome(
                    kind: b.kind,
                    turnover: b.turnover,
                    digitalTurnover: v,
                    declaredProfit: b.declaredProfit)),
          ),
          AmountField(
            label: 'Declare higher profit (optional)',
            value: b.declaredProfit ?? 0,
            onChanged: (v) => _set(
                ref,
                BusinessIncome(
                    kind: b.kind,
                    turnover: b.turnover,
                    digitalTurnover: b.digitalTurnover,
                    declaredProfit: v == 0 ? null : v)),
          ),
        ],
        if (b?.kind == BusinessIncomeKind.regular) ...[
          AmountField(
            label: 'Net profit as per books',
            helper: 'After all allowable expenses and depreciation',
            value: b!.netProfit,
            onChanged: (v) =>
                _set(ref, BusinessIncome(kind: b.kind, netProfit: v)),
          ),
          Surface(
            radius: 18,
            child: Text(
              'Books-of-account cases need ITR-3 and, above the s.44AB turnover limits, a tax audit signed by a chartered accountant. TaxOS routes those to a partner CA for sign-off.',
              style:
                  Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
            ),
          ),
        ],
      ],
    );
  }
}
