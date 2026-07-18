#!/usr/bin/env python3
"""Fermadagi Matematika — audio generatori (sof Python stdlib, tashqi asbobsiz).

Barcha 16 SFX + 2 musiqa loopi shu skript bilan protsedura orqali sintez
qilinadi: additiv ovozlar (garmonikalar), ADSR konvertlar, yumshoq saturatsiya,
o'ralib-ketuvchi (wrap-around) reverb dumi bilan UZUKSIZ loop, va soft-limiter
normalizatsiya.

Cheklov: muhitda ffmpeg/sox/numpy YO'Q — faqat `wave`,`struct`,`math`,`array`.
Litsenziya: hammasi o'zi-generatsiya → public-domain/CC0, attribution shart emas.

Ishlatish:
    python3 tools/gen_audio.py
Chiqish:
    assets/audio/sfx/*.wav  (16 ta, mono 44100/16-bit)
    assets/audio/music/music_map.wav, music_game.wav  (uzuksiz looplar)
"""

from __future__ import annotations

import array
import hashlib
import math
import os
import random
import struct
import wave

SR = 44100
TWO_PI = 2.0 * math.pi
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
MUSIC_DIR = os.path.join(ROOT, "assets", "audio", "music")


# ── Asosiy DSP yordamchilari ────────────────────────────────────────────────

def buf(n: int) -> list[float]:
    return [0.0] * n


def mix(dst: list[float], src: list[float], start: int, gain: float = 1.0) -> None:
    """src'ni dst ichiga `start` samplidan qo'shadi (chegaradan chiqsa kesadi)."""
    n = len(dst)
    if start >= n:
        return
    i = start
    for s in src:
        if i >= n:
            break
        if i >= 0:
            dst[i] += s * gain
        i += 1


def env_adsr(n: int, atk: int, dec: int, sus: float, rel: int):
    """Sample indeks → amplituda (0..1). atk/dec/rel — sample sonlari."""
    atk = max(1, atk)
    dec = max(1, dec)
    rel = max(1, rel)
    rel_start = max(atk + dec, n - rel)

    def f(i: int) -> float:
        if i < atk:
            return i / atk
        if i < atk + dec:
            return 1.0 + (sus - 1.0) * (i - atk) / dec
        if i < rel_start:
            return sus
        k = (i - rel_start) / rel
        return sus * (1.0 - min(1.0, k))

    return f


def env_perc(n: int, atk: int, tau: float):
    """Perkussiv: tez atak + eksponensial so'nish (tau — sample)."""
    atk = max(1, atk)

    def f(i: int) -> float:
        if i < atk:
            return i / atk
        return math.exp(-(i - atk) / tau)

    return f


def glide_tone(freq_fn, n: int, partials, env_fn, vib_hz=0.0, vib_depth=0.0):
    """Additiv ton; freq_fn(i)->Hz (glissando uchun faza akkumulyatsiyasi).

    partials: [(mult, amp), ...] — asosiy tonga nisbatan garmonikalar.
    """
    out = [0.0] * n
    inc = TWO_PI / SR
    phases = [0.0] * len(partials)
    for i in range(n):
        f = freq_fn(i)
        vib = 1.0 + vib_depth * math.sin(inc * vib_hz * i) if vib_depth else 1.0
        s = 0.0
        for k, (mult, amp) in enumerate(partials):
            phases[k] += inc * f * mult * vib
            s += amp * math.sin(phases[k])
        out[i] = s * env_fn(i)
    return out


def tone(freq: float, n: int, partials, env_fn, vib_hz=0.0, vib_depth=0.0):
    return glide_tone(lambda i: freq, n, partials, env_fn, vib_hz, vib_depth)


def noise(n: int, env_fn, rng: random.Random):
    return [rng.uniform(-1.0, 1.0) * env_fn(i) for i in range(n)]


def one_pole_lp(src, alpha: float):
    """Oddiy bir-polli past-o'tkazgich (alpha 0..1, katta=yorqinroq)."""
    y = 0.0
    out = [0.0] * len(src)
    for i, x in enumerate(src):
        y += alpha * (x - y)
        out[i] = y
    return out


def one_pole_hp(src, alpha: float):
    lp = one_pole_lp(src, alpha)
    return [x - l for x, l in zip(src, lp)]


def soft_clip(x: float) -> float:
    """Iliqlik uchun yumshoq tanh-saturatsiya."""
    return math.tanh(1.4 * x) / math.tanh(1.4)


def normalize(sig, peak: float = 0.89, saturate: bool = True):
    """Soft-limiter bilan normalizatsiya (klik/dag'allikni oldini oladi)."""
    m = max((abs(s) for s in sig), default=0.0)
    if m < 1e-9:
        return sig
    g = peak / m
    if saturate:
        return [soft_clip(s * g) * peak for s in sig]
    return [s * g for s in sig]


def wrap_seamless(long_buf, loop_len: int):
    """`loop_len`dan oshgan dum (reverb/so'nish)ni boshiga o'raydi → uzuksiz loop."""
    out = long_buf[:loop_len]
    if len(out) < loop_len:
        out += [0.0] * (loop_len - len(out))
    for i in range(loop_len, len(long_buf)):
        out[i - loop_len] += long_buf[i]
    # Seam'dagi mayda klikni o'ldirish uchun juda qisqa (3ms) chekka-fade.
    xf = int(0.003 * SR)
    for i in range(xf):
        out[i] *= i / xf
        out[loop_len - 1 - i] *= i / xf
    return out


def write_wav(path: str, samples) -> int:
    data = array.array(
        "h", (max(-32767, min(32767, int(s * 32767.0))) for s in samples)
    )
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())
    return len(data)


# ── Nota / cholg'u ──────────────────────────────────────────────────────────

_SEMI = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4, "F#": -3,
         "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}


def hz(name: str) -> float:
    """'C4','F#3' → chastota (A4=440)."""
    if name[1] == "#":
        letter, octv = name[:2], int(name[2:])
    else:
        letter, octv = name[0], int(name[1:])
    semis = _SEMI[letter] + (octv - 4) * 12
    return 440.0 * (2.0 ** (semis / 12.0))


def marimba(freq: float, dur_s: float):
    """Yumshoq marimba — iliq, kam ohangdor (yumshatilgan: past oberton)."""
    n = int(dur_s * SR)
    e = env_perc(n, int(0.007 * SR), tau=dur_s * SR * 0.32)
    parts = [(1.0, 1.0), (2.01, 0.18), (3.0, 0.06)]
    return tone(freq, n, parts, e, vib_hz=5.0, vib_depth=0.0016)


def bell(freq: float, dur_s: float):
    """Yumshoq qo'ng'iroq (yumshatilgan: keskin inharmonik yuqorilar pasaytirildi)."""
    n = int(dur_s * SR)
    e = env_perc(n, int(0.004 * SR), tau=dur_s * SR * 0.34)
    parts = [(1.0, 0.9), (2.76, 0.24), (5.4, 0.06)]
    return tone(freq, n, parts, e)


def pluck(freq: float, dur_s: float):
    """Yumaloq pluck (yumshatilgan: kamroq yorqin garmonika)."""
    n = int(dur_s * SR)
    e = env_perc(n, int(0.004 * SR), tau=dur_s * SR * 0.24)
    parts = [(1.0, 0.9), (2.0, 0.28), (3.0, 0.09)]
    return tone(freq, n, parts, e)


def pad(freq: float, dur_s: float):
    """Sekin, iliq pad (detune-chorus bilan)."""
    n = int(dur_s * SR)
    e = env_adsr(n, int(0.12 * SR), int(0.1 * SR), 0.8, int(0.5 * SR))
    out = [0.0] * n
    for det in (-0.004, 0.0, 0.004):
        f = freq * (1 + det)
        parts = [(1.0, 0.5), (2.0, 0.18), (3.0, 0.07)]
        t = tone(f, n, parts, e, vib_hz=4.5, vib_depth=0.003)
        for i in range(n):
            out[i] += t[i] / 3.0
    return out


def bass(freq: float, dur_s: float):
    n = int(dur_s * SR)
    e = env_perc(n, int(0.006 * SR), tau=dur_s * SR * 0.4)
    parts = [(1.0, 1.0), (2.0, 0.28), (3.0, 0.08)]
    return tone(freq, n, parts, e)


def kick(rng: random.Random):
    dur_s = 0.16
    n = int(dur_s * SR)
    e = env_perc(n, int(0.001 * SR), tau=n * 0.22)
    f = glide_tone(lambda i: 120.0 * math.exp(-i / (n * 0.14)) + 45.0,
                   n, [(1.0, 1.0)], e)
    click = noise(int(0.004 * SR), env_perc(int(0.004 * SR), 1, n * 0.02), rng)
    out = f[:]
    mix(out, click, 0, 0.3)
    return out


def hat(rng: random.Random, dur_s: float = 0.05):
    n = int(dur_s * SR)
    e = env_perc(n, 1, tau=n * 0.25)
    return one_pole_hp(noise(n, e, rng), 0.85)


# ── Musiqa aranjirovkalari ──────────────────────────────────────────────────

def sequence(events, bpm: float, total_len: int, render, gain: float, ring=1.0):
    """events: [(nota|None, davomiylik_bit), ...]. Nota o'z so'nishi bilan yangraydi."""
    out = [0.0] * total_len
    bs = 60.0 / bpm * SR
    t = 0.0
    for name, dur in events:
        start = int(t)
        if name is not None:
            b = render(hz(name), dur * (60.0 / bpm) * ring)
            mix(out, b, start, gain)
        t += dur * bs
    return out


def chords(prog, bpm: float, total_len: int, render, gain: float):
    """prog: [([nota,...], davomiylik_bit), ...] — akkordlar (pad/stab)."""
    out = [0.0] * total_len
    bs = 60.0 / bpm * SR
    t = 0.0
    for names, dur in prog:
        start = int(t)
        for nm in names:
            b = render(hz(nm), dur * (60.0 / bpm))
            mix(out, b, start, gain / max(1, len(names)))
        t += dur * bs
    return out


def build_map_music():
    """TINCH menyu treki — ~66 BPM, C-major, marimba + pad + yumshoq bas."""
    bpm = 66.0
    beats = 16  # 4 bar × 4 beat ≈ 14.5s
    loop_len = int(beats * 60.0 / bpm * SR)
    total = loop_len + int(1.6 * SR)  # dum uchun zaxira

    prog = [
        (["C3", "E4", "G4"], 4),
        (["A2", "C4", "E4"], 4),
        (["F2", "A3", "C4"], 4),
        (["G2", "B3", "D4"], 4),
    ]
    # Yumshoq pentatonik marimba motivi (C D E G A).
    melody = [
        ("G4", 1), ("E4", 1), ("C4", 1), ("D4", 1),
        ("E4", 2), ("G4", 1), ("A4", 1),
        ("G4", 1), ("E4", 1), ("F4", 1), ("A4", 1),
        ("G4", 2), ("D4", 1), ("E4", 1),
    ]
    bass_line = [
        ("C2", 2), ("G2", 2), ("A2", 2), ("E2", 2),
        ("F2", 2), ("C3", 2), ("G2", 2), ("D3", 2),
    ]

    out = [0.0] * total
    for part, g in (
        (chords(prog, bpm, total, pad, 0.42), 1.0),
        (sequence(melody, bpm, total, marimba, 0.5, ring=1.6), 1.0),
        (sequence(bass_line, bpm, total, bass, 0.34, ring=1.2), 1.0),
    ):
        for i in range(total):
            out[i] += part[i] * g

    out = one_pole_lp(out, 0.42)         # iliqroq, o'tkir emas (yumshatilgan)
    out = wrap_seamless(out, loop_len)
    return normalize(out, peak=0.72)


def build_game_music():
    """QUVNOQ o'yin treki — ~104 BPM, yumaloq pluck + yengil perkussiya + walking bas."""
    bpm = 104.0
    beats = 28  # ≈16s
    loop_len = int(beats * 60.0 / bpm * SR)
    total = loop_len + int(1.0 * SR)
    rng = random.Random(202607)

    # Yorqin, o'yinbop melodiya (C-major, ba'zi sakrashlar bilan).
    melody = [
        ("C5", 1), ("E5", 1), ("G5", 1), ("E5", 1),
        ("F5", 1), ("A5", 1), ("G5", 2),
        ("E5", 1), ("G5", 1), ("C6", 1), ("G5", 1),
        ("A5", 1), ("F5", 1), ("E5", 2),
        ("D5", 1), ("F5", 1), ("A5", 1), ("F5", 1),
        ("G5", 1), ("E5", 1), ("C5", 2),
        ("G4", 1), ("C5", 1), ("E5", 1), ("G5", 1),
    ]
    stabs = [
        (["C4", "E4", "G4"], 2), (["F4", "A4", "C5"], 2),
        (["C4", "E4", "G4"], 2), (["E4", "G4", "B4"], 2),
        (["F4", "A4", "C5"], 2), (["C4", "E4", "G4"], 2),
        (["G4", "B4", "D5"], 2),
    ]
    walk = [
        ("C3", 1), ("G3", 1), ("C3", 1), ("E3", 1),
        ("F3", 1), ("C3", 1), ("F3", 1), ("A3", 1),
        ("C3", 1), ("G3", 1), ("E3", 1), ("G3", 1),
        ("F3", 1), ("A3", 1), ("G3", 1), ("B3", 1),
        ("F3", 1), ("A3", 1), ("D3", 1), ("F3", 1),
        ("C3", 1), ("E3", 1), ("C3", 1), ("G3", 1),
        ("G3", 1), ("E3", 1), ("C3", 1), ("G3", 1),
    ]

    out = [0.0] * total
    mel = sequence(melody, bpm, total, pluck, 0.5, ring=1.0)
    stb = chords(stabs, bpm, total, lambda f, d: pluck(f, min(d, 0.28)), 0.3)
    bs_ = sequence(walk, bpm, total, bass, 0.4, ring=0.9)
    for i in range(total):
        out[i] += mel[i] + stb[i] + bs_[i]

    # Perkussiya: kick har bitda, hat offbeatda (yengilroq — kamroq "bachkana").
    bsamp = 60.0 / bpm * SR
    for b in range(beats):
        mix(out, kick(rng), int(b * bsamp), 0.3)
        mix(out, hat(rng), int((b + 0.5) * bsamp), 0.1)

    out = one_pole_lp(out, 0.5)          # umumiy yorqinlikni pasaytirish
    out = wrap_seamless(out, loop_len)
    return normalize(out, peak=0.8)


# ── SFX ─────────────────────────────────────────────────────────────────────

def sfx_tap():
    return normalize(pluck(880.0, 0.07), peak=0.7)


def sfx_card_slide(rng):
    n = int(0.2 * SR)
    e = env_adsr(n, int(0.02 * SR), int(0.02 * SR), 0.7, int(0.1 * SR))
    sw = one_pole_hp(noise(n, e, rng), 0.6)
    sw = one_pole_lp(sw, 0.4)
    return normalize(sw, peak=0.55)


def sfx_whoosh(rng):
    n = int(0.4 * SR)
    e = env_adsr(n, int(0.14 * SR), int(0.02 * SR), 0.9, int(0.2 * SR))
    nz = noise(n, e, rng)
    # LP kesim vaqt bilan ochiladi (sweep taassuroti).
    out = [0.0] * n
    y = 0.0
    for i in range(n):
        a = 0.05 + 0.5 * (i / n)
        y += a * (nz[i] - y)
        out[i] = y
    return normalize(out, peak=0.6)


def sfx_thunk():
    n = int(0.16 * SR)
    e = env_perc(n, int(0.002 * SR), tau=n * 0.18)
    t = glide_tone(lambda i: 180.0 * math.exp(-i / (n * 0.3)) + 70.0,
                   n, [(1.0, 1.0), (2.0, 0.2)], e)
    return normalize(t, peak=0.8)


def sfx_correct():
    # Yorqin major arpejio ↑: C5 E5 G5 C6.
    seq = ["C5", "E5", "G5", "C6"]
    step = int(0.085 * SR)
    total = step * len(seq) + int(0.4 * SR)
    out = [0.0] * total
    for k, nm in enumerate(seq):
        mix(out, marimba(hz(nm), 0.42), k * step, 0.8)
    return normalize(out, peak=0.85)


def sfx_wrong():
    # Yumshoq tushuvchi "boing" (buzzer EMAS): G4→D4 pitch-bend, iliq.
    n = int(0.3 * SR)
    e = env_perc(n, int(0.008 * SR), tau=n * 0.4)
    f0, f1 = hz("G4"), hz("D4")
    t = glide_tone(lambda i: f0 * (1 - i / n) + f1 * (i / n),
                   n, [(1.0, 1.0), (2.0, 0.25)], e, vib_hz=6.0, vib_depth=0.01)
    return normalize(one_pole_lp(t, 0.5), peak=0.62)


def sfx_coin():
    # Klassik ikki-ton "ding": B5 → E6.
    s1 = bell(hz("B5"), 0.09)
    s2 = bell(hz("E6"), 0.22)
    total = int(0.32 * SR)
    out = [0.0] * total
    mix(out, s1, 0, 0.7)
    mix(out, s2, int(0.07 * SR), 0.8)
    return normalize(out, peak=0.75)


def sfx_star():
    # Sparkle: yuqoriga bell triadasi + shimmer.
    seq = ["G5", "C6", "E6"]
    step = int(0.05 * SR)
    total = int(0.4 * SR)
    out = [0.0] * total
    for k, nm in enumerate(seq):
        mix(out, bell(hz(nm), 0.3), k * step, 0.6)
    return normalize(out, peak=0.72)


def sfx_win():
    # Tantanali fanfara: F-major yo'nalishi + oxirida C-major akkord.
    out = [0.0] * int(1.05 * SR)
    arp = ["C5", "E5", "G5", "C6"]
    step = int(0.1 * SR)
    for k, nm in enumerate(arp):
        mix(out, marimba(hz(nm), 0.5), k * step, 0.7)
    # Yakuniy akkord.
    for nm in ("C5", "E5", "G5", "C6"):
        mix(out, bell(hz(nm), 0.7), int(0.42 * SR), 0.5)
    return normalize(out, peak=0.9)


def sfx_unlock():
    # Ko'tariluvchi shimmer glissando.
    n = int(0.35 * SR)
    e = env_adsr(n, int(0.02 * SR), int(0.05 * SR), 0.8, int(0.18 * SR))
    f0, f1 = hz("C4"), hz("C6")
    t = glide_tone(lambda i: f0 * (2.0 ** (2.0 * i / n)),
                   n, [(1.0, 0.8), (2.0, 0.3), (3.0, 0.12)], e)
    return normalize(t, peak=0.7)


def sfx_tick():
    n = int(0.05 * SR)
    e = env_perc(n, 1, tau=n * 0.12)
    return normalize(tone(1600.0, n, [(1.0, 1.0)], e), peak=0.5)


# Hayvon ovozlari (cow_moo/pig_oink/sheep_baa/chicken_cluck/chick_cheep) bu
# skriptdan OLIB TASHLANDI — endi real CC0 yozuvlar, `prepare_animal_sounds.py`.


# ── Main ────────────────────────────────────────────────────────────────────

def _report(path: str):
    with wave.open(path, "rb") as w:
        fr = w.getnframes()
        rate = w.getframerate()
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        md5 = hashlib.md5(f.read()).hexdigest()[:8]
    return f"{os.path.basename(path):20s} {fr/rate:5.2f}s  {size/1024:7.1f}KB  md5:{md5}"


def main():
    os.makedirs(SFX_DIR, exist_ok=True)
    os.makedirs(MUSIC_DIR, exist_ok=True)
    rng = random.Random(4242)

    sfx = {
        "tap": sfx_tap(),
        "card_slide": sfx_card_slide(rng),
        "whoosh": sfx_whoosh(rng),
        "thunk": sfx_thunk(),
        "correct": sfx_correct(),
        "wrong": sfx_wrong(),
        "coin": sfx_coin(),
        "star": sfx_star(),
        "win": sfx_win(),
        "unlock": sfx_unlock(),
        "tick": sfx_tick(),
        # DIQQAT: 5 hayvon ovozi (cow_moo/pig_oink/sheep_baa/chicken_cluck/
        # chick_cheep) bu yerda EMAS — ular real CC0 yozuvlar, alohida
        # `tools/prepare_animal_sounds.py` bilan tayyorlanadi. Bu skript
        # ularni ustiga yozmaydi.
    }

    print("── SFX (musiqa + UI) ──")
    for name, sig in sfx.items():
        p = os.path.join(SFX_DIR, f"{name}.wav")
        write_wav(p, sig)
        print("  " + _report(p))

    print("── MUSIC ──")
    for name, sig in (("music_map", build_map_music()),
                      ("music_game", build_game_music())):
        p = os.path.join(MUSIC_DIR, f"{name}.wav")
        write_wav(p, sig)
        print("  " + _report(p))

    # Ikki musiqa fayli haqiqatan farqli ekanini tasdiqlash.
    m1 = os.path.join(MUSIC_DIR, "music_map.wav")
    m2 = os.path.join(MUSIC_DIR, "music_game.wav")
    with open(m1, "rb") as a, open(m2, "rb") as b:
        d1, d2 = a.read(), b.read()
    print(f"\nmap≠game: {hashlib.md5(d1).hexdigest() != hashlib.md5(d2).hexdigest()}")
    print(f"Yaratildi: 11 UI SFX + 2 music (hayvonlar alohida). SR={SR} mono/16-bit.")


if __name__ == "__main__":
    main()
