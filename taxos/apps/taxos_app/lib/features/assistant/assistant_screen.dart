import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glass_ui/glass_ui.dart';
import '../itr/itr_state.dart';
import 'assistant_brain.dart';

/// Chat-style assistant. Answers come from the engine's own numbers via
/// [AssistantBrain]; a language model can later rephrase them server-side
/// but never invents a figure.
class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <({bool me, String text})>[
    (
      me: false,
      text: 'Hi! Ask me why your tax is what it is, which regime or form fits, '
          'what HRA you can claim, or anything about GST. I only quote numbers '
          'the engine computed from your draft.'
    ),
  ];

  static const _suggestions = [
    'Why is my tax this much?',
    'Old or new regime?',
    'Which ITR form?',
    'How much HRA can I claim?',
    'When is the deadline?',
    'Do I owe interest?',
  ];

  void _send(String q) {
    if (q.trim().isEmpty) return;
    final brain = AssistantBrain(
      input: ref.read(itrDraftProvider),
      comparison: ref.read(comparisonProvider),
      form: ref.read(formRecommendationProvider),
    );
    setState(() {
      _messages.add((me: true, text: q.trim()));
      _messages.add((me: false, text: brain.answer(q)));
    });
    _ctrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.glass;
    final text = Theme.of(context).textTheme;
    final top = MediaQuery.paddingOf(context).top;
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.fromLTRB(16, top + 16, 16, 16),
            children: [
              Text('Assistant', style: text.headlineMedium),
              const SizedBox(height: 12),
              for (final m in _messages)
                Align(
                  alignment: m.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GlassPanel(
                        radius: 20,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        tint: m.me ? t.accent.withValues(alpha: 0.18) : null,
                        child: Text(m.text, style: text.bodyMedium),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _suggestions)
                    GestureDetector(
                      onTap: () => _send(s),
                      child: GlassChip(label: s, tone: GlassChipTone.accent),
                    ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
          child: Row(
            children: [
              Expanded(
                child: GlassTextField(
                  label: 'Ask TaxOS',
                  controller: _ctrl,
                  hint: 'Why is my tax this much?',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 10),
              GlassButton(label: 'Send', icon: Icons.arrow_upward, onPressed: () => _send(_ctrl.text)),
            ],
          ),
        ),
      ],
    );
  }
}
