import '../common/money.dart';
import 'models.dart';
import 'result.dart';

/// Turns a computation into plain-English sentences.
///
/// This is deterministic and template based so the numbers always match the
/// engine. A language model may rephrase the output for tone, but it never
/// produces a number of its own.
class ExplanationBuilder {
  const ExplanationBuilder();

  List<String> explain(ItrComputation c) {
    final out = <String>[];
    final regime = c.regime == TaxRegime.newRegime ? 'new' : 'old';
    out.add('Under the $regime regime your total income is '
        '${formatInr(c.totalIncome)}.');
    if (c.incomeFromSalary > 0) {
      out.add('Salary contributes ${formatInr(c.incomeFromSalary)} after the '
          'standard deduction and exemptions.');
    }
    if (c.incomeFromHouseProperty != 0) {
      out.add(c.incomeFromHouseProperty < 0
          ? 'House property shows a loss of '
              '${formatInr(-c.incomeFromHouseProperty)}, set off against other income.'
          : 'House property adds ${formatInr(c.incomeFromHouseProperty)}.');
    }
    if (c.incomeFromCapitalGains != 0) {
      out.add('Capital gains add ${formatInr(c.incomeFromCapitalGains)}, of which '
          '${formatInr(c.specialRateIncome)} is taxed at special rates.');
    }
    if (c.incomeFromBusiness != 0) {
      out.add('Business or profession contributes ${formatInr(c.incomeFromBusiness)}.');
    }
    if (c.incomeFromOtherSources > 0) {
      out.add('Other sources such as interest and dividends add '
          '${formatInr(c.incomeFromOtherSources)}.');
    }
    if (c.chapterVIADeductions > 0) {
      out.add('Chapter VI-A deductions reduce income by '
          '${formatInr(c.chapterVIADeductions)}.');
    }
    out.add('Tax at slab rates is ${formatInr(c.taxOnNormalIncome)}'
        '${c.taxOnSpecialIncome > 0 ? ' plus ${formatInr(c.taxOnSpecialIncome)} at special rates' : ''}.');
    if (c.rebate87A > 0) {
      out.add('A section 87A rebate of ${formatInr(c.rebate87A)} applies.');
    }
    if (c.surcharge > 0) {
      out.add('Surcharge adds ${formatInr(c.surcharge)}'
          '${c.marginalRelief > 0 ? ', reduced by marginal relief of ${formatInr(c.marginalRelief)}' : ''}.');
    }
    out.add('With ${formatInr(c.cess)} cess the total liability is '
        '${formatInr(c.totalTaxLiability)}, an effective rate of '
        '${c.effectiveRatePercent}%.');
    final credits = c.tdsAndTcs + c.advanceTaxPaid + c.selfAssessmentTaxPaid;
    if (credits > 0) {
      out.add('Taxes already paid total ${formatInr(credits)}.');
    }
    if (c.totalInterest > 0) {
      out.add('Interest under sections 234A/B/C adds ${formatInr(c.totalInterest)}.');
    }
    if (c.lateFee234F > 0) {
      out.add('Filing after the due date adds a ${formatInr(c.lateFee234F)} late fee under section 234F.');
    }
    out.add(c.isRefund
        ? 'You are due a refund of ${formatInr(c.refundDue)}.'
        : 'Balance tax payable is ${formatInr(c.netPayable)}.');
    return out;
  }

  List<String> explainComparison(RegimeComparison cmp) {
    final rec = cmp.recommended == TaxRegime.newRegime ? 'new' : 'old';
    return [
      'Old regime liability: ${formatInr(cmp.oldRegime.totalTaxLiability)}.',
      'New regime liability: ${formatInr(cmp.newRegime.totalTaxLiability)}.',
      cmp.savings == 0
          ? 'Both regimes cost the same; the new regime is recommended as it '
              'needs no opt-in form.'
          : 'The $rec regime saves ${formatInr(cmp.savings)}.',
    ];
  }
}
