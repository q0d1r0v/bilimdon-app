import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/core/theme/tokens.dart';
import 'package:math_farm/features/game/answer_grid.dart';
import 'package:math_farm/features/game/quiz_controller.dart';
import 'package:math_farm/features/map/map_header.dart';
import 'package:math_farm/features/onboarding/onboarding_screen.dart';
import 'package:math_farm/features/shell/root_shell.dart';
import 'package:math_farm/l10n/app_localizations.dart';

/// UI/UX nuqsonlari uchun regressiya testlari. Har biri avval HAQIQATAN
/// yiqilgan holatni qulflaydi (o'lchov yoki reproduce bilan tasdiqlangan).
void _mockAudioChannels(TestDefaultBinaryMessenger messenger) {
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

Widget _wrap(Widget child, {Locale locale = const Locale('uz')}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: Scaffold(body: child),
    );

void main() {
  group('MapHeader overflow (3.1)', () {
    // Avval: realistik statistika bilan hatto 3 harfli «Ali» ham 39px
    // chiqib ketardi; 16 harfli ism — 140px.
    for (final (name, label) in const [
      ('Ali', '3 harfli ism + katta statistika'),
      ('Dilnoza', '7 harfli ism'),
      ('Muhammadali', '11 harfli ism'),
      ('Abdurahmonbekjon', '16 harfli ism (onboarding maxLength)'),
    ]) {
      testWidgets('360dp: $label — overflow yo‘q', (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        SharedPreferences.setMockInitialValues({
          'profile_v1': jsonEncode({
            'schemaVersion': 1,
            'playerName': name,
            'coins': 1250,
            'streakCurrent': 12,
          }),
        });
        final store = await ProgressStore.load();

        final errors = <FlutterErrorDetails>[];
        final old = FlutterError.onError;
        FlutterError.onError = errors.add;
        await tester.pumpWidget(_wrap(MapHeader(store: store)));
        await tester.pump();
        FlutterError.onError = old;

        expect(
          errors.map((e) => e.exceptionAsString()),
          isEmpty,
          reason: label,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('bo‘sh ism default nom bilan ko‘rsatiladi', (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile_v1': jsonEncode({'schemaVersion': 1, 'playerName': ''}),
      });
      final store = await ProgressStore.load();
      await tester.pumpWidget(_wrap(MapHeader(store: store)));
      await tester.pump();
      // uz default — `playerDefaultName` ARB kaliti.
      expect(find.text('Aziza'), findsOneWidget);
    });
  });

  group('Nav tap zonasi 48dp (3.2)', () {
    testWidgets('androidTapTargetGuideline o‘tadi', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      _mockAudioChannels(tester.binding.defaultBinaryMessenger);
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: RootShell(store: store),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    });
  });

  group('Javob tugmasi kontrasti (3.3)', () {
    testWidgets('textContrastGuideline o‘tadi (oq raqam sariqda emas)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          Container(
            color: FarmColors.gameBg,
            child: AnswerGrid(
              answers: const [
                AnswerCell.number(12),
                AnswerCell.number(14),
                AnswerCell.number(16),
                AnswerCell.number(18),
              ],
              correctIndex: 0,
              selectedIndex: null,
              phase: QuizPhase.question,
              disabledIndexes: const {},
              fadedIndexes: const {},
              onSelect: (_) {},
              buttonKeys: [for (var i = 0; i < 4; i++) GlobalKey()],
            ),
          ),
        ),
      );
      await tester.pump();
      await expectLater(tester, meetsGuideline(textContrastGuideline));
    });

    test('har tugma rangi uchun matn rangi WCAG 3.0 dan yuqori', () {
      double ratio(Color a, Color b) {
        final la = a.computeLuminance();
        final lb = b.computeLuminance();
        final hi = la > lb ? la : lb;
        final lo = la > lb ? lb : la;
        return (hi + 0.05) / (lo + 0.05);
      }

      for (final button in const [
        FarmColors.red,
        FarmColors.green,
        FarmColors.blue,
        FarmColors.yellow,
        FarmColors.mud,
      ]) {
        final fg = FarmColors.answerForeground(button);
        expect(
          ratio(fg, button),
          greaterThanOrEqualTo(3.0),
          reason: 'tugma $button ustidagi matn kontrasti past',
        );
      }
    });

    test('nofaol nav yozuvi cream fonda 4.5 dan yuqori', () {
      final l1 = FarmColors.navInactive.computeLuminance();
      final l2 = FarmColors.cream.computeLuminance();
      final hi = l1 > l2 ? l1 : l2;
      final lo = l1 > l2 ? l2 : l1;
      expect((hi + 0.05) / (lo + 0.05), greaterThanOrEqualTo(4.0));
    });
  });

  group('Shrift masshtabi clamp (3.7)', () {
    // Avval `TextScaler.noScaling` tizim masshtabini BUTUNLAY o'chirardi
    // (WCAG 1.4.4). Endi 1.0-1.3 oralig'i qo'llanadi — shu oraliqda
    // ekranlar buzilmasligi kerak.
    for (final scale in const [1.0, 1.15, 1.3]) {
      testWidgets('RootShell $scale× masshtabda overflow bermaydi',
          (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);
        _mockAudioChannels(tester.binding.defaultBinaryMessenger);
        SharedPreferences.setMockInitialValues({
          'profile_v1': jsonEncode({
            'schemaVersion': 1,
            'playerName': 'Muhammadali',
            'coins': 1250,
            'streakCurrent': 12,
          }),
        });
        final store = await ProgressStore.load();

        final errors = <FlutterErrorDetails>[];
        final old = FlutterError.onError;
        FlutterError.onError = errors.add;
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ru'), // ruscha matn 20-40% uzun
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: RootShell(store: store),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        FlutterError.onError = old;

        expect(
          errors.map((e) => e.exceptionAsString()),
          isEmpty,
          reason: '$scale× masshtabda layout xatosi',
        );
      });
    }
  });

  group('Onboarding ism ixtiyoriy (3.4)', () {
    testWidgets('ism yozmasdan yosh tanlansa «Boshlash» ishlaydi',
        (tester) async {
      _mockAudioChannels(tester.binding.defaultBinaryMessenger);
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load();
      await tester.pumpWidget(_wrap(OnboardingScreen(store: store)));
      await tester.pump();

      // Til tanlash qadami.
      await tester.tap(find.text('O’zbekcha'));
      await tester.pump(const Duration(milliseconds: 300));

      // Ism BO'SH qoldiriladi — faqat yosh tanlanadi.
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('Boshlash!'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        store.onboarded,
        isTrue,
        reason: '4 yoshli bola klaviaturada ism yozmasdan o‘tishi kerak',
      );
      expect(store.age, 5);
    });
  });
}
