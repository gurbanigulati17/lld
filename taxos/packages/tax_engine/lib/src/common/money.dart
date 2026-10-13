/// Integer-rupee money helpers.
///
/// All amounts in the engine are whole rupees stored as [int]. The Income Tax
/// Act rounds total income (s.288A) and tax payable (s.288B) to the nearest
/// ten rupees; these helpers implement that and the percentage arithmetic
/// used throughout the engine.
library;

/// Applies [ratePercent] to [amount] and rounds to the nearest rupee.
int pct(int amount, double ratePercent) => (amount * ratePercent / 100).round();

/// Rounds to the nearest multiple of ten (s.288A / s.288B).
int roundTo10(int amount) {
  final sign = amount < 0 ? -1 : 1;
  final abs = amount.abs();
  return sign * (((abs + 5) ~/ 10) * 10);
}

/// Rounds *down* to the nearest multiple of 100 (used for interest base
/// amounts under s.234B/234C per Rule 119A).
int floorTo100(int amount) => (amount ~/ 100) * 100;

/// Clamps to zero or above.
int nonNegative(int amount) => amount < 0 ? 0 : amount;

/// Formats whole rupees in the Indian grouping style, e.g. `12,34,567`.
String formatInr(int amount, {bool symbol = true}) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last3 = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last3';
  }
  final body = symbol ? '₹$grouped' : grouped;
  return negative ? '-$body' : body;
}
