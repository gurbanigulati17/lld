import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calm_pop/audio/sfx.dart';
import 'package:calm_pop/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    Sfx.disabled = true;
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openGame(WidgetTester tester, String title) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    await tester.pumpWidget(const CalmPopApp());
    await tester.ensureVisible(find.text(title));
    await tester.pump();
    await tester.tap(find.text(title));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('home lists all the games', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 860));
    await tester.pumpWidget(const CalmPopApp());
    for (final t in ['Star Dash', 'Bubble Wrap', 'Breathe', 'Ripple Pond', 'Fidget Spinner']) {
      expect(find.text(t, skipOffstage: false), findsOneWidget);
    }
  });

  testWidgets('popping a bubble increments the counter', (tester) async {
    await openGame(tester, 'Bubble Wrap');
    expect(find.text('0 pops'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(CustomPaint).at(3)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('1 pops'), findsOneWidget);
  });

  testWidgets('breathing session starts and pauses', (tester) async {
    await openGame(tester, 'Breathe');
    await tester.tap(find.text('Start breathing'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Breathe in'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Ready?'), findsOneWidget);
  });

  testWidgets('touching the pond counts ripples', (tester) async {
    await openGame(tester, 'Ripple Pond');
    await tester.tapAt(const Offset(200, 400));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('flicking the spinner makes it spin', (tester) async {
    await openGame(tester, 'Fidget Spinner');
    await tester.flingFrom(const Offset(320, 450), const Offset(0, 250), 3000);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.text('0 rpm'), findsNothing);
  });

  testWidgets('star dash starts, plays and can pause', (tester) async {
    await openGame(tester, 'Star Dash');
    expect(find.text('Play'), findsOneWidget);
    await tester.tap(find.text('Play'));
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('Play'), findsNothing);
    expect(find.textContaining('Level'), findsOneWidget);
    await tester.drag(find.byType(CustomPaint).last, const Offset(-60, 0));
    await tester.pump(const Duration(milliseconds: 16));
    if (find.text('Game over').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Paused'), findsOneWidget);
    }
  });
}
