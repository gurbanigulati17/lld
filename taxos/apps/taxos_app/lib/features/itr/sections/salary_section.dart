import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class SalarySection extends ConsumerWidget {
  const SalarySection({super.key});

  void _set(WidgetRef ref, SalaryIncome Function(SalaryIncome) fn) {
    ref.read(itrDraftProvider.notifier).update(
          (d) => d.copyWith(salary: fn(d.salary ?? const SalaryIncome())),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(itrDraftProvider.select((d) => d.salary)) ??
        const SalaryIncome();
    return SectionScaffold(
      title: 'Salary',
      subtitle:
          'Copy from Form 16 Part B. HRA and allowances only matter in the old regime; the engine applies the right standard deduction for each.',
      actions: [
        IconButton(
          tooltip: 'Remove salary',
          onPressed: () => ref
              .read(itrDraftProvider.notifier)
              .update((d) => d.copyWith(clearSalary: true)),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
      children: [
        AmountField(
          label: 'Basic salary',
          value: s.basic,
          onChanged: (v) => _set(ref, (s) => _copy(s, basic: v)),
        ),
        AmountField(
          label: 'Dearness allowance',
          value: s.dearnessAllowance,
          onChanged: (v) => _set(ref, (s) => _copy(s, dearnessAllowance: v)),
        ),
        AmountField(
          label: 'HRA received',
          value: s.hraReceived,
          onChanged: (v) => _set(ref, (s) => _copy(s, hraReceived: v)),
        ),
        AmountField(
          label: 'Other taxable components',
          helper: 'Special allowance, bonus, taxable LTA',
          value: s.otherTaxableComponents,
          onChanged: (v) =>
              _set(ref, (s) => _copy(s, otherTaxableComponents: v)),
        ),
        AmountField(
          label: 'Perquisites',
          value: s.perquisites,
          onChanged: (v) => _set(ref, (s) => _copy(s, perquisites: v)),
        ),
        AmountField(
          label: 'Exempt allowances (old regime)',
          helper: 's.10(14): LTA claimed, children education, uniform',
          value: s.exemptAllowances,
          onChanged: (v) => _set(ref, (s) => _copy(s, exemptAllowances: v)),
        ),
        const SectionHeader('Rent (for HRA exemption)'),
        AmountField(
          label: 'Annual rent paid',
          value: s.rentPaid,
          onChanged: (v) => _set(ref, (s) => _copy(s, rentPaid: v)),
        ),
        SwitchTile(
          label: 'Metro city',
          helper:
              'Delhi, Mumbai, Kolkata, Chennai: 50% of basic instead of 40%',
          value: s.isMetroCity,
          onChanged: (v) => _set(ref, (s) => _copy(s, isMetroCity: v)),
        ),
        const SectionHeader('Employer deductions'),
        AmountField(
          label: 'Professional tax',
          value: s.professionalTax,
          onChanged: (v) => _set(ref, (s) => _copy(s, professionalTax: v)),
        ),
        AmountField(
          label: 'Employer NPS contribution',
          helper: 's.80CCD(2): allowed in both regimes',
          value: s.employerNpsContribution,
          onChanged: (v) =>
              _set(ref, (s) => _copy(s, employerNpsContribution: v)),
        ),
        AmountField(
          label: 'TDS on salary',
          helper: 'Form 16 Part A',
          value: s.tdsOnSalary,
          onChanged: (v) => _set(ref, (s) => _copy(s, tdsOnSalary: v)),
        ),
      ],
    );
  }

  static SalaryIncome _copy(
    SalaryIncome s, {
    int? basic,
    int? dearnessAllowance,
    int? hraReceived,
    int? otherTaxableComponents,
    int? exemptAllowances,
    int? perquisites,
    int? rentPaid,
    bool? isMetroCity,
    int? professionalTax,
    int? employerNpsContribution,
    int? tdsOnSalary,
  }) =>
      SalaryIncome(
        basic: basic ?? s.basic,
        dearnessAllowance: dearnessAllowance ?? s.dearnessAllowance,
        hraReceived: hraReceived ?? s.hraReceived,
        otherTaxableComponents:
            otherTaxableComponents ?? s.otherTaxableComponents,
        exemptAllowances: exemptAllowances ?? s.exemptAllowances,
        perquisites: perquisites ?? s.perquisites,
        rentPaid: rentPaid ?? s.rentPaid,
        isMetroCity: isMetroCity ?? s.isMetroCity,
        professionalTax: professionalTax ?? s.professionalTax,
        employerNpsContribution:
            employerNpsContribution ?? s.employerNpsContribution,
        tdsOnSalary: tdsOnSalary ?? s.tdsOnSalary,
      );
}
