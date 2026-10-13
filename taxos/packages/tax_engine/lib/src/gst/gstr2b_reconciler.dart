/// An invoice as it appears either in the purchase register (books) or in
/// the auto-drafted GSTR-2B statement.
class GstInvoice {
  const GstInvoice({
    required this.supplierGstin,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.taxableValue,
    required this.totalTax,
  });

  final String supplierGstin;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final int taxableValue;
  final int totalTax;

  /// Normalised key: GSTIN + invoice number without punctuation/case noise.
  String get key =>
      '${supplierGstin.toUpperCase().trim()}|${_norm(invoiceNumber)}';

  static String _norm(String s) =>
      s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '').replaceFirst(RegExp(r'^0+'), '');

  Map<String, Object?> toJson() => {
        'supplierGstin': supplierGstin,
        'invoiceNumber': invoiceNumber,
        'invoiceDate': invoiceDate.toIso8601String().substring(0, 10),
        'taxableValue': taxableValue,
        'totalTax': totalTax,
      };

  factory GstInvoice.fromJson(Map<String, Object?> j) => GstInvoice(
        supplierGstin: j['supplierGstin'] as String,
        invoiceNumber: j['invoiceNumber'] as String,
        invoiceDate: DateTime.parse(j['invoiceDate'] as String),
        taxableValue: (j['taxableValue'] as num).toInt(),
        totalTax: (j['totalTax'] as num).toInt(),
      );
}

enum ReconStatus {
  /// Present in both with matching tax (within tolerance).
  matched,

  /// Present in both but amounts differ beyond tolerance.
  mismatched,

  /// In books but not in 2B: ITC not yet available (s.16(2)(aa)).
  missingIn2B,

  /// In 2B but not in books: a purchase you may have forgotten to record.
  missingInBooks,
}

class ReconLine {
  const ReconLine({
    required this.status,
    this.books,
    this.statement,
  });

  final ReconStatus status;
  final GstInvoice? books;
  final GstInvoice? statement;

  int get taxDifference => (books?.totalTax ?? 0) - (statement?.totalTax ?? 0);

  Map<String, Object?> toJson() => {
        'status': status.name,
        if (books != null) 'books': books!.toJson(),
        if (statement != null) 'statement': statement!.toJson(),
        'taxDifference': taxDifference,
      };
}

class ReconResult {
  const ReconResult({required this.lines, required this.tolerance});

  final List<ReconLine> lines;
  final int tolerance;

  Iterable<ReconLine> where(ReconStatus s) => lines.where((l) => l.status == s);

  /// ITC that can be claimed this period: matched + mismatched (at the 2B
  /// value, which is what the portal allows).
  int get claimableItc => lines
      .where((l) => l.status == ReconStatus.matched || l.status == ReconStatus.mismatched)
      .fold(0, (s, l) => s + (l.statement?.totalTax ?? 0));

  /// ITC recorded in books that is not available yet.
  int get itcOnHold =>
      where(ReconStatus.missingIn2B).fold(0, (s, l) => s + (l.books?.totalTax ?? 0));

  Map<String, Object?> toJson() => {
        'tolerance': tolerance,
        'claimableItc': claimableItc,
        'itcOnHold': itcOnHold,
        'summary': {
          for (final s in ReconStatus.values) s.name: where(s).length,
        },
        'lines': lines.map((l) => l.toJson()).toList(),
      };
}

/// Matches the purchase register against GSTR-2B.
class Gstr2bReconciler {
  const Gstr2bReconciler({this.toleranceRupees = 1});

  /// Rounding differences up to this many rupees count as matched.
  final int toleranceRupees;

  ReconResult reconcile({
    required List<GstInvoice> books,
    required List<GstInvoice> statement,
  }) {
    final byKey2B = {for (final inv in statement) inv.key: inv};
    final seen = <String>{};
    final lines = <ReconLine>[];

    for (final b in books) {
      final s = byKey2B[b.key];
      if (s == null) {
        lines.add(ReconLine(status: ReconStatus.missingIn2B, books: b));
        continue;
      }
      seen.add(b.key);
      final diff = (b.totalTax - s.totalTax).abs() +
          (b.taxableValue - s.taxableValue).abs();
      lines.add(ReconLine(
        status: diff <= toleranceRupees ? ReconStatus.matched : ReconStatus.mismatched,
        books: b,
        statement: s,
      ));
    }
    for (final s in statement) {
      if (!seen.contains(s.key)) {
        lines.add(ReconLine(status: ReconStatus.missingInBooks, statement: s));
      }
    }
    return ReconResult(lines: List.unmodifiable(lines), tolerance: toleranceRupees);
  }
}
