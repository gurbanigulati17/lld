import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr_state.dart';
import '../widgets.dart';

class CapitalGainsSection extends ConsumerWidget {
  const CapitalGainsSection({super.key});

  static const _labels = {
    CapitalGainType.stcg111A: 'Short-term · listed equity (20%)',
    CapitalGainType.stcgOther: 'Short-term · other (slab rate)',
    CapitalGainType.ltcg112A: 'Long-term · listed equity (12.5% above ₹1.25L)',
    CapitalGainType.ltcgOther: 'Long-term · other assets (12.5%)',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gains = ref.watch(itrDraftProvider.select((d) => d.capitalGains));
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6);
    return SectionScaffold(
      title: 'Capital gains',
      subtitle: 'Enter the net gain per bucket (negative for a loss). The engine sets off losses in the order the Act allows and applies the ₹1.25L equity exemption.',
      children: [
        for (var i = 0; i < gains.length; i++)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<CapitalGainType>(
                          value: gains[i].type,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: text.titleSmall,
                          items: [
                            for (final t in CapitalGainType.values)
                              DropdownMenuItem(value: t, child: Text(_labels[t]!)),
                          ],
                          onChanged: (t) => _setAt(ref, i, CapitalGain(type: t!, gain: gains[i].gain, description: gains[i].description)),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(itrDraftProvider.notifier).update(
                            (d) => d.copyWith(capitalGains: [...d.capitalGains]..removeAt(i)),
                          ),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _SignedAmountField(
                  value: gains[i].gain,
                  onChanged: (v) => _setAt(ref, i, CapitalGain(type: gains[i].type, gain: v, description: gains[i].description)),
                ),
                const SizedBox(height: 6),
                Text('Import from broker P&L (Zerodha, Groww, Upstox) coming in the documents module.',
                    style: text.bodySmall?.copyWith(color: muted)),
              ],
            ),
          ),
        AppButton(
          label: 'Add gain or loss',
          icon: Icons.add,
          style: AppButtonStyle.secondary,
          expand: true,
          onPressed: () => ref.read(itrDraftProvider.notifier).update(
                (d) => d.copyWith(capitalGains: [
                  ...d.capitalGains,
                  const CapitalGain(type: CapitalGainType.ltcg112A, gain: 0),
                ]),
              ),
        ),
      ],
    );
  }

  static void _setAt(WidgetRef ref, int i, CapitalGain g) {
    ref.read(itrDraftProvider.notifier).update((d) {
      final list = [...d.capitalGains];
      list[i] = g;
      return d.copyWith(capitalGains: list);
    });
  }
}

/// Amount field with a gain/loss toggle so users never type a minus sign.
class _SignedAmountField extends StatelessWidget {
  const _SignedAmountField({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isLoss = value < 0;
    return Column(
      children: [
        Segmented<bool>(
          values: const [false, true],
          labels: const ['Gain', 'Loss'],
          selected: isLoss,
          onChanged: (loss) => onChanged(loss ? -value.abs() : value.abs()),
        ),
        const SizedBox(height: 10),
        AmountField(
          label: isLoss ? 'Loss amount' : 'Gain amount',
          value: value.abs(),
          onChanged: (v) => onChanged(isLoss ? -v : v),
        ),
      ],
    );
  }
}
