# Fermadagi Matematika (Math Farm)

4-8 yoshdagi bolalar uchun ferma mavzusidagi matematika o'yini.
Tasdiqlangan Claude Design prototipi (`DESIGN_SPEC.md`) asosida — **barcha
grafika kod bilan chizilgan** (rasm-asset yo'q), Flutter widgetlari CSS-art'ni
1:1 ko'chiradi.

## Texnologiya

- **Flutter** (sof widgetlar) — barcha ekranlar/personajlar
- **Flame** — faqat partikl-effektlar (konfetti, tanga-parvoz, uchqunlar)
- `shared_preferences` — lokal progress (`profile_v1` JSON, backend YO'Q)
- `audioplayers` — SFX + musiqa (barcha ovozlar sintezlangan, litsenziya-toza)
- 3 til: o'zbek (asos) / rus / ingliz — `lib/l10n/*.arb`
  - **Muhim:** Fredoka'da kirill YO'Q → ruscha Nunito bilan ko'rsatiladi
  - Apostrof siyosati: faqat U+2019 (') — `test/strings_lint_test.dart` nazorat qiladi

## Ishga tushirish

```bash
flutter pub get
flutter gen-l10n
flutter run
```

## Kontent

Savollar build-vaqtida generatsiya qilinadi (runtime'da EMAS):

```bash
node tools/generate_questions.mjs   # assets/content/ch{1,2,3}.json yozadi
```

3 bob × 6 daraja × 5 savol = 90 savol. 1-3 daraja — prototipdagi 5 savol aynan.
Deterministik (seed = daraja id) — har build bir xil natija.

## Testlar

```bash
flutter test                                  # to'liq suite (205 test)
flutter test --update-goldens test/goldens/   # goldenlarni yangilash
```

**Golden testlar = "design buzilmasin" mexanizmi.** Personaj yoki
dizayn-atomdagi har qanday piksel siljishi CI'da yiqiladi. Goldenlar Linux'da
generatsiya qilingan — faqat shu muhitda solishtiring.

### E2E (web, haqiqiy Chrome)

```bash
# 1) chromedriver ishga tushiring (Chrome versiyasiga mos bo'lishi shart):
~/chromedriver/chromedriver-linux64/chromedriver --port=4444 &

# 2) to'liq foydalanuvchi sayohati:
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/full_journey_test.dart \
  -d web-server --browser-name=chrome --headless
```

Sayohat: xarita → 1-1 daraja (hammasi to'g'ri) → 1-2 daraja (ataylab xato →
repeat-queue + yurak) → do'konda xarid + qo'yish → xaritada bezak ko'rinishi →
profil (til almashtirish, parental gate + statistika) → reyting stub →
qayta yuklashda progress saqlanishi.

**Testlarda `pumpAndSettle` ISHLATILMAYDI** — ilovada cheksiz animatsiyalar bor
(nafas, puls, bulutlar), u hech qachon tinchimaydi. Faqat chegaralangan
`pump(duration)` va `waitFor` helperlari.

## Muhim qoidalar

- `tokens.dart` dan tashqarida xom hex rang YO'Q
- O'yin to'liq offline ishlaydi. Release'dagi INTERNET/ACCESS_NETWORK_STATE/BILLING
  ruxsatlari FAQAT Play Billing kutubxonasidan (`in_app_purchase`) keladi —
  boshqa tarmoq so'rovi qo'shmang
- Analytics/ads/tracker SDK YO'Q — Play Families "No data collected"
- Pul bilan bog'liq har bir tugma ota-onalar darvozasi (`showParentGate`) ortida;
  3–6-boblar bir martalik `full_unlock` xaridi bilan ochiladi
  (`ProgressStore.freeChapters`, `lib/core/purchases/purchase_service.dart`)
- ★/♥/alanga — matn glifi emas, chizilgan widget (Fredoka'da bu glifllar yo'q)
- Yurak hech qachon o'yinni bloklamaydi (floor = 1), taymer faqat bonus rejimda

## Struktura

```
lib/characters/   — HIMOYALANGAN ZONA (golden-tested personajlar)
lib/scene/        — sahna elementlari (osmon/tepalik/panjara/...)
lib/widgets/      — dizayn atomlari (chunky tugma, pill, pufak...)
lib/effects/      — Flame partikl qatlami + LivingAnimal (nafas/pirpirash)
lib/content/      — savol modellari + repository
lib/features/     — ekranlar (map/game/shop/profile/rating/shell)
lib/core/         — theme/audio/persistence/utils
tools/            — build-vaqt savol generatori (Node)
```

## Release oldidan (Play Families)

1. Play Console akkaunt turini tekshiring (yangi shaxsiy akkaunt = 12 tester × 14 kun closed test!)
2. Privacy policy URL tayyorlang (offline bo'lsa ham majburiy)
3. `aapt dump permissions` — faqat BILLING, INTERNET, ACCESS_NETWORK_STATE (Billing'dan)
   va DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION bo'lishi kerak
4. Data safety: "No data collected"; IARC: Everyone/3+
5. Play Console → One-time products: `full_unlock` faol; App Store Connect'da
   xuddi shu ID bilan Non-Consumable
# bilimdon-app
