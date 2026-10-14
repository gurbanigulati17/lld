import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:taxos_ui/taxos_ui.dart';
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
    final t = context.ui;
    final text = Theme.of(context).textTheme;
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final top = MediaQuery.paddingOf(context).top;
    void set(Gstr3bInput Function(Gstr3bInput) fn) =>
        ref.read(gstDraftProvider.notifier).update(fn);

    return ListView(
      padding: EdgeInsets.fromLTRB(
          Space.gutter, top + 16, Space.gutter, Space.section),
      children: [
        PageHeading('GST', subtitle: 'GSTR-3B for ${input.period}'),
        const SizedBox(height: Space.gutter),
        Surface(
          emphasis: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const LabelBar('GSTR-3B · cash payable'),
              const SizedBox(height: Space.gap),
              Text(
                formatInr(r.totalCashOutflow),
                style: text.headlineMedium?.copyWith(color: t.primary),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(label: 'IGST ${formatInr(r.cashPayable.igst)}'),
                  Tag(label: 'CGST ${formatInr(r.cashPayable.cgst)}'),
                  Tag(label: 'SGST ${formatInr(r.cashPayable.sgst)}'),
                  if (r.lateFee > 0)
                    Tag(
                        label: 'Late fee ${formatInr(r.lateFee)}',
                        tone: TagTone.warning),
                  if (r.interest > 0)
                    Tag(
                        label: 'Interest ${formatInr(r.interest)}',
                        tone: TagTone.negative),
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
                  const OutwardSupply(
                      taxableValue: 0, ratePercent: 18, interState: false),
                ])),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
          ),
        ),
        if (input.outwardSupplies.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.gap),
            child: Text(
              'Add each GST rate you billed at this month. Turn on Nil return if you made no sales.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.ui.textMuted),
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
              onRemove: () => set((inp) => copyGstr3b(inp,
                  outwardSupplies: [...inp.outwardSupplies]..removeAt(i))),
            ),
          ),
        const SectionTitle('Input tax credit from GSTR-2B'),
        FieldGroup(children: [
          ..._headRows(input.itcAvailable, (h) => set((i) => copyGstr3b(i, itcAvailable: h))),
          SwitchTile(
            label: 'Nil return',
            helper: 'No outward supplies this period (lower late fee)',
            value: input.isNilReturn,
            onChanged: (v) => set((i) => copyGstr3b(i, isNilReturn: v)),
          ),
          AmountField(
            label: 'Previous-year turnover',
            helper: 'Sets the late-fee cap',
            value: input.annualTurnover,
            onChanged: (v) => set((i) => copyGstr3b(i, annualTurnover: v)),
          ),
        ]),
        const SizedBox(height: Space.gap),
        Surface(
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
                    Text('Filing date',
                        style: text.labelMedium?.copyWith(color: muted)),
                    Text(_fmt(input.filingDate), style: text.titleMedium),
                    Text('Due ${_fmt(input.dueDate)}',
                        style: text.bodySmall?.copyWith(color: muted)),
                  ],
                ),
              ),
              if (r.daysLate > 0)
                Tag(label: '${r.daysLate} days late', tone: TagTone.warning),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Set-off (Rule 88A)', style: text.titleMedium),
        const SizedBox(height: 8),
        Surface(
          child: Column(
            children: [
              for (final l in r.lineItems)
                AmountRow(
                    label: l.label,
                    amount: l.amount,
                    section: l.section,
                    note: l.note,
                    bold: l.code == 'GST.CASH'),
              if (r.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(r.notes.join('\n'),
                        style: text.bodySmall?.copyWith(color: t.positive)),
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

  static String _fmt(DateTime? d) =>
      d == null ? '—' : '${d.day}/${d.month}/${d.year}';
}

class _SupplyCard extends StatelessWidget {
  const _SupplyCard(
      {required this.supply, required this.onChanged, required this.onRemove});
  final OutwardSupply supply;
  final ValueChanged<OutwardSupply> onChanged;
  final VoidCallback onRemove;

  static const _rates = [0.0, 0.25, 3.0, 5.0, 12.0, 18.0, 28.0];

  @override
  Widget build(BuildContext context) {
    return Surface(
      padding: const EdgeInsets.all(Space.card),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Segmented<bool>(
                  center: false,
                  values: const [false, true],
                  labels: const ['Within state', 'Other states'],
                  selected: supply.interState,
                  onChanged: (v) => onChanged(OutwardSupply(
                    taxableValue: supply.taxableValue,
                    ratePercent: supply.ratePercent,
                    interState: v,
                    cessPercent: supply.cessPercent,
                  )),
                ),
              ),
              IconButton(
                  onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ],
          ),
          AmountField(
            label: 'Taxable value',
            value: supply.taxableValue,
            onChanged: (v) => onChanged(OutwardSupply(
              taxableValue: v,
              ratePercent: supply.ratePercent,
              interState: supply.interState,
              cessPercent: supply.cessPercent,
            )),
          ),
          Divider(height: 1, color: context.ui.hairline),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(child: Text('GST rate', style: TextStyle(fontSize: 16, color: context.ui.text))),
                Container(
                  width: 148,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: context.ui.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: context.ui.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<double>(
                      value: _rates.contains(supply.ratePercent) ? supply.ratePercent : 18,
                      isExpanded: true,
                      dropdownColor: context.ui.surface,
                      items: [for (final r in _rates) DropdownMenuItem(value: r, child: Text('${r % 1 == 0 ? r.toInt() : r}%'))],
                      onChanged: (r) => onChanged(OutwardSupply(
                        taxableValue: supply.taxableValue,
                        ratePercent: r!,
                        interState: supply.interState,
                        cessPercent: supply.cessPercent,
                      )),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _headRows(GstHeads heads, ValueChanged<GstHeads> onChanged) => [
      AmountField(
        label: 'IGST',
        value: heads.igst,
        onChanged: (v) => onChanged(GstHeads(igst: v, cgst: heads.cgst, sgst: heads.sgst, cess: heads.cess)),
      ),
      AmountField(
        label: 'CGST',
        value: heads.cgst,
        onChanged: (v) => onChanged(GstHeads(igst: heads.igst, cgst: v, sgst: heads.sgst, cess: heads.cess)),
      ),
      AmountField(
        label: 'SGST',
        value: heads.sgst,
        onChanged: (v) => onChanged(GstHeads(igst: heads.igst, cgst: heads.cgst, sgst: v, cess: heads.cess)),
      ),
    ];

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
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.65);
    final advice = const GstRegistrationAdvisor().advise(GstRegistrationInput(
      aggregateTurnover: _turnover,
      nature: _nature,
      makesInterStateSupplies: _interState,
      sellsThroughEcommerce: _ecommerce,
    ));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Do I need to register?'),
        FieldGroup(children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Segmented<SupplyNature>(
              values: SupplyNature.values,
              labels: const ['Goods', 'Services', 'Both'],
              selected: _nature,
              onChanged: (v) => setState(() => _nature = v),
            ),
          ),
          AmountField(
            label: 'Expected annual turnover',
            value: _turnover,
            onChanged: (v) => setState(() => _turnover = v),
          ),
          SwitchTile(label: 'Inter-state supplies', value: _interState, onChanged: (v) => setState(() => _interState = v)),
          SwitchTile(label: 'Sell via e-commerce', value: _ecommerce, onChanged: (v) => setState(() => _ecommerce = v)),
        ]),
        const SizedBox(height: Space.gap),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Tag(
                    label: advice.registrationRequired
                        ? 'Registration required'
                        : 'Optional',
                    tone: advice.registrationRequired
                        ? TagTone.warning
                        : TagTone.positive,
                  ),
                  if (advice.compositionEligible)
                    const Tag(
                        label: 'Composition eligible', tone: TagTone.primary),
                  if (advice.eInvoicingRequired)
                    const Tag(label: 'e-Invoicing', tone: TagTone.negative),
                ],
              ),
              const SizedBox(height: 8),
              for (final r in advice.reasons)
                Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $r',
                        style: text.bodySmall?.copyWith(color: muted))),
            ],
          ),
        ),
      ],
    );
  }
}
