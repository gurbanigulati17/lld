import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';

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
    final form = ref.watch(formRecommendationProvider);
    final gst = ref.watch(gstr3bResultProvider);
    final t = context.glass;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final top = MediaQuery.paddingOf(context).top;
    final name = draft.profile.name.isEmpty ? 'there' : draft.profile.name.split(' ').first;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 120),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello, $name', style: text.headlineMedium),
                  Text('${draft.assessmentYear.label} · ${draft.assessmentYear.financialYear}',
                      style: text.bodyMedium?.copyWith(color: muted)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Toggle theme',
              onPressed: () => ref.read(settingsProvider.notifier).toggleTheme(),
              icon: const Icon(Icons.brightness_6_outlined),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GlassPanel(
          emphasis: true,
          onTap: () => context.push(Routes.computation),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Estimated tax', style: text.labelLarge?.copyWith(color: muted)),
                  ),
                  const SizedBox(width: 8),
                  GlassChip(
                    label: cmp.recommended == TaxRegime.newRegime ? 'New regime' : 'Old regime',
                    tone: GlassChipTone.accent,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(formatInr(best.totalTaxLiability), style: text.displayLarge?.copyWith(fontSize: 44)),
              const SizedBox(height: 4),
              Text(
                best.isRefund
                    ? 'Refund due ${formatInr(best.refundDue)}'
                    : 'Balance payable ${formatInr(best.netPayable)}',
                style: text.bodyMedium?.copyWith(
                  color: best.isRefund ? t.positive : null,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(label: 'Total income', value: formatInr(best.totalIncome)),
                  ),
                  Expanded(
                    child: _MiniStat(label: 'Effective rate', value: '${best.effectiveRatePercent}%'),
                  ),
                  Expanded(
                    child: _MiniStat(label: 'Form', value: form.form.label.split(' ').first),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GlassStat(
                caption: 'Regime savings',
                icon: Icons.auto_awesome,
                value: formatInr(cmp.savings),
                valueColor: t.positive,
                onTap: () => context.push(Routes.computation),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassStat(
                caption: 'GSTR-3B cash',
                icon: Icons.receipt_long,
                value: formatInr(gst.cashPayable.total),
                onTap: () => context.go(Routes.gst),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Deadlines', style: text.titleMedium),
        const SizedBox(height: 10),
        _Deadline(
          title: 'ITR filing (non-audit)',
          date: ItrRulePack.forYear(draft.assessmentYear).dueDateNonAudit,
          icon: Icons.event_available,
        ),
        _Deadline(title: 'GSTR-1 (monthly)', date: _nextMonthly(11), icon: Icons.receipt),
        _Deadline(title: 'GSTR-3B (monthly)', date: _nextMonthly(20), icon: Icons.receipt_long),
        _Deadline(title: 'Advance tax instalment', date: _nextAdvanceTax(), icon: Icons.savings_outlined),
        const SizedBox(height: 20),
        Text('Get started', style: text.titleMedium),
        const SizedBox(height: 10),
        GlassPanel(
          onTap: () => context.go(Routes.itr),
          child: Row(
            children: [
              Icon(Icons.description_outlined, color: t.accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File your income-tax return', style: text.titleSmall),
                    Text('Salary to capital gains to business, with every rupee explained.',
                        style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassPanel(
          onTap: () => context.go(Routes.gst),
          child: Row(
            children: [
              Icon(Icons.receipt_long_outlined, color: t.accentSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GST returns and reconciliation', style: text.titleSmall),
                    Text('GSTR-3B set-off, late fees, 2B matching, registration advice.',
                        style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ],
    );
  }

  static DateTime _nextMonthly(int day) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, day);
    return now.isAfter(thisMonth) ? DateTime(now.year, now.month + 1, day) : thisMonth;
  }

  static DateTime _nextAdvanceTax() {
    final now = DateTime.now();
    final candidates = [
      DateTime(now.year, 6, 15),
      DateTime(now.year, 9, 15),
      DateTime(now.year, 12, 15),
      DateTime(now.year + 1, 3, 15),
    ];
    return candidates.firstWhere((d) => d.isAfter(now));
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: text.labelSmall?.copyWith(color: muted)),
        FittedBox(child: Text(value, style: text.titleMedium)),
      ],
    );
  }
}

class _Deadline extends StatelessWidget {
  const _Deadline({required this.title, required this.date, required this.icon});
  final String title;
  final DateTime date;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    final days = date.difference(DateTime.now()).inDays;
    final tone = days < 0
        ? GlassChipTone.negative
        : days <= 7
            ? GlassChipTone.warning
            : GlassChipTone.neutral;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassPanel(
        radius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.titleSmall),
                  Text('${date.day} ${months[date.month - 1]} ${date.year}',
                      style: text.bodySmall?.copyWith(color: muted)),
                ],
              ),
            ),
            GlassChip(
              label: days < 0 ? 'Overdue' : days == 0 ? 'Today' : 'In $days d',
              tone: tone,
            ),
          ],
        ),
      ),
    );
  }
}
