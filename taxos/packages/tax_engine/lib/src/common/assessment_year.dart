/// Assessment years supported by the engine.
///
/// Income earned in financial year `FY 2025-26` is assessed in
/// `AY 2026-27`. Each assessment year has its own [rule pack] with slabs,
/// thresholds and due dates, so adding a year never changes an old one.
enum AssessmentYear {
  ay2025_26(
    label: 'AY 2025-26',
    financialYear: 'FY 2024-25',
    fyStart: 2024,
  ),
  ay2026_27(
    label: 'AY 2026-27',
    financialYear: 'FY 2025-26',
    fyStart: 2025,
  );

  const AssessmentYear({
    required this.label,
    required this.financialYear,
    required this.fyStart,
  });

  final String label;
  final String financialYear;

  /// Calendar year in which the financial year starts (1 April).
  final int fyStart;

  /// 1 April of the financial year.
  DateTime get fyStartDate => DateTime(fyStart, 4, 1);

  /// 31 March at the end of the financial year.
  DateTime get fyEndDate => DateTime(fyStart + 1, 3, 31);

  /// Last date for a belated (s.139(4)) or revised (s.139(5)) return:
  /// 31 December of the assessment year.
  DateTime get belatedReturnLastDate => DateTime(fyStart + 1, 12, 31);

  static AssessmentYear get latest => AssessmentYear.ay2026_27;

  static AssessmentYear parse(String value) {
    for (final ay in values) {
      if (ay.name == value || ay.label == value) return ay;
    }
    throw ArgumentError.value(value, 'value', 'Unknown assessment year');
  }
}
