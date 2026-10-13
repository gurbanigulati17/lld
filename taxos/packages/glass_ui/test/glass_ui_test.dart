import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glass_ui/glass_ui.dart';

void main() {
  testWidgets('GlassPanel renders child and reacts to tap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: GlassTheme.light(),
      home: GlassScaffold(
        body: Center(
          child: GlassPanel(
            onTap: () => taps++,
            child: const Text('hello'),
          ),
        ),
      ),
    ));
    expect(find.text('hello'), findsOneWidget);
    await tester.tap(find.text('hello'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(taps, 1);
  });

  testWidgets('reduced effects path renders without BackdropFilter',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: GlassTheme.dark(),
      home: const GlassPerformance(
        reducedEffects: true,
        child: GlassScaffold(body: GlassPanel(child: Text('flat'))),
      ),
    ));
    expect(find.byType(BackdropFilter), findsNothing);
    expect(find.text('flat'), findsOneWidget);
  });

  test('Indian amount formatter', () {
    expect(IndianAmountFormatter.format(1234567), '12,34,567');
    expect(IndianAmountFormatter.format(999), '999');
    expect(IndianAmountFormatter.parse('12,34,567'), 1234567);
    expect(IndianAmountFormatter.parse(''), 0);
  });

  testWidgets('GlassSegmented switches value', (tester) async {
    var value = 'a';
    await tester.pumpWidget(MaterialApp(
      theme: GlassTheme.light(),
      home: StatefulBuilder(
        builder: (context, setState) => GlassScaffold(
          body: GlassSegmented<String>(
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
}
