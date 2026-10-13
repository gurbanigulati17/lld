import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

void main() {
  test('Rule 88A set-off order and cash payable', () {
    final r = const Gstr3bComputer().compute(Gstr3bInput(
      period: '2025-09',
      outwardSupplies: const [
        OutwardSupply(taxableValue: 1000000, ratePercent: 18, interState: false),
        OutwardSupply(taxableValue: 500000, ratePercent: 18, interState: true),
      ],
      itcAvailable: const GstHeads(igst: 120000, cgst: 50000, sgst: 50000),
      annualTurnover: 10000000,
      dueDate: DateTime(2025, 10, 20),
      filingDate: DateTime(2025, 10, 30),
    ));
    expect(r.outputTax, const GstHeadsMatcher(igst: 90000, cgst: 90000, sgst: 90000));
    expect(r.itcUtilised.igst, 120000);
    expect(r.cashPayable.igst, 0);
    expect(r.cashPayable.cgst, 10000);
    expect(r.cashPayable.sgst, 40000);
    expect(r.closingCreditLedger.total, 0);
    expect(r.daysLate, 10);
    expect(r.lateFee, 500);
    expect(r.interest, 247);
    expect(r.totalCashOutflow, 50747);
  });

  test('CGST credit never offsets SGST', () {
    final r = const Gstr3bComputer().compute(const Gstr3bInput(
      period: '2025-09',
      outwardSupplies: [
        OutwardSupply(taxableValue: 100000, ratePercent: 18, interState: false),
      ],
      itcAvailable: GstHeads(cgst: 20000),
    ));
    expect(r.cashPayable.cgst, 0);
    expect(r.cashPayable.sgst, 9000);
    expect(r.closingCreditLedger.cgst, 11000);
  });

  test('reverse charge is always cash and nil-return late fee is capped', () {
    final r = const Gstr3bComputer().compute(Gstr3bInput(
      period: '2025-09',
      outwardSupplies: const [],
      reverseChargeLiability: const GstHeads(cgst: 900, sgst: 900),
      itcAvailable: const GstHeads(igst: 100000),
      isNilReturn: true,
      dueDate: DateTime(2025, 10, 20),
      filingDate: DateTime(2025, 12, 20),
    ));
    expect(r.cashPayable.cgst, 900);
    expect(r.lateFee, 500);
    expect(r.closingCreditLedger.igst, 100000);
  });

  test('JSON round trip', () {
    final input = Gstr3bInput(
      period: '2025-09',
      outwardSupplies: const [OutwardSupply(taxableValue: 1000, ratePercent: 5, interState: true)],
      itcAvailable: const GstHeads(igst: 10),
      dueDate: DateTime(2025, 10, 20),
    );
    expect(Gstr3bInput.fromJson(input.toJson()).toJson(), input.toJson());
  });
}

class GstHeadsMatcher extends Matcher {
  const GstHeadsMatcher({this.igst = 0, this.cgst = 0, this.sgst = 0, this.cess = 0});
  final int igst, cgst, sgst, cess;

  @override
  bool matches(Object? item, Map matchState) =>
      item is GstHeads &&
      item.igst == igst &&
      item.cgst == cgst &&
      item.sgst == sgst &&
      item.cess == cess;

  @override
  Description describe(Description d) =>
      d.add('GstHeads(igst: $igst, cgst: $cgst, sgst: $sgst, cess: $cess)');
}
