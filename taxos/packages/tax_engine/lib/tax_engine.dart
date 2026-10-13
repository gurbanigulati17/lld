/// TaxOS computation engine.
///
/// Pure Dart, deterministic, and versioned per assessment year. The same
/// package runs on-device inside the Flutter app (instant what-if, offline
/// drafting) and inside the API service (authoritative pre-filing
/// computation), so the two can never disagree.
library;

export 'src/common/assessment_year.dart';
export 'src/common/line_item.dart';
export 'src/common/money.dart';
export 'src/gst/gstr2b_reconciler.dart';
export 'src/gst/gstr3b.dart';
export 'src/gst/registration_advisor.dart';
export 'src/itr/computer.dart';
export 'src/itr/explanation.dart';
export 'src/itr/form_selector.dart';
export 'src/itr/interest.dart';
export 'src/itr/models.dart';
export 'src/itr/result.dart';
export 'src/itr/rule_pack.dart';
