import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_ui/taxos_ui.dart';

import '../../core/auth.dart';
import '../itr/itr_state.dart';

/// Asked once, right after the first sign-in.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});

  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Enter your name as it appears on your PAN.');
      return;
    }
    ref.read(itrDraftProvider.notifier).update(
          (d) => d.copyWith(
            profile: TaxpayerProfile(
              name: name,
              pan: d.profile.pan,
              dateOfBirth: d.profile.dateOfBirth,
              ageCategory: d.profile.dateOfBirth == null ? d.profile.ageCategory : null,
              residentialStatus: d.profile.residentialStatus,
            ),
          ),
        );
    await ref.read(authProvider.notifier).setName(name);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.gutter, 48, Space.gutter, Space.section),
          children: [
            const PageHeading('What should we call you?', subtitle: 'Use the name on your PAN card, so your return matches.'),
            const SizedBox(height: 24),
            Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: 'Full name',
                    controller: _name,
                    hint: 'As on PAN',
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    errorText: _error,
                    onSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 20),
                  AppButton(label: 'Continue', onPressed: _save),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
