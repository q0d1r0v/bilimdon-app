# Asset manbalari (provenance)

## Shriftlar

| Fayl | Manba | Litsenziya |
|---|---|---|
| assets/fonts/Fredoka-*.ttf (4 vazn) | Google Fonts (fonts.gstatic.com, v17) | SIL OFL 1.1 — tijoriy foydalanish OK |
| assets/fonts/Nunito-*.ttf (4 vazn) | Google Fonts (fonts.gstatic.com, v32) | SIL OFL 1.1 |

Eslatma: Fredoka'da kirill va U+02BB glifi YO'Q (tekshirilgan) — ruscha Nunito
bilan, o'zbekcha apostrof U+2019 bilan yoziladi.

## Audio (18 fayl) — 2 manba

### Musiqa + UI ovozlari (13 fayl) — sintez, `tools/gen_audio.py`
Sof Python stdlib (`wave`/`struct`/`math`/`array` — ffmpeg/sox/numpy shart EMAS)
bilan **protsedura orqali sintez**. Manba YO'Q → **public-domain/CC0**.
Regeneratsiya: `python3 tools/gen_audio.py`. **Yumshatilgan** (iyul-17 fikr-mulohaza:
"juda bachkana" edi) — past oberton, kuchliroq LP, sekinroq tempo, yengil perkussiya.

| Fayl | Tavsif |
|---|---|
| sfx/tap, card_slide, whoosh, thunk | UI tovushlari (pluck / swish / sweep / thump) |
| sfx/correct (major arpejio ↑), wrong (yumshoq tushuvchi boing — buzzer EMAS) | javob feedbacki |
| sfx/coin (ikki-ton ding), star (sparkle), win (fanfara), unlock (shimmer), tick | mukofot tovushlari |
| music/music_map | **TINCH** menyu treki — ~66 BPM, marimba + pad + bas (~14.5s uzuksiz loop) |
| music/music_game | **QUVNOQ** o'yin treki — ~104 BPM, yumaloq pluck + yengil perkussiya + bas (~16s uzuksiz loop) |

### Hayvon ovozlari (5 fayl) — REAL yozuvlar, `tools/prepare_animal_sounds.py`
Real CC0 yozuvlar, **BigSoundBank** (bigsoundbank.com/licenses.html — CC0,
"Nothing is mandatory", attribution shart emas). Quvur: OGG (to'g'ridan-to'g'ri) →
`gst-launch-1.0` bilan 16-bit mono 44100 WAV → sof Python bilan birinchi toza
chaqiruvni ajratish + yumshoq normalizatsiya + chekka fade. Regeneratsiya:
`python3 tools/prepare_animal_sounds.py` (internet + gstreamer kerak).

| Fayl | Manba (BigSoundBank) | Litsenziya |
|---|---|---|
| sfx/cow_moo | #2382 "Cow moos 2" | CC0 |
| sfx/pig_oink | #1658 "Grumpy pig 1" | CC0 |
| sfx/sheep_baa | #2343 "Sheep 1" | CC0 |
| sfx/chicken_cluck | #0453 "Annoyed hen" | CC0 |
| sfx/chick_cheep | #0431 "Chick chirp" | CC0 |

## Grafika

Rasm-asset YO'Q — butun grafika kodda chizilgan (Container/BoxDecoration/
CustomPainter), manba: tasdiqlangan Claude Design prototipi (DESIGN_SPEC.md).
