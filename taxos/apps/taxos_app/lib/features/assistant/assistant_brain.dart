import 'package:tax_engine/tax_engine.dart';

/// Intent-matched, template-based answers grounded in the engine output.
///
/// Keep this deterministic: it is what the app can promise is correct. The
/// server-side language-model layer wraps these facts for tone and follow-up
/// questions, and is told to never produce a number not present here.
class AssistantBrain {
  AssistantBrain({
    required this.input,
    required this.comparison,
    required this.form,
  });

  final ItrInput input;
  final RegimeComparison comparison;
  final FormRecommendation form;

  String answer(String question) {
    final q = question.toLowerCase();
    final best = comparison.best;
    final rp = ItrRulePack.forYear(input.assessmentYear);

    if (q.contains('regime')) {
      return const ExplanationBuilder().explainComparison(comparison).join(' ');
    }
    if (q.contains('form') || q.contains('itr-') || q.contains('sahaj') || q.contains('sugam')) {
      return '${form.form.label}. ${form.reasons.join(' ')}';
    }
    if (q.contains('hra')) {
      final s = input.salary;
      if (s == null || s.hraReceived == 0) {
        return 'You have not entered HRA. Add HRA received and rent paid in the salary section and I will compute the exemption under s.10(13A).';
      }
      final old = comparison.oldRegime.lineItems.where((l) => l.code == 'SAL.HRA_EXEMPT');
      final amt = old.isEmpty ? 0 : -old.first.amount;
      return 'Your HRA exemption is ${formatInr(amt)} in the old regime: the least of HRA received (${formatInr(s.hraReceived)}), rent paid less 10% of basic and DA, and ${s.isMetroCity ? 50 : 40}% of basic and DA. The new regime does not allow it.';
    }
    if (q.contains('deadline') || q.contains('due date') || q.contains('when')) {
      final d = rp.dueDateNonAudit;
      return 'For ${input.assessmentYear.label} the non-audit due date is ${d.day}/${d.month}/${d.year}. Filing later attracts s.234A interest at 1% per month on unpaid tax and a late fee under s.234F.';
    }
    if (q.contains('interest') || q.contains('234')) {
      if (best.totalInterest == 0) return 'No interest is due on the current draft.';
      final notes = best.warnings.where((w) => w.contains('234')).join(' ');
      return 'Interest totals ${formatInr(best.totalInterest)}: s.234A ${formatInr(best.interest234A)}, s.234B ${formatInr(best.interest234B)}, s.234C ${formatInr(best.interest234C)}. $notes';
    }
    if (q.contains('refund')) {
      return best.isRefund
          ? 'Yes, a refund of ${formatInr(best.refundDue)} is due because taxes paid exceed the liability of ${formatInr(best.totalTaxLiability)}.'
          : 'No refund. You still owe ${formatInr(best.netPayable)}.';
    }
    if (q.contains('gst')) {
      return 'Open the GST tab for GSTR-3B: enter outward supplies and ITC from GSTR-2B and I apply the Rule 88A set-off order, late fee under s.47 and 18% interest under s.50 on the cash part.';
    }
    if (q.contains('80c') || q.contains('deduction') || q.contains('save')) {
      final room = rp.section80CCap - input.deductions.section80C;
      return 'Old-regime deductions allowed: ${formatInr(comparison.oldRegime.chapterVIADeductions)}. '
          '${room > 0 ? 'You have ${formatInr(room)} of 80C room left (PPF, ELSS, EPF, tuition, home-loan principal), plus up to ₹50,000 under 80CCD(1B) for NPS.' : '80C is fully used.'} '
          'Remember the new regime ignores these; it is currently ${comparison.recommended == TaxRegime.newRegime ? 'cheaper' : 'costlier'} for you.';
    }
    if (q.contains('why') || q.contains('how much') || q.contains('tax')) {
      return const ExplanationBuilder().explain(best).join(' ');
    }
    return 'I can explain your computation, compare regimes, pick the ITR form, work out HRA, deadlines, interest and GST set-off. Try one of the suggestions below.';
  }
}
