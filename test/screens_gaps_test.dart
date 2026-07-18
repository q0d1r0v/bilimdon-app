import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/characters/pig.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/core/theme/tokens.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/features/map/map_screen.dart';
import 'package:math_farm/features/profile/parent_gate.dart';
import 'package:math_farm/features/profile/profile_screen.dart';
import 'package:math_farm/features/rating/rating_screen.dart';
import 'package:math_farm/features/shop/shop_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';
import 'package:math_farm/scene/decorations.dart';
import 'package:math_farm/scene/lock_icon.dart';
import 'package:math_farm/widgets/chunky_button.dart';
import 'package:math_farm/widgets/icons.dart';

/// Ekranlarning kam qamralgan holatlari: xarita tugun holatlari va dekor
/// slotlari, do'kon tugma matnlari, profil sozlamalari/ota-onalar darvozasi,
/// reyting stubi va juda kichik ekranli o'yin.
///
/// Cheksiz animatsiyalar (pulse, bulutlar) bor — pumpAndSettle EMAS,
/// faqat chegaralangan pump qadamlari.
Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// audioplayers plagin kanallarini jim mock qiladi — tap/BGM chaqiruvlari
/// platformaga chiqmaydi va test xatosiz o'tadi.
void mockAudioChannels(TestDefaultBinaryMessenger messenger) {
  final channels = <String>[
    'xyz.luan/audioplayers',
    'xyz.luan/audioplayers.global',
    'xyz.luan/audioplayers.global/events',
    'xyz.luan/audioplayers/events/bgm',
    for (var i = 0; i < 4; i++) 'xyz.luan/audioplayers/events/sfx$i',
  ];
  for (final name in channels) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}

/// To'liq ekranli sahifalar (xarita, o'yin) uchun o'ram.
Widget wrapHome(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('uz'),
    home: child,
  );
}

/// Tab-kontent sahifalar (do'kon, profil, reyting) uchun o'ram.
Widget wrapBody(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('uz'),
    home: Scaffold(body: child),
  );
}

/// `profile_v1` hujjatini tayyorlaydi (schemaVersion avtomatik qo'shiladi).
void seedProfile(Map<String, Object?> fields) {
  SharedPreferences.setMockInitialValues({
    'profile_v1': jsonEncode({'schemaVersion': 1, ...fields}),
  });
}

Future<ProgressStore> loadStore() =>
    ProgressStore.load(nowProvider: () => DateTime(2026, 7, 16, 12));

/// Telefon portret yuzasi — GameScreen va xarita tugunlari sig'ishi uchun.
void usePhonePortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Qo'lda yasalgan sanash savoli (game_screen_test bilan bir uslub).
Question countingQ({
  required String id,
  required List<int> answers,
  required int correctIndex,
  int visualCount = 3,
}) {
  return Question(
    id: id,
    type: QuestionType.counting,
    data: const {'animal': 'chick'},
    visual: VisualHint(
      kind: VisualKind.count,
      animal: HintAnimal.chick,
      count: visualCount,
    ),
    answers: [for (final n in answers) AnswerCell.number(n)],
    correctIndex: correctIndex,
  );
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final uz = AppLocalizationsUz();

  setUp(() {
    mockAudioChannels(binding.defaultBinaryMessenger);
    // SFX/BGM chaqiruvlari platformaga chiqmasin.
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;
  });

  group('MapScreen', () {
    testWidgets(
        'bajarilgan tugun to’g’ri yulduzli pill ko’rsatadi va qayta '
        'o’ynash uchun bosiladi (GameScreen ochiladi)', (tester) async {
      usePhonePortrait(tester);
      seedProfile({
        'levels': {
          '1-1': {'stars': 2, 'attempts': 1},
        },
      });
      final store = await loadStore();
      expect(store.starsFor('1-1'), 2);

      // Oldingi testning fake-async zonasidagi rootBundle keshi bilan
      // to'qnashmaslik uchun toza boshlaymiz.
      rootBundle.clear();
      await tester.pumpWidget(wrapHome(MapScreen(store: store)));
      await pumpFrames(tester, 10);

      // 1-tugun bajarilgan: bitta ★-pill, ichida aynan 2 to'la yulduz.
      expect(find.byType(StarRatingPill), findsOneWidget);
      expect(
        tester.widget<StarRatingPill>(find.byType(StarRatingPill)).stars,
        2,
      );
      expect(
        find.descendant(
          of: find.byType(StarRatingPill),
          matching:
              find.byWidgetPredicate((w) => w is StarIcon && w.filled),
        ),
        findsNWidgets(2),
      );

      // Bajarilgan tugun QAYTA O'YNALADI: bosish darajani ochadi.
      await tester.tap(find.text('1'));
      await pumpFrames(tester, 8);
      expect(find.byType(GameScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('qulflangan tugun bosilganda navigatsiya YO’Q (faqat wiggle)',
        (tester) async {
      usePhonePortrait(tester);
      SharedPreferences.setMockInitialValues({});
      final store = await loadStore();

      rootBundle.clear();
      await tester.pumpWidget(wrapHome(MapScreen(store: store)));
      await pumpFrames(tester, 10);

      // Yangi profil: butun scroll-xaritada faqat 1-1 faol, qolgan 35 qulf.
      expect(find.byType(LockIcon), findsNWidgets(35));

      // Ko'rinadigan qulflangan tugunni tanlab bosamiz (scroll-xarita).
      final locked = find.byType(LockIcon).last;
      await tester.ensureVisible(locked);
      await pumpFrames(tester, 2);
      await tester.tap(locked, warnIfMissed: false);
      // Wiggle 420ms — chegaralangan kadrlar bilan o'tkazamiz.
      await pumpFrames(tester, 6);

      expect(find.byType(GameScreen), findsNothing);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dekor slotlari faqat kiyilgan buyumlarni chizadi',
        (tester) async {
      seedProfile({
        'shop': {
          'owned': ['flowerBed', 'tree', 'hay', 'pond'],
          'equipped': {'decor1': 'flowerBed', 'decor2': 'tree'},
        },
      });
      final store = await loadStore();

      rootBundle.clear();
      await tester.pumpWidget(wrapHome(MapScreen(store: store)));
      await pumpFrames(tester, 10);

      // Kiyilganlar chizilgan, sotib olingan-lekin-kiyilmaganlar YO'Q.
      expect(find.byType(FlowerBed), findsOneWidget);
      expect(find.byType(AppleTree), findsOneWidget);
      expect(find.byType(HayStack), findsNothing);
      expect(find.byType(Pond), findsNothing);

      // Slotga kiyish jonli ravishda xaritani yangilaydi.
      await store.setEquipped('decor3', 'hay');
      await pumpFrames(tester, 2);
      expect(find.byType(HayStack), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('header displayLevel/tanga/streak ni store’dan ko’rsatadi',
        (tester) async {
      seedProfile({
        'coins': 250,
        'streakCurrent': 7,
        'streakBest': 7,
        'levels': {
          for (var l = 1; l <= 4; l++)
            '1-$l': {'stars': 3, 'attempts': 1},
        },
      });
      final store = await loadStore();
      // 12 yulduz -> displayLevel = 1 + 12 ~/ 6 = 3.
      expect(store.displayLevel, 3);

      rootBundle.clear();
      await tester.pumpWidget(wrapHome(MapScreen(store: store)));
      await pumpFrames(tester, 10);

      expect(find.text('Aziza'), findsOneWidget);
      expect(find.text(uz.levelBadge(3)), findsOneWidget);
      expect(find.text('250'), findsOneWidget); // tanga pill
      expect(find.text('7'), findsOneWidget); // streak pill
      expect(tester.takeException(), isNull);
    });
  });

  group('ShopScreen', () {
    testWidgets('uchala tugma holati matnlari buyum holatiga mos',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      seedProfile({
        'coins': 0,
        'shop': {
          'owned': ['flowerBed', 'cowHat', 'chickBow'],
          'equipped': {'decor1': 'flowerBed', 'cow': 'cowHat'},
        },
      });
      final store = await loadStore();

      await tester.pumpWidget(wrapBody(ShopScreen(store: store)));
      await tester.pump();

      // Kiyilgan dekor — «olib qo'yish», kiyilgan aksessuar — «yechish»,
      // sotib olingan-lekin-kiyilmagan aksessuar — «kiyish».
      expect(find.text(uz.shopRemove), findsOneWidget); // flowerBed
      expect(find.text(uz.shopUnequip), findsOneWidget); // cowHat
      expect(find.text(uz.shopEquip), findsOneWidget); // chickBow
      expect(find.text(uz.shopPlace), findsNothing);

      // Sotib olinganlarning narxi ko'rinmaydi, qolganlarniki ko'rinadi.
      expect(find.text('100'), findsNothing); // flowerBed olingan
      expect(find.text('200'), findsNothing); // chickBow olingan
      expect(find.text('300'), findsNWidgets(3)); // tree/pigGlasses/sheepScarf
      expect(find.text('400'), findsOneWidget); // hay
      expect(find.text('500'), findsOneWidget); // pond (cowHat olingan)
      expect(tester.takeException(), isNull);
    });

    testWidgets('tanga yetmasa shopNotEnough pufagi chiqadi, balans o’zgarmas',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      seedProfile({'coins': 350});
      final store = await loadStore();

      await tester.pumpWidget(wrapBody(ShopScreen(store: store)));
      await tester.pump();

      // hay narxi 400 — yagona '400' tugma. (Power-up seksiyasi tepada,
      // dekor pastroqda — ko'rinadigan qilib scroll qilamiz.)
      await tester.ensureVisible(find.text('400'));
      await tester.pump();
      await tester.tap(find.text('400'));
      await tester.pump();

      expect(find.text(uz.shopNotEnough), findsOneWidget);
      expect(store.coins, 350);
      expect(store.ownedItems, isEmpty);

      // Pufak 1.2s dan keyin o'zi yo'qoladi.
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text(uz.shopNotEnough), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'sotib olish -> qo’yish -> olib qo’yish to’liq oqimi store’ni '
        'yangilaydi', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      seedProfile({'coins': 150});
      final store = await loadStore();

      await tester.pumpWidget(wrapBody(ShopScreen(store: store)));
      await tester.pump();

      // Sotib olish: flowerBed narxi 100 — yagona '100' tugma.
      await tester.tap(find.text('100'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // popIn tugashi

      expect(store.coins, 50);
      expect(store.ownedItems.contains('flowerBed'), isTrue);
      expect(find.text(uz.shopPlace), findsOneWidget);

      // Qo'yish: slot band bo'ladi, tugma «olib qo'yish»ga aylanadi.
      await tester.tap(find.text(uz.shopPlace));
      await tester.pump();
      expect(store.equippedFor('decor1'), 'flowerBed');
      expect(find.text(uz.shopRemove), findsOneWidget);
      expect(find.text(uz.shopPlace), findsNothing);

      // Olib qo'yish: slot bo'shaydi, tugma yana «qo'yish».
      await tester.tap(find.text(uz.shopRemove));
      await tester.pump();
      expect(store.equippedFor('decor1'), isNull);
      expect(find.text(uz.shopPlace), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ProfileScreen', () {
    testWidgets(
        'til chiplari joriy tilni belgilaydi, bosish setLocaleOverride '
        'chaqiradi', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final store = await loadStore();
      expect(store.localeOverride, isNull);

      await tester.pumpWidget(wrapBody(ProfileScreen(store: store)));
      await tester.pump();

      // Joriy locale uz — faqat o'zbekcha chip yashil.
      final uzChip = tester.widget<ChunkyButton>(find.ancestor(
        of: find.text('O’zbekcha'),
        matching: find.byType(ChunkyButton),
      ));
      final ruChip = tester.widget<ChunkyButton>(find.ancestor(
        of: find.text('Русский'),
        matching: find.byType(ChunkyButton),
      ));
      final enChip = tester.widget<ChunkyButton>(find.ancestor(
        of: find.text('English'),
        matching: find.byType(ChunkyButton),
      ));
      expect(uzChip.color, FarmColors.green);
      expect(ruChip.color, Colors.white);
      expect(enChip.color, Colors.white);

      // Chip bosilganda override store'ga yoziladi.
      await tester.tap(find.text('Русский'));
      await tester.pump();
      expect(store.localeOverride, 'ru');

      await tester.tap(find.text('English'));
      await tester.pump();
      expect(store.localeOverride, 'en');
      expect(tester.takeException(), isNull);
    });

    testWidgets('ovoz/musiqa/taymer switchlari store’ga saqlanadi',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final store = await loadStore();
      expect(store.soundOn, isTrue);
      expect(store.musicOn, isTrue);
      expect(store.timerAllowed, isTrue);

      await tester.pumpWidget(wrapBody(ProfileScreen(store: store)));
      await tester.pump();

      // Tartib: ovoz, musiqa, taymer.
      await tester.tap(find.byType(Switch).at(0));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.soundOn, isFalse);
      expect(AudioService.instance.soundOn, isFalse);

      await tester.tap(find.byType(Switch).at(1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.musicOn, isFalse);

      await tester.tap(find.byType(Switch).at(2));
      await tester.pump(const Duration(milliseconds: 300));
      expect(store.timerAllowed, isFalse);

      // Diskka ham yozilgan: qayta yuklangan store xuddi shu holatda.
      final reloaded = await loadStore();
      expect(reloaded.soundOn, isFalse);
      expect(reloaded.musicOn, isFalse);
      expect(reloaded.timerAllowed, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'ota-onalar darvozasi: noto’g’ri javob qayta so’raydi, to’g’risi '
        'haqiqiy statistikani ochadi', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      seedProfile({
        'coins': 123,
        'streakCurrent': 4,
        'streakBest': 6,
        'levels': {
          '1-1': {'stars': 3, 'attempts': 2},
          '1-2': {'stars': 2, 'attempts': 1},
        },
        'skills': {
          'counting': {'answered': 30, 'correctFirstTry': 21},
          'addition': {'answered': 12, 'correctFirstTry': 9},
        },
        'totals': {'questionsAnswered': 42, 'levelsCompleted': 2},
      });
      final store = await loadStore();

      await tester.pumpWidget(wrapBody(ProfileScreen(store: store)));
      await tester.pump();

      // Statistika qulflangan — qatorlar ko'rinmaydi.
      expect(find.text(uz.statQuestions), findsNothing);
      expect(find.text('42'), findsNothing);

      await tester.tap(find.text(uz.statsTitle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ParentGateDialog), findsOneWidget);

      // Savol matnidan a × b ni o'qib olamiz.
      (int, int) parsePrompt() {
        final text = tester.widget<Text>(find.textContaining('×')).data!;
        final m = RegExp(r'(\d+) × (\d+)').firstMatch(text)!;
        return (int.parse(m.group(1)!), int.parse(m.group(2)!));
      }

      List<int> options() => [
            for (final t in tester.widgetList<Text>(find.descendant(
              of: find.byType(ParentGateDialog),
              matching: find.byType(Text),
            )))
              if (int.tryParse(t.data ?? '') != null) int.parse(t.data!),
          ];

      var (a, b) = parsePrompt();
      var correct = a * b;
      final opts = options();
      expect(opts.length, 4);
      expect(opts, contains(correct));

      // Noto'g'ri javob: dialog yopilmaydi, ogohlantirish chiqadi,
      // statistika hali ham qulf ortida.
      final wrong = opts.firstWhere((o) => o != correct);
      await tester.tap(find.descendant(
        of: find.byType(ParentGateDialog),
        matching: find.text('$wrong'),
      ));
      await tester.pump();
      expect(find.byType(ParentGateDialog), findsOneWidget);
      expect(find.text(uz.parentGateWrong), findsOneWidget);
      // Statistika hali ham qulf ortida. DIQQAT: qiymat ('42') bilan emas,
      // qator YORLIG'I bilan tekshiramiz — darvoza variantlari tasodifan
      // 42 (6×7) bo'lishi mumkin.
      expect(find.text(uz.statQuestions), findsNothing);

      // Reroll'dan keyingi YANGI savolga to'g'ri javob beramiz.
      (a, b) = parsePrompt();
      correct = a * b;
      await tester.tap(find.descendant(
        of: find.byType(ParentGateDialog),
        matching: find.text('$correct'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ParentGateDialog), findsNothing);
      // Qatorlar haqiqiy store raqamlari bilan. DIQQAT: profil kartasidagi
      // yosh chiplari (4–8) ham raqam ko'rsatadi, shuning uchun statistika
      // qiymatlari FAQAT statistika kartasi ichida qidiriladi.
      Finder statCell(String v) => find.descendant(
            of: find.byKey(const ValueKey('statsCard')),
            matching: find.text(v),
          );
      expect(find.text(uz.statQuestions), findsOneWidget);
      expect(statCell('42'), findsOneWidget); // savollar
      expect(find.text(uz.statCorrectFirstTry), findsOneWidget);
      expect(statCell('30'), findsOneWidget); // 21 + 9
      expect(statCell('5'), findsOneWidget); // yulduzlar: 3 + 2
      expect(statCell('2'), findsOneWidget); // tugatilgan darajalar
      expect(statCell('4'), findsOneWidget); // streak
      expect(statCell('123'), findsOneWidget); // tangalar
      expect(tester.takeException(), isNull);
    });
  });

  group('RatingScreen', () {
    testWidgets('stub «tez kunda» matni, cho’chqa va 3 sirli pill bilan',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await loadStore();

      await tester.pumpWidget(wrapBody(RatingScreen(store: store)));
      await pumpFrames(tester, 3);

      expect(find.text(uz.comingSoon), findsOneWidget);
      expect(find.text(uz.ratingSoonBubble), findsOneWidget);
      expect(find.byType(PigWidget), findsOneWidget);
      expect(find.text('???'), findsNWidgets(3));

      // Cho'chqa bosilsa xur-xur (mock) — istisnosiz.
      await tester.tap(find.byType(PigWidget));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('GameScreen kichik ekran', () {
    testWidgets('320x568 ultra-kichik ekranda 1-1 q1 da overflow yo’q',
        (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({});
      final store = await loadStore();
      final level = LevelDef(
        id: '1-1',
        chapter: 1,
        index: 1,
        timerEnabled: false,
        timerSeconds: 0,
        questions: [
          countingQ(
            id: 'q1',
            answers: [1, 2, 3, 4],
            correctIndex: 3,
            visualCount: 4,
          ),
        ],
      );

      // RenderFlex overflow xatolari FlutterError.reportError orqali
      // keladi — to'g'ridan-to'g'ri ushlab, bo'shligini tekshiramiz.
      final layoutErrors = <FlutterErrorDetails>[];
      final oldOnError = FlutterError.onError;
      FlutterError.onError = layoutErrors.add;

      await tester.pumpWidget(
        wrapHome(GameScreen(store: store, level: level)),
      );
      await tester.pump(const Duration(milliseconds: 500));

      FlutterError.onError = oldOnError;
      expect(layoutErrors, isEmpty);
      expect(tester.takeException(), isNull);
      // Skroll-fallback tufayli savol baribir quriladi.
      expect(find.text('Savol 1 / 1'), findsOneWidget);

      // Toza yopilish — taymer/tickerlar qolmaydi.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
