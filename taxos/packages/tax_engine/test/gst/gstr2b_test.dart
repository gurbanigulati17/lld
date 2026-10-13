import 'package:tax_engine/tax_engine.dart';
import 'package:test/test.dart';

GstInvoice inv(String gstin, String no, int value, int tax) => GstInvoice(
      supplierGstin: gstin,
      invoiceNumber: no,
      invoiceDate: DateTime(2025, 9, 5),
      taxableValue: value,
      totalTax: tax,
    );

void main() {
  test('matches, mismatches and missing lines', () {
    final books = [
      inv('27AAAAA0000A1Z5', 'INV-001', 10000, 1800),
      inv('27AAAAA0000A1Z5', 'inv/002', 20000, 3600),
      inv('29BBBBB0000B1Z4', '7', 5000, 900),
    ];
    final statement = [
      inv('27AAAAA0000A1Z5', 'INV001', 10000, 1800),
      inv('27AAAAA0000A1Z5', 'INV002', 20000, 3000),
      inv('29CCCCC0000C1Z3', '99', 1000, 180),
    ];
    final r = const Gstr2bReconciler().reconcile(books: books, statement: statement);
    expect(r.where(ReconStatus.matched).length, 1);
    expect(r.where(ReconStatus.mismatched).length, 1);
    expect(r.where(ReconStatus.missingIn2B).length, 1);
    expect(r.where(ReconStatus.missingInBooks).length, 1);
    expect(r.claimableItc, 1800 + 3000);
    expect(r.itcOnHold, 900);
  });

  test('registration advisor thresholds', () {
    const advisor = GstRegistrationAdvisor();
    final a = advisor.advise(const GstRegistrationInput(
      aggregateTurnover: 3000000,
      nature: SupplyNature.goods,
    ));
    expect(a.registrationRequired, isFalse);
    expect(a.compositionEligible, isTrue);

    final b = advisor.advise(const GstRegistrationInput(
      aggregateTurnover: 3000000,
      nature: SupplyNature.services,
    ));
    expect(b.registrationRequired, isTrue);

    final c = advisor.advise(const GstRegistrationInput(
      aggregateTurnover: 60000000,
      nature: SupplyNature.both,
      makesInterStateSupplies: true,
    ));
    expect(c.registrationRequired, isTrue);
    expect(c.compositionEligible, isFalse);
    expect(c.eInvoicingRequired, isTrue);
  });
}
