import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../app/router.dart';
import 'itr_state.dart';

/// The ITR wizard overview: sections as glass cards with status, live
/// regime toggle, and the path to the full computation and filing.
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

  static const _icons = {
    'profile': Icons.person_outline,
    'salary': Icons.work_outline,
    'houseProperty': Icons.house_outlined,
    'capitalGains': Icons.show_chart,
    'business': Icons.storefront_outlined,
    'otherSources': Icons.account_balance_outlined,
    'deductions': Icons.savings_outlined,
    'taxesPaid': Icons.verified_outlined,
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
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final top = MediaQuery.paddingOf(context).top;
    final done = sections.where((s) => s.done).length;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(child: Text('Income tax return', style: text.headlineMedium)),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz),
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
                  CheckedPopupMenuItem(
                    value: 'ay:${ay.name}',
                    checked: ay == draft.assessmentYear,
                    child: Text(ay.label),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'reset', child: Text('Start over')),
              ],
            ),
          ],
        ),
        Text('${draft.assessmentYear.label} · $done of ${sections.length} sections',
            style: text.bodyMedium?.copyWith(color: muted)),
        const SizedBox(height: 16),
        Segmented<TaxRegime?>(
          values: const [null, TaxRegime.oldRegime, TaxRegime.newRegime],
          labels: const ['Best', 'Old', 'New'],
          selected: selected,
          onChanged: (v) => ref.read(selectedRegimeProvider.notifier).state = v,
        ),
        const SizedBox(height: 12),
        Surface(
          emphasis: true,
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
          onTap: () => context.push(Routes.computation),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LabelBar('${active.regime == TaxRegime.newRegime ? 'New' : 'Old'} regime · ${form.form.label}'),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: SplitStat(
                  left: StatValue(
                    label: 'Liability',
                    value: formatInr(active.totalTaxLiability),
                    color: t.primary,
                  ),
                  right: StatValue(
                    label: 'Best regime saves',
                    value: formatInr(cmp.savings),
                    color: cmp.savings == 0 ? null : t.positive,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final s in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              radius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              onTap: () => context.push(_routes[s.id]!),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (s.done ? t.positive : t.primary).withValues(alpha: 0.14),
                    ),
                    child: Icon(
                      s.done ? Icons.check : _icons[s.id],
                      size: 20,
                      color: s.done ? t.positive : t.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.title, style: text.titleSmall),
                        Text(s.summary, style: text.bodySmall?.copyWith(color: muted), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Review and file',
          icon: Icons.send_outlined,
          expand: true,
          onPressed: () => context.push(Routes.filing),
        ),
      ],
    );
  }
}
