import '../common/assessment_year.dart';
import 'models.dart';

/// One progressive slab: income above [from] up to [to] (null = no cap) is
/// taxed at [ratePercent].
class Slab {
  const Slab(this.from, this.to, this.ratePercent);
  final int from;
  final int? to;
  final double ratePercent;
}

/// Surcharge band: total income above [threshold] attracts [ratePercent].
class SurchargeBand {
  const SurchargeBand(this.threshold, this.ratePercent);
  final int threshold;
  final double ratePercent;
}

/// Parameters of the s.87A rebate.
class RebateRule {
  const RebateRule({
    required this.incomeThreshold,
    required this.maxRebate,
    required this.marginalRelief,
    required this.excludesSpecialRateIncome,
  });

  final int incomeThreshold;
  final int maxRebate;

  /// Whether tax above the threshold is capped at the excess income.
  final bool marginalRelief;

  /// Whether the rebate is computed only on slab-rate tax (true for the new
  /// regime from AY 2026-27 under the Finance Act 2025).
  final bool excludesSpecialRateIncome;
}

/// Everything that is a number in the Act, keyed by assessment year.
///
/// Changing a year's rules must never change another year's output, so each
/// year is a separate immutable instance.
class ItrRulePack {
  const ItrRulePack({
    required this.assessmentYear,
    required this.oldRegimeSlabs,
    required this.newRegimeSlabs,
    required this.oldRegimeRebate,
    required this.newRegimeRebate,
    required this.oldRegimeSurcharge,
    required this.newRegimeSurcharge,
    required this.specialIncomeSurchargeCapPercent,
    required this.cessPercent,
    required this.standardDeductionOld,
    required this.standardDeductionNew,
    required this.familyPensionDeductionOld,
    required this.familyPensionDeductionNew,
    required this.selfOccupiedInterestCap,
    required this.housePropertyLossSetOffCap,
    required this.section80CCap,
    required this.section80CCD1BCap,
    required this.section80DSelfCap,
    required this.section80DSelfSeniorCap,
    required this.section80DParentsCap,
    required this.section80DParentsSeniorCap,
    required this.section80TTACap,
    required this.section80TTBCap,
    required this.section80EEACap,
    required this.stcg111ARatePercent,
    required this.ltcg112ARatePercent,
    required this.ltcg112AExemption,
    required this.ltcgOtherRatePercent,
    required this.presumptive44ADRatePercent,
    required this.presumptive44ADDigitalRatePercent,
    required this.presumptive44ADTurnoverCap,
    required this.presumptive44ADARatePercent,
    required this.presumptive44ADAReceiptsCap,
    required this.itr1IncomeCap,
    required this.advanceTaxThreshold,
    required this.dueDateNonAudit,
    required this.employerNpsCapPercentOld,
    required this.employerNpsCapPercentNew,
  });

  final AssessmentYear assessmentYear;
  final Map<AgeCategory, List<Slab>> oldRegimeSlabs;
  final List<Slab> newRegimeSlabs;
  final RebateRule oldRegimeRebate;
  final RebateRule newRegimeRebate;
  final List<SurchargeBand> oldRegimeSurcharge;
  final List<SurchargeBand> newRegimeSurcharge;

  /// Surcharge on tax attributable to s.111A / s.112A / dividend income is
  /// capped at this rate.
  final double specialIncomeSurchargeCapPercent;
  final double cessPercent;
  final int standardDeductionOld;
  final int standardDeductionNew;
  final int familyPensionDeductionOld;
  final int familyPensionDeductionNew;
  final int selfOccupiedInterestCap;
  final int housePropertyLossSetOffCap;
  final int section80CCap;
  final int section80CCD1BCap;
  final int section80DSelfCap;
  final int section80DSelfSeniorCap;
  final int section80DParentsCap;
  final int section80DParentsSeniorCap;
  final int section80TTACap;
  final int section80TTBCap;
  final int section80EEACap;
  final double stcg111ARatePercent;
  final double ltcg112ARatePercent;
  final int ltcg112AExemption;
  final double ltcgOtherRatePercent;
  final double presumptive44ADRatePercent;
  final double presumptive44ADDigitalRatePercent;
  final int presumptive44ADTurnoverCap;
  final double presumptive44ADARatePercent;
  final int presumptive44ADAReceiptsCap;
  final int itr1IncomeCap;

  /// Below this net tax (after TDS), no advance-tax interest applies.
  final int advanceTaxThreshold;
  final DateTime dueDateNonAudit;
  final double employerNpsCapPercentOld;
  final double employerNpsCapPercentNew;

  List<Slab> slabsFor(TaxRegime regime, AgeCategory age) =>
      regime == TaxRegime.newRegime
          ? newRegimeSlabs
          : oldRegimeSlabs[age] ?? oldRegimeSlabs[AgeCategory.below60]!;

  RebateRule rebateFor(TaxRegime regime) =>
      regime == TaxRegime.newRegime ? newRegimeRebate : oldRegimeRebate;

  List<SurchargeBand> surchargeFor(TaxRegime regime) =>
      regime == TaxRegime.newRegime ? newRegimeSurcharge : oldRegimeSurcharge;

  int standardDeductionFor(TaxRegime regime) => regime == TaxRegime.newRegime
      ? standardDeductionNew
      : standardDeductionOld;

  int familyPensionDeductionFor(TaxRegime regime) =>
      regime == TaxRegime.newRegime
          ? familyPensionDeductionNew
          : familyPensionDeductionOld;

  double employerNpsCapPercentFor(TaxRegime regime) =>
      regime == TaxRegime.newRegime
          ? employerNpsCapPercentNew
          : employerNpsCapPercentOld;

  static ItrRulePack forYear(AssessmentYear ay) => switch (ay) {
        AssessmentYear.ay2025_26 => _ay2025_26,
        AssessmentYear.ay2026_27 => _ay2026_27,
      };

  static const _oldSlabsCommon = <Slab>[
    Slab(250000, 500000, 5),
    Slab(500000, 1000000, 20),
    Slab(1000000, null, 30),
  ];

  static const _oldSlabs = <AgeCategory, List<Slab>>{
    AgeCategory.below60: _oldSlabsCommon,
    AgeCategory.senior: [
      Slab(300000, 500000, 5),
      Slab(500000, 1000000, 20),
      Slab(1000000, null, 30),
    ],
    AgeCategory.superSenior: [
      Slab(500000, 1000000, 20),
      Slab(1000000, null, 30),
    ],
  };

  static const _oldSurcharge = <SurchargeBand>[
    SurchargeBand(5000000, 10),
    SurchargeBand(10000000, 15),
    SurchargeBand(20000000, 25),
    SurchargeBand(50000000, 37),
  ];

  static const _newSurcharge = <SurchargeBand>[
    SurchargeBand(5000000, 10),
    SurchargeBand(10000000, 15),
    SurchargeBand(20000000, 25),
  ];

  /// FY 2024-25. New-regime slabs as amended by the Finance (No. 2) Act 2024.
  static final _ay2025_26 = ItrRulePack(
    assessmentYear: AssessmentYear.ay2025_26,
    oldRegimeSlabs: _oldSlabs,
    newRegimeSlabs: const [
      Slab(300000, 700000, 5),
      Slab(700000, 1000000, 10),
      Slab(1000000, 1200000, 15),
      Slab(1200000, 1500000, 20),
      Slab(1500000, null, 30),
    ],
    oldRegimeRebate: const RebateRule(
      incomeThreshold: 500000,
      maxRebate: 12500,
      marginalRelief: false,
      excludesSpecialRateIncome: false,
    ),
    newRegimeRebate: const RebateRule(
      incomeThreshold: 700000,
      maxRebate: 25000,
      marginalRelief: true,
      excludesSpecialRateIncome: false,
    ),
    oldRegimeSurcharge: _oldSurcharge,
    newRegimeSurcharge: _newSurcharge,
    specialIncomeSurchargeCapPercent: 15,
    cessPercent: 4,
    standardDeductionOld: 50000,
    standardDeductionNew: 75000,
    familyPensionDeductionOld: 15000,
    familyPensionDeductionNew: 25000,
    selfOccupiedInterestCap: 200000,
    housePropertyLossSetOffCap: 200000,
    section80CCap: 150000,
    section80CCD1BCap: 50000,
    section80DSelfCap: 25000,
    section80DSelfSeniorCap: 50000,
    section80DParentsCap: 25000,
    section80DParentsSeniorCap: 50000,
    section80TTACap: 10000,
    section80TTBCap: 50000,
    section80EEACap: 150000,
    stcg111ARatePercent: 20,
    ltcg112ARatePercent: 12.5,
    ltcg112AExemption: 125000,
    ltcgOtherRatePercent: 12.5,
    presumptive44ADRatePercent: 8,
    presumptive44ADDigitalRatePercent: 6,
    presumptive44ADTurnoverCap: 30000000,
    presumptive44ADARatePercent: 50,
    presumptive44ADAReceiptsCap: 7500000,
    itr1IncomeCap: 5000000,
    advanceTaxThreshold: 10000,
    // Extended by CBDT from 31 July 2025 to 15 September 2025.
    dueDateNonAudit: DateTime(2025, 9, 15),
    employerNpsCapPercentOld: 10,
    employerNpsCapPercentNew: 14,
  );

  /// FY 2025-26. New-regime slabs and ₹12L rebate per the Finance Act 2025.
  static final _ay2026_27 = ItrRulePack(
    assessmentYear: AssessmentYear.ay2026_27,
    oldRegimeSlabs: _oldSlabs,
    newRegimeSlabs: const [
      Slab(400000, 800000, 5),
      Slab(800000, 1200000, 10),
      Slab(1200000, 1600000, 15),
      Slab(1600000, 2000000, 20),
      Slab(2000000, 2400000, 25),
      Slab(2400000, null, 30),
    ],
    oldRegimeRebate: const RebateRule(
      incomeThreshold: 500000,
      maxRebate: 12500,
      marginalRelief: false,
      excludesSpecialRateIncome: false,
    ),
    newRegimeRebate: const RebateRule(
      incomeThreshold: 1200000,
      maxRebate: 60000,
      marginalRelief: true,
      excludesSpecialRateIncome: true,
    ),
    oldRegimeSurcharge: _oldSurcharge,
    newRegimeSurcharge: _newSurcharge,
    specialIncomeSurchargeCapPercent: 15,
    cessPercent: 4,
    standardDeductionOld: 50000,
    standardDeductionNew: 75000,
    familyPensionDeductionOld: 15000,
    familyPensionDeductionNew: 25000,
    selfOccupiedInterestCap: 200000,
    housePropertyLossSetOffCap: 200000,
    section80CCap: 150000,
    section80CCD1BCap: 50000,
    section80DSelfCap: 25000,
    section80DSelfSeniorCap: 50000,
    section80DParentsCap: 25000,
    section80DParentsSeniorCap: 50000,
    section80TTACap: 10000,
    section80TTBCap: 50000,
    section80EEACap: 150000,
    stcg111ARatePercent: 20,
    ltcg112ARatePercent: 12.5,
    ltcg112AExemption: 125000,
    ltcgOtherRatePercent: 12.5,
    presumptive44ADRatePercent: 8,
    presumptive44ADDigitalRatePercent: 6,
    presumptive44ADTurnoverCap: 30000000,
    presumptive44ADARatePercent: 50,
    presumptive44ADAReceiptsCap: 7500000,
    itr1IncomeCap: 5000000,
    advanceTaxThreshold: 10000,
    dueDateNonAudit: DateTime(2026, 7, 31),
    employerNpsCapPercentOld: 10,
    employerNpsCapPercentNew: 14,
  );
}
