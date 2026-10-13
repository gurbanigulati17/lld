import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import '../../core/settings.dart';
import '../gst/gst_state.dart';
import '../itr/itr_state.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(itrDraftProvider);
    final cmp = ref.watch(comparisonProvider);
    final best = cmp.best;
    final other = cmp.recommended == TaxRegime.newRegime ? cmp.oldRegime : cmp.newRegime;
    final form = ref.watch(formRecommendationProvider);
    final sections = ref.watch(sectionStatusProvider);
    final gst = ref.watch(gstr3bResultProvider);
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    final firstName = draft.profile.name.trim().split(' ').first;
    final done = sections.where((s) => s.done).length;
    final bestLabel = cmp.recommended == TaxRegime.newRegime ? 'new regime' : 'old regime';
    final otherLabel = cmp.recommended == TaxRegime.newRegime ? 'Old regime' : 'New regime';

    return ListView(
      padding: EdgeInsets.fromLTRB(20, top + 16, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(draft.assessmentYear.label, style: text.bodySmall?.copyWith(color: t.textMuted)),
                  Text.rich(
                    TextSpan(
                      text: firstName.isEmpty ? 'Hello' : 'Hello, ',
                      children: [
                        if (firstName.isNotEmpty)
                          TextSpan(text: firstName, style: TextStyle(color: t.primary)),
                      ],
                    ),
                    style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Switch light or dark',
              onPressed: () => ref.read(settingsProvider.notifier).toggleTheme(),
              style: IconButton.styleFrom(
                side: BorderSide(color: t.primary, width: 1.5),
                foregroundColor: t.primary,
              ),
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                size: 20,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // Headline: what you pay versus what you earned.
        Surface(
          emphasis: true,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
          onTap: () => context.push(Routes.computation),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabelBar('Estimated tax · $bestLabel'),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SplitStat(
                  left: StatValue(
                    label: best.isRefund ? 'Refund due' : 'You pay',
                    value: formatInr(best.isRefund ? best.refundDue : best.totalTaxLiability),
                    color: best.isRefund ? t.positive : t.primary,
                    note: best.rebate87A > 0
                        ? 'after ${formatInr(best.rebate87A)} rebate'
                        : '${best.effectiveRatePercent}% effective',
                  ),
                  right: StatValue(
                    label: 'Total income',
                    value: formatInrCompact(best.totalIncome),
                    note: '${form.form.label.split(' ').first} · $done of ${sections.length} done',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Supporting card: the regime you are not using.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Surface(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
            onTap: () => context.push(Routes.computation),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LabelBar('$otherLabel would cost', secondary: true, dense: true),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: SplitStat(
                    large: false,
                    left: StatValue(label: otherLabel, value: formatInr(other.totalTaxLiability)),
                    right: StatValue(
                      label: cmp.savings == 0 ? 'Difference' : 'You save',
                      value: formatInr(cmp.savings),
                      color: cmp.savings == 0 ? null : t.positive,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 22),

        Text('Coming up', style: text.titleMedium),
        const SizedBox(height: 10),
        for (final d in _deadlines(draft.assessmentYear, DateTime.now()))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _DeadlineRow(item: d),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: StatTile(
                caption: 'GSTR-3B cash',
                icon: Icons.receipt_long_outlined,
                value: formatInr(gst.cashPayable.total),
                onTap: () => context.go(Routes.gst),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatTile(
                caption: 'Taxes paid',
                icon: Icons.verified_outlined,
                value: formatInr(best.tdsAndTcs + best.advanceTaxPaid + best.selfAssessmentTaxPaid),
                onTap: () => context.push(Routes.taxesPaid),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppButton(
          label: done == 0 ? 'Start your return' : 'Continue your return',
          expand: true,
          onPressed: () => context.go(Routes.itr),
        ),
      ],
    );
  }

  /// Upcoming statutory dates, nearest first. The ITR row switches to the
  /// belated-return window once the original due date has passed.
  static List<_Deadline> _deadlines(AssessmentYear ay, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final rp = ItrRulePack.forYear(ay);
    DateTime nextMonthly(int day) {
      final d = DateTime(today.year, today.month, day);
      return today.isAfter(d) ? DateTime(today.year, today.month + 1, day) : d;
    }

    final advance = [
      DateTime(today.year, 6, 15),
      DateTime(today.year, 9, 15),
      DateTime(today.year, 12, 15),
      DateTime(today.year + 1, 3, 15),
    ].firstWhere((d) => !d.isBefore(today));

    final items = <_Deadline>[
      if (!today.isAfter(rp.dueDateNonAudit))
        _Deadline('ITR filing', rp.dueDateNonAudit, today)
      else if (!today.isAfter(ay.belatedReturnLastDate))
        _Deadline('ITR, belated return', ay.belatedReturnLastDate, today, prefix: 'Last date '),
      _Deadline('GSTR-3B', nextMonthly(20), today),
      _Deadline('GSTR-1', nextMonthly(11), today),
      _Deadline('Advance tax instalment', advance, today),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return items;
  }
}

class _Deadline {
  _Deadline(this.title, this.date, DateTime today, {this.prefix = ''})
      : days = date.difference(today).inDays;
  final String title;
  final DateTime date;
  final int days;
  final String prefix;
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.item});
  final _Deadline item;

  static const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    final d = item.date;
    final tone = item.days <= 7
        ? TagTone.negative
        : item.days <= 30
            ? TagTone.warning
            : TagTone.neutral;
    final label = item.days == 0
        ? 'Today'
        : item.days == 1
            ? '1 day'
            : '${item.days} days';
    return Surface(
      radius: 14,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  '${item.prefix}${d.day} ${_months[d.month - 1]} ${d.year}',
                  style: text.bodySmall?.copyWith(color: t.textMuted),
                ),
              ],
            ),
          ),
          Tag(label: label, tone: tone),
        ],
      ),
    );
  }
}
