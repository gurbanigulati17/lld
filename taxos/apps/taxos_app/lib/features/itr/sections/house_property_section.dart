import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class HousePropertySection extends ConsumerWidget {
  const HousePropertySection({super.key});

  void _setAt(WidgetRef ref, int i, HouseProperty hp) {
    ref.read(itrDraftProvider.notifier).update((d) {
      final list = [...d.houseProperties];
      list[i] = hp;
      return d.copyWith(houseProperties: list);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final props = ref.watch(itrDraftProvider.select((d) => d.houseProperties));
    final text = Theme.of(context).textTheme;
    return SectionScaffold(
      title: 'House property',
      subtitle:
          'Self-occupied: home-loan interest up to ₹2L (old regime). Let-out: rent less municipal tax, 30% standard deduction and full interest.',
      children: [
        for (var i = 0; i < props.length; i++)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child:
                            Text('Property ${i + 1}', style: text.titleMedium)),
                    IconButton(
                      onPressed: () =>
                          ref.read(itrDraftProvider.notifier).update(
                                (d) => d.copyWith(
                                  houseProperties: [...d.houseProperties]
                                    ..removeAt(i),
                                ),
                              ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                Segmented<HousePropertyType>(
                  values: const [
                    HousePropertyType.selfOccupied,
                    HousePropertyType.letOut
                  ],
                  labels: const ['Self-occupied', 'Let out'],
                  selected: props[i].type == HousePropertyType.deemedLetOut
                      ? HousePropertyType.letOut
                      : props[i].type,
                  onChanged: (v) => _setAt(ref, i, _copy(props[i], type: v)),
                ),
                const SizedBox(height: 12),
                if (props[i].type != HousePropertyType.selfOccupied) ...[
                  AmountField(
                    label: 'Annual rent received',
                    value: props[i].annualRent,
                    onChanged: (v) =>
                        _setAt(ref, i, _copy(props[i], annualRent: v)),
                  ),
                  const SizedBox(height: 12),
                  AmountField(
                    label: 'Municipal taxes paid',
                    value: props[i].municipalTaxesPaid,
                    onChanged: (v) =>
                        _setAt(ref, i, _copy(props[i], municipalTaxesPaid: v)),
                  ),
                  const SizedBox(height: 12),
                ],
                AmountField(
                  label: 'Home loan interest this year',
                  helper: 's.24(b)',
                  value: props[i].interestOnLoan,
                  onChanged: (v) =>
                      _setAt(ref, i, _copy(props[i], interestOnLoan: v)),
                ),
                const SizedBox(height: 12),
                AmountField(
                  label: 'Pre-construction interest (1/5th)',
                  value: props[i].preConstructionInterest,
                  onChanged: (v) => _setAt(
                      ref, i, _copy(props[i], preConstructionInterest: v)),
                ),
              ],
            ),
          ),
        AppButton(
          label: 'Add property',
          icon: Icons.add,
          style: AppButtonStyle.secondary,
          expand: true,
          onPressed: () => ref.read(itrDraftProvider.notifier).update(
                (d) => d.copyWith(houseProperties: [
                  ...d.houseProperties,
                  const HouseProperty(type: HousePropertyType.selfOccupied),
                ]),
              ),
        ),
      ],
    );
  }

  static HouseProperty _copy(
    HouseProperty h, {
    HousePropertyType? type,
    int? annualRent,
    int? municipalTaxesPaid,
    int? interestOnLoan,
    int? preConstructionInterest,
  }) =>
      HouseProperty(
        type: type ?? h.type,
        annualRent: annualRent ?? h.annualRent,
        municipalTaxesPaid: municipalTaxesPaid ?? h.municipalTaxesPaid,
        interestOnLoan: interestOnLoan ?? h.interestOnLoan,
        preConstructionInterest:
            preConstructionInterest ?? h.preConstructionInterest,
      );
}
