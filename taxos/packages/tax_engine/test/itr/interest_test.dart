import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

InterestInput base({
  List<({DateTime date, int amount})> advance = const [],
  DateTime? filing,
  int tds = 0,
  int tax = 100000,
}) =>
    InterestInput(
      assessmentYear: AssessmentYear.ay2026_27,
      totalTaxLiability: tax,
      tdsAndTcs: tds,
      advanceTaxPayments: advance,
      filingDate: filing ?? DateTime(2026, 7, 31),
      dueDate: DateTime(2026, 7, 31),
      advanceTaxThreshold: 10000,
    );

void main() {
  test('months or part thereof', () {
    expect(monthsOrPartThereof(DateTime(2026, 4, 1), DateTime(2026, 7, 31)), 4);
    expect(monthsOrPartThereof(DateTime(2026, 4, 1), DateTime(2026, 8, 5)), 5);
    expect(monthsOrPartThereof(DateTime(2026, 8, 1), DateTime(2026, 8, 1)), 1);
    expect(monthsOrPartThereof(DateTime(2026, 8, 1), DateTime(2026, 9, 1)), 2);
    expect(monthsOrPartThereof(DateTime(2026, 8, 1), DateTime(2026, 7, 1)), 0);
  });

  test('instalments paid on time attract no interest', () {
    final r = computeInterest(base(advance: [
      (date: DateTime(2025, 6, 10), amount: 15000),
      (date: DateTime(2025, 9, 10), amount: 30000),
      (date: DateTime(2025, 12, 10), amount: 30000),
      (date: DateTime(2026, 3, 10), amount: 25000),
    ]));
    expect(r.total, 0);
  });

  test('no advance tax at all: 234B for four months and 234C per instalment', () {
    final r = computeInterest(base());
    expect(r.section234B, 4000);
    expect(r.section234C, 450 + 1350 + 2250 + 1000);
    expect(r.section234A, 0);
  });

  test('12% / 36% tolerance on the first two instalments', () {
    final r = computeInterest(base(advance: [
      (date: DateTime(2025, 6, 10), amount: 12000),
      (date: DateTime(2025, 9, 10), amount: 24000),
      (date: DateTime(2025, 12, 10), amount: 39000),
      (date: DateTime(2026, 3, 10), amount: 25000),
    ]));
    expect(r.section234C, 0);
    expect(r.section234B, 0);
  });

  test('late filing by one month charges 234A on unpaid tax', () {
    final r = computeInterest(base(
      filing: DateTime(2026, 8, 31),
      advance: [(date: DateTime(2026, 3, 10), amount: 95000)],
    ));
    expect(r.section234A, 50);
    expect(r.section234B, 0);
  });

  test('below the ₹10,000 threshold no 234B/234C applies', () {
    final r = computeInterest(base(tax: 9000));
    expect(r.total, 0);
  });

  test('TDS reduces assessed tax', () {
    final r = computeInterest(base(tds: 95000));
    expect(r.total, 0);
  });
}
