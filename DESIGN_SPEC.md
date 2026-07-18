# DESIGN SPEC — "Fermadagi Matematika" (design buzilmasin shartnomasi)

Manba: Claude Design `Matematika Oyini.dc.html` (proyekt 82a603a1). Har qiymat prototipdan aynan
ko'chirilgan. Bu fayl — personaj/sahna/ekran widgetlari uchun yagona haqiqat manbai.
CSS `border-radius: X%` → Flutter `Radius.elliptical(w*X, h*X)`. Barcha px = logical dp.

## Palitra

| Token | Hex | Ishlatilishi |
|---|---|---|
| skyTop | #57ADEE | osmon tepasi |
| skyMid | #8FD0F8 | osmon o'rtasi (46%) |
| skyLow | #B8E6FF | osmon pasti (60%) |
| grassLight | #8ED95E | orqa tepalik |
| grass | #6FC93F | old tepalik / o'yin yer paneli |
| bushDark | #4CA82E | butalar |
| navGrass | #7ED957 | pastki nav yuqori chizig'i (4px) |
| red | #E8433F | CTA, faol tugun, tovuq toji, yurak |
| redDark | #C22F2C | tugma pastki jant |
| redGradTop | #F26B5E / #F05A50 | tugma/banner gradient tepa |
| green | #58B94A | to'g'ri javob, bajarilgan tugun |
| greenDark | #3F8F33 | yashil jant |
| greenLight | #8EDD5F | progress gradient oxiri |
| blue | #3D9BE9 / dark #2C79BD | javob tugmasi 3 |
| yellow | #FFC23C / dark #DB9A14 | javob tugmasi 4 |
| coin | #FFD43C, border #E3A81E, matn #D69410 | tanga |
| streakOrange | #FF8A3D ichi #FFD43C, matn #F07A22 | alanga |
| outline | #4A3B28 | universal jigarrang kontur (2.5-3px) |
| cream | #FFFDF6 | nav fon, panjara ustunlari (#F7F5EE rels) |
| beje | #F2E9CE / jant #D8CBA4 / qulf #B3A67E | qulflangan tugun |
| cardBorder | #F0DDB4 | savol kartasi janti (3px) |
| cardBg oyin | #FDF6E3 | o'yin ekrani foni (166px dan pastda) |
| inkDark | #3A3520 | savol matni |
| inkOlive | #6E7F5A | ikkilamchi matn |
| inkGray | #8A8266 | ✕ tugma |
| navInactive | #A8B894 / #C4CFB4 | nav faol emas |
| mud | #B0654A / dark #8C4C36 | noto'g'ri tugma |
| correctBg | #E3F7E9 | pufak to'g'ri |
| wrongBg | #FFE8E6 | pufak noto'g'ri |
| tagGreen matn #3F8F33 fon #E7F6DF | savol tegi |
| starGold | #FFB020 | ★ |
| headerYellowGlow | rgba(255,212,60,.25) | quyosh halo (12px ring) |
| pathDot | #F7E8B8 | xarita nuqta-yo'li |
| brown | #B5793B / dark #8E5C2B | BOSHLA tugmasi |
| hornFill | #F2D8A0 | sigir shoxi |
| pigPink | #F7B8C4 | sigir quloq/tumshuq, cho'chqa quloq |
| pigBody | #F9BCCB, snout #F08CA4, nostril #A8455C, blush #F585A0, ear #F7A8B8 | cho'chqa |
| sheepWool | #FFFDF6, face/leg #EFD9B8 | qo'y |
| chickBody | #FFD43C, wing #F2B93C, beak/leg #F07A22 | jo'ja |
| nostrilCow | #C25E77 | sigir burun teshigi |

Shrift: Fredoka (uz/en), Nunito (ru — Fredoka'da kirill YO'Q). ★/♥/♡/alanga/tanga — HECH QACHON
matn glifi emas (Fredoka'da yo'q) — widget sifatida chiziladi.

## Personajlar (Stack + Positioned, clipBehavior: Clip.none)

### SIGIR (cow) — bazа 100×92
| Qatlam | Pozitsiya | O'lcham | Stil |
|---|---|---|---|
| chap shox | left:8, top:0 | 16×15 | #F2D8A0, border 3 #4A3B28, radius 7/7/2/2, rotate −14° |
| o'ng shox | right:8, top:0 | 16×15 | shu, rotate +14° |
| chap quloq | left:−5, top:24 | 20×14 | #F7B8C4, border 3, radius 99 (stadium), rotate −20° |
| o'ng quloq | right:−5, top:24 | 20×14 | shu, rotate +20° |
| bosh | left:8, top:10 | 84×76 | #fff, border 3 #4A3B28, radius 46%/46%/44%/44%, overflow hidden |
| — dog' (bosh ichida) | right:−14, top:−12 | 40×36 | #4A3B28 doira (clip qiladi burchakda) |
| — chap ko'z | left:18, top:28 | 11×14 | #4A3B28 ellips; ichida left:2,top:2 4×4 #fff nur |
| — o'ng ko'z | right:18, top:28 | 11×14 | shu |
| — tumshuq | markaz, bottom:3 | 56×26 | #F7B8C4, border 3, radius 14; ichida 2 burun teshigi left/right:12, top:7, 6×9 #C25E77 ellips |
Ishlatish o'lchamlari: avatar 46px doira ichida scale .4; xarita hero 116×107 (scale 1.16); o'yin paneli 100×92; finish 100×92.

### CHO'CHQA (pig) — baza 90×82 (xaritada konteyner 90×82 to'liq o'lchamda)
| chap quloq | left:8, top:0 | 20×20 | #F7A8B8, border 2.5, radius 30%/60%/20%/60%, rotate −16° |
| o'ng quloq | right:8, top:0 | 20×20 | radius 60%/30%/60%/20%, rotate +16° |
| tana/bosh | left:2, top:8 | 86×70 | #F9BCCB, border 3, radius 48% |
| ko'zlar | left/right:20, top:30 | 8×11 | #4A3B28 ellips |
| tumshuq | markaz, top:38 | 34×25 | #F08CA4, border 3, radius 50%; teshiklar left/right:7, top:6, 5×9 #A8455C radius 3 |
| yonoqlar | left/right:8, top:48 | 12×9 | #F585A0 ellips, opacity .85 |
Hint-qatorda: scale .5 → 45×41.

### QO'Y (sheep) — baza 46×42 (xaritada scale 1.8 → 84×78ga yaqin konteyner)
| jun tepa | left:17, top:−2 | 12×10 | #FFFDF6, border 2.5, radius 50% |
| chap quloq | left:−2, top:14 | 11×8 | #EFD9B8, border 2.5, radius 99, rotate −24° |
| o'ng quloq | right:−2, top:14 | 11×8 | shu, rotate +24° |
| tana | left:2, top:2 | 42×32 | #FFFDF6, border 2.5, radius 60%/60%/52%/52% |
| yuz | left:11, top:16 | 24×19 | #EFD9B8, border 2.5, radius 50%; ko'zlar left/right:5, top:6, 4×6 #4A3B28 |

### JO'JA (chick) — baza 40×44
| tuk | left:16, top:−3 | 7×7 | #F07A22, radius 50/50/50/0, rotate −45° |
| tana | left:2, top:4 | 36×38 | #FFD43C, border 2.5 #4A3B28, radius 50% |
| ko'zlar | left/right:12, top:18 | 5×7 | #4A3B28 ellips |
| tumshuq | markaz, top:27 | uchburchak: chap/o'ng 5px transparent, tepa 8px #F07A22 (pastga qaragan) |
| qanotlar | left/right:−2, top:20 | 10×14 | #F2B93C, border 2.5, radius 50%, rotate ±16° |
Juft holda ikkinchisi: scaleX(−1) scale(.86), origin bottom.

### TOVUQ (chicken) — baza 72×84
| toj (3 doira) | left:24,top:−2 11×11; left:31,top:−7 12×13; left:40,top:−2 11×11 | #E8433F, border 2.5, radius 50% |
| oyoqlar | left/right:24, top:72 | 4×11 | #F07A22, radius 2 |
| tana | left:4, top:6 | 64×68 | #FFFDF6, border 3, radius 50%/50%/46%/46% |
| ko'zlar | left/right:22, top:28 | 6×8 | #4A3B28 |
| tumshuq | markaz, top:38 | uchburchak 6px yon / 9px tepa #F07A22 |
| soqol (wattle) | markaz, top:46 | 9×11 | #E8433F ellips |

## Sahna elementlari

- **Quyosh:** 44×44 doira #FFD43C + box-shadow 0 0 0 12px rgba(255,212,60,.25); xaritada left:16, top:2.
- **Bulut:** 38×16 #fff radius 99 opacity .95 + shadow-klonlar `26px 6px 0 -4px #fff, -20px 8px 0 -6px #fff`; kichigi 30×13 opacity .8.
- **Tepaliklar:** orqa — left:−24%, right:−24%, top:96, h:520, #8ED95E, radius 50%/50%/0/0; old — left:−20%, right:−20%, top:150, h:560, #6FC93F.
- **Panjara:** konteyner left/right:14, top:104, h:40. 2 rels: top:8 va top:24, h:5, #EFEDE6 (o'yin ekranida #F7F5EE), radius 3, opacity .95. Ustunlar: repeating 7px ustun + 35px oraliq, #F7F5EE (o'yinda #FFFDF6), butun balandlik.
- **Butalar:** chap — left:−16, bottom:−20, 86×86 #4CA82E doira + shadow `40px 18px 0 -12px`; o'ng — right:−20, bottom:−26, 104×104 + shadow `−46px 22px 0 -16px`.
- **Gullar:** 7×7 doiralar box-shadow klonlar bilan: to'plam1 left:36,top:186 #fff + `52px 30px #FFD43C, 120px −6px #fff, 210px 40px #FFD43C, 300px 10px #fff`; to'plam2 left:70,top:330 #FFD43C + `90px 46px #fff, 190px 20px #FFD43C, 250px 70px #fff`. O'yin panelida: left:150,top:18 6×6 + `36px 12px #FFD43C, 80px 4px #fff, −16px 22px #FFD43C`.
- **Nuqta-yo'l (path):** SVG viewBox 0 0 390 500, `M71 441 C 130 440,190 420,191 381 C 192 340,110 330,98 288 C 88 250,200 250,241 211 C 280 175,140 160,121 120 C 105 85,220 80,261 40`, stroke #F7E8B8, w:6, dasharray "1 15", linecap round → PathMetrics bilan har 16px'da r=3 doira.

## Ekran 1: Xarita (fon: gradient #57ADEE 0% → #8FD0F8 46% → #B8E6FF 60%)

- **Header** (padding 8/16/0, gap 10): avatar 46×46 doira #FFF6DE, border 3 #fff, shadow 0 2 6 rgba(30,60,20,.18), ichida sigir scale .4 (left:3,top:5). Ism 15px w600 #fff (text-shadow 0 1 2 rgba(20,60,110,.35)), "3-daraja" 11px #E3F3FF. Pill'lar (gap 6): oq fon, radius 99, padding 5/10, shadow 0 2 5 rgba(30,60,20,.15): alanga 13×13 (#FF8A3D tomchi rotate −45°, ichida #FFD43C) + "5" 13px w600 #F07A22; tanga 14×14 doira #FFD43C border 3 #E3A81E + "240" #D69410; yurak ♥ #E8433F + "3".
- **Bob banneri** (margin 10/16/0): gradient 135° #F05A50→#E8433F, border 3 #fff, radius 18, padding 10/14, shadow 0 4 12 rgba(180,40,35,.35). Molxona ikonkasi 40×36 (uchburchak tom 21px yon/15px past #E3B778 + tana 34×20 #FFF6DE + eshik 12×13 #C22F2C). "1-BOB · MOLXONA" 10.5px w600 ls1.5 #FFD9CF; "Sanash va qo'shish" 17px w600 #fff. O'ngda jo'ja 40×44.
- **Tugunlar:** bajarilgan — 66×66 doira #58B94A, border 3 #fff + pastki 6 #3F8F33, raqam 26px w700 #fff, ostida oq pill ★★★ 10px #FFB020 (padding 2/8). Pozitsiyalar: 1 → left:40,top:408; 2 → left:158,top:348. Faol — left:55,top:210, ustida BOSHLA! tugma (#B5793B, pastki 4 #8E5C2B, radius 10, padding 5/14, 12.5px w700 ls.5), tugun 86×86 gradient #F26B5E→#E8433F, border 3 #fff + past 7 #C22F2C, "3" 34px, shadow 0 6 14 rgba(190,45,40,.45), pulse 1.6s. Qulflangan — 58×58 #F2E9CE, border 3 #fff + past 6 #D8CBA4, qulf ikonka (#B3A67E: yoy 12×9 border 3 + tana 18×13 radius 3). Pozitsiyalar: left:213,top:183; left:93,top:92; left:233,top:12.
- **Hayvonlar + pufaklar:** cho'chqa right:12,top:96 (90×82), pufagi right:10,top:64 "Xryu! Salom!"; tovuq left:156,top:32 (72×84), pufagi left:148,top:0 "Qo-qo-qo!"; qo'y left:2,top:330 scale 1.8, pufagi left:4,top:300 "Bee-e!"; sigir left:250,top:376 scale 1.16 (116×107), pufagi left:246,top:338 "Muu! O'ynaymizmi?"; 2 jo'ja left:122,top:446 (40×44 + scaleX(−1) scale .86). Pufak: oq, radius 12, padding 5/10, 11.5px w600 #4A3B28, shadow 0 3 8 rgba(40,70,20,.22), dumi 10×10 rotate 45° left:16, bottom:−5.
- **Pastki nav:** fon #FFFDF6, border-top 4 #7ED957, padding 10/8/26. 4 tab: Xarita (faol, #E8433F, bayroq ikonka), Do'kon (uy #A8B894/#C4CFB4), Reyting (kubok), Profil (odam). Matn 10px, faol w600.

## Ekran 2: O'yin (fon: gradient #57ADEE 0 → #8FD0F8 166px → #FDF6E3 170px; panjara top:124)

- **Top bar** (padding 8/16/0, gap 12): ✕ 32×32 oq doira 14px #8A8266; progress 16px oq radius 99, ichida gradient 90° #58B94A→#8EDD5F, width %, transition .4s; yurak pill (♥ 14px ls1 #E8433F).
- **Taymer qatori** (agar yoqiq): soat 18×18 border 3 #fff + mil; bar h:12 rgba(255,255,255,.6) radius 99, ichi gradient 90° #F07A22→#FFD43C, scaleX 1→0 linear, origin left.
- **Savol kartasi** (margin 58/16/12): oq, border 3 #F0DDB4, radius 24, padding 18/16/16, shadow 0 4 14 rgba(90,80,40,.12). Tag: 10.5px w600 ls2 #3F8F33, fon #E7F6DF, radius 99, padding 3/12. Savol: 36px w700 #3A3520. Hint-qator: gap 8, min-h 44, markazda; hayvonlar (jo'ja 40×44 / cho'chqa scale .5 / qo'y 46×42), ayirishda oxirgilari opacity .25; "+" belgisi 28px w700 #E8433F.
- **Javoblar:** grid 2×2, gap 12, margin 0/16. Tugma: padding 14/8, min-h 78, radius 22, pastki jant 5px dark, 28px w600 #fff. Ranglar tartibi: qizil/yashil/ko'k/sariq. Tanlanganda boshqalar opacity .55. To'g'ri → yashil popIn; noto'g'ri → #B0654A shakeX. Shakl-javoblar: oq shakllar (uchburchak 48×40, doira 42, kvadrat 40 r8, romb 34 rotate 45 r7).
- **Yer paneli:** h:132, #6FC93F, radius 24/24/0/0, margin-top 14. Sigir left:16, bottom:12 (100×92). Pufak left:126, bottom:64, radius 14, padding 8/13, 13px w600 #3A3520, max-w 180, fon oq/#E3F7E9/#FFE8E6, dumi chapda bottom:8. O'ngda: tanga pill + "Savol N / 5" pill (11.5px w600 #6E7F5A).
- **Finish overlay:** fon rgba(253,246,227,.94). Karta: oq, border 3 #F0DDB4, radius 28, padding 26/28, w:260, shadow 0 12 34 rgba(90,80,40,.2), popIn .4s. Ichida: sigir 100×92; yulduzlar 32px ls4 #FFB020; "Muu! Barakalla!" 24px w700 #3A3520; "3-daraja tugadi" 14px #9A9070; bonus pill fon #FFF4D6 radius 99 padding 7/16 (+N tanga 16px w700 #D69410); "Qaytadan o'ynash" tugma gradient #F26B5E→#E8433F, past 5 #C22F2C, radius 18, padding 13/26, 16px w700.

## Animatsiyalar (aynan)

- `pulseNode`: scale 1→1.07→1, 1.6s ease-in-out infinite (faol tugun).
- `shakeX`: translateX 0/−7/+7/−7/+7/0 (20/40/60/80%), .4s ease.
- `popIn`: scale .4 (op 0) → 1.12 (70%) → 1 (op 1), .35-.4s ease.
- `timebar`: scaleX 1→0 linear, davomiyligi timerSeconds, origin left.

## Prototip savollari (1-3 daraja aynan shular)

1. SANASH "Nechta jo'jacha?" — 4 jo'ja vizual; javoblar [3,4,5,6], to'g'ri: 4.
2. QO'SHISH "3 + 2 = ?" — 3 cho'chqa + belgi + 2 cho'chqa; [4,5,6,3], to'g'ri: 5.
3. SHAKLLAR "Uchburchakni top!" — javoblar shakl: [doira? — prototipda tartib: tri,cir,sq,dia], to'g'ri: uchburchak (index 0).
4. AYIRISH "5 − 2 = ?" — 5 qo'y, oxirgi 2 tasi opacity .25; [2,3,4,6], to'g'ri: 3.
5. MANTIQ "2, 4, 6, ... ?" — vizualsiz; [7,8,10,9], to'g'ri: 8.

Pufak matnlari: to'g'ri "Muu! Zo'r! +10 tanga" (fon #E3F7E9); noto'g'ri "Hechqisi yo'q, yana urin!"
(#FFE8E6); neytral "Qani, o'ylab ko'r-chi..." (oq). Finish: yulduz = yurak (3→★★★, 2→★★☆, 1→★☆☆),
bonus = 20 + yurak×10.
