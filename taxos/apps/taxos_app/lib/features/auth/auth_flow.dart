import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth.dart';

/// The code we are waiting for, between the phone and verify screens.
final pendingChallengeProvider = StateProvider<OtpChallenge?>((ref) => null);
