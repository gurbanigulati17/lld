"""Synthesises every sound effect and music loop used by Calm Pop.

All audio is generated from scratch (no samples), so it is free to ship.
Run from the calm_pop folder:  python3 tool/gen_sounds.py
Writes WAV files to assets/sounds/ and lib/audio/sound_durations.g.dart.
"""

import math
import os
import wave

import numpy as np

SR = 44100
MUSIC_SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
DART = os.path.join(os.path.dirname(__file__), "..", "lib", "audio", "sound_durations.g.dart")
rng = np.random.default_rng(7)
durations = {}


def t_axis(sec, sr=SR):
    return np.arange(int(sec * sr)) / sr


def sweep(f0, f1, sec, sr=SR, curve=1.0):
    """Sine whose frequency glides from f0 to f1."""
    t = t_axis(sec, sr)
    k = (t / sec) ** curve
    f = f0 + (f1 - f0) * k
    return np.sin(2 * np.pi * np.cumsum(f) / sr)


def tone(f, sec, sr=SR, harmonics=((1, 1.0),)):
    t = t_axis(sec, sr)
    return sum(a * np.sin(2 * np.pi * f * h * t) for h, a in harmonics)


def env(n, attack, decay, sr=SR):
    """Linear attack then exponential decay (decay = time constant, seconds)."""
    t = np.arange(n) / sr
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-np.maximum(t - attack, 0) / decay)


def lowpass(x, cutoff, sr=SR):
    """One-pole low-pass; cutoff may be an array (time-varying)."""
    cutoff = np.broadcast_to(cutoff, x.shape)
    alpha = 1 - np.exp(-2 * np.pi * cutoff / sr)
    y = np.empty_like(x)
    acc = 0.0
    for i in range(len(x)):
        acc += alpha[i] * (x[i] - acc)
        y[i] = acc
    return y


def highpass(x, cutoff, sr=SR):
    return x - lowpass(x, cutoff, sr)


def noise(sec, sr=SR):
    return rng.uniform(-1, 1, int(sec * sr))


def echo(x, delay, feedback, taps=4, sr=SR):
    d = int(delay * sr)
    out = np.concatenate([x, np.zeros(d * taps)])
    for k in range(1, taps + 1):
        out[d * k:d * k + len(x)] += x * (feedback ** k)
    return out


def bell(f, sec, decay=0.6):
    """Soft inharmonic bell."""
    x = tone(f, sec, harmonics=((1, 1.0), (2.0, 0.35), (2.76, 0.25), (5.4, 0.08)))
    return x * env(len(x), 0.004, decay)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def seq(notes, step, fn):
    """Places fn(freq) every `step` seconds."""
    parts = []
    for i, f in enumerate(notes):
        s = fn(f)
        parts.append(np.concatenate([np.zeros(int(i * step * SR)), s]))
    return mix(*parts)


def note(name):
    names = {"C": -9, "D": -7, "E": -5, "F": -4, "G": -2, "A": 0, "B": 2}
    base = names[name[0]]
    rest = name[1:]
    if rest.startswith("#"):
        base += 1
        rest = rest[1:]
    octave = int(rest)
    return 440.0 * 2 ** ((base + (octave - 4) * 12) / 12)


def save(name, x, peak=0.85, sr=SR, fade=0.01):
    x = np.asarray(x, dtype=np.float64)
    if fade:
        n = min(int(fade * sr), len(x))
        x[-n:] *= np.linspace(1, 0, n)
    x = np.tanh(x / (np.max(np.abs(x)) + 1e-9) * 1.2) / math.tanh(1.2) * peak
    pcm = (x * 32767).astype("<i2")
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    durations[name] = int(len(x) / sr * 1000)


def square_ish(f, sec):
    return tone(f, sec, harmonics=((1, 1.0), (3, 0.3), (5, 0.12), (7, 0.05)))


# ---------------------------------------------------------------- UI + calm
def make_ui_and_calm():
    for i, k in enumerate([1.0, 1.16, 0.86]):
        body = sweep(820 * k, 260 * k, 0.09, curve=0.4)
        body *= env(len(body), 0.001, 0.022)
        click = highpass(noise(0.012), 2500) * env(int(0.012 * SR), 0.0005, 0.003)
        save(f"pop_{i}", mix(body, click * 0.6), peak=0.9)

    t = sweep(1500, 1100, 0.04) * env(int(0.04 * SR), 0.001, 0.008)
    save("tap", t, peak=0.5)

    chime = seq([note("C6"), note("E6"), note("G6"), note("C7")], 0.09, lambda f: bell(f, 1.2, 0.35))
    save("sheet", echo(chime, 0.18, 0.3, 3), peak=0.7)

    save("breathe_in", echo(mix(bell(note("C5"), 2.5, 0.9), 0.6 * bell(note("G5"), 2.5, 0.7)), 0.25, 0.25, 3), peak=0.6)
    save("breathe_out", echo(mix(bell(note("G4"), 2.5, 1.0), 0.6 * bell(note("D5"), 2.5, 0.8)), 0.25, 0.25, 3), peak=0.6)
    save("breathe_hold", bell(note("E5"), 1.5, 0.4), peak=0.4)

    # Water drops on a pentatonic scale so random taps sound musical.
    for i, n in enumerate(["C5", "D5", "E5", "G5", "A5", "C6", "D6", "E6"]):
        f = note(n)
        body = sweep(f * 0.7, f * 1.25, 0.35, curve=0.25)
        body *= env(len(body), 0.002, 0.09)
        save(f"drop_{i}", echo(body, 0.12, 0.35, 4), peak=0.75)

    tick = highpass(noise(0.02), 1800) * env(int(0.02 * SR), 0.0005, 0.004)
    tick = mix(tick, 0.5 * tone(2400, 0.02) * env(int(0.02 * SR), 0.0005, 0.003))
    save("spin_tick", tick, peak=0.5)

    n = noise(0.45)
    sw = lowpass(n, np.linspace(400, 2600, len(n)) * np.sin(np.linspace(0, np.pi, len(n))) + 200)
    sw *= np.sin(np.linspace(0, np.pi, len(n))) ** 2
    save("whoosh", sw, peak=0.6)


# ----------------------------------------------------------------- Star Dash
def make_dash():
    las = sweep(1700, 520, 0.11, curve=0.5)
    las = mix(las, 0.3 * np.sign(las)) * env(len(las), 0.001, 0.035)
    save("laser", lowpass(las, 5000), peak=0.6)

    def boom(sec, cutoff, thump_f, decay):
        nz = noise(sec)
        cut = cutoff * np.exp(-np.arange(len(nz)) / SR / (decay * 0.8)) + 120
        nz = lowpass(nz, cut) * env(len(nz), 0.002, decay)
        th = sweep(thump_f, thump_f * 0.4, sec) * env(int(sec * SR), 0.002, decay * 0.7)
        return mix(nz * 1.4, th)

    save("explode_small", boom(0.35, 3500, 140, 0.07), peak=0.8)
    save("explode_big", boom(0.8, 2500, 90, 0.18), peak=0.9)

    hit = mix(boom(0.5, 1800, 70, 0.12), 0.4 * square_ish(110, 0.25) * env(int(0.25 * SR), 0.002, 0.06))
    save("hit", hit, peak=0.9)

    ding = lambda f: square_ish(f, 0.25) * env(int(0.25 * SR), 0.002, 0.07)
    save("coin", lowpass(seq([note("B5"), note("E6")], 0.07, ding), 6000), peak=0.55)

    up = seq([note(n) for n in ["C5", "E5", "G5", "C6", "E6", "G6", "C7"]], 0.045,
             lambda f: square_ish(f, 0.2) * env(int(0.2 * SR), 0.002, 0.05))
    save("powerup", lowpass(up, 6000), peak=0.55)

    start = seq([note("E5"), note("A5"), note("E6")], 0.11,
                lambda f: square_ish(f, 0.35) * env(int(0.35 * SR), 0.003, 0.12))
    save("start", lowpass(start, 5000), peak=0.55)

    over = seq([note(n) for n in ["G4", "E4", "C4", "G3"]], 0.22,
               lambda f: tone(f, 0.6, harmonics=((1, 1), (3, 0.11), (5, 0.04))) * env(int(0.6 * SR), 0.005, 0.25))
    save("gameover", echo(over, 0.2, 0.25, 2), peak=0.65)


# --------------------------------------------------------------------- Music
def place_loop(buf, sig, start):
    """Adds sig into the loop buffer, wrapping the tail to the start."""
    n = len(buf)
    idx = (np.arange(len(sig)) + start) % n
    np.add.at(buf, idx, sig)


def make_music():
    sr = MUSIC_SR
    bpm = 108
    beat = 60 / bpm
    bars = 8
    total = int(bars * 4 * beat * sr)
    buf = np.zeros(total)

    def tt(sec):
        return np.arange(int(sec * sr)) / sr

    def e(n, a, d):
        t = np.arange(n) / sr
        return np.clip(t / a, 0, 1) * np.exp(-np.maximum(t - a, 0) / d)

    chords = [("A2", ["A4", "C5", "E5"]), ("F2", ["F4", "A4", "C5"]),
              ("C3", ["G4", "C5", "E5"]), ("G2", ["G4", "B4", "D5"])] * 2
    arp_order = [0, 1, 2, 1, 0, 2, 1, 2]
    for bar, (root, triad) in enumerate(chords):
        bar_start = bar * 4 * beat
        # Bass: pulsing eighths.
        for k in range(8):
            f = note(root) * (2 if k % 4 == 3 else 1)
            t = tt(beat / 2)
            s = np.sin(2 * np.pi * f * t) + 0.4 * np.sin(2 * np.pi * 2 * f * t) + 0.15 * np.sin(2 * np.pi * 3 * f * t)
            place_loop(buf, 0.33 * s * e(len(t), 0.005, 0.12), int((bar_start + k * beat / 2) * sr))
        # Arpeggio plucks: sixteenths.
        for k in range(16):
            f = note(triad[arp_order[k % 8]]) * (2 if k >= 8 else 1)
            t = tt(0.4)
            s = np.sin(2 * np.pi * f * t) + 0.25 * np.sin(2 * np.pi * 2 * f * t)
            place_loop(buf, 0.11 * s * e(len(t), 0.003, 0.09), int((bar_start + k * beat / 4) * sr))
        # Pad: detuned chord swelling over the bar.
        t = tt(4 * beat + 0.6)
        pad = sum(np.sin(2 * np.pi * note(n) / 2 * d * t) for n in triad for d in (0.997, 1.003))
        shape = np.sin(np.clip(t / (4 * beat + 0.6), 0, 1) * np.pi) ** 1.5
        place_loop(buf, 0.045 * pad * shape, int(bar_start * sr))
        # Drums.
        for b in range(4):
            kt = tt(0.25)
            kick = np.sin(2 * np.pi * np.cumsum(55 + 110 * np.exp(-kt / 0.03)) / sr) * e(len(kt), 0.001, 0.08)
            place_loop(buf, 0.55 * kick, int((bar_start + b * beat) * sr))
            hat = rng.uniform(-1, 1, int(0.05 * sr))
            hat = (hat - np.concatenate([[0], hat[:-1]])) * e(len(hat), 0.0005, 0.012)
            place_loop(buf, 0.09 * hat, int((bar_start + b * beat + beat / 2) * sr))
            if b in (1, 3):
                sn = rng.uniform(-1, 1, int(0.18 * sr)) * e(int(0.18 * sr), 0.001, 0.05)
                place_loop(buf, 0.16 * sn, int((bar_start + b * beat) * sr))
    save("music_dash", buf, peak=0.7, sr=sr, fade=0)

    # Calm ambient loop: slow pads with sparse bells.
    sec_per = 6.0
    calm_chords = [["C4", "E4", "G4", "B4"], ["A3", "C4", "E4", "B4"],
                   ["F3", "A3", "C4", "E4"], ["G3", "B3", "D4", "A4"]]
    total = int(sec_per * len(calm_chords) * sr)
    buf = np.zeros(total)
    for i, ch in enumerate(calm_chords):
        t = tt(sec_per + 3)
        pad = sum(np.sin(2 * np.pi * note(n) * d * t + d) for n in ch for d in (0.996, 1.0, 1.004))
        shape = np.clip(t / 2.5, 0, 1) * np.clip((sec_per + 3 - t) / 3.0, 0, 1)
        place_loop(buf, 0.05 * pad * shape, int(i * sec_per * sr))
    bells = ["E5", "G5", "C6", "A5", "D6", "G5", "E6", "C6"]
    for i, n in enumerate(bells):
        t = tt(3.0)
        f = note(n)
        s = (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2.76 * f * t)) * e(len(t), 0.004, 0.8)
        place_loop(buf, 0.1 * s, int((i * 3.0 + 1.1) * sr))
    save("music_calm", buf, peak=0.55, sr=sr, fade=0)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    make_ui_and_calm()
    make_dash()
    make_music()
    with open(DART, "w") as f:
        f.write("// Generated by tool/gen_sounds.py. Do not edit.\n\n")
        f.write("/// Length of each sound in milliseconds.\n")
        f.write("const soundDurationsMs = <String, int>{\n")
        for k in sorted(durations):
            f.write(f"  '{k}': {durations[k]},\n")
        f.write("};\n")
    total = sum(os.path.getsize(os.path.join(OUT, p)) for p in os.listdir(OUT))
    print(f"{len(durations)} sounds, {total / 1024:.0f} KB")
