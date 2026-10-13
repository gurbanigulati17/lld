enum SupplyNature { goods, services, both }

class GstRegistrationInput {
  const GstRegistrationInput({
    required this.aggregateTurnover,
    required this.nature,
    this.inSpecialCategoryState = false,
    this.makesInterStateSupplies = false,
    this.sellsThroughEcommerce = false,
    this.isCasualOrNonResident = false,
    this.liableUnderReverseCharge = false,
  });

  /// Expected PAN-level aggregate turnover for the financial year.
  final int aggregateTurnover;
  final SupplyNature nature;

  /// Manipur, Mizoram, Nagaland, Tripura and other notified states.
  final bool inSpecialCategoryState;
  final bool makesInterStateSupplies;
  final bool sellsThroughEcommerce;
  final bool isCasualOrNonResident;
  final bool liableUnderReverseCharge;
}

class GstRegistrationAdvice {
  const GstRegistrationAdvice({
    required this.registrationRequired,
    required this.threshold,
    required this.compositionEligible,
    required this.eInvoicingRequired,
    required this.reasons,
  });

  final bool registrationRequired;
  final int threshold;
  final bool compositionEligible;
  final bool eInvoicingRequired;
  final List<String> reasons;

  Map<String, Object?> toJson() => {
        'registrationRequired': registrationRequired,
        'threshold': threshold,
        'compositionEligible': compositionEligible,
        'eInvoicingRequired': eInvoicingRequired,
        'reasons': reasons,
      };
}

/// Answers "do I need GST registration, and which scheme?" from s.22–24
/// thresholds and the e-invoicing notification.
class GstRegistrationAdvisor {
  const GstRegistrationAdvisor();

  static const int goodsThreshold = 4000000;
  static const int servicesThreshold = 2000000;
  static const int specialStateThreshold = 1000000;
  static const int compositionGoodsLimit = 15000000;
  static const int compositionServicesLimit = 5000000;
  static const int eInvoicingThreshold = 50000000;

  GstRegistrationAdvice advise(GstRegistrationInput i) {
    final reasons = <String>[];
    final threshold = i.inSpecialCategoryState
        ? specialStateThreshold
        : (i.nature == SupplyNature.goods ? goodsThreshold : servicesThreshold);

    var required = false;
    if (i.aggregateTurnover > threshold) {
      required = true;
      reasons.add('Aggregate turnover exceeds the threshold (s.22).');
    }
    if (i.makesInterStateSupplies && i.nature != SupplyNature.services) {
      required = true;
      reasons.add('Inter-state supply of goods requires registration '
          'regardless of turnover (s.24).');
    }
    if (i.sellsThroughEcommerce && i.nature != SupplyNature.services) {
      required = true;
      reasons.add('Selling goods through an e-commerce operator requires '
          'registration (s.24).');
    }
    if (i.isCasualOrNonResident) {
      required = true;
      reasons.add('Casual and non-resident taxable persons must register.');
    }
    if (i.liableUnderReverseCharge) {
      required = true;
      reasons.add('Persons liable under reverse charge must register.');
    }
    if (!required) {
      reasons.add('Turnover is within the threshold; registration is optional '
          '(voluntary registration lets you claim ITC).');
    }

    final compositionLimit =
        i.nature == SupplyNature.services ? compositionServicesLimit : compositionGoodsLimit;
    final composition = i.aggregateTurnover <= compositionLimit &&
        !i.makesInterStateSupplies &&
        !i.sellsThroughEcommerce &&
        !i.isCasualOrNonResident;
    if (composition) {
      reasons.add('Eligible for the composition scheme (s.10): lower flat '
          'rate, quarterly payment, no ITC.');
    }
    final eInvoicing = i.aggregateTurnover > eInvoicingThreshold;
    if (eInvoicing) {
      reasons.add('Turnover above ₹5 crore: e-invoicing is mandatory for B2B '
          'supplies.');
    }

    return GstRegistrationAdvice(
      registrationRequired: required,
      threshold: threshold,
      compositionEligible: composition,
      eInvoicingRequired: eInvoicing,
      reasons: reasons,
    );
  }
}
