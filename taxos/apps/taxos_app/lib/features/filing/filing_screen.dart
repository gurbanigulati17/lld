import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../core/api_client.dart';
import '../../core/settings.dart';
import '../itr/itr_state.dart';

/// Readiness checklist, server verification, and the e-filing hand-off.
///
/// Actual submission goes through the Income Tax Department's e-Return
/// Intermediary (ERI) APIs from the API service, never from the device, so
/// the button here is a stub until ERI credentials are provisioned.
class FilingScreen extends ConsumerStatefulWidget {
  const FilingScreen({super.key});

  @override
  ConsumerState<FilingScreen> createState() => _FilingScreenState();
}

class _FilingScreenState extends ConsumerState<FilingScreen> {
  bool _verifying = false;
  ServerVerification? _verification;
  String? _error;

  Future<void> _verify() async {
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final api =
          TaxosApiClient(baseUrl: ref.read(settingsProvider).apiBaseUrl);
      final v = await api.verifyItr(ref.read(itrDraftProvider));
      setState(() => _verification = v);
    } catch (e) {
      setState(() => _error = 'Could not reach the TaxOS service: $e');
    } finally {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(itrDraftProvider);
    final cmp = ref.watch(comparisonProvider);
    final best = cmp.best;
    final form = ref.watch(formRecommendationProvider);
    final sections = ref.watch(sectionStatusProvider);
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);

    final checks = <({String label, bool ok, String detail})>[
      (
        label: 'PAN and name',
        ok: RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(draft.profile.pan) &&
            draft.profile.name.isNotEmpty,
        detail: 'Needed to prefill and e-verify',
      ),
      (
        label: 'At least one income source',
        ok: best.grossTotalIncome > 0,
        detail: 'Salary, property, gains, business or other sources',
      ),
      (
        label: 'Regime chosen',
        ok: true,
        detail:
            '${cmp.recommended == TaxRegime.newRegime ? 'New' : 'Old'} regime (recommended) saves ${formatInr(cmp.savings)}',
      ),
      (
        label: 'Form selected',
        ok: true,
        detail: form.form.label,
      ),
      (
        label: 'Server verification',
        ok: _verification != null &&
            _verification!.totalTaxLiability == best.totalTaxLiability,
        detail: _verification == null
            ? 'Run the same engine on the server before filing'
            : _verification!.totalTaxLiability == best.totalTaxLiability
                ? 'Server agrees: ${formatInr(_verification!.totalTaxLiability)} (engine ${_verification!.engineVersion})'
                : 'Mismatch! Server says ${formatInr(_verification!.totalTaxLiability)}',
      ),
      (
        label: 'No tax audit needed',
        ok: draft.business?.kind != BusinessIncomeKind.regular,
        detail: 'Books-of-account cases above s.44AB limits need a CA sign-off',
      ),
    ];
    final ready = checks.every((c) => c.ok);
    final filled = sections.where((s) => s.done).length;

    return AppScaffold(
      title: 'Review and file',
      body: ListView(
        padding: EdgeInsets.fromLTRB(Space.gutter, 8, Space.gutter, 32),
        children: [
          Surface(
            emphasis: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${draft.assessmentYear.label} · ${form.form.label}',
                    style: text.labelLarge?.copyWith(color: muted)),
                const SizedBox(height: 4),
                Text(
                  best.isRefund
                      ? 'Refund ${formatInr(best.refundDue)}'
                      : 'Pay ${formatInr(best.netPayable)}',
                  style: text.headlineMedium
                      ?.copyWith(color: best.isRefund ? t.positive : null),
                ),
                Text('$filled of ${sections.length} sections filled',
                    style: text.bodySmall?.copyWith(color: muted)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Readiness', style: text.titleMedium),
          const SizedBox(height: 8),
          for (final c in checks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Surface(
                radius: 18,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      c.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: c.ok ? t.positive : muted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.label, style: text.titleSmall),
                          Text(c.detail,
                              style: text.bodySmall?.copyWith(color: muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(_error!,
                  style: text.bodySmall?.copyWith(color: t.negative)),
            ),
          AppButton(
            label: 'Verify with server',
            icon: Icons.cloud_done_outlined,
            style: AppButtonStyle.secondary,
            expand: true,
            loading: _verifying,
            onPressed: _verify,
          ),
          const SizedBox(height: 10),
          AppButton(
            label: 'Submit via e-filing (ERI)',
            icon: Icons.send,
            expand: true,
            onPressed: ready
                ? () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'ERI submission is wired on the server side and needs ITD credentials. '
                            'Your return JSON is ready; export it from the API service.'),
                      ),
                    )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            'Filing runs through the Income Tax Department\'s e-Return Intermediary APIs from our servers, '
            'followed by Aadhaar-OTP e-verification. Your PAN and bank details are encrypted at rest and '
            'never leave India.',
            style: text.bodySmall?.copyWith(color: muted),
          ),
        ],
      ),
    );
  }
}
