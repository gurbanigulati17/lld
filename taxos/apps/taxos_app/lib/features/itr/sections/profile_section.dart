import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class ProfileSection extends ConsumerStatefulWidget {
  const ProfileSection({super.key});

  @override
  ConsumerState<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends ConsumerState<ProfileSection> {
  late final TextEditingController _name;
  late final TextEditingController _pan;

  @override
  void initState() {
    super.initState();
    final p = ref.read(itrDraftProvider).profile;
    _name = TextEditingController(text: p.name);
    _pan = TextEditingController(text: p.pan);
  }

  @override
  void dispose() {
    _name.dispose();
    _pan.dispose();
    super.dispose();
  }

  void _update(TaxpayerProfile Function(TaxpayerProfile) fn) {
    ref.read(itrDraftProvider.notifier).update((d) => d.copyWith(profile: fn(d.profile)));
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(itrDraftProvider.select((d) => d.profile));
    final ay = ref.watch(itrDraftProvider.select((d) => d.assessmentYear));
    final panOk = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(p.pan);
    return SectionScaffold(
      title: 'Profile',
      subtitle: 'Your age on 31 March decides the basic exemption; residency decides which incomes are taxed here.',
      children: [
        GlassTextField(
          label: 'Full name (as on PAN)',
          controller: _name,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => _update((p) => TaxpayerProfile(
                name: v,
                pan: p.pan,
                dateOfBirth: p.dateOfBirth,
                ageCategory: p.dateOfBirth == null ? p.ageCategory : null,
                residentialStatus: p.residentialStatus,
              )),
        ),
        GlassTextField(
          label: 'PAN',
          controller: _pan,
          hint: 'ABCDE1234F',
          maxLength: 10,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
            TextInputFormatter.withFunction(
              (o, n) => n.copyWith(text: n.text.toUpperCase()),
            ),
          ],
          helper: p.pan.isEmpty
              ? null
              : panOk
                  ? 'Valid format'
                  : 'PAN is 5 letters, 4 digits, 1 letter',
          onChanged: (v) => _update((p) => TaxpayerProfile(
                name: p.name,
                pan: v,
                dateOfBirth: p.dateOfBirth,
                ageCategory: p.dateOfBirth == null ? p.ageCategory : null,
                residentialStatus: p.residentialStatus,
              )),
        ),
        GlassPanel(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: p.dateOfBirth ?? DateTime(1990, 1, 1),
              firstDate: DateTime(1920),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              _update((p) => TaxpayerProfile(
                    name: p.name,
                    pan: p.pan,
                    dateOfBirth: picked,
                    residentialStatus: p.residentialStatus,
                  ));
            }
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Date of birth', style: Theme.of(context).textTheme.labelMedium),
                    const SizedBox(height: 4),
                    Text(
                      p.dateOfBirth == null
                          ? 'Tap to choose'
                          : '${p.dateOfBirth!.day}/${p.dateOfBirth!.month}/${p.dateOfBirth!.year}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              GlassChip(
                label: switch (p.ageCategoryFor(ay)) {
                  AgeCategory.below60 => 'Below 60',
                  AgeCategory.senior => 'Senior citizen',
                  AgeCategory.superSenior => 'Super senior',
                },
                tone: GlassChipTone.accent,
              ),
            ],
          ),
        ),
        const SectionHeader('Residential status'),
        GlassSegmented<ResidentialStatus>(
          values: ResidentialStatus.values,
          labels: const ['Resident', 'RNOR', 'Non-resident'],
          selected: p.residentialStatus,
          onChanged: (v) => _update((p) => TaxpayerProfile(
                name: p.name,
                pan: p.pan,
                dateOfBirth: p.dateOfBirth,
                ageCategory: p.dateOfBirth == null ? p.ageCategory : null,
                residentialStatus: v,
              )),
        ),
      ],
    );
  }
}
