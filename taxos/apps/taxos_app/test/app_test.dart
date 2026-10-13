import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_app/app/app.dart';
import 'package:taxos_app/features/assistant/assistant_brain.dart';
import 'package:taxos_app/features/itr/itr_state.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Widget app() => const ProviderScope(child: TaxosApp());

  testWidgets('dashboard renders with a zero estimate on a fresh draft', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    expect(find.text('Estimated tax'), findsOneWidget);
    expect(find.text('₹0'), findsWidgets);
  });

  testWidgets('entering a salary updates the live liability', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const TaxosApp(),
    ));
    await tester.pump();

    container.read(itrDraftProvider.notifier).update(
          (d) => d.copyWith(salary: const SalaryIncome(basic: 2000000)),
        );
    await tester.pump();

    final cmp = container.read(comparisonProvider);
    // ₹20L basic − ₹75k std = ₹19.25L; new regime tax 1,85,000 + 4% = 1,92,400.
    expect(cmp.newRegime.totalTaxLiability, 192400);
    expect(find.text(formatInr(cmp.best.totalTaxLiability)), findsWidgets);
  });

  testWidgets('ITR tab lists all eight sections', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());
    await tester.pump();
    await tester.tap(find.text('ITR'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Income tax return'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Taxes paid'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Taxes paid'), findsOneWidget);
  });

  test('assistant answers from engine numbers', () {
    final input = ItrInput(
      assessmentYear: AssessmentYear.ay2026_27,
      profile: const TaxpayerProfile(ageCategory: AgeCategory.below60),
      salary: const SalaryIncome(basic: 1500000),
    );
    final cmp = const ItrComputer().compare(input);
    final brain = AssistantBrain(
      input: input,
      comparison: cmp,
      form: selectForm(input, totalIncome: cmp.best.totalIncome),
    );
    expect(brain.answer('Old or new regime?'), contains(formatInr(cmp.newRegime.totalTaxLiability)));
    expect(brain.answer('Which ITR form?'), contains('ITR-1'));
    expect(brain.answer('Do I owe interest?'), contains('interest'));
  });
}
