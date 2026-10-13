import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class TaxesPaidSection extends ConsumerWidget {
  const TaxesPaidSection({super.key});

  void _set(WidgetRef ref, TaxesPaid Function(TaxesPaid) fn) => ref
      .read(itrDraftProvider.notifier)
      .update((d) => d.copyWith(taxesPaid: fn(d.taxesPaid)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tp = ref.watch(itrDraftProvider.select((d) => d.taxesPaid));
    final draft = ref.watch(itrDraftProvider);
    final c = ref.watch(activeComputationProvider);
    final text = Theme.of(context).textTheme;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final rp = ItrRulePack.forYear(draft.assessmentYear);
    return SectionScaffold(
      title: 'Taxes paid',
      subtitle:
          'TDS on salary comes from the salary section. Add other TDS from Form 26AS, advance-tax challans, and your planned filing date for interest.',
      children: [
        AmountField(
          label: 'TDS other than salary',
          helper: 'Bank interest, professional fees (Form 26AS)',
          value: tp.tdsOther,
          onChanged: (v) => _set(
              ref,
              (t) => TaxesPaid(
                  tdsOther: v,
                  tcs: t.tcs,
                  advanceTax: t.advanceTax,
                  selfAssessmentTax: t.selfAssessmentTax)),
        ),
        AmountField(
          label: 'TCS',
          value: tp.tcs,
          onChanged: (v) => _set(
              ref,
              (t) => TaxesPaid(
                  tdsOther: t.tdsOther,
                  tcs: v,
                  advanceTax: t.advanceTax,
                  selfAssessmentTax: t.selfAssessmentTax)),
        ),
        AmountField(
          label: 'Self-assessment tax paid',
          value: tp.selfAssessmentTax,
          onChanged: (v) => _set(
              ref,
              (t) => TaxesPaid(
                  tdsOther: t.tdsOther,
                  tcs: t.tcs,
                  advanceTax: t.advanceTax,
                  selfAssessmentTax: v)),
        ),
        const SectionHeader('Advance tax challans'),
        for (var i = 0; i < tp.advanceTax.length; i++)
          Surface(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Surface(
                    radius: 14,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: tp.advanceTax[i].date,
                        firstDate: draft.assessmentYear.fyStartDate,
                        lastDate: draft.assessmentYear.fyEndDate
                            .add(const Duration(days: 180)),
                      );
                      if (picked != null) {
                        _set(ref, (t) {
                          final list = [...t.advanceTax];
                          list[i] = AdvanceTaxPayment(
                              date: picked, amount: list[i].amount);
                          return TaxesPaid(
                              tdsOther: t.tdsOther,
                              tcs: t.tcs,
                              advanceTax: list,
                              selfAssessmentTax: t.selfAssessmentTax);
                        });
                      }
                    },
                    child: Text(
                      '${tp.advanceTax[i].date.day}/${tp.advanceTax[i].date.month}/${tp.advanceTax[i].date.year}',
                      style: text.titleSmall,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: AmountField(
                    label: 'Amount',
                    value: tp.advanceTax[i].amount,
                    onChanged: (v) => _set(ref, (t) {
                      final list = [...t.advanceTax];
                      list[i] =
                          AdvanceTaxPayment(date: list[i].date, amount: v);
                      return TaxesPaid(
                          tdsOther: t.tdsOther,
                          tcs: t.tcs,
                          advanceTax: list,
                          selfAssessmentTax: t.selfAssessmentTax);
                    }),
                  ),
                ),
                IconButton(
                  onPressed: () => _set(
                      ref,
                      (t) => TaxesPaid(
                            tdsOther: t.tdsOther,
                            tcs: t.tcs,
                            advanceTax: [...t.advanceTax]..removeAt(i),
                            selfAssessmentTax: t.selfAssessmentTax,
                          )),
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        AppButton(
          label: 'Add challan',
          icon: Icons.add,
          style: AppButtonStyle.secondary,
          expand: true,
          onPressed: () => _set(
              ref,
              (t) => TaxesPaid(
                    tdsOther: t.tdsOther,
                    tcs: t.tcs,
                    advanceTax: [
                      ...t.advanceTax,
                      AdvanceTaxPayment(
                          date: DateTime(draft.assessmentYear.fyStart, 6, 15),
                          amount: 0),
                    ],
                    selfAssessmentTax: t.selfAssessmentTax,
                  )),
        ),
        const SectionHeader('Filing date'),
        Surface(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: draft.filingDate ?? rp.dueDateNonAudit,
              firstDate: draft.assessmentYear.fyEndDate,
              lastDate:
                  draft.assessmentYear.fyEndDate.add(const Duration(days: 365)),
            );
            if (picked != null) {
              ref
                  .read(itrDraftProvider.notifier)
                  .update((d) => d.copyWith(filingDate: picked));
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Planned filing date',
                        style: text.labelMedium?.copyWith(color: muted)),
                    Text(
                      _fmt(draft.filingDate ?? rp.dueDateNonAudit),
                      style: text.titleMedium,
                    ),
                    Text('Due date ${_fmt(rp.dueDateNonAudit)}',
                        style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              if (c.totalInterest > 0)
                Tag(
                    label: 'Interest ${formatInr(c.totalInterest)}',
                    tone: TagTone.warning),
            ],
          ),
        ),
      ],
    );
  }

  static String _fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
