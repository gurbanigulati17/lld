import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import '../../core/auth.dart';
import '../../core/settings.dart';
import 'auth_flow.dart';

/// Sign in: one phone number field and a green pill button.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _phone = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref.read(authRepositoryProvider).requestOtp(_phone.text);
      ref.read(pendingChallengeProvider.notifier).state = challenge;
      if (mounted) context.push(Routes.verify);
    } on AuthFailure catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final config = ref.watch(configProvider);
    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 40, Space.gutter, Space.section),
          children: [
            const Center(child: _Wordmark()),
            const SizedBox(height: 40),
            const PageHeading(
              'Taxes, kar do.',
              subtitle: 'File your income tax and GST returns in minutes. We explain every rupee.',
              center: true,
            ),
            const SizedBox(height: 32),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Mobile number',
                    controller: _phone,
                    hint: '98765 43210',
                    keyboardType: TextInputType.phone,
                    autofillHints: const [AutofillHints.telephoneNumberNational],
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9 +]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    prefix: Text('+91', style: TextStyle(fontSize: 17, color: t.textMuted)),
                    errorText: _error,
                    onSubmitted: (_) => _send(),
                  ),
                  const SizedBox(height: 20),
                  AppButton(label: 'Send code', loading: _busy, onPressed: _send),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              config.hasServer
                  ? 'We will text you a 6-digit code. Standard SMS rates may apply.'
                  : 'Demo build: no SMS is sent. Your code appears on the next screen.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.4),
            ),
            const SizedBox(height: 24),
            Text(
              'Your tax data stays encrypted and is never shared without your consent.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: t.heading, borderRadius: BorderRadius.circular(10)),
          alignment: Alignment.center,
          child: Text.rich(
            TextSpan(children: [
              const TextSpan(text: 'K', style: TextStyle(color: Colors.white)),
              TextSpan(text: '.', style: TextStyle(color: t.tint)),
            ]),
            style: const TextStyle(fontFamily: AppTheme.serif, fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          AppConfig.appName,
          style: TextStyle(fontFamily: AppTheme.serif, fontSize: 26, fontWeight: FontWeight.w700, color: t.heading),
        ),
      ],
    );
  }
}
