import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';

/// Uchidan-uchiga tekshiruv: HAQIQIY kontentdagi har yangi vizual turi bilan
/// `GameScreen` eng kichik qo'llanadigan ekranda (320×568) va odatiy telefonda
/// (360×640) layout xatosi bermasligi.
///
/// Bu rejaning eng katta xatarini yopadi: vizual kartani cho'zib, javob
/// tugmalarini «buklama ostiga» tushirib qo'yishi.
ChapterDef _loadChapter(String name) {
  final file = File('${Directory.current.path}/assets/content/$name.json');
  final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  return ChapterDef.fromJson(
    Map<String, Object?>.from(root['chapter'] as Map),
  );
}

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

Widget _wrapHome(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('uz'),
      home: child,
    );

void main() {
  late List<ChapterDef> chapters;

  setUpAll(() {
    chapters = [
      for (final name in ['ch1', 'ch2', 'ch3', 'ch4', 'ch5', 'ch6'])
        _loadChapter(name),
    ];
  });

  /// Kontentdan berilgan shartga mos BIRINCHI savolni topadi.
  Question findQuestion(bool Function(Question q) test, String what) {
    for (final chapter in chapters) {
      for (final level in chapter.levels) {
        for (final q in level.questions) {
          if (test(q)) return q;
        }
      }
    }
    fail('kontentda $what topilmadi');
  }

  Future<void> expectNoLayoutError(
    WidgetTester tester,
    Question question,
    Size surface,
    String label,
  ) async {
    tester.view.physicalSize = surface;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    _mockAudioChannels(
      tester.binding.defaultBinaryMessenger,
    );
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    final level = LevelDef(
      id: '1-1',
      chapter: 1,
      index: 1,
      timerEnabled: false,
      timerSeconds: 0,
      questions: [question],
    );

    // RenderFlex overflow FlutterError.reportError orqali keladi.
    final layoutErrors = <FlutterErrorDetails>[];
    final oldOnError = FlutterError.onError;
    FlutterError.onError = layoutErrors.add;

    await tester.pumpWidget(_wrapHome(GameScreen(store: store, level: level)));
    // Pop animatsiyasi tugagach ham tekshiramiz (o'lcham o'sha payt maksimal).
    await tester.pump(const Duration(milliseconds: 600));

    FlutterError.onError = oldOnError;
    expect(
      layoutErrors.map((e) => e.exceptionAsString()),
      isEmpty,
      reason: '$label — $surface da layout xatosi',
    );
    expect(tester.takeException(), isNull, reason: label);

    // Toza yopilish — ticker/taymer qolmaydi.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(tester.takeException(), isNull, reason: '$label yopilishi');
  }

  const surfaces = {
    'eng kichik 320x568': Size(320, 568),
    'odatiy 360x640': Size(360, 640),
  };

  for (final (label, matcher) in <(String, bool Function(Question))>[
    (
      'groupRows (ko’paytirish)',
      (q) => q.visual?.kind == VisualKind.groupRows,
    ),
    (
      'tenFrame qo’shish',
      (q) =>
          q.visual?.kind == VisualKind.tenFrame &&
          q.type == QuestionType.addition &&
          q.data['missing'] == 'none',
    ),
    (
      'tenFrame ayirish (xira)',
      (q) =>
          q.visual?.kind == VisualKind.tenFrame && q.visual?.faded != null,
    ),
    (
      'tenFrame yetishmayotgan operand (sariq halqa)',
      (q) =>
          q.visual?.kind == VisualKind.tenFrame && q.visual?.target != null,
    ),
    ('numberLine (ketma-ketlik)', (q) => q.visual?.kind == VisualKind.numberLine),
    ('bars (taqqoslash)', (q) => q.visual?.kind == VisualKind.bars),
  ]) {
    for (final entry in surfaces.entries) {
      testWidgets('$label — ${entry.key}', (tester) async {
        final question = findQuestion(matcher, label);
        await expectNoLayoutError(tester, question, entry.value, label);
      });
    }
  }

  testWidgets('eng katta ko’paytirish (3 qator) ham sig’adi', (tester) async {
    // Balandlik budjeti eng qattiq holat: 3 guruh.
    final question = findQuestion(
      (q) => q.visual?.kind == VisualKind.groupRows && q.visual!.groups!.length == 3,
      'uch guruhli ko’paytirish',
    );
    await expectNoLayoutError(
      tester,
      question,
      const Size(320, 568),
      '3 qatorli groupRows',
    );
  });
}
