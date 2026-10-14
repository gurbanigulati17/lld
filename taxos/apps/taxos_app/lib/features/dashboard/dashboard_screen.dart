import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import '../../core/auth.dart';
import '../account/account_sheet.dart';
import '../itr/itr_state.dart';

/// Home: a plain-language summary, regime bars, and next steps.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static String greeting(DateTime now) => now.hour < 12
      ? 'Good morning'
      : now.hour < 17
          ? 'Good afternoon'
          : 'Good evening';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(itrDraftProvider);
    final cmp = ref.watch(comparisonProvider);
    final session = ref.watch(authProvider).valueOrNull;
    final sections = ref.watch(sectionStatusProvider);
    final t = context.ui;
    final top = MediaQuery.paddingOf(context).top;

    final best = cmp.best;
    final bestName = cmp.recommended == TaxRegime.newRegime ? 'new regime' : 'old regime';
    final maxTax = [cmp.oldRegime.totalTaxLiability, cmp.newRegime.totalTaxLiability, 1].reduce((a, b) => a > b ? a : b);
    final name = (session?.name.isNotEmpty ?? false) ? session!.name.split(' ').first : draft.profile.name.split(' ').first;
    final started = best.grossTotalIncome > 0;
    final done = sections.where((s) => s.done).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(Space.gutter, top + 8, Space.gutter, Space.section),
      children: [
        Row(
          children: [
            Expanded(child: Text(draft.assessmentYear.label, style: TextStyle(fontSize: 15, color: t.textMuted))),
            IconButton(
              tooltip: 'Account',
              onPressed: () => showAccountSheet(context),
              icon: Icon(Icons.account_circle_outlined, size: 30, color: t.text),
            ),
          ],
        ),
        PageHeading(
          name.isEmpty ? greeting(DateTime.now()) : '${greeting(DateTime.now())}, $name',
          subtitle: started ? 'Here is where your tax stands today.' : 'Start your return and see your tax as you go.',
        ),
        const SizedBox(height: Space.gutter),

        Surface(
          onTap: started ? () => context.push(Routes.computation) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (started)
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: best.isRefund ? 'You can expect a refund of ' : 'You are on track to pay '),
                    TextSpan(
                      text: formatInr(best.isRefund ? best.refundDue : best.totalTaxLiability),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: best.isRefund ? ' with the $bestName.' : ' in tax this year with the $bestName.'),
                  ]),
                  style: TextStyle(fontSize: 17, height: 1.4, color: t.text),
                )
              else
                Text('Add your salary or other income and Kardo works out your tax under both regimes.',
                    style: TextStyle(fontSize: 17, height: 1.4, color: t.text)),
              const SizedBox(height: 16),
              ProgressRow(
                label: 'New regime',
                value: formatInr(cmp.newRegime.totalTaxLiability),
                fraction: cmp.newRegime.totalTaxLiability / maxTax,
                color: t.chartPrimary,
              ),
              const SizedBox(height: 14),
              ProgressRow(
                label: 'Old regime',
                value: formatInr(cmp.oldRegime.totalTaxLiability),
                fraction: cmp.oldRegime.totalTaxLiability / maxTax,
                color: t.chartSecondary,
              ),
              const SizedBox(height: 14),
              Text(
                cmp.savings == 0
                    ? 'Estimate as of today, based on what you have entered.'
                    : 'Estimate as of today, based on what you have entered. The $bestName saves you ${formatInr(cmp.savings)}.',
                style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.45),
              ),
              if (started) HelpLink('How we got these numbers', onTap: () => context.push(Routes.computation)),
            ],
          ),
        ),

        const SectionTitle('Next steps'),
        for (final n in _nextSteps(context, draft, best, done, sections.length))
          Padding(padding: const EdgeInsets.only(bottom: Space.gap), child: n),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: draft.houseProperties.isEmpty
                  ? ActionTile(
                      icon: Icons.home_outlined,
                      text: 'Got a home loan?',
                      linkLabel: 'Add house property',
                      onTap: () => context.push(Routes.houseProperty),
                    )
                  : ActionTile(
                      icon: Icons.savings_outlined,
                      text: 'Saved in PPF, ELSS or insurance?',
                      linkLabel: 'Check deductions',
                      onTap: () => context.push(Routes.deductions),
                    ),
            ),
            const SizedBox(width: Space.gap),
            Expanded(
              child: ActionTile(
                icon: Icons.receipt_long_outlined,
                text: 'GSTR-3B due ${_shortDate(_nextMonthly(20))}',
                linkLabel: 'Review GST',
                onTap: () => context.go(Routes.gst),
              ),
            ),
          ],
        ),
        const SizedBox(height: Space.section),
        AppButton(
          label: done == 0 ? 'Start your return' : 'Continue your return',
          onPressed: () => context.go(Routes.itr),
        ),
      ],
    );
  }

  List<Widget> _nextSteps(
    BuildContext context,
    ItrInput draft,
    ItrComputation best,
    int done,
    int total,
  ) {
    final today = DateTime.now();
    final rp = ItrRulePack.forYear(draft.assessmentYear);
    final due = rp.dueDateNonAudit;
    final belated = draft.assessmentYear.belatedReturnLastDate;
    final items = <Widget>[];
    if (!today.isAfter(due)) {
      items.add(InfoCard(
        title: 'File your return by ${_shortDate(due)}',
        detail: '${due.difference(today).inDays} days left · $done of $total sections done',
        onTap: () => context.go(Routes.itr),
      ));
    } else if (!today.isAfter(belated)) {
      final fee = best.totalIncome > 500000 ? 5000 : 1000;
      items.add(InfoCard(
        title: 'File your return by ${_shortDate(belated)}',
        detail: best.totalIncome > ItrRulePack.forYear(draft.assessmentYear).newRegimeSlabs.first.from
            ? 'The July date has passed. A ${formatInr(fee)} late fee now applies.'
            : 'The July date has passed. A belated return is still allowed.',
        onTap: () => context.go(Routes.itr),
      ));
    }
    if (best.netPayable > 0 && best.grossTotalIncome > 0) {
      items.add(InfoCard(
        icon: Icons.account_balance_wallet_outlined,
        title: 'Pay ${formatInr(best.netPayable)} before filing',
        detail: 'Self-assessment tax through Challan 280',
        onTap: () => context.push(Routes.filing),
      ));
    }
    return items;
  }

  static DateTime _nextMonthly(int day) {
    final now = DateTime.now();
    final d = DateTime(now.year, now.month, day);
    return now.isAfter(d) ? DateTime(now.year, now.month + 1, day) : d;
  }

  static String _shortDate(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}
