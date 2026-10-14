import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxos_ui/taxos_ui.dart';

Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light(), home: AppScaffold(body: child));

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

void main() {
  testWidgets('Surface renders child and reacts to tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(wrap(Center(child: Surface(onTap: () => taps++, child: const Text('hello')))));
    await tester.tap(find.text('hello'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  test('Indian amount formatter', () {
    expect(IndianAmountFormatter.format(1234567), '12,34,567');
    expect(IndianAmountFormatter.format(999), '999');
    expect(IndianAmountFormatter.parse('12,34,567'), 1234567);
    expect(IndianAmountFormatter.parse(''), 0);
  });

  testWidgets('AmountField reports parsed rupees', (tester) async {
    var v = 0;
    await tester.pumpWidget(wrap(FieldGroup(children: [
      AmountField(label: 'Basic salary', value: 0, onChanged: (x) => v = x),
    ])));
    await tester.enterText(find.byType(TextField), '600000');
    expect(v, 600000);
    expect(find.text('6,00,000'), findsOneWidget);
  });

  testWidgets('Segmented switches value', (tester) async {
    var value = 'a';
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: StatefulBuilder(
        builder: (context, setState) => AppScaffold(
          body: Segmented<String>(
            values: const ['a', 'b'],
            labels: const ['A', 'B'],
            selected: value,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(value, 'b');
  });

  testWidgets('AppNavBar reports taps', (tester) async {
    var idx = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: StatefulBuilder(
        builder: (context, setState) => AppScaffold(
          body: const SizedBox(),
          bottomNavigationBar: AppNavBar(
            index: idx,
            onChanged: (i) => setState(() => idx = i),
            items: const [
              AppNavItem(icon: Icons.home_outlined, label: 'Home'),
              AppNavItem(icon: Icons.description_outlined, label: 'Return'),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Return'));
    await tester.pump();
    expect(idx, 1);
  });

  testWidgets('Evergreen widgets render', (tester) async {
    await tester.pumpWidget(wrap(SingleChildScrollView(
      child: Column(children: [
        const PageHeading('Good evening', subtitle: 'Here is where your tax stands today.'),
        const ProgressRow(label: 'New regime', value: '₹41,600', fraction: 0.5),
        InfoCard(title: 'File by 31 Dec', detail: 'Late fee applies', onTap: () {}),
        ActionTile(icon: Icons.home_outlined, text: 'Got a home loan?', linkLabel: 'Add house property', onTap: () {}),
        const LedgerRow(label: 'To pay', amount: '₹43,883', bold: true),
        HelpLink('How we got these numbers', onTap: () {}),
      ]),
    )));
    expect(find.text('Good evening'), findsOneWidget);
    expect(find.text('₹43,883'), findsOneWidget);
    expect(find.text('Add house property'), findsOneWidget);
  });

  test('Evergreen colours meet WCAG AA contrast', () {
    const t = UiTokens.evergreen;
    expect(contrast(t.surface, t.text), greaterThan(7));
    expect(contrast(t.surface, t.textMuted), greaterThan(4.5));
    expect(contrast(t.ground, t.textMuted), greaterThan(4.5));
    expect(contrast(t.ground, t.heading), greaterThan(7));
    expect(contrast(t.primary, t.onPrimary), greaterThan(4.5));
    expect(contrast(t.tint, t.onTint), greaterThan(4.5));
    expect(contrast(t.warning, t.onWarning), greaterThan(4.5));
    expect(contrast(t.negative, t.onNegative), greaterThan(4.5));
    expect(contrast(t.positive, t.onPositive), greaterThan(4.5));
  });
}
