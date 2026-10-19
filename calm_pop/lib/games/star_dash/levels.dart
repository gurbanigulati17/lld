import 'package:flutter/material.dart';

/// What the player has to do to clear a level.
enum Goal { destroy, survive, collect, boss, endless }

/// Enemy types that can be mixed into a level.
enum Foe { rock, comet, ufo, mine }

/// Look and feel of one region of the galaxy.
class Sector {
  const Sector({
    required this.name,
    required this.tagline,
    required this.sky,
    required this.nebula,
    required this.rockColors,
    required this.accent,
    required this.planet,
    this.ringed = false,
  });

  final String name;
  final String tagline;

  /// Three colours, top to bottom.
  final List<Color> sky;
  final List<Color> nebula;
  final List<Color> rockColors;
  final Color accent;

  /// Two colours used to paint the big planet in the background.
  final List<Color> planet;
  final bool ringed;
}

const sectors = <Sector>[
  Sector(
    name: 'Moon Belt',
    tagline: 'Asteroids drifting past the old moon',
    sky: [Color(0xFF0E0B26), Color(0xFF231C4D), Color(0xFF3A2559)],
    nebula: [Color(0xFF6B4FC4), Color(0xFFB77AA8)],
    rockColors: [Color(0xFF8E86B8), Color(0xFF7A9CC2), Color(0xFFB48AA8)],
    accent: Color(0xFFB8A9FF),
    planet: [Color(0xFFD9D4F0), Color(0xFF6F68A0)],
  ),
  Sector(
    name: 'Comet Alley',
    tagline: 'Icy comets streak through at full speed',
    sky: [Color(0xFF041427), Color(0xFF0B2C4A), Color(0xFF134B66)],
    nebula: [Color(0xFF2FA7C9), Color(0xFF6CE0D0)],
    rockColors: [Color(0xFF7FA9C9), Color(0xFF8CC4C9), Color(0xFF6E8FB8)],
    accent: Color(0xFF9FD3FF),
    planet: [Color(0xFFBFF3FF), Color(0xFF2C7FA8)],
    ringed: true,
  ),
  Sector(
    name: 'Alien Reef',
    tagline: 'Curious UFOs that shoot back',
    sky: [Color(0xFF0A1A14), Color(0xFF173A2E), Color(0xFF3B1E4D)],
    nebula: [Color(0xFF3FD69A), Color(0xFFD45FC8)],
    rockColors: [Color(0xFF6FAE95), Color(0xFF9C7FB8), Color(0xFF7FA88A)],
    accent: Color(0xFF8FDFC4),
    planet: [Color(0xFFB6FFD9), Color(0xFF7A3F9C)],
  ),
  Sector(
    name: 'Mine Nebula',
    tagline: 'Spiky mines that chain-explode',
    sky: [Color(0xFF1F0A0A), Color(0xFF4A1A14), Color(0xFF6B2E1A)],
    nebula: [Color(0xFFFF7A45), Color(0xFFFFC46B)],
    rockColors: [Color(0xFFB8836E), Color(0xFFC49A7F), Color(0xFF9E6E5E)],
    accent: Color(0xFFFFBFA0),
    planet: [Color(0xFFFFD6A0), Color(0xFFB0402A)],
    ringed: true,
  ),
  Sector(
    name: 'Void Core',
    tagline: 'Everything at once, and the Mothership',
    sky: [Color(0xFF050505), Color(0xFF15122A), Color(0xFF2A1F12)],
    nebula: [Color(0xFFFFD36B), Color(0xFF7D5CE0)],
    rockColors: [Color(0xFF8C8370), Color(0xFF7A7398), Color(0xFFA08C6A)],
    accent: Color(0xFFFFE29A),
    planet: [Color(0xFFFFF0C2), Color(0xFF3A2A10)],
  ),
];

class LevelSpec {
  const LevelSpec({
    required this.number,
    required this.sector,
    required this.goal,
    required this.target,
    required this.mix,
    this.spawnEvery = 0.9,
    this.speed = 1.0,
    this.boss = 0,
  });

  /// 1-based; 0 is endless mode.
  final int number;
  final int sector;
  final Goal goal;

  /// Kills, seconds or stars depending on [goal].
  final int target;
  final Map<Foe, double> mix;
  final double spawnEvery;
  final double speed;

  /// 0 = none, 1 = Grumbo (mini boss), 2 = Mothership Omega.
  final int boss;

  Sector get theme => sectors[sector];
  bool get isBoss => boss > 0;

  String get foeName => switch (mix.keys.toList()) {
        [Foe.rock] => 'asteroids',
        [Foe.ufo] => 'UFOs',
        _ => 'enemies',
      };

  String get goalText => switch (goal) {
        Goal.destroy => 'Destroy $target $foeName',
        Goal.survive => 'Survive for $target seconds',
        Goal.collect => 'Collect $target star crystals',
        Goal.boss => boss == 1 ? 'Defeat Grumbo the giant UFO' : 'Defeat Mothership Omega',
        Goal.endless => 'Survive as long as you can',
      };
}

const levels = <LevelSpec>[
  LevelSpec(number: 1, sector: 0, goal: Goal.destroy, target: 20, mix: {Foe.rock: 1}, spawnEvery: 1.0),
  LevelSpec(number: 2, sector: 0, goal: Goal.survive, target: 40, mix: {Foe.rock: 1}, spawnEvery: 0.6, speed: 1.25),
  LevelSpec(number: 3, sector: 1, goal: Goal.destroy, target: 25, mix: {Foe.rock: 0.6, Foe.comet: 0.4}, spawnEvery: 0.85),
  LevelSpec(number: 4, sector: 1, goal: Goal.collect, target: 8, mix: {Foe.rock: 0.4, Foe.comet: 0.6}, spawnEvery: 0.75, speed: 1.15),
  LevelSpec(number: 5, sector: 2, goal: Goal.destroy, target: 12, mix: {Foe.ufo: 1}, spawnEvery: 1.6),
  LevelSpec(number: 6, sector: 2, goal: Goal.boss, target: 1, mix: {}, boss: 1),
  LevelSpec(number: 7, sector: 3, goal: Goal.destroy, target: 30, mix: {Foe.rock: 0.35, Foe.mine: 0.45, Foe.comet: 0.2}, spawnEvery: 0.8),
  LevelSpec(number: 8, sector: 3, goal: Goal.survive, target: 60, mix: {Foe.rock: 0.3, Foe.mine: 0.3, Foe.comet: 0.2, Foe.ufo: 0.2}, spawnEvery: 0.7, speed: 1.15),
  LevelSpec(number: 9, sector: 4, goal: Goal.destroy, target: 40, mix: {Foe.rock: 0.3, Foe.comet: 0.25, Foe.ufo: 0.25, Foe.mine: 0.2}, spawnEvery: 0.6, speed: 1.2),
  LevelSpec(number: 10, sector: 4, goal: Goal.boss, target: 1, mix: {}, boss: 2),
];

const endlessLevel = LevelSpec(
  number: 0,
  sector: 0,
  goal: Goal.endless,
  target: 0,
  mix: {Foe.rock: 1},
);
