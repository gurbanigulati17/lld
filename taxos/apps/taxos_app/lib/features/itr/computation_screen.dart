import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import 'itr_state.dart';

/// "How we got your tax": the summary in a sentence, the few lines that
/// matter, and every line of the computation on demand.
class ComputationScreen extends ConsumerStatefulWidget {
  const ComputationScreen({super.key});

  @override
  ConsumerState<ComputationScreen> createState() => _ComputationScreenState();
}

class _ComputationScreenState extends ConsumerState<ComputationScreen> {
  bool _showAll = false;

  static String _group(LineGroup g) => switch (g) {
        LineGroup.salary => 'Salary',
        LineGroup.houseProperty => 'House property',
        LineGroup.capitalGains => 'Capital gains',
        LineGroup.business => 'Business or profession',
        LineGroup.otherSources => 'Other sources',
        LineGroup.deductions => 'Deductions',
        LineGroup.tax => 'Tax',
        LineGroup.credits => 'Taxes already paid',
        LineGroup.interest => 'Interest and fees',
        LineGroup.other => 'Totals',
      };

  @override
  Widget build(BuildContext context) {
    final cmp = ref.watch(comparisonProvider);
    final c = ref.watch(activeComputationProvider);
    final form = ref.watch(formRecommendationProvider);
    final t = context.ui;
    final paid = c.tdsAndTcs + c.advanceTaxPaid + c.selfAssessmentTaxPaid;
    final extras = [
      if (c.totalInterest > 0) 'interest',
      if (c.lateFee234F > 0) 'the late fee',
    ];
    final maxTax = [cmp.oldRegime.totalTaxLiability, cmp.newRegime.totalTaxLiability, 1].reduce((a, b) => a > b ? a : b);

    final groups = <LineGroup, List<LineItem>>{};
    for (final l in c.lineItems) {
      groups.putIfAbsent(l.group, () => []).add(l);
    }

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, Space.section),
        children: [
          const PageHeading('How we got your tax', subtitle: 'Every number comes from what you entered.'),
          const SizedBox(height: Space.gutter),
          Surface(
            padding: const EdgeInsets.fromLTRB(Space.gutter, Space.gutter, Space.gutter, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text.rich(
                  TextSpan(children: [
                    if (c.isRefund) ...[
                      const TextSpan(text: 'You should get a refund of '),
                      TextSpan(text: formatInr(c.refundDue), style: const TextStyle(fontWeight: FontWeight.w700)),
                      const TextSpan(text: ', because tax already paid is more than your tax.'),
                    ] else if (c.netPayable == 0 && c.totalIncome == 0) ...[
                      const TextSpan(text: 'Add your income to see how your tax is worked out.'),
                    ] else if (c.netPayable == 0) ...[
                      const TextSpan(text: 'Nothing more to pay. Taxes already paid cover your tax.'),
                    ] else ...[
                      const TextSpan(text: 'You need to pay '),
                      TextSpan(text: formatInr(c.netPayable), style: const TextStyle(fontWeight: FontWeight.w700)),
                      TextSpan(text: extras.isEmpty ? ' before filing.' : ' before filing, including ${extras.join(' and ')}.'),
                    ],
                  ]),
                  style: TextStyle(fontSize: 17, height: 1.4, color: t.text),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: t.hairline),
                LedgerRow(label: 'Total income', amount: formatInr(c.totalIncome)),
                Divider(height: 1, color: t.hairline),
                LedgerRow(
                  label: c.rebate87A > 0 ? 'Tax after rebate' : 'Tax on your income',
                  note: c.rebate87A > 0
                      ? (c.totalIncome > ItrRulePack.forYear(ref.read(itrDraftProvider).assessmentYear).rebateFor(c.regime).incomeThreshold
                          ? 'marginal relief, s.87A'
                          : 'rebate, s.87A')
                      : null,
                  amount: formatInr(c.taxAfterRebate),
                ),
                if (c.surcharge > 0) ...[
                  Divider(height: 1, color: t.hairline),
                  LedgerRow(
                    label: 'Surcharge',
                    note: c.marginalRelief > 0 ? 'after marginal relief' : null,
                    amount: formatInr(c.surcharge - c.marginalRelief),
                  ),
                ],
                Divider(height: 1, color: t.hairline),
                LedgerRow(label: 'Health and education cess', amount: formatInr(c.cess)),
                if (paid > 0) ...[
                  Divider(height: 1, color: t.hairline),
                  LedgerRow(label: 'Tax already paid', note: 'TDS, TCS and advance tax', amount: '−${formatInr(paid)}', color: t.positive),
                ],
                if (c.totalInterest > 0) ...[
                  Divider(height: 1, color: t.hairline),
                  LedgerRow(label: 'Interest', note: 'ss.234A–C', amount: formatInr(c.totalInterest)),
                ],
                if (c.lateFee234F > 0) ...[
                  Divider(height: 1, color: t.hairline),
                  LedgerRow(label: 'Late filing fee', note: 's.234F', amount: formatInr(c.lateFee234F)),
                ],
                Divider(height: 1.5, thickness: 1.5, color: t.text),
                LedgerRow(
                  label: c.isRefund ? 'Refund' : 'To pay',
                  amount: formatInr(c.isRefund ? c.refundDue : c.netPayable),
                  bold: true,
                  color: c.isRefund ? t.positive : null,
                ),
              ],
            ),
          ),

          const SectionTitle('Old or new regime'),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ProgressRow(
                  label: 'New regime${cmp.recommended == TaxRegime.newRegime ? ' · best for you' : ''}',
                  value: formatInr(cmp.newRegime.totalTaxLiability),
                  fraction: cmp.newRegime.totalTaxLiability / maxTax,
                  color: t.chartPrimary,
                ),
                const SizedBox(height: 14),
                ProgressRow(
                  label: 'Old regime${cmp.recommended == TaxRegime.oldRegime ? ' · best for you' : ''}',
                  value: formatInr(cmp.oldRegime.totalTaxLiability),
                  fraction: cmp.oldRegime.totalTaxLiability / maxTax,
                  color: t.chartSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  const ExplanationBuilder().explainComparison(cmp).last,
                  style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.4),
                ),
              ],
            ),
          ),

          const SectionTitle('Your form'),
          InfoCard(
            icon: Icons.description_outlined,
            iconColor: t.heading,
            title: form.form.label,
            detail: form.reasons.join(' '),
          ),

          if (c.warnings.isNotEmpty) ...[
            const SectionTitle('Good to know'),
            for (final w in c.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.gap),
                child: InfoCard(title: w),
              ),
          ],

          const SizedBox(height: Space.gap),
          Align(
            alignment: Alignment.centerLeft,
            child: DottedLink(
              _showAll ? 'Hide the full computation' : 'See every line of the computation',
              onTap: () => setState(() => _showAll = !_showAll),
            ),
          ),
          if (_showAll) ...[
            for (final g in LineGroup.values)
              if (groups[g] case final items?) ...[
                const SizedBox(height: Space.gap),
                Surface(
                  flat: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LabelBar(_group(g)),
                      for (final l in items)
                        LedgerRow(
                          label: l.label,
                          note: [if (l.section != null) l.section!, if (l.note != null) l.note!].join(' · ').ifEmptyNull,
                          amount: l.amount < 0 ? '−${formatInr(-l.amount)}' : formatInr(l.amount),
                          color: l.amount < 0 ? t.positive : null,
                          bold: l.code == 'TI' || l.code == 'TAX.TOTAL' || l.code.startsWith('NET.'),
                        ),
                    ],
                  ),
                ),
              ],
          ],
          const SizedBox(height: Space.gutter),
          Text(
            'These figures follow the Income-tax Act for ${ref.read(itrDraftProvider).assessmentYear.label} as entered by you. '
            'Check them against Form 16 and your AIS before filing.',
            style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.5),
          ),
          const SizedBox(height: Space.section),
          AppButton(label: 'Continue to filing', onPressed: () => context.push(Routes.filing)),
        ],
      ),
    );
  }
}

extension on String {
  String? get ifEmptyNull => isEmpty ? null : this;
}
