import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sound_durations.g.dart';

/// Sound effects and background music for every game.
///
/// Effects use small pools of low-latency players so rapid sounds (bubble
/// pops, lasers) can overlap. All calls are fire-and-forget and never throw.
class Sfx with WidgetsBindingObserver {
  Sfx._();

  static final instance = Sfx._();

  /// Set in widget tests, where there is no audio plugin.
  static bool disabled = false;

  static const _prefsKey = 'sound_enabled';

  final enabled = ValueNotifier<bool>(true);

  final _context = AudioContextConfig(focus: AudioContextConfigFocus.mixWithOthers).build();
  final _pools = <String, Future<AudioPool?>>{};
  final _lastPlayed = <String, int>{};
  final _clock = Stopwatch()..start();

  AudioPlayer? _music;
  String? _musicName;
  double _musicVolume = 0.5;
  bool _musicWanted = false;

  Future<void> init() async {
    if (disabled) return;
    WidgetsBinding.instance.addObserver(this);
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_prefsKey) ?? true;
      await AudioPlayer.global.setAudioContext(_context);
    } catch (e) {
      debugPrint('Sfx init failed: $e');
    }
    preload(const ['tap']);
  }

  Future<void> toggle() async {
    enabled.value = !enabled.value;
    if (enabled.value) {
      if (_musicWanted) _resumeMusic();
      play('tap');
    } else {
      _safe(_music?.pause());
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey, enabled.value);
    } catch (_) {}
  }

  /// Creates player pools ahead of time so the first play has no delay.
  void preload(List<String> names) {
    if (disabled) return;
    for (final n in names) {
      _pool(n);
    }
  }

  Future<AudioPool?> _pool(String name) {
    return _pools.putIfAbsent(name, () async {
      try {
        return await AudioPool.create(
          source: AssetSource('sounds/$name.wav'),
          minPlayers: 2,
          maxPlayers: 5,
          playerMode: PlayerMode.lowLatency,
          audioContext: _context,
        );
      } catch (e) {
        debugPrint('Sfx: could not load $name: $e');
        return null;
      }
    });
  }

  /// Plays a one-shot effect. [minGapMs] skips the sound if it was played
  /// more recently than that, which keeps rapid repeats from turning to mush.
  void play(String name, {double volume = 1.0, int minGapMs = 0}) {
    if (disabled || !enabled.value) return;
    final now = _clock.elapsedMilliseconds;
    final last = _lastPlayed[name];
    if (last != null && now - last < minGapMs) return;
    _lastPlayed[name] = now;
    unawaited(_play(name, volume));
  }

  Future<void> _play(String name, double volume) async {
    try {
      final pool = await _pool(name);
      if (pool == null) return;
      final stop = await pool.start(volume: volume.clamp(0.0, 1.0));
      // Low-latency players don't report completion, so hand the player
      // back to the pool once the sound has finished.
      final ms = soundDurationsMs[name] ?? 1000;
      Timer(Duration(milliseconds: ms + 60), () => _safe(stop()));
    } catch (e) {
      debugPrint('Sfx: play $name failed: $e');
    }
  }

  /// Starts a looping background track (replacing any other one).
  void playMusic(String name, {double volume = 0.5}) {
    if (disabled) return;
    _musicWanted = true;
    _musicVolume = volume;
    if (_musicName == name && _music != null) {
      _resumeMusic();
      return;
    }
    _musicName = name;
    unawaited(() async {
      try {
        final old = _music;
        _music = null;
        await old?.dispose();
        final player = AudioPlayer();
        _music = player;
        await player.setAudioContext(_context);
        await player.setReleaseMode(ReleaseMode.loop);
        await player.setSource(AssetSource('sounds/$name.wav'));
        await player.setVolume(volume);
        if (_musicWanted && enabled.value && _music == player) await player.resume();
      } catch (e) {
        debugPrint('Sfx: music $name failed: $e');
      }
    }());
  }

  void _resumeMusic() {
    if (!enabled.value) return;
    final m = _music;
    if (m == null) return;
    _safe(() async {
      await m.setVolume(_musicVolume);
      await m.resume();
    }());
  }

  void pauseMusic() {
    _musicWanted = false;
    _safe(_music?.pause());
  }

  void stopMusic() {
    _musicWanted = false;
    final m = _music;
    _music = null;
    _musicName = null;
    _safe(m?.dispose());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_musicWanted) _resumeMusic();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _safe(_music?.pause());
    }
  }

  void _safe(Future<void>? f) {
    f?.catchError((Object e) => debugPrint('Sfx: $e'));
  }
}

/// Speaker button that mutes / unmutes all sound.
class SoundToggle extends StatelessWidget {
  const SoundToggle({super.key, required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: Sfx.instance.enabled,
      builder: (context, on, _) => IconButton(
        tooltip: on ? 'Mute sound' : 'Turn sound on',
        icon: Icon(on ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: color),
        onPressed: Sfx.instance.toggle,
      ),
    );
  }
}
