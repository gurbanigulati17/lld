import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../app/router.dart';
import '../../core/api_client.dart';
import '../../core/settings.dart';
import '../itr/itr_state.dart';

/// "Almost ready to file": checklist, payment, submit.
///
/// Submission goes through the Income Tax Department's e-return
/// intermediary (ERI) service from the server. Until Kardo is registered as
/// an ERI, the submit step explains that instead of pretending to file.
class FilingScreen extends ConsumerStatefulWidget {
  const FilingScreen({super.key});

  @override
  ConsumerState<FilingScreen> createState() => _FilingScreenState();
}

class _FilingScreenState extends ConsumerState<FilingScreen> {
  bool _verifying = false;
  bool _paid = false;
  ServerVerification? _verification;
  String? _error;

  Future<void> _verify() async {
    final config = ref.read(configProvider);
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      final api = TaxosApiClient(baseUrl: config.apiBaseUrl);
      final v = await api.verifyItr(ref.read(itrDraftProvider));
      setState(() => _verification = v);
    } catch (_) {
      setState(() => _error = 'Could not reach Kardo. Your figures on this phone are unchanged.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _submit() async {
    final t = context.ui;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Your return is ready', style: Theme.of(ctx).textTheme.titleLarge),
        content: Text(
          'Direct filing with the Income Tax Department switches on once Kardo is registered as an e-return '
          'intermediary. Your return is saved on this phone and nothing has been submitted yet.',
          style: TextStyle(fontSize: 16, height: 1.4, color: t.text),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(itrDraftProvider);
    final cmp = ref.watch(comparisonProvider);
    final best = cmp.best;
    final form = ref.watch(formRecommendationProvider);
    final config = ref.watch(configProvider);
    final t = context.ui;
    final rp = ItrRulePack.forYear(draft.assessmentYear);
    final today = DateTime.now();
    final belated = today.isAfter(rp.dueDateNonAudit);
    final lastDate = belated ? draft.assessmentYear.belatedReturnLastDate : rp.dueDateNonAudit;
    final mustPay = best.netPayable > 0;

    final panOk = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(draft.profile.pan) && draft.profile.name.isNotEmpty;
    final hasIncome = best.grossTotalIncome > 0;
    final noAudit = draft.business?.kind != BusinessIncomeKind.regular;
    final serverOk = _verification != null && _verification!.totalTaxLiability == best.totalTaxLiability;

    final checks = <_Check>[
      _Check(
        'Your details',
        panOk ? '${draft.profile.pan} · ${draft.profile.name}' : 'Add your name and PAN',
        panOk,
        onTap: panOk ? null : () => context.push(Routes.profile),
      ),
      _Check(
        'Your income',
        hasIncome ? 'Total income ${formatInr(best.totalIncome)}' : 'Add salary or other income',
        hasIncome,
        onTap: hasIncome ? null : () => context.go(Routes.itr),
      ),
      _Check(
        'Regime and form',
        '${cmp.recommended == TaxRegime.newRegime ? 'New' : 'Old'} regime${cmp.savings > 0 ? ' saves ${formatInr(cmp.savings)}' : ''} · ${form.form.label.split(' ').first}',
        true,
      ),
      if (!noAudit)
        _Check('Tax audit', 'Books-of-account cases above the s.44AB limit need a chartered accountant to sign.', false),
      if (config.hasServer)
        _Check(
          'Double-checked',
          _verification == null
              ? 'Run the same calculation on our server'
              : serverOk
                  ? 'Our server got the same ${formatInr(_verification!.totalTaxLiability)}'
                  : 'Server says ${formatInr(_verification!.totalTaxLiability)}. Please contact support.',
          serverOk,
        ),
      if (mustPay)
        _Check('Pay ${formatInr(best.netPayable)}', 'Self-assessment tax via Challan 280', _paid, toggle: (v) => setState(() => _paid = v)),
    ];
    final remaining = checks.where((c) => !c.ok).length;
    final ready = remaining == 0;

    return AppScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.gutter, 4, Space.gutter, Space.section),
        children: [
          PageHeading(
            ready ? 'Ready to file' : 'Almost ready to file',
            subtitle: ready ? 'Everything checks out.' : '$remaining ${remaining == 1 ? 'step' : 'steps'} left before you submit.',
          ),
          const SizedBox(height: Space.gutter),
          InfoCard(
            title: belated ? 'Belated return, last date ${_date(lastDate)}' : 'Due by ${_date(lastDate)}',
            detail: belated
                ? 'After that, only an updated return with extra tax is possible.'
                : '${lastDate.difference(today).inDays} days left to file on time.',
          ),
          const SizedBox(height: Space.gap),
          Surface(
            padding: const EdgeInsets.symmetric(horizontal: Space.gutter, vertical: 4),
            child: Column(
              children: [
                for (var i = 0; i < checks.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: t.hairline),
                  _CheckRow(check: checks[i]),
                ],
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: Space.gap),
            Text(_error!, style: TextStyle(fontSize: 14, color: t.negative)),
          ],
          const SizedBox(height: Space.gutter),
          Text(
            'We submit through the Income Tax Department\'s e-return intermediary service. You then e-verify with '
            'an Aadhaar OTP. Your PAN and bank details stay encrypted in India.',
            style: TextStyle(fontSize: 13, color: t.textMuted, height: 1.5),
          ),
          const SizedBox(height: Space.section),
          if (config.hasServer && !serverOk) ...[
            AppButton(label: 'Double-check', style: AppButtonStyle.secondary, loading: _verifying, onPressed: _verify),
            const SizedBox(height: Space.gap),
          ],
          AppButton(label: 'Submit and e-verify', onPressed: ready ? _submit : null),
          const SizedBox(height: 8),
          Center(
            child: DottedLink('See how we got your tax', onTap: () => context.push(Routes.computation)),
          ),
        ],
      ),
    );
  }

  static String _date(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }
}

class _Check {
  const _Check(this.title, this.detail, this.ok, {this.onTap, this.toggle});
  final String title;
  final String detail;
  final bool ok;
  final VoidCallback? onTap;

  /// For steps only the user can confirm, such as paying the tax.
  final ValueChanged<bool>? toggle;
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({required this.check});
  final _Check check;

  @override
  Widget build(BuildContext context) {
    final t = context.ui;
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: check.ok ? t.primary : Colors.transparent,
              border: check.ok ? null : Border.all(color: t.border, width: 1.5),
            ),
            child: check.ok ? Icon(Icons.check, size: 15, color: t.onPrimary) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(check.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: t.text)),
                Text(check.detail, style: TextStyle(fontSize: 14, color: t.textMuted, height: 1.35)),
              ],
            ),
          ),
          if (check.toggle != null)
            Switch.adaptive(value: check.ok, onChanged: check.toggle)
          else if (check.onTap != null)
            Icon(Icons.chevron_right, color: t.textMuted),
        ],
      ),
    );
    return Semantics(
      label: check.ok ? 'Done' : 'To do',
      child: check.onTap == null ? row : InkWell(onTap: check.onTap, child: row),
    );
  }
}
