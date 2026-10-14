import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tax_engine/tax_engine.dart';
import 'package:taxos_app/app/app.dart';
import 'package:taxos_app/core/auth.dart';
import 'package:taxos_app/features/assistant/assistant_brain.dart';
import 'package:taxos_app/features/itr/itr_state.dart';

String _session({String name = 'Gurbani Gulati'}) => jsonEncode(AuthSession(
      phone: '9876543210',
      token: 'demo-token',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      name: name,
      demo: true,
    ).toJson());

Future<void> _phone(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('signed out: welcome screen asks for a phone number', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(const ProviderScope(child: TaxosApp()));
    await _settle(tester);
    expect(find.text('Taxes, kar do.'), findsOneWidget);
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('demo sign-in: phone, code, name, then home', (tester) async {
    await _phone(tester);
    await tester.pumpWidget(const ProviderScope(child: TaxosApp()));
    await _settle(tester);

    await tester.tap(find.text('Send code'));
    await _settle(tester);
    expect(find.text('Enter a 10-digit Indian mobile number.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '98765 43210');
    await tester.tap(find.text('Send code'));
    await _settle(tester);
    expect(find.text('Enter the code'), findsOneWidget);

    final demo = tester.widget<Text>(find.textContaining('Demo code: ')).data!;
    final code = demo.replaceAll(RegExp(r'[^0-9]'), '');
    await tester.enterText(find.byType(TextField), code == '000000' ? '111111' : '000000');
    await tester.tap(find.text('Verify'));
    await _settle(tester);
    expect(find.text('That code is not right.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), code);
    await _settle(tester);
    expect(find.text('What should we call you?'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Gurbani Gulati');
    await tester.tap(find.text('Continue'));
    await _settle(tester);
    expect(find.textContaining('Gurbani'), findsWidgets);
    expect(find.text('Next steps'), findsOneWidget);
  });

  testWidgets('signed in: home, return tab, and sign out clears the draft', (tester) async {
    await _phone(tester);
    FlutterSecureStorage.setMockInitialValues({'kardo.session.v1': _session()});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const TaxosApp()));
    await _settle(tester);
    expect(find.text('Next steps'), findsOneWidget);

    container.read(itrDraftProvider.notifier).update(
          (d) => d.copyWith(salary: const SalaryIncome(basic: 600000, otherTaxableComponents: 685000)),
        );
    await _settle(tester);
    expect(container.read(comparisonProvider).newRegime.totalTaxLiability, 10400);
    expect(find.textContaining('₹10,400'), findsWidgets);

    await tester.tap(find.text('Return'));
    await _settle(tester);
    expect(find.text('Your income tax return'), findsOneWidget);
    expect(find.text('Salary'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await _settle(tester);
    await tester.tap(find.byTooltip('Account'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Sign out'));
    await _settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await _settle(tester);

    expect(find.text('Taxes, kar do.'), findsOneWidget);
    expect(container.read(authProvider).valueOrNull, isNull);
    expect(container.read(itrDraftProvider).salary, isNull);
  });

  test('phone numbers are normalised and validated', () {
    expect(normalisePhone('+91 98765 43210'), '9876543210');
    expect(normalisePhone('09876543210'), '9876543210');
    expect(() => normalisePhone('12345'), throwsA(isA<AuthFailure>()));
    expect(() => normalisePhone('5876543210'), throwsA(isA<AuthFailure>()));
  });

  test('demo repository: right code signs in once, wrong code fails', () async {
    final repo = DemoAuthRepository();
    final c = await repo.requestOtp('9876543210');
    await expectLater(repo.verifyOtp('9876543210', 'nope'), throwsA(isA<AuthFailure>()));
    final s = await repo.verifyOtp('9876543210', c.demoCode!);
    expect(s.phone, '9876543210');
    expect(s.demo, isTrue);
    await expectLater(repo.verifyOtp('9876543210', c.demoCode!), throwsA(isA<AuthFailure>()));
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
      today: DateTime(2026, 10, 13),
    );
    expect(brain.answer('Old or new regime?'), contains(formatInr(cmp.newRegime.totalTaxLiability)));
    expect(brain.answer('Which ITR form?'), contains('ITR-1'));
    expect(brain.answer('When is the deadline?'), contains('belated return until 31/12/2026'));
  });

  test('an edit made before the saved draft loads is kept along with the draft', () async {
    final saved = ItrInput(
      assessmentYear: AssessmentYear.latest,
      profile: const TaxpayerProfile(ageCategory: AgeCategory.below60, pan: 'ABCPG1234K'),
    );
    SharedPreferences.setMockInitialValues({'kardo.itr.draft.v1': jsonEncode(saved.toJson())});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(itrDraftProvider.notifier).update(
          (d) => d.copyWith(
            profile: TaxpayerProfile(name: 'Asha Rao', pan: d.profile.pan, ageCategory: AgeCategory.below60),
          ),
        );
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final draft = container.read(itrDraftProvider);
    expect(draft.profile.pan, 'ABCPG1234K');
    expect(draft.profile.name, 'Asha Rao');
    final stored = (await SharedPreferences.getInstance()).getString('kardo.itr.draft.v1')!;
    expect(stored, contains('Asha Rao'));
  });
}
