/// A single traceable line in a computation.
///
/// Every rupee the engine produces is attached to a [LineItem] so the UI can
/// show *why* a number is what it is ("this comes from Form 16 Part B,
/// section 16(ia)"). This is the provenance trail that lets the app replace
/// a chartered accountant's explanation, not just their arithmetic.
class LineItem {
  const LineItem({
    required this.code,
    required this.label,
    required this.amount,
    this.section,
    this.note,
    this.group = LineGroup.other,
  });

  /// Stable machine code, e.g. `SAL.GROSS`, `TAX.CESS`.
  final String code;

  /// Human readable label.
  final String label;

  /// Whole rupees. Negative values are deductions or losses.
  final int amount;

  /// Statutory reference, e.g. `s.16(ia)`.
  final String? section;

  /// Short explanation of how the amount was derived.
  final String? note;

  final LineGroup group;

  Map<String, Object?> toJson() => {
        'code': code,
        'label': label,
        'amount': amount,
        if (section != null) 'section': section,
        if (note != null) 'note': note,
        'group': group.name,
      };

  @override
  String toString() => '$code $label = $amount';
}

enum LineGroup {
  salary,
  houseProperty,
  capitalGains,
  business,
  otherSources,
  deductions,
  tax,
  credits,
  interest,
  other,
}
