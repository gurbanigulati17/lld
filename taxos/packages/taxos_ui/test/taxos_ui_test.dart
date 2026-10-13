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

  testWidgets('dark theme outlines cards instead of shadowing them', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.dark(),
      home: const AppScaffold(body: Surface(child: Text('flat'))),
    ));
    final box = tester.widget<DecoratedBox>(
      find.ancestor(of: find.text('flat'), matching: find.byType(DecoratedBox)).first,
    );
    final deco = box.decoration as BoxDecoration;
    expect(deco.boxShadow, isEmpty);
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
}
