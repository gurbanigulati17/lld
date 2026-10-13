import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import 'package:tax_engine/tax_engine.dart';

import '../itr/widgets.dart';
import 'gst_state.dart';

/// GSTR-3B calculator with Rule 88A set-off, late fee and interest, plus a
/// registration advisor.
class GstScreen extends ConsumerWidget {
  const GstScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(gstDraftProvider);
    final r = ref.watch(gstr3bResultProvider);
    final t = context.glass;
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final top = MediaQuery.paddingOf(context).top;
    void set(Gstr3bInput Function(Gstr3bInput) fn) => ref.read(gstDraftProvider.notifier).update(fn);

    return ListView(
      padding: EdgeInsets.fromLTRB(16, top + 16, 16, 120),
      children: [
        Text('GST', style: text.headlineMedium),
        Text('GSTR-3B for ${input.period}', style: text.bodyMedium?.copyWith(color: muted)),
        const SizedBox(height: 16),
        GlassPanel(
          emphasis: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cash payable', style: text.labelLarge?.copyWith(color: muted)),
              Text(formatInr(r.totalCashOutflow), style: text.displayLarge?.copyWith(fontSize: 40)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlassChip(label: 'IGST ${formatInr(r.cashPayable.igst)}'),
                  GlassChip(label: 'CGST ${formatInr(r.cashPayable.cgst)}'),
                  GlassChip(label: 'SGST ${formatInr(r.cashPayable.sgst)}'),
                  if (r.lateFee > 0) GlassChip(label: 'Late fee ${formatInr(r.lateFee)}', tone: GlassChipTone.warning),
                  if (r.interest > 0) GlassChip(label: 'Interest ${formatInr(r.interest)}', tone: GlassChipTone.negative),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionHeader(
          'Outward supplies',
          trailing: TextButton.icon(
            onPressed: () => set((i) => copyGstr3b(i, outwardSupplies: [
                  ...i.outwardSupplies,
                  const OutwardSupply(taxableValue: 0, ratePercent: 18, interState: false),
                ])),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
        for (var i = 0; i < input.outwardSupplies.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SupplyCard(
              supply: input.outwardSupplies[i],
              onChanged: (s) => set((inp) {
                final list = [...inp.outwardSupplies];
                list[i] = s;
                return copyGstr3b(inp, outwardSupplies: list);
              }),
              onRemove: () => set((inp) => copyGstr3b(inp, outwardSupplies: [...inp.outwardSupplies]..removeAt(i))),
            ),
          ),
        const SectionHeader('Input tax credit (from GSTR-2B)'),
        _HeadsEditor(
          heads: input.itcAvailable,
          onChanged: (h) => set((i) => copyGstr3b(i, itcAvailable: h)),
        ),
        const SizedBox(height: 10),
        GlassSwitchTile(
          label: 'Nil return',
          helper: 'No outward supplies this period (lower late fee)',
          value: input.isNilReturn,
          onChanged: (v) => set((i) => copyGstr3b(i, isNilReturn: v)),
        ),
        const SizedBox(height: 10),
        GlassAmountField(
          label: 'Previous-year turnover',
          helper: 'Drives the late-fee cap',
          value: input.annualTurnover,
          onChanged: (v) => set((i) => copyGstr3b(i, annualTurnover: v)),
        ),
        const SizedBox(height: 10),
        GlassPanel(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: input.filingDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2035),
            );
            if (picked != null) set((i) => copyGstr3b(i, filingDate: picked));
          },
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Filing date', style: text.labelMedium?.copyWith(color: muted)),
                    Text(_fmt(input.filingDate), style: text.titleMedium),
                    Text('Due ${_fmt(input.dueDate)}', style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              if (r.daysLate > 0) GlassChip(label: '${r.daysLate} days late', tone: GlassChipTone.warning),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Set-off (Rule 88A)', style: text.titleMedium),
        const SizedBox(height: 8),
        GlassPanel(
          child: Column(
            children: [
              for (final l in r.lineItems)
                AmountRow(label: l.label, amount: l.amount, section: l.section, note: l.note, bold: l.code == 'GST.CASH'),
              if (r.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(r.notes.join('\n'), style: text.bodySmall?.copyWith(color: t.positive)),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const _RegistrationAdvisor(),
      ],
    );
  }

  static String _fmt(DateTime? d) => d == null ? '—' : '${d.day}/${d.month}/${d.year}';
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard({required this.supply, required this.onChanged, required this.onRemove});
  final OutwardSupply supply;
  final ValueChanged<OutwardSupply> onChanged;
  final VoidCallback onRemove;

  static const _rates = [0.0, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0];

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: GlassSegmented<bool>(
                  values: const [false, true],
                  labels: const ['Intra-state', 'Inter-state'],
                  selected: supply.interState,
                  onChanged: (v) => onChanged(OutwardSupply(
                    taxableValue: supply.taxableValue,
                    ratePercent: supply.ratePercent,
                    interState: v,
                    cessPercent: supply.cessPercent,
                  )),
                ),
              ),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: GlassAmountField(
                  label: 'Taxable value',
                  value: supply.taxableValue,
                  onChanged: (v) => onChanged(OutwardSupply(
                    taxableValue: v,
                    ratePercent: supply.ratePercent,
                    interState: supply.interState,
                    cessPercent: supply.cessPercent,
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: GlassPanel(
                  radius: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: _rates.contains(supply.ratePercent) ? supply.ratePercent : 18,
                      isExpanded: true,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      items: [for (final r in _rates) DropdownMenuItem(value: r, child: Text('$r%'))],
                      onChanged: (r) => onChanged(OutwardSupply(
                        taxableValue: supply.taxableValue,
                        ratePercent: r!,
                        interState: supply.interState,
                        cessPercent: supply.cessPercent,
                      )),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeadsEditor extends StatelessWidget {
  const _HeadsEditor({required this.heads, required this.onChanged});
  final GstHeads heads;
  final ValueChanged<GstHeads> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassAmountField(
            label: 'IGST',
            value: heads.igst,
            onChanged: (v) => onChanged(GstHeads(igst: v, cgst: heads.cgst, sgst: heads.sgst, cess: heads.cess)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassAmountField(
            label: 'CGST',
            value: heads.cgst,
            onChanged: (v) => onChanged(GstHeads(igst: heads.igst, cgst: v, sgst: heads.sgst, cess: heads.cess)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GlassAmountField(
            label: 'SGST',
            value: heads.sgst,
            onChanged: (v) => onChanged(GstHeads(igst: heads.igst, cgst: heads.cgst, sgst: v, cess: heads.cess)),
          ),
        ),
      ],
    );
  }
}

class _RegistrationAdvisor extends StatefulWidget {
  const _RegistrationAdvisor();

  @override
  State<_RegistrationAdvisor> createState() => _RegistrationAdvisorState();
}

class _RegistrationAdvisorState extends State<_RegistrationAdvisor> {
  int _turnover = 0;
  SupplyNature _nature = SupplyNature.services;
  bool _interState = false;
  bool _ecommerce = false;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final advice = const GstRegistrationAdvisor().advise(GstRegistrationInput(
      aggregateTurnover: _turnover,
      nature: _nature,
      makesInterStateSupplies: _interState,
      sellsThroughEcommerce: _ecommerce,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Do I need to register?', style: text.titleMedium),
        const SizedBox(height: 8),
        GlassAmountField(
          label: 'Expected annual turnover',
          value: _turnover,
          onChanged: (v) => setState(() => _turnover = v),
        ),
        const SizedBox(height: 10),
        GlassSegmented<SupplyNature>(
          values: SupplyNature.values,
          labels: const ['Goods', 'Services', 'Both'],
          selected: _nature,
          onChanged: (v) => setState(() => _nature = v),
        ),
        const SizedBox(height: 10),
        GlassSwitchTile(label: 'Inter-state supplies', value: _interState, onChanged: (v) => setState(() => _interState = v)),
        const SizedBox(height: 10),
        GlassSwitchTile(label: 'Sell via e-commerce', value: _ecommerce, onChanged: (v) => setState(() => _ecommerce = v)),
        const SizedBox(height: 10),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GlassChip(
                    label: advice.registrationRequired ? 'Registration required' : 'Optional',
                    tone: advice.registrationRequired ? GlassChipTone.warning : GlassChipTone.positive,
                  ),
                  if (advice.compositionEligible) const GlassChip(label: 'Composition eligible', tone: GlassChipTone.accent),
                  if (advice.eInvoicingRequired) const GlassChip(label: 'e-Invoicing', tone: GlassChipTone.negative),
                ],
              ),
              const SizedBox(height: 8),
              for (final r in advice.reasons)
                Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('• $r', style: text.bodySmall?.copyWith(color: muted))),
            ],
          ),
        ),
      ],
    );
  }
}
