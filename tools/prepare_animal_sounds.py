#!/usr/bin/env python3
"""Real hayvon ovozlarini (CC0, BigSoundBank) yuklab, kesib, normallashtirib
`assets/audio/sfx/` ga WAV sifatida saqlaydi.

Nega: sintez hayvon ovozlari «juda bachkana» tuyuldi → real yozuvlar.
Litsenziya: BigSoundBank — CC0 / public-domain («Nothing is mandatory»,
bigsoundbank.com/licenses.html). Attribution shart emas.

Quvur: OGG (to'g'ridan-to'g'ri, anti-botsiz) → GStreamer bilan 16-bit mono
44100 WAV → sof Python bilan birinchi toza chaqiruvni ajratish + yumshoq
normalizatsiya + chekka fade. (ffmpeg/sox yo'q; WAV yuklash anti-bot bilan
yopiq — shuning uchun OGG + `gst-launch-1.0`.)

TALAB: internet + `gst-launch-1.0` (gstreamer, ogg/vorbis plaginlari).
Chiqish committ qilinadi — keyin qayta ishga tushirish shart emas.

Ishlatish: python3 tools/prepare_animal_sounds.py
"""

from __future__ import annotations

import math
import os
import struct
import subprocess
import tempfile
import urllib.request
import wave

SR = 44100
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
SFX_DIR = os.path.join(ROOT, "assets", "audio", "sfx")
REFERER = "https://bigsoundbank.com/"

# fayl_nomi -> (BigSoundBank id, manba slug, oyna soniya, rejim)
# rejim: "onset" — birinchi chaqiruvdan ketma-ketlikni oladi (yakka/qatorli
#        tovushlar: moo, baa, qo-qo); "densest" — eng zich energiyali oynani
#        oladi (siyrak, uzun yozuvlardan zich burst: jo'ja chirillashi).
# Nomlar diqqat bilan tanlangan: "grumpy-pig" (do'ng'illash) — "prout" (osurik)
# EMAS; "annoyed-hen" (qoqish) — "cock-song" (xo'roz) emas.
SOURCES = {
    "cow_moo":       ("2382", "cow-moos-2-s2382",        1.30, "onset"),
    "pig_oink":      ("1658", "grumpy-pig-1-s1658",      1.20, "onset"),
    "sheep_baa":     ("2343", "sheep-1-s2343",           1.00, "onset"),
    "chicken_cluck": ("0453", "annoyed-hen-s0453",       0.90, "onset"),
    "chick_cheep":   ("0431", "chick-2-stuffings-s0431", 0.45, "densest"),
    # Yangi turlar: o'rdak (haqiqiy "qak-qak") va quyon (yumshoq g'ing'irlash —
    # quyonlar deyarli ovozsiz, shuning uchun cho'zilgan g'ijirlash-squeak).
    "duck_quack":    ("0276", "ducks-s0276",             0.90, "onset"),
    "rabbit_squeak": ("0879", "squeaker-toy-2-s0879",    0.40, "densest"),
}


def download_ogg(sound_id: str, dst: str) -> None:
    url = f"https://bigsoundbank.com/UPLOAD/ogg/{sound_id}.ogg"
    req = urllib.request.Request(url, headers={
        "Referer": REFERER,
        "User-Agent": "Mozilla/5.0 (math_farm asset prep)",
    })
    with urllib.request.urlopen(req, timeout=30) as r, open(dst, "wb") as f:
        f.write(r.read())
    if os.path.getsize(dst) < 2000:
        raise RuntimeError(f"OGG yuklanmadi (juda kichik): {url}")


def ogg_to_wav(src_ogg: str, dst_wav: str) -> None:
    subprocess.run(
        [
            "gst-launch-1.0", "-q",
            "filesrc", f"location={src_ogg}", "!", "decodebin", "!",
            "audioconvert", "!", "audioresample", "!",
            f"audio/x-raw,format=S16LE,rate={SR},channels=1", "!",
            "wavenc", "!", "filesink", f"location={dst_wav}",
        ],
        check=True, capture_output=True,
    )


def load(path: str) -> list[float]:
    with wave.open(path, "rb") as w:
        n = w.getnframes()
        raw = w.readframes(n)
    return [x / 32768.0 for x in struct.unpack(f"<{n}h", raw)]


def _envelope(s: list[float]):
    """5ms rolling absolyut envelope (prefix-sum bilan tez)."""
    n = len(s)
    win = int(0.005 * SR)
    ab = [abs(x) for x in s]
    pre = [0.0] * (n + 1)
    for i in range(n):
        pre[i + 1] = pre[i] + ab[i]
    peak = max(ab) if ab else 0.0

    def env(i: int) -> float:
        a = max(0, i - win)
        b = min(n, i + win)
        return (pre[b] - pre[a]) / (b - a)

    return env, n, peak


def extract_call(s: list[float], target_s: float,
                 thr_frac=0.06, pre_ms=5, tail_ms=45) -> list[float]:
    """Onset'dan `target_s` oyna oladi, oxirgi tovushgacha kesadi (tabiiy
    ketma-ketlikni saqlaydi: «qo-qo-qo», «chip-chip»)."""
    env, n, peak = _envelope(s)
    thr = max(thr_frac * peak, 0.008)
    onset = next((i for i in range(n) if env(i) > thr), 0)
    window_end = min(n, onset + int(target_s * SR))
    last = onset
    for i in range(onset, window_end):
        if env(i) > thr:
            last = i
    a = max(0, onset - int(pre_ms / 1000 * SR))
    b = min(n, last + int(tail_ms / 1000 * SR))
    return s[a:b]


def extract_densest(s: list[float], win_s: float, hop_s=0.02,
                    pre_ms=5, tail_ms=40) -> list[float]:
    """Eng ko'p energiyali `win_s` oynani topadi (siyrak yozuvdan zich burst)."""
    n = len(s)
    win = int(win_s * SR)
    hop = max(1, int(hop_s * SR))
    sq = [x * x for x in s]
    pre = [0.0] * (n + 1)
    for i in range(n):
        pre[i + 1] = pre[i] + sq[i]
    best, bi = -1.0, 0
    for a in range(0, max(1, n - win), hop):
        e = pre[a + win] - pre[a]
        if e > best:
            best, bi = e, a
    a = max(0, bi - int(pre_ms / 1000 * SR))
    b = min(n, bi + win + int(tail_ms / 1000 * SR))
    return s[a:b]


def normalize_fade(s: list[float], peak_t=0.85, fin_ms=4, fout_ms=30):
    m = max((abs(x) for x in s), default=0.0)
    if m > 0:
        g = peak_t / m
        k = math.tanh(1.3)
        s = [math.tanh(1.3 * x * g) / k * peak_t for x in s]
    fi = int(fin_ms / 1000 * SR)
    fo = int(fout_ms / 1000 * SR)
    n = len(s)
    for i in range(min(fi, n)):
        s[i] *= i / fi
    for i in range(min(fo, n)):
        s[n - 1 - i] *= i / fo
    return s


def write_wav(path: str, samples: list[float]) -> None:
    data = struct.pack(
        f"<{len(samples)}h",
        *(max(-32767, min(32767, int(x * 32767))) for x in samples),
    )
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data)


def main() -> None:
    os.makedirs(SFX_DIR, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for name, (sound_id, slug, target_s, mode) in SOURCES.items():
            ogg = os.path.join(tmp, f"{name}.ogg")
            raw_wav = os.path.join(tmp, f"{name}_raw.wav")
            download_ogg(sound_id, ogg)
            ogg_to_wav(ogg, raw_wav)
            raw = load(raw_wav)
            seg = (extract_densest(raw, target_s) if mode == "densest"
                   else extract_call(raw, target_s))
            call = normalize_fade(seg)
            out = os.path.join(SFX_DIR, f"{name}.wav")
            write_wav(out, call)
            print(f"  {name:15s} <- BigSoundBank #{sound_id} ({slug})  "
                  f"{len(call)/SR:.2f}s  {os.path.getsize(out)/1024:.1f}KB")
    print("5 real hayvon ovozi tayyor (CC0, BigSoundBank).")


if __name__ == "__main__":
    main()
