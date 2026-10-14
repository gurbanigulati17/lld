import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tax_engine/tax_engine.dart';

import '../../core/auth.dart';
import '../../core/draft_store.dart';

/// The ITR draft the user is editing. Every edit recomputes both regimes
/// synchronously (the engine is pure and fast) and persists the draft.
class ItrDraftNotifier extends Notifier<ItrInput> {
  static const _store = DraftStore();

  @override
  ItrInput build() {
    // A new person signing in on this phone starts from a clean draft.
    ref.listen(authProvider, (prev, next) {
      if (prev?.valueOrNull != null && next.valueOrNull == null) ref.invalidateSelf();
    });
    _loaded = false;
    _pending.clear();
    _restore();
    return ItrInput(
      assessmentYear: AssessmentYear.latest,
      profile: const TaxpayerProfile(ageCategory: AgeCategory.below60),
    );
  }

  // Edits made before the saved draft has loaded are replayed on top of it,
  // so neither the draft nor the edit is lost.
  final _pending = <ItrInput Function(ItrInput)>[];
  var _loaded = false;

  Future<void> _restore() async {
    final json = await _store.loadItr();
    ItrInput? saved;
    if (json != null) {
      try {
        saved = ItrInput.fromJson(json);
      } catch (_) {
        // Corrupt or outdated draft: keep the fresh one.
      }
    }
    _loaded = true;
    if (saved != null) state = _pending.fold(saved, (s, fn) => fn(s));
    if (_pending.isNotEmpty) _store.saveItr(state.toJson());
    _pending.clear();
  }

  void update(ItrInput Function(ItrInput) fn) {
    state = fn(state);
    if (!_loaded) {
      _pending.add(fn);
      return;
    }
    _store.saveItr(state.toJson());
  }

  void reset() => update(
        (_) => ItrInput(
          assessmentYear: AssessmentYear.latest,
          profile: const TaxpayerProfile(ageCategory: AgeCategory.below60),
        ),
      );
}

final itrDraftProvider =
    NotifierProvider<ItrDraftNotifier, ItrInput>(ItrDraftNotifier.new);

/// Regime the user wants to view. `null` means "the recommended one".
final selectedRegimeProvider = StateProvider<TaxRegime?>((ref) => null);

final comparisonProvider = Provider<RegimeComparison>((ref) {
  final input = ref.watch(itrDraftProvider);
  return const ItrComputer().compare(input);
});

final activeComputationProvider = Provider<ItrComputation>((ref) {
  final cmp = ref.watch(comparisonProvider);
  final sel = ref.watch(selectedRegimeProvider);
  if (sel == null) return cmp.best;
  return sel == TaxRegime.oldRegime ? cmp.oldRegime : cmp.newRegime;
});

final formRecommendationProvider = Provider<FormRecommendation>((ref) {
  final input = ref.watch(itrDraftProvider);
  final best = ref.watch(comparisonProvider).best;
  return selectForm(input, totalIncome: best.totalIncome);
});

/// Which sections have data, for the wizard checklist.
class SectionStatus {
  const SectionStatus(
      {required this.id,
      required this.title,
      required this.done,
      required this.summary});
  final String id;
  final String title;
  final bool done;
  final String summary;
}

final sectionStatusProvider = Provider<List<SectionStatus>>((ref) {
  final d = ref.watch(itrDraftProvider);
  final c = ref.watch(activeComputationProvider);
  String inr(int v) => formatInr(v);
  return [
    SectionStatus(
      id: 'profile',
      title: 'Profile',
      done: d.profile.name.isNotEmpty && d.profile.pan.length == 10,
      summary: d.profile.name.isEmpty
          ? 'Name, PAN, date of birth'
          : [d.profile.name, d.profile.pan].where((s) => s.isNotEmpty).join(' · '),
    ),
    SectionStatus(
      id: 'salary',
      title: 'Salary',
      done: d.salary != null && d.salary!.grossSalary > 0,
      summary: d.salary == null
          ? 'Form 16 details'
          : 'Taxable ${inr(c.incomeFromSalary)}',
    ),
    SectionStatus(
      id: 'houseProperty',
      title: 'House property',
      done: d.houseProperties.isNotEmpty,
      summary: d.houseProperties.isEmpty
          ? 'Home loan, rent received'
          : '${d.houseProperties.length} propert${d.houseProperties.length == 1 ? 'y' : 'ies'} · ${inr(c.incomeFromHouseProperty)}',
    ),
    SectionStatus(
      id: 'capitalGains',
      title: 'Capital gains',
      done: d.capitalGains.isNotEmpty,
      summary: d.capitalGains.isEmpty
          ? 'Shares, mutual funds, property'
          : '${d.capitalGains.length} entries · ${inr(c.incomeFromCapitalGains)}',
    ),
    SectionStatus(
      id: 'business',
      title: 'Business / profession',
      done: d.business != null,
      summary: d.business == null
          ? 'Freelance, presumptive, books'
          : inr(c.incomeFromBusiness),
    ),
    SectionStatus(
      id: 'otherSources',
      title: 'Other sources',
      done: d.otherSources.total > 0,
      summary: d.otherSources.total == 0
          ? 'Interest, dividends'
          : inr(c.incomeFromOtherSources),
    ),
    SectionStatus(
      id: 'deductions',
      title: 'Deductions',
      done: d.deductions.section80C > 0 ||
          d.deductions.section80D > 0 ||
          d.deductions.section80CCD1B > 0,
      summary: c.chapterVIADeductions == 0
          ? '80C, 80D, NPS'
          : 'Allowed ${inr(c.chapterVIADeductions)}',
    ),
    SectionStatus(
      id: 'taxesPaid',
      title: 'Taxes paid',
      done: c.tdsAndTcs + c.advanceTaxPaid + c.selfAssessmentTaxPaid > 0,
      summary:
          'TDS, advance tax · ${inr(c.tdsAndTcs + c.advanceTaxPaid + c.selfAssessmentTaxPaid)}',
    ),
  ];
});
