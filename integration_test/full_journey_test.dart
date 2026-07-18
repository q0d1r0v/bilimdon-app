import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:math_farm/app.dart';
import 'package:math_farm/content/content_repository.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/game/answer_grid.dart';
import 'package:math_farm/features/game/finish_overlay.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/features/map/level_node.dart';
import 'package:math_farm/features/shop/shop_item_card.dart';
import 'package:math_farm/scene/decorations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// To'liq E2E sayohat (web/Chrome): xarita → 2 daraja o'ynash (xato-yo'l
/// bilan) → do'konda xarid + qo'yish → profil (til, parental gate) →
/// reyting stub. Kontent deterministik (seed = daraja id) — to'g'ri
/// javoblar JSON'dan o'qiladi.
///
/// MUHIM: ilovada cheksiz animatsiyalar bor (pulse, nafas, bulutlar) —
/// pumpAndSettle HECH QACHON ishlatilmaydi, faqat chegaralangan pump.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Chegaralangan pump: real vaqt o'tishi bilan kadrlarni aylantiradi.
  Future<void> pumpFor(WidgetTester tester, Duration duration) async {
    final end = DateTime.now().add(duration);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Shart bajarilguncha kutadi (max [timeout]).
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 100));
      if (finder.evaluate().isNotEmpty) return;
    }
    // Diagnostika: hozir daraxtda qanday matnlar bor?
    final visible = find
        .byType(Text)
        .evaluate()
        .map((e) => (e.widget as Text).data)
        .whereType<String>()
        .take(20)
        .toList();
    fail('Kutilgan element topilmadi: $finder\nKo’ringan matnlar: $visible');
  }

  /// BOSHLA!ni bosib o'yin ochilishini kutadi. Pop-tranzitsiya paytida
  /// birinchi bosish «miss» bo'lishi mumkin — 3 martagacha qayta urinadi
  /// (bola ham xuddi shunday qiladi).
  Future<void> tapStart(WidgetTester tester) async {
    for (var attempt = 0; attempt < 3; attempt++) {
      await waitFor(tester, find.text('BOSHLA!'));
      // Xarita scroll'li bo'lsa tugmani ko'rinadigan joyga suramiz.
      try {
        await tester.ensureVisible(find.text('BOSHLA!').first);
        await tester.pump(const Duration(milliseconds: 200));
      } catch (_) {
        // Scrollable yo'q (katta ekran) — davom etamiz.
      }
      await tester.tap(find.text('BOSHLA!').first, warnIfMissed: false);
      final end = DateTime.now().add(const Duration(seconds: 4));
      while (DateTime.now().isBefore(end)) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(GameScreen).evaluate().isNotEmpty) return;
      }
    }
    fail('BOSHLA! bosilsa ham GameScreen ochilmadi (3 urinish)');
  }

  /// Javob gridida to'g'ri javobni topib bosadi.
  Future<void> tapAnswer(WidgetTester tester, AnswerCell cell) async {
    final Finder target;
    if (cell.number != null) {
      target = find.descendant(
        of: find.byType(AnswerGrid),
        matching: find.text('${cell.number}'),
      );
    } else {
      // Shakl javoblari: to'g'ri indeks bo'yicha bosamiz (pastda alohida).
      throw StateError('shape uchun tapAnswerShape ishlating');
    }
    await waitFor(tester, target);
    await tester.tap(target.first, warnIfMissed: false);
    await tester.pump();
  }

  /// Darajani boshidan-oxirigacha to'g'ri javoblar bilan o'ynaydi.
  /// [wrongOnce] true bo'lsa birinchi savolda avval ataylab xato qiladi
  /// (repeat-queue va yurak mexanikasi sinovi).
  Future<void> playLevel(
    WidgetTester tester,
    LevelDef level, {
    bool wrongOnce = false,
  }) async {
    // O'yin ekrani ochilishini kutamiz.
    await waitFor(tester, find.byType(GameScreen));

    final expectedTotal =
        level.questions.length + (wrongOnce ? 1 : 0); // repeat qo'shiladi
    var answered = 0;
    var qIndex = 0;
    final queue = List<Question>.of(level.questions);

    while (answered < expectedTotal) {
      final q = queue[qIndex];
      if (wrongOnce && answered == 0) {
        // Ataylab noto'g'ri javob: to'g'ri bo'lmagan birinchi raqamni bosamiz.
        final wrong = q.answers
            .firstWhere((a) => a != q.answers[q.correctIndex]);
        if (wrong.number != null) {
          await tapAnswer(tester, wrong);
          // Xato dwell (~800ms) + shu savol qaytadi.
          await pumpFor(tester, const Duration(milliseconds: 1100));
          // Xato savol daraja oxirida takrorlanadi.
          queue.add(q);
        }
      }
      // To'g'ri javob.
      final correct = q.answers[q.correctIndex];
      if (correct.number != null) {
        await tapAnswer(tester, correct);
      } else {
        // Shakl savoli: AnswerGrid ichidagi tugmalar tartibi aralashtirilgan
        // bo'lishi mumkin — barcha 4 tugmani sinab, to'g'risini topamiz:
        // noto'g'ri bosishda savol o'zgarmaydi, to'g'risida keyingisiga o'tadi.
        // Determinizm uchun: har tugmani bosib, feedback dwellni kutamiz.
        for (var b = 0; b < 4; b++) {
          final buttons = find.descendant(
            of: find.byType(AnswerGrid),
            matching: find.byType(GestureDetector),
          );
          await tester.tap(buttons.at(b), warnIfMissed: false);
          await pumpFor(tester, const Duration(milliseconds: 1300));
          // Agar savol o'zgargan bo'lsa (yoki finish chiqsa) — to'g'ri edi.
          final stillSame = find
              .textContaining('Savol ${answered + 1} /')
              .evaluate()
              .isNotEmpty;
          if (!stillSame) break;
        }
        answered++;
        qIndex++;
        continue;
      }
      // To'g'ri javob dwell (~1s) + o'tish.
      await pumpFor(tester, const Duration(milliseconds: 1400));
      answered++;
      qIndex++;
    }

    // Finish overlay.
    await waitFor(tester, find.byType(FinishOverlay));
    await pumpFor(tester, const Duration(milliseconds: 2200)); // yulduzlar
    // "Davom etish" bilan xaritaga qaytamiz.
    final cont = find.text('Davom etish');
    await waitFor(tester, cont);
    await tester.tap(cont, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 800));
  }

  testWidgets('to’liq sayohat: xarita → 2 daraja → do’kon → profil',
      (tester) async {
    // Toza holat + ovozsiz (web autoplay muammolaridan qochamiz).
    SharedPreferences.setMockInitialValues({});
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;
    final store = await ProgressStore.load();
    await store.setSoundOn(false);
    await store.setMusicOn(false);
    // Headless Chrome tili en-US — sayohat o'zbekcha matnlarni tekshiradi,
    // shuning uchun aniq uz'dan boshlaymiz (keyin en'ga almashtirib sinaymiz).
    await store.setLocaleOverride('uz');

    final content = ContentRepository();
    final chapters = await content.loadAll();
    final level11 = chapters.first.levels[0];
    final level12 = chapters.first.levels[1];

    await tester.pumpWidget(MathFarmApp(store: store));

    // ===== 1. XARITA: header, banner, tugunlar =====
    // Kontent asinxron yuklanadi (FutureBuilder) — banner chiqquncha kutamiz.
    await waitFor(tester, find.textContaining('1-BOB'),
        timeout: const Duration(seconds: 20));
    expect(find.text('Aziza'), findsOneWidget);
    expect(find.byType(LevelNode), findsNWidgets(6));
    await waitFor(tester, find.text('BOSHLA!'));

    // ===== 2. 1-1 DARAJA: hammasi to'g'ri =====
    await tapStart(tester);
    await playLevel(tester, level11);

    // Xaritaga qaytdik: tangalar 100 (50 savol + 50 bonus), 1-2 faol.
    await waitFor(tester, find.text('BOSHLA!'));
    expect(store.coins, 100);
    expect(store.starsFor('1-1'), 3);
    expect(store.isLevelUnlocked('1-2'), isTrue);

    // ===== 3. 1-2 DARAJA: bitta ataylab xato (repeat-queue + yurak) =====
    await tapStart(tester);
    await playLevel(tester, level12, wrongOnce: true);

    // Xato bor edi: 2 yulduz, mukofot 50(savollar)+10(takror)... —
    // aniq summani store'dan tekshiramiz: kamida 190 tanga yig'ildi.
    expect(store.starsFor('1-2'), 2);
    expect(store.coins, greaterThanOrEqualTo(190));

    // ===== 4. DO'KON: xarid + qo'yish =====
    await tester.tap(find.text('Do’kon').last, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.byType(ShopItemCard), findsWidgets);

    final coinsBefore = store.coins;
    // Gul to'plami (100 tanga) — narx tugmasini bosamiz.
    final flowerCard = find.ancestor(
      of: find.text('Gul to’plami'),
      matching: find.byType(ShopItemCard),
    );
    await tester.tap(
      find.descendant(of: flowerCard, matching: find.text('100')).first,
      warnIfMissed: false,
    );
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(store.coins, coinsBefore - 100);
    expect(store.ownedItems.contains('flowerBed'), isTrue);

    // Endi "Qo'yish" tugmasi chiqdi — bosamiz.
    await tester.tap(
      find.descendant(of: flowerCard, matching: find.text('Qo’yish')),
      warnIfMissed: false,
    );
    await pumpFor(tester, const Duration(milliseconds: 400));
    expect(store.equippedFor('decor1'), 'flowerBed');

    // Xaritada gul to'plami ko'rinadi.
    await tester.tap(find.text('Xarita').last, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 700));
    expect(find.byType(FlowerBed), findsWidgets);

    // ===== 5. PROFIL: til almashtirish =====
    await tester.tap(find.text('Profil').last, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 700));
    await tester.tap(find.text('English'), warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 900));
    // Nav yorlig'i inglizchaga o'tdi.
    expect(find.text('Map'), findsWidgets);
    expect(store.localeOverride, 'en');
    // Qaytaramiz.
    await tester.tap(find.text('O’zbekcha'), warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 900));
    expect(find.text('Xarita'), findsWidgets);

    // ===== 6. PARENTAL GATE + STATISTIKA =====
    final statsTitle = find.text('Natijalar (ota-onalar uchun)');
    await waitFor(tester, statsTitle);
    await tester.tap(statsTitle, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 600));
    // Gate savolidan a × b ni o'qib, to'g'ri javobni bosamiz.
    final promptFinder = find.textContaining('×');
    if (promptFinder.evaluate().isNotEmpty) {
      final promptText =
          (promptFinder.evaluate().first.widget as Text).data ?? '';
      final m = RegExp(r'(\d+)\s*×\s*(\d+)').firstMatch(promptText);
      if (m != null) {
        final answer = int.parse(m.group(1)!) * int.parse(m.group(2)!);
        await tester.tap(find.text('$answer').last, warnIfMissed: false);
        await pumpFor(tester, const Duration(milliseconds: 600));
        // Statistika ko'rinadi: kamida savollar soni qatori.
        expect(find.text('Javob berilgan savollar'), findsOneWidget);
      }
    }

    // ===== 7. REYTING STUB =====
    await tester.tap(find.text('Reyting').last, warnIfMissed: false);
    await pumpFor(tester, const Duration(milliseconds: 600));
    expect(find.text('Tez kunda!'), findsOneWidget);

    // ===== 8. Progress qayta yuklashda saqlanganini tasdiqlash =====
    final store2 = await ProgressStore.load();
    expect(store2.starsFor('1-1'), 3);
    expect(store2.starsFor('1-2'), 2);
    expect(store2.ownedItems.contains('flowerBed'), isTrue);
  });
}
