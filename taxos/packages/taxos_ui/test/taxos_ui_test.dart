import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taxos_ui/taxos_ui.dart';

void main() {
  testWidgets('Surface renders child and reacts to tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: AppScaffold(
        body: Center(child: Surface(onTap: () => taps++, child: const Text('hello'))),
      ),
    ));
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(find.text('hello'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('dark theme outlines cards with a hairline', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const AppScaffold(body: Surface(child: Text('flat'))),
    ));
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('flat'), matching: find.byType(DecoratedBox)).first,
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.border, isNotNull);
  });

  test('Indian amount formatter', () {
    expect(IndianAmountFormatter.format(1234567), '12,34,567');
    expect(IndianAmountFormatter.format(999), '999');
    expect(IndianAmountFormatter.parse('12,34,567'), 1234567);
    expect(IndianAmountFormatter.parse(''), 0);
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
    await tester.pump(const Duration(milliseconds: 300));
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
              AppNavItem(icon: Icons.description_outlined, label: 'ITR'),
            ],
          ),
        ),
      ),
    ));
    await tester.tap(find.text('ITR'));
    await tester.pump();
    expect(idx, 1);
  });

  testWidgets('LabelBar uppercases and SplitStat shows both figures', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const AppScaffold(
        body: Column(children: [
          LabelBar('Estimated tax'),
          SplitStat(
            left: StatValue(label: 'You pay', value: '₹10,400'),
            right: StatValue(label: 'Total income', value: '₹12.1L'),
          ),
        ]),
      ),
    ));
    expect(find.text('ESTIMATED TAX'), findsOneWidget);
    expect(find.text('₹10,400'), findsOneWidget);
    expect(find.text('₹12.1L'), findsOneWidget);
  });

  test('status tags are solid with contrasting labels', () {
    const t = UiTokens.copperNoir;
    double lum(Color c) {
      double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
    }
    double ratio(Color a, Color b) {
      final x = lum(a), y = lum(b);
      return (x > y ? x + 0.05 : y + 0.05) / (x > y ? y + 0.05 : x + 0.05);
    }
    expect(ratio(t.warning, t.onWarning), greaterThan(4.5));
    expect(ratio(t.positive, t.onPositive), greaterThan(4.5));
    expect(ratio(t.negative, t.onNegative), greaterThan(3.0));
  });

  testWidgets('GlowBackground paints the ground colour under the glow', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const GlowBackground(child: SizedBox.expand()),
    ));
    final box = tester.widget<ColoredBox>(
      find.descendant(of: find.byType(GlowBackground), matching: find.byType(ColoredBox)).first,
    );
    expect(box.color, UiTokens.copperNoir.ground);
  });
}
