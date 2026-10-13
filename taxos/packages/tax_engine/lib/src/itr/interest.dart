import '../common/assessment_year.dart';
import '../common/money.dart';

/// Number of "months or part of a month" from [start] (inclusive) to [end]
/// (inclusive), the way ss.234A/B/C count them.
int monthsOrPartThereof(DateTime start, DateTime end) {
  if (end.isBefore(start)) return 0;
  final whole = (end.year - start.year) * 12 + (end.month - start.month);
  return whole + (end.day >= start.day ? 1 : 0);
}

/// Inputs for the advance-tax interest computation. All amounts are rupees.
class InterestInput {
  const InterestInput({
    required this.assessmentYear,
    required this.totalTaxLiability,
    required this.tdsAndTcs,
    required this.advanceTaxPayments,
    required this.filingDate,
    required this.dueDate,
    required this.advanceTaxThreshold,
    this.isWhollyPresumptive = false,
  });

  final AssessmentYear assessmentYear;
  final int totalTaxLiability;
  final int tdsAndTcs;

  /// `(date, amount)` pairs in any order.
  final List<({DateTime date, int amount})> advanceTaxPayments;
  final DateTime filingDate;
  final DateTime dueDate;
  final int advanceTaxThreshold;

  /// s.44AD / s.44ADA taxpayers pay the whole advance tax by 15 March.
  final bool isWhollyPresumptive;

  int get assessedTax => nonNegative(totalTaxLiability - tdsAndTcs);
  int get totalAdvanceTax =>
      advanceTaxPayments.fold(0, (s, p) => s + p.amount);

  int paidOnOrBefore(DateTime date) => advanceTaxPayments
      .where((p) => !p.date.isAfter(date))
      .fold(0, (s, p) => s + p.amount);
}

class InterestResult {
  const InterestResult({
    required this.section234A,
    required this.section234B,
    required this.section234C,
    required this.notes,
  });

  final int section234A;
  final int section234B;
  final int section234C;
  final List<String> notes;

  int get total => section234A + section234B + section234C;
}

/// Computes interest under ss.234A, 234B and 234C of the Income-tax Act.
///
/// Simplifications (documented so the UI can show them):
/// * Self-assessment tax is assumed to be paid on the filing date.
/// * s.234C relief for capital gains / dividends arising after an instalment
///   date is not applied.
InterestResult computeInterest(InterestInput i) {
  final notes = <String>[];
  final assessed = i.assessedTax;
  final advance = i.totalAdvanceTax;

  // ---- s.234A: late filing ---------------------------------------------
  var s234A = 0;
  if (i.filingDate.isAfter(i.dueDate)) {
    final base = floorTo100(nonNegative(assessed - advance));
    final months = monthsOrPartThereof(
      i.dueDate.add(const Duration(days: 1)),
      i.filingDate,
    );
    s234A = pct(base, 1.0 * months);
    if (s234A > 0) {
      notes.add('Return filed $months month(s) after the due date; '
          's.234A interest at 1% per month on ${formatInr(base)}.');
    }
  }

  // ---- s.234B / s.234C only when net tax >= threshold --------------------
  if (assessed < i.advanceTaxThreshold) {
    if (assessed > 0) {
      notes.add('Net tax after TDS is below ${formatInr(i.advanceTaxThreshold)}; '
          'advance tax was not required, so no s.234B/234C interest.');
    }
    return InterestResult(
      section234A: s234A,
      section234B: 0,
      section234C: 0,
      notes: notes,
    );
  }

  // ---- s.234B: default in payment of advance tax -------------------------
  var s234B = 0;
  if (advance < pct(assessed, 90)) {
    final base = floorTo100(assessed - advance);
    final months =
        monthsOrPartThereof(i.assessmentYear.fyEndDate.add(const Duration(days: 1)), i.filingDate);
    s234B = pct(base, 1.0 * months);
    notes.add('Advance tax paid (${formatInr(advance)}) is below 90% of assessed '
        'tax (${formatInr(assessed)}); s.234B interest for $months month(s).');
  }

  // ---- s.234C: deferment of instalments ---------------------------------
  var s234C = 0;
  final fy = i.assessmentYear.fyStart;
  if (i.isWhollyPresumptive) {
    final due = DateTime(fy + 1, 3, 15);
    final paid = i.paidOnOrBefore(due);
    final shortfall = floorTo100(nonNegative(assessed - paid));
    if (shortfall > 0) {
      s234C = pct(shortfall, 1);
      notes.add('Presumptive taxpayer: 100% of advance tax was due by 15 March; '
          's.234C interest for 1 month on ${formatInr(shortfall)}.');
    }
  } else {
    final instalments = <({DateTime due, int pct, int tolerancePct, int months})>[
      (due: DateTime(fy, 6, 15), pct: 15, tolerancePct: 12, months: 3),
      (due: DateTime(fy, 9, 15), pct: 45, tolerancePct: 36, months: 3),
      (due: DateTime(fy, 12, 15), pct: 75, tolerancePct: 75, months: 3),
      (due: DateTime(fy + 1, 3, 15), pct: 100, tolerancePct: 100, months: 1),
    ];
    for (final inst in instalments) {
      final required = pct(assessed, inst.pct.toDouble());
      final tolerance = pct(assessed, inst.tolerancePct.toDouble());
      final paid = i.paidOnOrBefore(inst.due);
      if (paid >= tolerance) continue;
      final shortfall = floorTo100(nonNegative(required - paid));
      if (shortfall <= 0) continue;
      final interest = pct(shortfall, 1.0 * inst.months);
      s234C += interest;
      notes.add('Instalment due ${_d(inst.due)}: paid ${formatInr(paid)} of '
          '${formatInr(required)} (${inst.pct}%); s.234C interest '
          '${formatInr(interest)}.');
    }
  }

  return InterestResult(
    section234A: s234A,
    section234B: s234B,
    section234C: s234C,
    notes: notes,
  );
}

String _d(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
