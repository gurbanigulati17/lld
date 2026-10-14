import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../core/auth.dart';
import '../../core/draft_store.dart';

class GstDraftNotifier extends Notifier<Gstr3bInput> {
  static const _store = DraftStore();

  @override
  Gstr3bInput build() {
    ref.listen(authProvider, (prev, next) {
      if (prev?.valueOrNull != null && next.valueOrNull == null) ref.invalidateSelf();
    });
    _loaded = false;
    _pending.clear();
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

  // Edits made before the saved draft has loaded are replayed on top of it,
  // so neither the draft nor the edit is lost.
  final _pending = <Gstr3bInput Function(Gstr3bInput)>[];
  var _loaded = false;

  Future<void> _restore() async {
    final json = await _store.loadGst();
    Gstr3bInput? saved;
    if (json != null) {
      try {
        saved = Gstr3bInput.fromJson(json);
      } catch (_) {
        // Corrupt or outdated draft: keep the fresh one.
      }
    }
    _loaded = true;
    if (saved != null) state = _pending.fold(saved, (s, fn) => fn(s));
    if (_pending.isNotEmpty) _store.saveGst(state.toJson());
    _pending.clear();
  }

  void update(Gstr3bInput Function(Gstr3bInput) fn) {
    state = fn(state);
    if (!_loaded) {
      _pending.add(fn);
      return;
    }
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
      reverseChargeLiability:
          reverseChargeLiability ?? i.reverseChargeLiability,
      itcAvailable: itcAvailable ?? i.itcAvailable,
      itcReversal: itcReversal ?? i.itcReversal,
      openingCreditLedger: openingCreditLedger ?? i.openingCreditLedger,
      annualTurnover: annualTurnover ?? i.annualTurnover,
      dueDate: dueDate ?? i.dueDate,
      filingDate: filingDate ?? i.filingDate,
      isNilReturn: isNilReturn ?? i.isNilReturn,
    );
