import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

void main() {
  test('explanation numbers match the computation', () {
    final input = ItrInput(
      assessmentYear: AssessmentYear.ay2026_27,
      profile: const TaxpayerProfile(ageCategory: AgeCategory.below60),
      salary: const SalaryIncome(basic: 1500000, tdsOnSalary: 100000),
    );
    final cmp = const ItrComputer().compare(input);
    final lines = const ExplanationBuilder().explain(cmp.best);
    expect(lines.first, contains(formatInr(cmp.best.totalIncome)));
    expect(lines.last, contains(formatInr(cmp.best.refundDue > 0 ? cmp.best.refundDue : cmp.best.netPayable)));
    final c = const ExplanationBuilder().explainComparison(cmp);
    expect(c, hasLength(3));
  });

  test('Indian number formatting', () {
    expect(formatInr(0), '₹0');
    expect(formatInr(999), '₹999');
    expect(formatInr(1000), '₹1,000');
    expect(formatInr(1234567), '₹12,34,567');
    expect(formatInr(-50000), '-₹50,000');
    expect(roundTo10(30181), 30180);
    expect(roundTo10(30185), 30190);
    expect(floorTo100(109299), 109200);
  });
}
