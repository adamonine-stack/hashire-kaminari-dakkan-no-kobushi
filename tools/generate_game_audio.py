#!/usr/bin/env python3
"""Generate deterministic arcade-style BGM and impact SFX for ST_action.

Uses only the Python standard library so GitHub Actions can build the audio
assets before Godot imports/exports the Web build.
"""
from array import array
from pathlib import Path
import math
import random
import wave

SR = 22050
ROOT = Path(__file__).resolve().parents[1] / "godot" / "assets" / "audio"
BGM_DIR = ROOT / "bgm"
SFX_DIR = ROOT / "sfx"
TAU = math.tau


def midi_hz(note: int) -> float:
    return 440.0 * (2.0 ** ((note - 69) / 12.0))


def blank(duration: float):
    return array("f", [0.0]) * max(1, int(duration * SR))


def add_tone(buf, start, duration, f0, amp, wave_kind="sine", f1=None, decay=1.8, attack=0.003):
    i0 = int(start * SR)
    n = min(int(duration * SR), len(buf) - i0)
    if n <= 0:
        return
    phase = 0.0
    attack_n = max(1, int(attack * SR))
    for i in range(n):
        p = i / max(1, n - 1)
        freq = f0 if f1 is None else f0 + (f1 - f0) * p
        phase += TAU * freq / SR
        if wave_kind == "square":
            value = 1.0 if math.sin(phase) >= 0.0 else -1.0
        elif wave_kind == "saw":
            value = 2.0 * ((phase / TAU) % 1.0) - 1.0
        elif wave_kind == "triangle":
            value = 2.0 * abs(2.0 * ((phase / TAU) % 1.0) - 1.0) - 1.0
        else:
            value = math.sin(phase)
        env = max(0.0, 1.0 - p) ** decay
        if i < attack_n:
            env *= i / attack_n
        buf[i0 + i] += amp * value * env


def add_noise(buf, start, duration, amp, decay=2.0, seed=1):
    i0 = int(start * SR)
    n = min(int(duration * SR), len(buf) - i0)
    if n <= 0:
        return
    rng = random.Random(seed + i0)
    prev = rng.uniform(-1.0, 1.0)
    for i in range(n):
        p = i / max(1, n - 1)
        current = rng.uniform(-1.0, 1.0)
        high = current - prev
        prev = current
        buf[i0 + i] += amp * high * (max(0.0, 1.0 - p) ** decay) * 0.5


def add_kick(buf, start, amp=0.55):
    duration = 0.18
    i0 = int(start * SR)
    n = min(int(duration * SR), len(buf) - i0)
    if n <= 0:
        return
    phase = 0.0
    for i in range(n):
        t = i / SR
        p = i / max(1, n - 1)
        freq = 118.0 + (45.0 - 118.0) * min(1.0, p * 1.3)
        phase += TAU * freq / SR
        env = math.exp(-20.0 * t)
        click = (1.0 - i / max(1, int(0.012 * SR))) if i < int(0.012 * SR) else 0.0
        buf[i0 + i] += amp * (math.sin(phase) * env + 0.11 * click)


def add_snare(buf, start, amp=0.23, seed=10):
    add_noise(buf, start, 0.14, amp * 1.25, 2.2, seed)
    add_tone(buf, start, 0.12, 185.0, amp * 0.22, "sine", decay=2.5)


def add_hat(buf, start, amp=0.055, seed=20):
    add_noise(buf, start, 0.045, amp * 1.4, 3.4, seed)


def add_impact(buf, start=0.0, strength=1.0):
    add_kick(buf, start, 0.72 * strength)
    add_noise(buf, start, 0.17, 0.48 * strength, 2.5, 81)
    add_tone(buf, start, 0.24, 145.0, 0.30 * strength, "sine", f1=85.0, decay=1.8)
    add_tone(buf, start + 0.004, 0.09, 920.0, 0.11 * strength, "square", decay=3.0)


def save_wav(path: Path, buf, drive=1.25):
    path.parent.mkdir(parents=True, exist_ok=True)
    pcm = array("h")
    peak = 0.0
    shaped = array("f")
    for value in buf:
        sample = math.tanh(value * drive)
        shaped.append(sample)
        peak = max(peak, abs(sample))
    gain = 0.94 / peak if peak > 0.94 else 1.0
    for sample in shaped:
        pcm.append(int(max(-1.0, min(1.0, sample * gain)) * 32767.0))
    with wave.open(str(path), "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SR)
        wf.writeframes(pcm.tobytes())


def make_music(name, bpm, bars, root, progression, melody, energy=1.0, boss=False):
    beat = 60.0 / bpm
    step_duration = beat / 4.0
    steps = bars * 16
    buf = blank(steps * step_duration)
    for step in range(steps):
        t = step * step_duration
        bar = step // 16
        pos = step % 16
        chord_root = root + progression[bar % len(progression)]

        if pos in (0, 8) or (boss and pos == 14):
            add_kick(buf, t, 0.48 * energy)
        if pos in ((4, 12) if not boss else (4, 10, 12)):
            add_snare(buf, t, 0.24 * energy, 100 + bar * 17 + pos)
        if pos % 2 == 0:
            add_hat(buf, t, 0.052 * energy * (1.3 if boss and pos in (6, 14) else 1.0), 200 + step)

        if pos % 2 == 0:
            bass_offsets = (0, 0, 7, 0, 0, 10, 7, 0) if not boss else (0, 7, 0, 10, 0, 7, 12, 10)
            bass_note = chord_root - 12 + bass_offsets[(pos // 2) % 8]
            add_tone(buf, t, step_duration * 1.65, midi_hz(bass_note), 0.105 * energy, "square", decay=1.7)
            add_tone(buf, t, step_duration * 1.9, midi_hz(bass_note - 12), 0.060 * energy, "sine", decay=1.5)

        if pos in (2, 6, 10, 14):
            intervals = (0, 3, 7) if not boss else (0, 3, 6)
            for interval in intervals:
                add_tone(buf, t, step_duration * 1.45, midi_hz(chord_root + 12 + interval), 0.034 * energy, "saw", decay=2.0)

        mel = melody[step % len(melody)]
        if mel is not None and (pos % 2 == 0 or boss):
            lead_note = chord_root + 12 + mel
            add_tone(buf, t, step_duration * 1.75, midi_hz(lead_note), 0.070 * energy, "square", decay=1.3)
            add_tone(buf, t, step_duration * 1.55, midi_hz(lead_note + 12), 0.017 * energy, "sine", decay=1.4)

    save_wav(BGM_DIR / f"{name}.wav", buf, 1.4)


def make_sfx(name, duration, build, drive=1.45):
    buf = blank(duration)
    build(buf)
    save_wav(SFX_DIR / f"{name}.wav", buf, drive)


def generate_bgm():
    make_music("title", 112.0, 8, 48, (0, -5, -3, -7),
               (0, None, 7, None, 10, None, 7, None, 3, None, 7, None, 12, None, 10, None), 0.80)
    make_music("battle", 136.0, 8, 45, (0, -5, -2, -7),
               (0, 3, 7, 10, 7, 3, 5, 7, 0, 3, 7, 12, 10, 7, 5, 3), 1.05)
    make_music("final_boss", 148.0, 8, 43, (0, -2, -5, -7),
               (0, 3, 6, 10, 12, 10, 6, 3, 0, 3, 6, 13, 12, 10, 6, 3), 1.15, True)
    make_music("clear", 154.0, 4, 60, (0, 5, 7, 0),
               (0, 4, 7, 12, 16, 12, 7, 4, 7, 12, 16, 19, 16, 12, 7, 4), 0.90)
    make_music("game_over", 84.0, 4, 50, (0, -2, -5, -7),
               (0, None, -2, None, -5, None, -7, None, -5, None, -2, None, -5, None, -7, None), 0.65)


def generate_sfx():
    make_sfx("punch_whiff", 0.18, lambda b: (add_noise(b, 0, 0.16, 0.34, 2.1, 11), add_tone(b, 0.01, 0.12, 390, 0.08, "sine", f1=210, decay=2.2)))
    make_sfx("kick_whiff", 0.24, lambda b: (add_noise(b, 0, 0.22, 0.44, 1.6, 12), add_tone(b, 0.01, 0.18, 280, 0.14, "sine", f1=135, decay=1.9)))
    make_sfx("jump", 0.18, lambda b: (add_tone(b, 0, 0.17, 300, 0.18, "triangle", f1=820, decay=1.4), add_noise(b, 0, 0.08, 0.08, 2.0, 13)))
    make_sfx("land", 0.20, lambda b: (add_kick(b, 0, 0.62), add_noise(b, 0, 0.16, 0.20, 2.2, 14)), 1.55)
    make_sfx("dash", 0.18, lambda b: (add_noise(b, 0, 0.17, 0.40, 1.5, 15), add_tone(b, 0, 0.13, 180, 0.10, "sine", f1=95, decay=2.0)))
    make_sfx("guard", 0.22, lambda b: (add_tone(b, 0, 0.18, 920, 0.28, "sine", decay=2.2), add_tone(b, 0, 0.20, 1380, 0.16, "sine", decay=2.0), add_noise(b, 0, 0.08, 0.18, 2.5, 16)), 1.55)
    make_sfx("throw", 0.30, lambda b: (add_kick(b, 0.04, 0.72), add_noise(b, 0, 0.24, 0.28, 1.8, 17), add_tone(b, 0.02, 0.25, 125, 0.18, "sine", f1=70, decay=1.7)), 1.6)
    make_sfx("throw_escape", 0.22, lambda b: (add_noise(b, 0, 0.20, 0.30, 1.7, 18), add_tone(b, 0, 0.18, 720, 0.16, "square", f1=1500, decay=2.2)))

    make_sfx("hit_weak", 0.20, lambda b: (add_impact(b, 0, 0.72), add_noise(b, 0, 0.10, 0.18, 3.1, 21)), 1.65)
    make_sfx("hit_strong", 0.30, lambda b: (add_impact(b, 0, 1.10), add_noise(b, 0, 0.19, 0.34, 2.3, 22)), 1.75)
    make_sfx("hit_special", 0.38, lambda b: (add_impact(b, 0, 1.18), add_tone(b, 0.01, 0.30, 480, 0.20, "saw", f1=1180, decay=1.55), add_noise(b, 0.02, 0.28, 0.26, 1.8, 23)), 1.8)
    make_sfx("hit_ko", 0.52, lambda b: (add_impact(b, 0, 1.42), add_tone(b, 0, 0.48, 92, 0.42, "sine", f1=48, decay=1.45), add_noise(b, 0, 0.30, 0.52, 1.9, 24)), 1.9)

    make_sfx("special_start", 0.36, lambda b: (add_tone(b, 0, 0.34, 280, 0.24, "saw", f1=1100, decay=1.2), add_tone(b, 0.03, 0.30, 560, 0.12, "square", f1=1500, decay=1.5), add_noise(b, 0, 0.18, 0.10, 2.0, 31)))
    make_sfx("special_attack", 0.42, lambda b: (add_noise(b, 0, 0.34, 0.34, 1.3, 32), add_tone(b, 0, 0.34, 540, 0.20, "saw", f1=130, decay=1.2), add_impact(b, 0.12, 0.90)), 1.75)
    make_sfx("ultimate_warning", 0.55, lambda b: (add_tone(b, 0, 0.50, 330, 0.16, "square", f1=660, decay=0.8), add_tone(b, 0.18, 0.32, 660, 0.15, "square", f1=990, decay=1.0), add_noise(b, 0, 0.50, 0.05, 1.2, 33)))
    make_sfx("ultimate_attack", 0.64, lambda b: (add_noise(b, 0, 0.52, 0.52, 1.0, 34), add_tone(b, 0, 0.46, 950, 0.28, "saw", f1=90, decay=1.1), add_impact(b, 0.08, 1.35), add_impact(b, 0.24, 0.95)), 1.95)

    make_sfx("ui_cursor", 0.08, lambda b: add_tone(b, 0, 0.07, 880, 0.15, "square", decay=2.0))
    make_sfx("ui_confirm", 0.12, lambda b: (add_tone(b, 0, 0.10, 660, 0.15, "square", decay=2.0), add_tone(b, 0.035, 0.08, 990, 0.12, "square", decay=2.0)))
    make_sfx("ui_cancel", 0.12, lambda b: (add_tone(b, 0, 0.10, 660, 0.12, "square", decay=2.0), add_tone(b, 0.035, 0.08, 440, 0.12, "square", decay=2.0)))


def main():
    BGM_DIR.mkdir(parents=True, exist_ok=True)
    SFX_DIR.mkdir(parents=True, exist_ok=True)
    generate_bgm()
    generate_sfx()
    files = sorted(ROOT.rglob("*.wav"))
    total = sum(path.stat().st_size for path in files)
    print(f"ST_ACTION_AUDIO_OK files={len(files)} bytes={total}")


if __name__ == "__main__":
    main()
