import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

final profile = TaxpayerProfile(ageCategory: AgeCategory.below60);

ItrInput base({
  List<CapitalGain> cg = const [],
  List<HouseProperty> hp = const [],
  BusinessIncome? business,
  bool foreign = false,
}) =>
    ItrInput(
      assessmentYear: AssessmentYear.ay2026_27,
      profile: profile,
      salary: const SalaryIncome(basic: 800000),
      capitalGains: cg,
      houseProperties: hp,
      business: business,
      hasForeignAssetsOrIncome: foreign,
    );

void main() {
  test('plain salary is ITR-1', () {
    expect(selectForm(base(), totalIncome: 725000).form, ItrForm.itr1);
  });

  test('small 112A gains stay in ITR-1', () {
    final i = base(cg: const [CapitalGain(type: CapitalGainType.ltcg112A, gain: 100000)]);
    expect(selectForm(i, totalIncome: 825000).form, ItrForm.itr1);
  });

  test('other capital gains need ITR-2', () {
    final i = base(cg: const [CapitalGain(type: CapitalGainType.stcg111A, gain: 10000)]);
    expect(selectForm(i, totalIncome: 735000).form, ItrForm.itr2);
  });

  test('income above ₹50L needs ITR-2', () {
    expect(selectForm(base(), totalIncome: 5100000).form, ItrForm.itr2);
  });

  test('two house properties need ITR-2', () {
    final i = base(hp: const [
      HouseProperty(type: HousePropertyType.selfOccupied),
      HouseProperty(type: HousePropertyType.letOut, annualRent: 120000),
    ]);
    expect(selectForm(i, totalIncome: 800000).form, ItrForm.itr2);
  });

  test('presumptive business is ITR-4, with foreign assets ITR-3', () {
    final biz = const BusinessIncome(kind: BusinessIncomeKind.presumptive44AD, turnover: 5000000);
    expect(selectForm(base(business: biz), totalIncome: 1125000).form, ItrForm.itr4);
    expect(selectForm(base(business: biz, foreign: true), totalIncome: 1125000).form, ItrForm.itr3);
  });

  test('books-of-account business is ITR-3', () {
    final biz = const BusinessIncome(kind: BusinessIncomeKind.regular, netProfit: 500000);
    expect(selectForm(base(business: biz), totalIncome: 1225000).form, ItrForm.itr3);
  });
}
