import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'levels.dart';
import 'ships.dart';

/// Saved campaign progress: stars per level, chosen ship, endless best.
class DashProgress extends ChangeNotifier {
  DashProgress._();

  static final instance = DashProgress._();

  final _stars = <int, int>{};
  String _ship = ships.first.id;
  int endlessBest = 0;
  bool loaded = false;

  int starsFor(int level) => _stars[level] ?? 0;
  int get totalStars => _stars.values.fold(0, (a, b) => a + b);
  int get maxStars => levels.length * 3;
  bool isUnlocked(int level) => level <= 1 || starsFor(level - 1) > 0;
  bool shipUnlocked(ShipSpec s) => totalStars >= s.stars;
  ShipSpec get ship {
    final s = shipById(_ship);
    return shipUnlocked(s) ? s : ships.first;
  }

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      for (final l in levels) {
        final v = p.getInt('sd_stars_${l.number}');
        if (v != null) _stars[l.number] = v;
      }
      _ship = p.getString('sd_ship') ?? _ship;
      endlessBest = p.getInt('star_dash_best') ?? 0;
    } catch (_) {}
    loaded = true;
    notifyListeners();
  }

  /// Records a result and returns true if it beat the previous rating.
  Future<bool> record(int level, int stars) async {
    if (stars <= starsFor(level)) return false;
    _stars[level] = stars;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('sd_stars_$level', stars);
    } catch (_) {}
    return true;
  }

  Future<void> selectShip(ShipSpec s) async {
    _ship = s.id;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString('sd_ship', s.id);
    } catch (_) {}
  }

  Future<void> recordEndless(int score) async {
    if (score <= endlessBest) return;
    endlessBest = score;
    notifyListeners();
    try {
      final p = await SharedPreferences.getInstance();
      await p.setInt('star_dash_best', score);
    } catch (_) {}
  }
}
