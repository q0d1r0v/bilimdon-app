import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/game/finish_overlay.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/features/game/prompt_text.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// audioplayers plagin kanallarini test muhitida jim mock qiladi —
/// aks holda EventChannel «listen» xatolari FlutterError orqali testni
/// yiqitadi.
void _mockAudioChannels(WidgetTester tester) {
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (call) async => null,
  );
  for (final id in ['bgm', 'sfx0', 'sfx1', 'sfx2', 'sfx3']) {
    messenger.setMockStreamHandler(
      EventChannel('xyz.luan/audioplayers/events/$id'),
      MockStreamHandler.inline(onListen: (arguments, events) {}),
    );
  }
  messenger.setMockStreamHandler(
    const EventChannel('xyz.luan/audioplayers.global/events'),
    MockStreamHandler.inline(onListen: (arguments, events) {}),
  );
}

/// Qo'lda yasalgan sanash savoli — to'g'ri javob matn orqali topiladi.
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

LevelDef twoQuestionLevel() => LevelDef(
      id: '1-1',
      chapter: 1,
      index: 1,
      timerEnabled: false,
      timerSeconds: 0,
      questions: [
        countingQ(id: 'q1', answers: [1, 2, 3, 4], correctIndex: 3, visualCount: 4),
        countingQ(id: 'q2', answers: [5, 6, 7, 8], correctIndex: 3, visualCount: 8),
      ],
    );

LevelDef threeQuestionLevel() => LevelDef(
      id: '1-1',
      chapter: 1,
      index: 1,
      timerEnabled: false,
      timerSeconds: 0,
      questions: [
        countingQ(id: 'q1', answers: [1, 2, 3, 4], correctIndex: 3, visualCount: 4),
        countingQ(id: 'q2', answers: [5, 6, 7, 8], correctIndex: 3, visualCount: 8),
        countingQ(
            id: 'q3', answers: [9, 10, 11, 12], correctIndex: 3, visualCount: 6),
      ],
    );

void main() {
  group('promptFor', () {
    final l10n = AppLocalizationsUz();

    Question q(QuestionType type, Map<String, Object?> data) => Question(
          id: 't',
          type: type,
          data: data,
          answers: const [
            AnswerCell.number(1),
            AnswerCell.number(2),
            AnswerCell.number(3),
            AnswerCell.number(4),
          ],
          correctIndex: 0,
        );

    test('arifmetika va ketma-ketlik matnlari', () {
      expect(
        promptFor(
          q(QuestionType.addition, {'a': 3, 'b': 2, 'missing': 'none'}),
          l10n,
        ),
        '3 + 2 = ?',
      );
      expect(
        promptFor(
          q(QuestionType.addition, {'a': 3, 'b': 4, 'missing': 'b', 'c': 7}),
          l10n,
        ),
        '3 + ? = 7',
      );
      // U+2212 minus (prototipdagidek).
      expect(
        promptFor(
          q(QuestionType.subtraction, {'a': 5, 'b': 2, 'missing': 'none'}),
          l10n,
        ),
        '5 − 2 = ?',
      );
      expect(
        promptFor(
          q(QuestionType.subtraction, {'a': 9, 'b': 4, 'missing': 'b', 'c': 5}),
          l10n,
        ),
        '9 − ? = 5',
      );
      expect(
        promptFor(q(QuestionType.sequence, {'terms': [2, 4, 6]}), l10n),
        '2, 4, 6, ... ?',
      );
      expect(
        promptFor(q(QuestionType.comparison, {'mode': 'biggest'}), l10n),
        l10n.promptBiggest,
      );
      expect(
        promptFor(q(QuestionType.shapes, {'target': 'triangle'}), l10n),
        l10n.promptFindShape('triangle'),
      );
      expect(
        promptFor(q(QuestionType.counting, {'animal': 'chick'}), l10n),
        l10n.promptCount('chick'),
      );
    });
  });

  testWidgets('o‘yin oqimi: to‘g‘ri/noto‘g‘ri javoblar, yakun va commit',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(tester);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final level = twoQuestionLevel();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(store: store, level: level),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // 1-savol ko'rinadi.
    expect(find.text('Savol 1 / 2'), findsOneWidget);
    expect(find.text('Nechta jo’jacha?'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);

    // To'g'ri javob -> dwell (1s) -> 2-savolga o'tadi.
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Savol 2 / 2'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    // Noto'g'ri javob -> savol o'zgarmaydi (shu savol qoladi).
    await tester.tap(find.text('5'));
    await tester.pump();
    expect(find.text('Savol 2 / 2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 900));
    expect(find.text('Savol 2 / 2'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    // Endi to'g'ri javob: xato bo'lgani uchun savol oxiriga takror qo'shiladi.
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('Savol 3 / 3'), findsOneWidget);
    expect(find.text('8'), findsOneWidget);

    // Takrorni ham yechamiz -> yakun overleyi.
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    // Pufakdagi tasodifiy «Muu! Barakalla!» varianti bilan to'qnashmaslik
    // uchun sarlavhani overlay ichidan qidiramiz.
    expect(
      find.descendant(
        of: find.byType(FinishOverlay),
        matching: find.text('Muu! Barakalla!'),
      ),
      findsOneWidget,
    );
    // Bola ko'radigan daraja raqami (index=1), ichki '1-1' id emas.
    expect(find.text('1-daraja tugadi'), findsOneWidget);
    expect(find.text('Qaytadan o’ynash'), findsOneWidget);
    expect(find.text('Davom etish'), findsOneWidget);

    // Yulduz taymeri tugashi uchun (2 yulduz + bekor qilish tiki).
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pump(const Duration(milliseconds: 800));

    // Commit: 3 to'g'ri javob (30) + yakun bonusi (20 + 2 yurak x 10 = 40).
    expect(store.coins, 70);
    expect(store.starsFor('1-1'), 2);
    expect(store.levels['1-1']?.attempts, 1);

    // Ekranni yopib, barcha taymerlar/tickerlar tozalanishini tekshiramiz.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('kichik ekranda (360x640) vertikal overflow bo‘lmaydi',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(tester);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    // RenderFlex overflow xatolari FlutterError.reportError orqali keladi —
    // ularni to'g'ridan-to'g'ri ushlab, ro'yxat bo'sh ekanini tekshiramiz.
    final layoutErrors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = layoutErrors.add;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(store: store, level: twoQuestionLevel()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    FlutterError.onError = oldOnError;
    expect(layoutErrors, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Savol 1 / 2'), findsOneWidget);

    // Javob bermasdan darhol yopamiz — AnswerGrid kontrollerlari lazy
    // bo'lganida bu unmount dispose ichida «Looking up a deactivated
    // widget's ancestor» xatosini berardi (F3 regressiyasi).
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'yakuniy feedback paytida ✕ bosilsa ham mukofot aynan bir marta '
      'commit bo‘ladi va FinishOverlay pop paytida chiqmaydi',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(tester);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
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

    // GameScreen push qilinadi (root route emas) — ✕ haqiqatan pop qilsin.
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => GameScreen(store: store, level: level),
                  ),
                ),
                child: const Text('boshlash'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('boshlash'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('4'), findsOneWidget);

    // Oxirgi (yagona) savolga to'g'ri javob — feedbackCorrect boshlanadi.
    await tester.tap(find.text('4'));
    await tester.pump();

    // Dwell (1000ms) tugashidan ancha oldin ✕ bosiladi.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const ValueKey('game-close')));
    await tester.pump();

    // Pop tranzitsiyasi davomida FinishOverlay yarq etib chiqmasligi kerak.
    await tester.pump(const Duration(milliseconds: 150));
    expect(find.byType(FinishOverlay), findsNothing);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(GameScreen), findsNothing);
    expect(find.byType(FinishOverlay), findsNothing);

    // Mukofot yo'qolmagan: 10 (to'g'ri javob) + 20 + 3 yurak x 10 = 60.
    expect(store.coins, 60);
    expect(store.starsFor('1-1'), 3);
    expect(store.levels['1-1']?.attempts, 1);

    // Dwell muddati o'tib ketganda ham ikkinchi commit bo'lmaydi.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(store.coins, 60);
    expect(store.levels['1-1']?.attempts, 1);
  });

  testWidgets('3 yurak tugasa FailOverlay chiqadi, commit yo‘q, Qaytadan '
      'darajani 1-savoldan boshlaydi', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(tester);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;

    final uz = AppLocalizationsUz();
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(store: store, level: threeQuestionLevel()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('4'), findsOneWidget);

    // Har savolda birinchi urinishda xato — yurak ketadi; so'ng to'g'ri javob.
    // Q1: yurak 3→2.
    await tester.tap(find.text('1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('4'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('8'), findsOneWidget); // Q2

    // Q2: yurak 2→1.
    await tester.tap(find.text('5'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));
    await tester.tap(find.text('8'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.text('12'), findsOneWidget); // Q3

    // Q3: birinchi urinishda xato — yurak 1→0 → muloyim FailOverlay.
    await tester.tap(find.text('9'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text(uz.failTitle), findsOneWidget);
    expect(find.byType(FinishOverlay), findsNothing);
    // Jarima yo'q: mukofot commit qilinmaydi.
    expect(store.coins, 0);
    expect(store.levels.containsKey('1-1'), isFalse);

    // «Qaytadan» — daraja 1-savoldan qayta boshlanadi (yuraklar tiklanadi).
    await tester.tap(find.text(uz.failRetry));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text(uz.failTitle), findsNothing);
    expect(find.text('4'), findsOneWidget); // yana Q1

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('power-up tugmalari: Yordam xatoni xiralashtiradi, O‘tkazish '
      'keyingi savolga o‘tadi — ikkalasi ham sarflanadi', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(tester);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;

    final uz = AppLocalizationsUz();
    SharedPreferences.setMockInitialValues({
      'profile_v1':
          '{"schemaVersion":1,"coins":0,"powerups":{"powerHint":1,"powerSkip":1}}',
    });
    final store = await ProgressStore.load();
    expect(store.powerupCount('powerHint'), 1);
    expect(store.powerupCount('powerSkip'), 1);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('uz'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: GameScreen(store: store, level: twoQuestionLevel()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    final hintLabel = '${uz.itemPowerHint} (1)'; // "Yordam (1)"
    final skipLabel = '${uz.itemPowerSkip} (1)'; // "O'tkazish (1)"
    expect(find.text(hintLabel), findsOneWidget);
    expect(find.text(skipLabel), findsOneWidget);

    // Yordam: bitta noto'g'ri javobni xiralashtiradi va power-up sarflanadi.
    await tester.ensureVisible(find.text(hintLabel));
    await tester.tap(find.text(hintLabel));
    await tester.pump();
    expect(store.powerupCount('powerHint'), 0);
    expect(find.text(hintLabel), findsNothing); // tugma yo'qoldi
    expect(find.text(skipLabel), findsOneWidget); // skip hali bor

    // O'tkazish: yuraksiz keyingi savolga o'tadi va power-up sarflanadi.
    await tester.ensureVisible(find.text(skipLabel));
    await tester.tap(find.text(skipLabel));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(store.powerupCount('powerSkip'), 0);
    expect(find.text('8'), findsOneWidget); // Q2 ga o'tdi

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
}
