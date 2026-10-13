import '../common/assessment_year.dart';

/// Which of the two personal-tax regimes applies (s.115BAC is the "new"
/// default regime; the "old" regime keeps most exemptions and deductions).
enum TaxRegime { oldRegime, newRegime }

/// Age bands that change basic exemption under the old regime.
enum AgeCategory { below60, senior, superSenior }

enum ResidentialStatus { resident, residentNotOrdinarilyResident, nonResident }

enum HousePropertyType { selfOccupied, letOut, deemedLetOut }

/// Capital gain buckets, each with its own rate under the Finance Act.
enum CapitalGainType {
  /// Short-term, STT-paid listed equity / equity MF (s.111A): 20%.
  stcg111A,

  /// Short-term on any other asset: taxed at slab rates.
  stcgOther,

  /// Long-term, STT-paid listed equity / equity MF (s.112A): 12.5% above
  /// the ₹1,25,000 exemption.
  ltcg112A,

  /// Long-term on other assets (s.112): 12.5% without indexation.
  ltcgOther,
}

enum BusinessIncomeKind {
  /// Books-of-account business or profession, net profit supplied.
  regular,

  /// Presumptive business under s.44AD (8% / 6% of turnover).
  presumptive44AD,

  /// Presumptive profession under s.44ADA (50% of gross receipts).
  presumptive44ADA,
}

class TaxpayerProfile {
  const TaxpayerProfile({
    this.name = '',
    this.pan = '',
    this.dateOfBirth,
    this.ageCategory,
    this.residentialStatus = ResidentialStatus.resident,
  }) : assert(dateOfBirth != null || ageCategory != null,
            'Provide dateOfBirth or ageCategory');

  final String name;
  final String pan;
  final DateTime? dateOfBirth;
  final AgeCategory? ageCategory;
  final ResidentialStatus residentialStatus;

  /// Age on the last day of the financial year decides the category.
  AgeCategory ageCategoryFor(AssessmentYear ay) {
    if (ageCategory != null) return ageCategory!;
    final dob = dateOfBirth!;
    final end = ay.fyEndDate;
    var age = end.year - dob.year;
    if (end.month < dob.month ||
        (end.month == dob.month && end.day < dob.day)) {
      age -= 1;
    }
    if (age >= 80) return AgeCategory.superSenior;
    if (age >= 60) return AgeCategory.senior;
    return AgeCategory.below60;
  }

  bool get isResident => residentialStatus != ResidentialStatus.nonResident;

  Map<String, Object?> toJson() => {
        'name': name,
        'pan': pan,
        if (dateOfBirth != null)
          'dateOfBirth': dateOfBirth!.toIso8601String().substring(0, 10),
        if (ageCategory != null) 'ageCategory': ageCategory!.name,
        'residentialStatus': residentialStatus.name,
      };

  factory TaxpayerProfile.fromJson(Map<String, Object?> json) =>
      TaxpayerProfile(
        name: (json['name'] as String?) ?? '',
        pan: (json['pan'] as String?) ?? '',
        dateOfBirth: json['dateOfBirth'] == null
            ? null
            : DateTime.parse(json['dateOfBirth'] as String),
        ageCategory: json['ageCategory'] == null
            ? null
            : AgeCategory.values.byName(json['ageCategory'] as String),
        residentialStatus: json['residentialStatus'] == null
            ? ResidentialStatus.resident
            : ResidentialStatus.values
                .byName(json['residentialStatus'] as String),
      );
}

/// Salary as it appears on Form 16 Part B, broken into the components the
/// engine needs for HRA exemption and the standard deduction.
class SalaryIncome {
  const SalaryIncome({
    this.basic = 0,
    this.dearnessAllowance = 0,
    this.hraReceived = 0,
    this.otherTaxableComponents = 0,
    this.exemptAllowances = 0,
    this.perquisites = 0,
    this.rentPaid = 0,
    this.isMetroCity = false,
    this.professionalTax = 0,
    this.employerNpsContribution = 0,
    this.tdsOnSalary = 0,
  });

  final int basic;
  final int dearnessAllowance;
  final int hraReceived;

  /// Special allowance, bonus, LTA (taxable part), etc.
  final int otherTaxableComponents;

  /// Allowances exempt under s.10(14) etc. that are only exempt in the old
  /// regime (LTA claimed, children education allowance, …).
  final int exemptAllowances;
  final int perquisites;
  final int rentPaid;
  final bool isMetroCity;
  final int professionalTax;

  /// Employer's NPS contribution (s.80CCD(2)); deductible in both regimes.
  final int employerNpsContribution;
  final int tdsOnSalary;

  int get grossSalary =>
      basic +
      dearnessAllowance +
      hraReceived +
      otherTaxableComponents +
      exemptAllowances +
      perquisites;

  Map<String, Object?> toJson() => {
        'basic': basic,
        'dearnessAllowance': dearnessAllowance,
        'hraReceived': hraReceived,
        'otherTaxableComponents': otherTaxableComponents,
        'exemptAllowances': exemptAllowances,
        'perquisites': perquisites,
        'rentPaid': rentPaid,
        'isMetroCity': isMetroCity,
        'professionalTax': professionalTax,
        'employerNpsContribution': employerNpsContribution,
        'tdsOnSalary': tdsOnSalary,
      };

  factory SalaryIncome.fromJson(Map<String, Object?> j) => SalaryIncome(
        basic: _i(j['basic']),
        dearnessAllowance: _i(j['dearnessAllowance']),
        hraReceived: _i(j['hraReceived']),
        otherTaxableComponents: _i(j['otherTaxableComponents']),
        exemptAllowances: _i(j['exemptAllowances']),
        perquisites: _i(j['perquisites']),
        rentPaid: _i(j['rentPaid']),
        isMetroCity: (j['isMetroCity'] as bool?) ?? false,
        professionalTax: _i(j['professionalTax']),
        employerNpsContribution: _i(j['employerNpsContribution']),
        tdsOnSalary: _i(j['tdsOnSalary']),
      );
}

class HouseProperty {
  const HouseProperty({
    required this.type,
    this.annualRent = 0,
    this.municipalTaxesPaid = 0,
    this.interestOnLoan = 0,
    this.preConstructionInterest = 0,
  });

  final HousePropertyType type;
  final int annualRent;
  final int municipalTaxesPaid;

  /// Interest on housing loan for the year (s.24(b)).
  final int interestOnLoan;

  /// 1/5th instalment of pre-construction interest claimable this year.
  final int preConstructionInterest;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'annualRent': annualRent,
        'municipalTaxesPaid': municipalTaxesPaid,
        'interestOnLoan': interestOnLoan,
        'preConstructionInterest': preConstructionInterest,
      };

  factory HouseProperty.fromJson(Map<String, Object?> j) => HouseProperty(
        type: HousePropertyType.values.byName(j['type'] as String),
        annualRent: _i(j['annualRent']),
        municipalTaxesPaid: _i(j['municipalTaxesPaid']),
        interestOnLoan: _i(j['interestOnLoan']),
        preConstructionInterest: _i(j['preConstructionInterest']),
      );
}

class CapitalGain {
  const CapitalGain({
    required this.type,
    required this.gain,
    this.description = '',
  });

  final CapitalGainType type;

  /// Net gain (positive) or loss (negative) in rupees after cost of
  /// acquisition and transfer expenses.
  final int gain;
  final String description;

  Map<String, Object?> toJson() => {
        'type': type.name,
        'gain': gain,
        'description': description,
      };

  factory CapitalGain.fromJson(Map<String, Object?> j) => CapitalGain(
        type: CapitalGainType.values.byName(j['type'] as String),
        gain: _i(j['gain']),
        description: (j['description'] as String?) ?? '',
      );
}

class BusinessIncome {
  const BusinessIncome({
    required this.kind,
    this.turnover = 0,
    this.digitalTurnover = 0,
    this.grossReceipts = 0,
    this.netProfit = 0,
    this.declaredProfit,
  });

  final BusinessIncomeKind kind;

  /// Total turnover (s.44AD); [digitalTurnover] is the part received by
  /// account-payee cheque / digital modes and is deemed at 6% instead of 8%.
  final int turnover;
  final int digitalTurnover;

  /// Gross professional receipts (s.44ADA).
  final int grossReceipts;

  /// Net profit as per books (regular).
  final int netProfit;

  /// Optional higher profit the taxpayer chooses to declare under a
  /// presumptive scheme (must be >= the deemed minimum).
  final int? declaredProfit;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'turnover': turnover,
        'digitalTurnover': digitalTurnover,
        'grossReceipts': grossReceipts,
        'netProfit': netProfit,
        if (declaredProfit != null) 'declaredProfit': declaredProfit,
      };

  factory BusinessIncome.fromJson(Map<String, Object?> j) => BusinessIncome(
        kind: BusinessIncomeKind.values.byName(j['kind'] as String),
        turnover: _i(j['turnover']),
        digitalTurnover: _i(j['digitalTurnover']),
        grossReceipts: _i(j['grossReceipts']),
        netProfit: _i(j['netProfit']),
        declaredProfit:
            j['declaredProfit'] == null ? null : _i(j['declaredProfit']),
      );
}

class OtherSourcesIncome {
  const OtherSourcesIncome({
    this.savingsInterest = 0,
    this.fixedDepositInterest = 0,
    this.dividends = 0,
    this.familyPension = 0,
    this.other = 0,
  });

  final int savingsInterest;
  final int fixedDepositInterest;
  final int dividends;
  final int familyPension;
  final int other;

  int get total =>
      savingsInterest + fixedDepositInterest + dividends + familyPension + other;

  Map<String, Object?> toJson() => {
        'savingsInterest': savingsInterest,
        'fixedDepositInterest': fixedDepositInterest,
        'dividends': dividends,
        'familyPension': familyPension,
        'other': other,
      };

  factory OtherSourcesIncome.fromJson(Map<String, Object?> j) =>
      OtherSourcesIncome(
        savingsInterest: _i(j['savingsInterest']),
        fixedDepositInterest: _i(j['fixedDepositInterest']),
        dividends: _i(j['dividends']),
        familyPension: _i(j['familyPension']),
        other: _i(j['other']),
      );
}

/// Chapter VI-A deductions as claimed. The engine applies statutory caps.
class Deductions {
  const Deductions({
    this.section80C = 0,
    this.section80CCD1B = 0,
    this.section80D = 0,
    this.section80DParents = 0,
    this.parentsAreSenior = false,
    this.section80E = 0,
    this.section80G = 0,
    this.section80EEA = 0,
    this.section80U = 0,
  });

  /// LIC, PPF, ELSS, EPF, tuition, principal repayment … (cap ₹1.5L with
  /// 80CCC and 80CCD(1)).
  final int section80C;

  /// Additional NPS self-contribution (cap ₹50,000).
  final int section80CCD1B;

  /// Health insurance premium for self / family.
  final int section80D;

  /// Health insurance premium for parents.
  final int section80DParents;
  final bool parentsAreSenior;

  /// Education loan interest (no cap).
  final int section80E;

  /// Donations (already net of the 50% / 100% rule; caller supplies the
  /// eligible amount).
  final int section80G;

  /// Affordable-housing loan interest (cap ₹1.5L).
  final int section80EEA;

  /// Disability deduction (flat ₹75,000 / ₹1,25,000; caller supplies).
  final int section80U;

  Map<String, Object?> toJson() => {
        'section80C': section80C,
        'section80CCD1B': section80CCD1B,
        'section80D': section80D,
        'section80DParents': section80DParents,
        'parentsAreSenior': parentsAreSenior,
        'section80E': section80E,
        'section80G': section80G,
        'section80EEA': section80EEA,
        'section80U': section80U,
      };

  factory Deductions.fromJson(Map<String, Object?> j) => Deductions(
        section80C: _i(j['section80C']),
        section80CCD1B: _i(j['section80CCD1B']),
        section80D: _i(j['section80D']),
        section80DParents: _i(j['section80DParents']),
        parentsAreSenior: (j['parentsAreSenior'] as bool?) ?? false,
        section80E: _i(j['section80E']),
        section80G: _i(j['section80G']),
        section80EEA: _i(j['section80EEA']),
        section80U: _i(j['section80U']),
      );
}

/// One advance-tax challan.
class AdvanceTaxPayment {
  const AdvanceTaxPayment({required this.date, required this.amount});
  final DateTime date;
  final int amount;

  Map<String, Object?> toJson() => {
        'date': date.toIso8601String().substring(0, 10),
        'amount': amount,
      };

  factory AdvanceTaxPayment.fromJson(Map<String, Object?> j) =>
      AdvanceTaxPayment(
        date: DateTime.parse(j['date'] as String),
        amount: _i(j['amount']),
      );
}

class TaxesPaid {
  const TaxesPaid({
    this.tdsOther = 0,
    this.tcs = 0,
    this.advanceTax = const [],
    this.selfAssessmentTax = 0,
  });

  /// TDS other than on salary (bank interest, professional fees, …). TDS on
  /// salary is taken from [SalaryIncome.tdsOnSalary].
  final int tdsOther;
  final int tcs;
  final List<AdvanceTaxPayment> advanceTax;
  final int selfAssessmentTax;

  int get totalAdvanceTax => advanceTax.fold(0, (s, p) => s + p.amount);

  Map<String, Object?> toJson() => {
        'tdsOther': tdsOther,
        'tcs': tcs,
        'advanceTax': advanceTax.map((p) => p.toJson()).toList(),
        'selfAssessmentTax': selfAssessmentTax,
      };

  factory TaxesPaid.fromJson(Map<String, Object?> j) => TaxesPaid(
        tdsOther: _i(j['tdsOther']),
        tcs: _i(j['tcs']),
        advanceTax: ((j['advanceTax'] as List?) ?? const [])
            .map((e) => AdvanceTaxPayment.fromJson(e as Map<String, Object?>))
            .toList(),
        selfAssessmentTax: _i(j['selfAssessmentTax']),
      );
}

/// Complete input for one income-tax return.
class ItrInput {
  const ItrInput({
    required this.assessmentYear,
    required this.profile,
    this.salary,
    this.houseProperties = const [],
    this.capitalGains = const [],
    this.business,
    this.otherSources = const OtherSourcesIncome(),
    this.deductions = const Deductions(),
    this.taxesPaid = const TaxesPaid(),
    this.agriculturalIncome = 0,
    this.hasForeignAssetsOrIncome = false,
    this.isDirectorOrHoldsUnlistedShares = false,
    this.broughtForwardLosses = 0,
    this.filingDate,
  });

  final AssessmentYear assessmentYear;
  final TaxpayerProfile profile;
  final SalaryIncome? salary;
  final List<HouseProperty> houseProperties;
  final List<CapitalGain> capitalGains;
  final BusinessIncome? business;
  final OtherSourcesIncome otherSources;
  final Deductions deductions;
  final TaxesPaid taxesPaid;
  final int agriculturalIncome;
  final bool hasForeignAssetsOrIncome;
  final bool isDirectorOrHoldsUnlistedShares;

  /// Brought-forward losses from earlier years (affects form choice).
  final int broughtForwardLosses;

  /// Expected filing date; drives s.234A interest. Defaults to the due date.
  final DateTime? filingDate;

  bool get hasBusinessIncome => business != null;
  bool get hasCapitalGains => capitalGains.isNotEmpty;

  Map<String, Object?> toJson() => {
        'assessmentYear': assessmentYear.name,
        'profile': profile.toJson(),
        if (salary != null) 'salary': salary!.toJson(),
        'houseProperties': houseProperties.map((h) => h.toJson()).toList(),
        'capitalGains': capitalGains.map((c) => c.toJson()).toList(),
        if (business != null) 'business': business!.toJson(),
        'otherSources': otherSources.toJson(),
        'deductions': deductions.toJson(),
        'taxesPaid': taxesPaid.toJson(),
        'agriculturalIncome': agriculturalIncome,
        'hasForeignAssetsOrIncome': hasForeignAssetsOrIncome,
        'isDirectorOrHoldsUnlistedShares': isDirectorOrHoldsUnlistedShares,
        'broughtForwardLosses': broughtForwardLosses,
        if (filingDate != null)
          'filingDate': filingDate!.toIso8601String().substring(0, 10),
      };

  factory ItrInput.fromJson(Map<String, Object?> j) => ItrInput(
        assessmentYear: AssessmentYear.parse(j['assessmentYear'] as String),
        profile: TaxpayerProfile.fromJson(j['profile'] as Map<String, Object?>),
        salary: j['salary'] == null
            ? null
            : SalaryIncome.fromJson(j['salary'] as Map<String, Object?>),
        houseProperties: ((j['houseProperties'] as List?) ?? const [])
            .map((e) => HouseProperty.fromJson(e as Map<String, Object?>))
            .toList(),
        capitalGains: ((j['capitalGains'] as List?) ?? const [])
            .map((e) => CapitalGain.fromJson(e as Map<String, Object?>))
            .toList(),
        business: j['business'] == null
            ? null
            : BusinessIncome.fromJson(j['business'] as Map<String, Object?>),
        otherSources: j['otherSources'] == null
            ? const OtherSourcesIncome()
            : OtherSourcesIncome.fromJson(
                j['otherSources'] as Map<String, Object?>),
        deductions: j['deductions'] == null
            ? const Deductions()
            : Deductions.fromJson(j['deductions'] as Map<String, Object?>),
        taxesPaid: j['taxesPaid'] == null
            ? const TaxesPaid()
            : TaxesPaid.fromJson(j['taxesPaid'] as Map<String, Object?>),
        agriculturalIncome: _i(j['agriculturalIncome']),
        hasForeignAssetsOrIncome:
            (j['hasForeignAssetsOrIncome'] as bool?) ?? false,
        isDirectorOrHoldsUnlistedShares:
            (j['isDirectorOrHoldsUnlistedShares'] as bool?) ?? false,
        broughtForwardLosses: _i(j['broughtForwardLosses']),
        filingDate: j['filingDate'] == null
            ? null
            : DateTime.parse(j['filingDate'] as String),
      );

  ItrInput copyWith({
    AssessmentYear? assessmentYear,
    TaxpayerProfile? profile,
    SalaryIncome? salary,
    bool clearSalary = false,
    List<HouseProperty>? houseProperties,
    List<CapitalGain>? capitalGains,
    BusinessIncome? business,
    bool clearBusiness = false,
    OtherSourcesIncome? otherSources,
    Deductions? deductions,
    TaxesPaid? taxesPaid,
    int? agriculturalIncome,
    bool? hasForeignAssetsOrIncome,
    bool? isDirectorOrHoldsUnlistedShares,
    int? broughtForwardLosses,
    DateTime? filingDate,
  }) =>
      ItrInput(
        assessmentYear: assessmentYear ?? this.assessmentYear,
        profile: profile ?? this.profile,
        salary: clearSalary ? null : (salary ?? this.salary),
        houseProperties: houseProperties ?? this.houseProperties,
        capitalGains: capitalGains ?? this.capitalGains,
        business: clearBusiness ? null : (business ?? this.business),
        otherSources: otherSources ?? this.otherSources,
        deductions: deductions ?? this.deductions,
        taxesPaid: taxesPaid ?? this.taxesPaid,
        agriculturalIncome: agriculturalIncome ?? this.agriculturalIncome,
        hasForeignAssetsOrIncome:
            hasForeignAssetsOrIncome ?? this.hasForeignAssetsOrIncome,
        isDirectorOrHoldsUnlistedShares: isDirectorOrHoldsUnlistedShares ??
            this.isDirectorOrHoldsUnlistedShares,
        broughtForwardLosses: broughtForwardLosses ?? this.broughtForwardLosses,
        filingDate: filingDate ?? this.filingDate,
      );
}

int _i(Object? v) => v == null ? 0 : (v as num).toInt();
