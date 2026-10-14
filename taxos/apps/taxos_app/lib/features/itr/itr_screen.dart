import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import 'itr_state.dart';

/// "Your income tax return": regime tabs, the figure, and the sections.
class ItrScreen extends ConsumerWidget {
  const ItrScreen({super.key});

  static const _routes = {
    'profile': Routes.profile,
    'salary': Routes.salary,
    'houseProperty': Routes.houseProperty,
    'capitalGains': Routes.capitalGains,
    'business': Routes.business,
    'otherSources': Routes.otherSources,
    'deductions': Routes.deductions,
    'taxesPaid': Routes.taxesPaid,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionStatusProvider);
    final cmp = ref.watch(comparisonProvider);
    final selected = ref.watch(selectedRegimeProvider);
    final active = ref.watch(activeComputationProvider);
    final form = ref.watch(formRecommendationProvider);
    final draft = ref.watch(itrDraftProvider);
    final t = context.ui;
    final top = MediaQuery.paddingOf(context).top;
    final done = sections.where((s) => s.done).length;
    final regimeName = active.regime == TaxRegime.newRegime ? 'new regime' : 'old regime';

    return ListView(
      padding: EdgeInsets.fromLTRB(Space.gutter, top + 16, Space.gutter, Space.section),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: PageHeading(
                'Your income tax return',
                subtitle: '$done of ${sections.length} sections done · ${form.form.label.split(' ').first}',
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: Icon(Icons.more_horiz, color: t.textMuted),
              onSelected: (v) {
                if (v == 'reset') ref.read(itrDraftProvider.notifier).reset();
                if (v.startsWith('ay:')) {
                  ref.read(itrDraftProvider.notifier).update(
                        (d) => d.copyWith(assessmentYear: AssessmentYear.parse(v.substring(3))),
                      );
                }
              },
              itemBuilder: (_) => [
                for (final ay in AssessmentYear.values)
                  CheckedPopupMenuItem(value: 'ay:${ay.name}', checked: ay == draft.assessmentYear, child: Text(ay.label)),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'reset', child: Text('Start over')),
              ],
            ),
          ],
        ),
        const SizedBox(height: Space.gutter),
        Surface(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Segmented<TaxRegime?>(
                values: const [null, TaxRegime.oldRegime, TaxRegime.newRegime],
                labels: const ['Best', 'Old', 'New'],
                selected: selected,
                onChanged: (v) => ref.read(selectedRegimeProvider.notifier).state = v,
              ),
              InkWell(
                onTap: () => context.push(Routes.computation),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(Space.gutter, 18, Space.gutter, Space.gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LabelBar(active.isRefund ? 'Refund due to you' : 'Tax you will pay'),
                      const SizedBox(height: 4),
                      Text(
                        formatInr(active.isRefund ? active.refundDue : active.totalTaxLiability),
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: t.text, fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                      Text(
                        cmp.savings == 0
                            ? '$regimeName, as of today'
                            : '$regimeName, as of today · ${active.regime == cmp.recommended ? 'saves ${formatInr(cmp.savings)}' : 'costs ${formatInr(cmp.savings)} more'}',
                        style: TextStyle(fontSize: 14, color: t.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Sections'),
        Surface(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) Divider(height: 1, color: t.hairline),
                _SectionRow(
                  title: sections[i].title,
                  summary: sections[i].summary,
                  done: sections[i].done,
                  onTap: () => context.push(_routes[sections[i].id]!),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Space.section),
        AppButton(label: 'Review and file', onPressed: () => context.push(Routes.filing)),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.summary, required this.done, required this.onTap});
  final String title;
  final String summary;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Semantics(
              label: done ? 'Done' : 'Not started',
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? t.primary : Colors.transparent,
                  border: done ? null : Border.all(color: t.border, width: 1.5),
                ),
                child: done ? Icon(Icons.check, size: 15, color: t.onPrimary) : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.text)),
                  Text(summary, style: TextStyle(fontSize: 14, color: t.textMuted), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.textMuted),
          ],
        ),
      ),
    );
  }
}
