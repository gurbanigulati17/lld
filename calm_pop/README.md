# Calm Pop 🌿

A small, friendly stress-relief app built with Flutter. An arcade space shooter, a cozy fairy game, plus four calming mini games, soft pastel UI, haptic feedback, no ads, no sign-up, works offline.

| Home | Bubble Wrap | Breathe | Ripple Pond | Fidget Spinner |
|---|---|---|---|---|
| ![](screenshots/1_home.png) | ![](screenshots/2_bubble.png) | ![](screenshots/3_breathe.png) | ![](screenshots/4_ripple.png) | ![](screenshots/5_spinner.png) |

| Star Dash | Star Dash (playing) | Fairy Glow | Fairy Glow (playing) |
|---|---|---|---|
| ![](screenshots/0_star_dash_menu.png) | ![](screenshots/0_star_dash_play.png) | ![](screenshots/0_fairy_glow_menu.png) | ![](screenshots/0_fairy_glow_play.png) |

## Games

- **Star Dash (arcade)** – drag to fly your ship; it fires on its own. Blast asteroids (big ones split in two), build combos, and grab power-ups: ⭐ +50 points, ⚡ triple shot, 🛡 shield, ❤ extra life. It speeds up every level, and your best score is saved.

- **Fairy Glow (cozy)** – a little fairy shelters under a purple flower umbrella topped with a glowing star, in a lavender meadow at night. Slide her to catch falling stars (each one in a row plays the next note), grab fireflies for a big boost, and dodge gloom drops. The star lamp slowly dims, so keep catching! Music-box lullaby, best score saved. The fairy is drawn entirely in code.
- **Bubble Wrap** – tap bubbles to pop them (with a click and a vibration). A new sheet in a new colour appears when you finish one.
- **Breathe** – a guided breathing circle with three patterns: Calm (4-6), Box (4-4-4-4) and Relax (4-7-8).
- **Ripple Pond** – tap or swipe the night-time pond to make glowing coloured ripples.
- **Fidget Spinner** – flick the spinner and watch it coast down. Tracks RPM, spins and your best speed. Tap the palette to change its colour.

The home screen also shows a calming tip. Tap it to see another one.

## Sound

Every game has sound effects: bubble pops, musical water drops (low notes on the left of the pond, high on the right), breathing bells, spinner ticks and whooshes, and lasers, explosions and power-ups in Star Dash. Star Dash has its own background music, and Breathe and Ripple Pond play a soft ambient track. Tap the speaker icon on the home screen or in any game to mute; the choice is remembered.

All sounds are synthesised from scratch by `tool/gen_sounds.py` (no samples, nothing to license). To tweak them, edit the script and run `python3 tool/gen_sounds.py` (needs numpy).

## Get the APK

**From GitHub (no setup needed):** every push that changes `calm_pop/` runs the
**Build Calm Pop APK** workflow. Open the repo's **Actions** tab → latest run →
download the `calm-pop-apk` artifact, unzip it, and install `app-release.apk` on
your phone (allow "install unknown apps" when Android asks). You can also start
the workflow by hand with **Run workflow**.

**Build locally:**

```bash
cd calm_pop
flutter pub get
flutter build apk --release
# APK: build/app/outputs/flutter-apk/app-release.apk
```

Or plug in a phone and run `flutter run`.

> The release build is signed with the debug key so it installs straight away.
> Before publishing to the Play Store, set up your own signing key
> (see https://docs.flutter.dev/deployment/android).

## Project layout

```
assets/sounds/           generated WAV effects and music loops
tool/gen_sounds.py       synthesiser that makes those sounds
lib/
  main.dart              app entry + theme
  audio/sfx.dart         sound effects, music and mute toggle
  theme.dart             pastel colour palette
  home_screen.dart       greeting, tip card, game grid
  widgets/game_scaffold.dart  shared header + stat pills
  games/
    star_dash.dart
    fairy_glow.dart
    bubble_wrap.dart
    breathe.dart
    ripple_pond.dart
    fidget_spinner.dart
```

Packages: `audioplayers` for sound and `shared_preferences` to remember the best score and mute setting. Everything is drawn with Flutter widgets and `CustomPainter`.
