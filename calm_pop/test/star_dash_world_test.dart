import 'package:calm_pop/audio/sfx.dart';
import 'package:calm_pop/games/star_dash/levels.dart';
import 'package:calm_pop/games/star_dash/progress.dart';
import 'package:calm_pop/games/star_dash/ships.dart';
import 'package:calm_pop/games/star_dash/world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

DashWorld startedWorld(LevelSpec level) {
  final w = DashWorld(level, ships.first)
    ..resize(const Size(400, 800))
    ..start();
  return w;
}

void run(DashWorld w, double seconds) {
  for (var t = 0.0; t < seconds; t += 1 / 60) {
    w.update(1 / 60);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Sfx.disabled = true;
    SharedPreferences.setMockInitialValues({});
  });

  test('there are 10 levels across 5 sectors, ending with two bosses', () {
    expect(levels, hasLength(10));
    expect(levels.map((l) => l.sector).toSet(), hasLength(sectors.length));
    expect(levels[5].boss, 1);
    expect(levels.last.boss, 2);
    for (var i = 0; i < levels.length; i++) {
      expect(levels[i].number, i + 1);
    }
  });

  test('a destroy goal wins once enough kills are made, with a star rating', () {
    final w = startedWorld(levels.first);
    w.kills = levels.first.target;
    run(w, 1.0);
    expect(w.phase, DashPhase.won);
    expect(w.stars, 3);
  });

  test('stars drop as lives are lost', () {
    final w = startedWorld(levels.first)..livesLost = 1;
    expect(w.stars, 2);
    w.livesLost = 2;
    expect(w.stars, 1);
  });

  test('a survive goal wins after the timer', () {
    final w = startedWorld(levels[1])..invuln = 1000; // can't be hurt
    run(w, DashWorld.introTime + levels[1].target + 1.5);
    expect(w.phase, DashPhase.won);
  });

  test('boss level sounds a warning and then the boss arrives', () {
    final w = startedWorld(levels.last)..invuln = 1000;
    run(w, DashWorld.introTime + 0.5);
    expect(w.warning, greaterThan(0));
    expect(w.boss, isNull);
    run(w, 3);
    expect(w.boss, isNotNull);
    expect(w.boss!.name, 'Mothership Omega');
  });

  test('progress unlocks levels and ships', () async {
    final p = DashProgress.instance;
    await p.load();
    expect(p.isUnlocked(1), isTrue);
    expect(p.isUnlocked(2), isFalse);
    await p.record(1, 2);
    expect(p.isUnlocked(2), isTrue);
    expect(await p.record(1, 1), isFalse, reason: 'a worse result keeps the best rating');
    expect(p.starsFor(1), 2);
    expect(p.shipUnlocked(ships[1]), isFalse);
  });
}
