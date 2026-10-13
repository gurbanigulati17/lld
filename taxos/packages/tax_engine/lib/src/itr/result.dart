import '../common/line_item.dart';
import 'models.dart';

/// The output of one regime computation. Every number has a matching
/// [LineItem] in [lineItems] carrying its provenance.
class ItrComputation {
  const ItrComputation({
    required this.regime,
    required this.incomeFromSalary,
    required this.incomeFromHouseProperty,
    required this.incomeFromCapitalGains,
    required this.incomeFromBusiness,
    required this.incomeFromOtherSources,
    required this.grossTotalIncome,
    required this.chapterVIADeductions,
    required this.totalIncome,
    required this.normalRateIncome,
    required this.specialRateIncome,
    required this.taxOnNormalIncome,
    required this.taxOnSpecialIncome,
    required this.rebate87A,
    required this.taxAfterRebate,
    required this.surcharge,
    required this.marginalRelief,
    required this.cess,
    required this.totalTaxLiability,
    required this.tdsAndTcs,
    required this.advanceTaxPaid,
    required this.selfAssessmentTaxPaid,
    required this.interest234A,
    required this.interest234B,
    required this.interest234C,
    required this.netPayable,
    required this.effectiveRatePercent,
    required this.lineItems,
    required this.warnings,
  });

  final TaxRegime regime;
  final int incomeFromSalary;
  final int incomeFromHouseProperty;
  final int incomeFromCapitalGains;
  final int incomeFromBusiness;
  final int incomeFromOtherSources;
  final int grossTotalIncome;
  final int chapterVIADeductions;

  /// Rounded to the nearest ₹10 (s.288A).
  final int totalIncome;
  final int normalRateIncome;
  final int specialRateIncome;
  final int taxOnNormalIncome;
  final int taxOnSpecialIncome;
  final int rebate87A;
  final int taxAfterRebate;
  final int surcharge;
  final int marginalRelief;
  final int cess;

  /// Tax + surcharge − relief + cess, rounded to ₹10 (s.288B).
  final int totalTaxLiability;
  final int tdsAndTcs;
  final int advanceTaxPaid;
  final int selfAssessmentTaxPaid;
  final int interest234A;
  final int interest234B;
  final int interest234C;

  /// Positive = pay this much; negative = refund due.
  final int netPayable;
  final double effectiveRatePercent;
  final List<LineItem> lineItems;
  final List<String> warnings;

  bool get isRefund => netPayable < 0;
  int get refundDue => isRefund ? -netPayable : 0;
  int get totalInterest => interest234A + interest234B + interest234C;

  Map<String, Object?> toJson() => {
        'regime': regime.name,
        'incomeFromSalary': incomeFromSalary,
        'incomeFromHouseProperty': incomeFromHouseProperty,
        'incomeFromCapitalGains': incomeFromCapitalGains,
        'incomeFromBusiness': incomeFromBusiness,
        'incomeFromOtherSources': incomeFromOtherSources,
        'grossTotalIncome': grossTotalIncome,
        'chapterVIADeductions': chapterVIADeductions,
        'totalIncome': totalIncome,
        'normalRateIncome': normalRateIncome,
        'specialRateIncome': specialRateIncome,
        'taxOnNormalIncome': taxOnNormalIncome,
        'taxOnSpecialIncome': taxOnSpecialIncome,
        'rebate87A': rebate87A,
        'taxAfterRebate': taxAfterRebate,
        'surcharge': surcharge,
        'marginalRelief': marginalRelief,
        'cess': cess,
        'totalTaxLiability': totalTaxLiability,
        'tdsAndTcs': tdsAndTcs,
        'advanceTaxPaid': advanceTaxPaid,
        'selfAssessmentTaxPaid': selfAssessmentTaxPaid,
        'interest234A': interest234A,
        'interest234B': interest234B,
        'interest234C': interest234C,
        'netPayable': netPayable,
        'effectiveRatePercent': effectiveRatePercent,
        'lineItems': lineItems.map((l) => l.toJson()).toList(),
        'warnings': warnings,
      };
}

/// Both regimes side by side with the engine's recommendation.
class RegimeComparison {
  const RegimeComparison({
    required this.oldRegime,
    required this.newRegime,
  });

  final ItrComputation oldRegime;
  final ItrComputation newRegime;

  /// The regime with the lower total liability; ties go to the new regime
  /// because it is the default and needs no opt-in form.
  TaxRegime get recommended =>
      oldRegime.totalTaxLiability < newRegime.totalTaxLiability
          ? TaxRegime.oldRegime
          : TaxRegime.newRegime;

  ItrComputation get best =>
      recommended == TaxRegime.oldRegime ? oldRegime : newRegime;

  /// How much the recommended regime saves against the other one.
  int get savings =>
      (oldRegime.totalTaxLiability - newRegime.totalTaxLiability).abs();

  Map<String, Object?> toJson() => {
        'oldRegime': oldRegime.toJson(),
        'newRegime': newRegime.toJson(),
        'recommended': recommended.name,
        'savings': savings,
      };
}
