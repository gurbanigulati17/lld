import 'models.dart';
import 'rule_pack.dart';

enum ItrForm { itr1, itr2, itr3, itr4 }

extension ItrFormLabel on ItrForm {
  String get label => switch (this) {
        ItrForm.itr1 => 'ITR-1 (Sahaj)',
        ItrForm.itr2 => 'ITR-2',
        ItrForm.itr3 => 'ITR-3',
        ItrForm.itr4 => 'ITR-4 (Sugam)',
      };
}

class FormRecommendation {
  const FormRecommendation({required this.form, required this.reasons});
  final ItrForm form;

  /// Human-readable reasons, most decisive first.
  final List<String> reasons;

  Map<String, Object?> toJson() => {'form': form.name, 'reasons': reasons};
}

/// Picks the simplest form the taxpayer is eligible for.
///
/// The decision order mirrors the Income Tax Department's eligibility
/// notes: anything with books-of-account business income is ITR-3; a
/// presumptive-only business is ITR-4; capital gains beyond the small
/// s.112A carve-out, more than one house property, foreign assets, income
/// above ₹50L, directorships or unlisted shares push to ITR-2; everything
/// else is ITR-1.
FormRecommendation selectForm(ItrInput input, {required int totalIncome}) {
  final rp = ItrRulePack.forYear(input.assessmentYear);
  final reasons = <String>[];
  final business = input.business;

  if (business != null && business.kind == BusinessIncomeKind.regular) {
    reasons.add('Business or professional income with books of account.');
    return FormRecommendation(form: ItrForm.itr3, reasons: reasons);
  }

  // Facts that rule out the two simple forms (ITR-1 / ITR-4).
  final nonResident = !input.profile.isResident;
  if (nonResident) reasons.add('Non-resident taxpayers cannot use ITR-1/ITR-4.');
  if (input.hasForeignAssetsOrIncome) {
    reasons.add('Foreign assets or income require Schedule FA (ITR-2/3).');
  }
  if (input.isDirectorOrHoldsUnlistedShares) {
    reasons.add('Directors and holders of unlisted shares cannot use ITR-1/4.');
  }
  if (totalIncome > rp.itr1IncomeCap) {
    reasons.add('Total income exceeds ₹50 lakh.');
  }
  if (input.houseProperties.length > 1) {
    reasons.add('More than one house property.');
  }
  if (input.agriculturalIncome > 5000) {
    reasons.add('Agricultural income above ₹5,000.');
  }
  if (input.broughtForwardLosses > 0) {
    reasons.add('Brought-forward losses to set off.');
  }
  final hpLoss = input.houseProperties.any((h) =>
      h.type == HousePropertyType.letOut &&
      (h.annualRent - h.municipalTaxesPaid) * 0.7 - h.interestOnLoan < 0);
  if (hpLoss) reasons.add('Loss from a let-out house property.');

  // Capital gains: ITR-1/4 allow only s.112A LTCG up to the exemption, no
  // losses, from AY 2025-26 onward.
  final cg = input.capitalGains;
  if (cg.isNotEmpty) {
    final only112A = cg.every((g) => g.type == CapitalGainType.ltcg112A);
    final total112A = cg.fold(0, (s, g) => s + g.gain);
    final anyLoss = cg.any((g) => g.gain < 0);
    if (!only112A || anyLoss || total112A > rp.ltcg112AExemption) {
      reasons.add('Capital gains beyond the small s.112A carve-out.');
    }
  }

  final blockedFromSimple = reasons.isNotEmpty;

  if (business != null) {
    // Presumptive business only.
    if (blockedFromSimple) {
      reasons.insert(0, 'Presumptive business income plus a fact that rules '
          'out ITR-4, so ITR-3 applies.');
      return FormRecommendation(form: ItrForm.itr3, reasons: reasons);
    }
    reasons.add('Presumptive income under s.44AD/s.44ADA with no other '
        'disqualifying facts.');
    return FormRecommendation(form: ItrForm.itr4, reasons: reasons);
  }

  if (blockedFromSimple) {
    return FormRecommendation(form: ItrForm.itr2, reasons: reasons);
  }
  reasons.add('Resident individual with salary, one house property and other '
      'sources, total income up to ₹50 lakh.');
  return FormRecommendation(form: ItrForm.itr1, reasons: reasons);
}
