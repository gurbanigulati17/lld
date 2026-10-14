import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../core/auth.dart';
import 'auth_flow.dart';

/// Enter the 6-digit code. Verifies automatically on the sixth digit.
class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({super.key});

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _resendIn = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn = (_resendIn - 1).clamp(0, 30));
      if (_resendIn == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final challenge = ref.read(pendingChallengeProvider);
    if (challenge == null || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await ref.read(authRepositoryProvider).verifyOtp(challenge.phone, _code.text);
      ref.read(pendingChallengeProvider.notifier).state = null;
      await ref.read(authProvider.notifier).signedIn(session);
      // The router moves on once the session is set.
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _resend() async {
    final challenge = ref.read(pendingChallengeProvider);
    if (challenge == null) return;
    try {
      final next = await ref.read(authRepositoryProvider).requestOtp(challenge.phone);
      ref.read(pendingChallengeProvider.notifier).state = next;
      _code.clear();
      setState(() => _error = null);
      _startTimer();
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final challenge = ref.watch(pendingChallengeProvider);
    final phone = challenge?.phone ?? '';
    final shown = phone.length == 10 ? '+91 ${phone.substring(0, 5)} ${phone.substring(5)}' : phone;
    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, Space.section),
        children: [
          PageHeading('Enter the code', subtitle: 'We sent a 6-digit code to $shown.'),
          if (challenge?.demoCode != null) ...[
            const SizedBox(height: 20),
            InfoCard(
              title: 'Demo code: ${challenge!.demoCode}',
              detail: 'This build has no SMS service, so the code is shown here.',
            ),
          ],
          const SizedBox(height: 20),
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  label: 'Verification code',
                  showLabel: false,
                  controller: _code,
                  hint: '••••••',
                  large: true,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  errorText: _error,
                  onChanged: (v) {
                    if (v.length == 6) _verify();
                  },
                ),
                const SizedBox(height: 20),
                AppButton(label: 'Verify', loading: _busy, onPressed: _verify),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: _resendIn > 0
                ? Text('Resend code in $_resendIn s', style: TextStyle(fontSize: 15, color: t.textMuted))
                : DottedLink('Resend code', onTap: _resend),
          ),
        ],
      ),
    );
  }
}
