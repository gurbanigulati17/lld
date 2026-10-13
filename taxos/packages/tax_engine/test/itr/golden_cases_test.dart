// Golden cases: every expected number below was worked by hand from the
// Finance Act 2025 slabs and compared against the Income Tax Department's
// published worked examples. Changing an expectation here needs a statutory
// citation in the commit message.
import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

const computer = ItrComputer();

TaxpayerProfile adult({ResidentialStatus status = ResidentialStatus.resident}) =>
    TaxpayerProfile(
      name: 'Test',
      ageCategory: AgeCategory.below60,
      residentialStatus: status,
    );

void main() {
  group('AY 2026-27 new regime', () {
    test('₹12.75L salary pays zero tax after 87A rebate', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 600000, otherTaxableComponents: 675000),
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.incomeFromSalary, 1200000);
      expect(r.totalIncome, 1200000);
      expect(r.taxOnNormalIncome, 60000);
      expect(r.rebate87A, 60000);
      expect(r.totalTaxLiability, 0);
      expect(r.netPayable, 0);
    });

    test('₹12.10L total income gets marginal relief on the rebate', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 600000, otherTaxableComponents: 685000),
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.totalIncome, 1210000);
      expect(r.taxOnNormalIncome, 61500);
      expect(r.rebate87A, 51500);
      expect(r.taxAfterRebate, 10000);
      expect(r.cess, 400);
      expect(r.totalTaxLiability, 10400);
    });

    test('capital gains with intra-head set-off and the 112A exemption', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 1000000, otherTaxableComponents: 1000000),
        capitalGains: const [
          CapitalGain(type: CapitalGainType.ltcg112A, gain: 300000),
          CapitalGain(type: CapitalGainType.stcg111A, gain: 100000),
          CapitalGain(type: CapitalGainType.stcgOther, gain: -50000),
        ],
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.incomeFromCapitalGains, 350000);
      expect(r.totalIncome, 2275000);
      expect(r.normalRateIncome, 1925000);
      expect(r.taxOnNormalIncome, 185000);
      expect(r.taxOnSpecialIncome, 31875);
      expect(r.cess, 8675);
      expect(r.totalTaxLiability, 225550);
    });

    test('surcharge marginal relief just above ₹50L', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 2000000, otherTaxableComponents: 3175000),
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.totalIncome, 5100000);
      expect(r.taxOnNormalIncome, 1110000);
      expect(r.surcharge, 111000);
      expect(r.marginalRelief, 41000);
      expect(r.cess, 47200);
      expect(r.totalTaxLiability, 1227200);
    });

    test('unexhausted basic exemption absorbs 112A gains for residents', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        capitalGains: const [
          CapitalGain(type: CapitalGainType.ltcg112A, gain: 500000),
        ],
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.totalIncome, 500000);
      expect(r.taxOnSpecialIncome, 0);
      expect(r.totalTaxLiability, 0);
    });

    test('non-residents do not get the basic exemption against 112A', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(status: ResidentialStatus.nonResident),
        capitalGains: const [
          CapitalGain(type: CapitalGainType.ltcg112A, gain: 500000),
        ],
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      // (5,00,000 − 1,25,000) × 12.5% = 46,875; + 4% cess = 48,750.
      expect(r.taxOnSpecialIncome, 46875);
      expect(r.rebate87A, 0);
      expect(r.totalTaxLiability, 48750);
    });

    test('presumptive professional pays 234B and 234C with no advance tax', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        business: const BusinessIncome(
          kind: BusinessIncomeKind.presumptive44ADA,
          grossReceipts: 3000000,
        ),
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.incomeFromBusiness, 1500000);
      expect(r.taxOnNormalIncome, 105000);
      expect(r.totalTaxLiability, 109200);
      expect(r.interest234A, 0);
      expect(r.interest234B, 4368);
      expect(r.interest234C, 1092);
      expect(r.netPayable, 114660);
      final form = selectForm(input, totalIncome: r.totalIncome);
      expect(form.form, ItrForm.itr4);
    });
  });

  group('AY 2026-27 old regime', () {
    test('salary with HRA, 80C, 80D, 80TTA and professional tax', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(
          basic: 500000,
          hraReceived: 200000,
          otherTaxableComponents: 300000,
          rentPaid: 240000,
          isMetroCity: true,
          professionalTax: 2400,
        ),
        otherSources: const OtherSourcesIncome(savingsInterest: 8000),
        deductions: const Deductions(section80C: 150000, section80D: 25000),
      );
      final old = computer.compute(input, TaxRegime.oldRegime);
      expect(old.incomeFromSalary, 757600);
      expect(old.grossTotalIncome, 765600);
      expect(old.chapterVIADeductions, 183000);
      expect(old.totalIncome, 582600);
      expect(old.taxOnNormalIncome, 29020);
      expect(old.cess, 1161);
      expect(old.totalTaxLiability, 30180);

      // New regime: ₹9,33,000 total income is inside the ₹12L rebate band.
      final cmp = computer.compare(input);
      expect(cmp.newRegime.totalIncome, 933000);
      expect(cmp.newRegime.taxOnNormalIncome, 33300);
      expect(cmp.newRegime.rebate87A, 33300);
      expect(cmp.newRegime.totalTaxLiability, 0);
      expect(cmp.recommended, TaxRegime.newRegime);
      expect(cmp.savings, 30180);
    });

    test('senior citizen pension with 80TTB', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: const TaxpayerProfile(ageCategory: AgeCategory.senior),
        salary: const SalaryIncome(basic: 600000),
        otherSources: const OtherSourcesIncome(fixedDepositInterest: 300000),
      );
      final r = computer.compute(input, TaxRegime.oldRegime);
      expect(r.chapterVIADeductions, 50000);
      expect(r.totalIncome, 800000);
      expect(r.taxOnNormalIncome, 70000);
      expect(r.totalTaxLiability, 72800);
    });

    test('87A wipes out tax at ₹4.9L total income', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 540000),
      );
      final r = computer.compute(input, TaxRegime.oldRegime);
      expect(r.totalIncome, 490000);
      expect(r.taxOnNormalIncome, 12000);
      expect(r.rebate87A, 12000);
      expect(r.totalTaxLiability, 0);
    });

    test('agricultural income is partially integrated', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 650000),
        agriculturalIncome: 100000,
      );
      final r = computer.compute(input, TaxRegime.oldRegime);
      expect(r.totalIncome, 600000);
      expect(r.taxOnNormalIncome, 47500);
    });

    test('self-occupied interest is capped at ₹2L and set off', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: adult(),
        salary: const SalaryIncome(basic: 1000000),
        houseProperties: const [
          HouseProperty(type: HousePropertyType.selfOccupied, interestOnLoan: 350000),
        ],
      );
      final old = computer.compute(input, TaxRegime.oldRegime);
      expect(old.incomeFromHouseProperty, -200000);
      expect(old.grossTotalIncome, 750000);
      final neu = computer.compute(input, TaxRegime.newRegime);
      expect(neu.incomeFromHouseProperty, 0);
      expect(neu.warnings, isNotEmpty);
    });
  });

  group('AY 2025-26 rule pack is independent', () {
    test('₹7L total income is tax free under the 2024 slabs', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2025_26,
        profile: adult(),
        salary: const SalaryIncome(basic: 775000),
      );
      final r = computer.compute(input, TaxRegime.newRegime);
      expect(r.totalIncome, 700000);
      expect(r.taxOnNormalIncome, 20000);
      expect(r.rebate87A, 20000);
      expect(r.totalTaxLiability, 0);
    });
  });

  group('JSON round trip', () {
    test('input survives toJson/fromJson unchanged', () {
      final input = ItrInput(
        assessmentYear: AssessmentYear.ay2026_27,
        profile: TaxpayerProfile(name: 'A', pan: 'ABCDE1234F', dateOfBirth: DateTime(1990, 5, 1)),
        salary: const SalaryIncome(basic: 500000, hraReceived: 100000, rentPaid: 120000, tdsOnSalary: 12000),
        houseProperties: const [HouseProperty(type: HousePropertyType.letOut, annualRent: 240000, interestOnLoan: 100000)],
        capitalGains: const [CapitalGain(type: CapitalGainType.ltcg112A, gain: 150000)],
        deductions: const Deductions(section80C: 100000),
        taxesPaid: TaxesPaid(advanceTax: [AdvanceTaxPayment(date: DateTime(2025, 6, 10), amount: 5000)]),
      );
      final again = ItrInput.fromJson(input.toJson());
      expect(again.toJson(), input.toJson());
      final a = computer.compute(input, TaxRegime.oldRegime);
      final b = computer.compute(again, TaxRegime.oldRegime);
      expect(a.toJson(), b.toJson());
    });
  });
}
