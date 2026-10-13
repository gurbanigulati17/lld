import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../core/draft_store.dart';

class GstDraftNotifier extends Notifier<Gstr3bInput> {
  static const _store = DraftStore();

  @override
  Gstr3bInput build() {
    _restore();
    final now = DateTime.now();
    final prev = DateTime(now.year, now.month - 1, 1);
    return Gstr3bInput(
      period: '${prev.year}-${prev.month.toString().padLeft(2, '0')}',
      outwardSupplies: const [],
      dueDate: DateTime(now.year, now.month, 20),
      filingDate: DateTime(now.year, now.month, 20),
    );
  }

  Future<void> _restore() async {
    final json = await _store.loadGst();
    if (json == null) return;
    try {
      state = Gstr3bInput.fromJson(json);
    } catch (_) {}
  }

  void update(Gstr3bInput Function(Gstr3bInput) fn) {
    state = fn(state);
    _store.saveGst(state.toJson());
  }
}

final gstDraftProvider =
    NotifierProvider<GstDraftNotifier, Gstr3bInput>(GstDraftNotifier.new);

final gstr3bResultProvider = Provider<Gstr3bResult>(
  (ref) => const Gstr3bComputer().compute(ref.watch(gstDraftProvider)),
);

Gstr3bInput copyGstr3b(
  Gstr3bInput i, {
  String? period,
  List<OutwardSupply>? outwardSupplies,
  GstHeads? reverseChargeLiability,
  GstHeads? itcAvailable,
  GstHeads? itcReversal,
  GstHeads? openingCreditLedger,
  int? annualTurnover,
  DateTime? dueDate,
  DateTime? filingDate,
  bool? isNilReturn,
}) =>
    Gstr3bInput(
      period: period ?? i.period,
      outwardSupplies: outwardSupplies ?? i.outwardSupplies,
      reverseChargeLiability: reverseChargeLiability ?? i.reverseChargeLiability,
      itcAvailable: itcAvailable ?? i.itcAvailable,
      itcReversal: itcReversal ?? i.itcReversal,
      openingCreditLedger: openingCreditLedger ?? i.openingCreditLedger,
      annualTurnover: annualTurnover ?? i.annualTurnover,
      dueDate: dueDate ?? i.dueDate,
      filingDate: filingDate ?? i.filingDate,
      isNilReturn: isNilReturn ?? i.isNilReturn,
    );
