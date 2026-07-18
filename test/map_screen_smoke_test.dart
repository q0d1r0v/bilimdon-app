import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/features/map/chapter_banner.dart';
import 'package:math_farm/features/map/level_node.dart';
import 'package:math_farm/features/map/map_header.dart';
import 'package:math_farm/features/map/map_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';

/// Xarita ekrani smoke-testi. Faol tugun pulse animatsiyasi cheksiz —
/// pumpAndSettle hech qachon tinchimaydi, shuning uchun chegaralangan
/// pump qadamlari ishlatiladi.
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

Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('uz'),
    home: child,
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

  testWidgets('map screen renders header, banner and all 36 level nodes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    await tester.pumpWidget(wrap(MapScreen(store: store)));

    // Kontent (rootBundle) yuklanishi va sahna qurilishi uchun kadrlar.
    await pumpFrames(tester, 10);

    expect(tester.takeException(), isNull);
    expect(find.byType(MapScreen), findsOneWidget);
    expect(find.byType(MapHeader), findsOneWidget);
    expect(find.byType(ChapterBanner), findsOneWidget);
    expect(find.byType(LevelNode), findsNWidgets(36));

    // Yangi profil: 1-bob ko’rsatiladi, 1-daraja faol (BOSHLA! ko’rinadi).
    expect(find.text('BOSHLA!'), findsOneWidget);

    // Pulse animatsiyasi bilan yana bir necha kadr — istisnosiz.
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping BOSHLA! actually starts the level (opens GameScreen)',
      (tester) async {
    // GameScreen — portret o'yin; standart 800×600 landshaft yuzasida
    // 5px overflow beradi. Telefon portret yuzasini o'rnatamiz.
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    // Oldingi test rootBundle keshiga O'Z zonasida yaratilgan future'larni
    // qoldiradi — bu zonadan await qilinsa hech qachon tugamaydi (fake-async
    // zonalar orasida microtask almashinmaydi). Toza boshlaymiz.
    rootBundle.clear();

    await tester.pumpWidget(wrap(MapScreen(store: store)));
    await pumpFrames(tester, 10);

    // Standart warnIfMissed bilan — hit-test o'tmasa test shovqin bilan
    // yiqiladi (F1 regressiyasi: tugma widget chegarasidan tashqarida edi).
    await tester.tap(find.text('BOSHLA!'));
    await pumpFrames(tester, 8);

    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ctaBelow LevelNode: BOSHLA! below the circle fires onPlay',
      (tester) async {
    var played = 0;
    await tester.pumpWidget(
      wrap(
        Stack(
          children: [
            // Yuqori qator tuguni kabi: widget tepasi ekranning 0-y nuqtasida.
            Positioned(
              left: 100,
              top: 0,
              child: LevelNode(
                number: 6,
                state: LevelNodeState.active,
                ctaBelow: true,
                onPlay: () => played++,
              ),
            ),
          ],
        ),
      ),
    );
    await pumpFrames(tester, 3);

    await tester.tap(find.text('BOSHLA!'));
    expect(played, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('content load failure shows retry state; retry recovers',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    // Oldingi testlar kontentni global rootBundle keshiga yozib qo'ygan —
    // sinov toza boshlansin.
    rootBundle.clear();

    // Aktiv o'qishlarini sindiramiz: kanal bo'sh javob qaytaradi.
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async => null,
    );

    await tester.pumpWidget(wrap(MapScreen(store: store)));
    await pumpFrames(tester, 5);

    // Xato hisobotga yozilgan (jim yutilmagan) va bola uchun qayta
    // urinish tugmali holat ko'rsatilgan — bo'sh osmon emas.
    expect(tester.takeException(), isNotNull);
    expect(find.text(uz.retryButton), findsOneWidget);
    expect(find.byType(LevelNode), findsNothing);

    // Aktivlar «tiklandi». DIQQAT: mockni null bilan olib tashlash
    // flutter_test'ning o'z disk-xizmatchisini ham o'chiradi (xabarlar
    // hech qachon javob olmaydi) — o'rniga diskdan o'qiydigan
    // passthrough-handler qo'yamiz.
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      (message) async {
        final key = utf8.decode(message!.buffer.asUint8List(
          message.offsetInBytes,
          message.lengthInBytes,
        ));
        final file = File(key);
        if (!file.existsSync()) return null;
        final bytes = file.readAsBytesSync();
        return ByteData.view(Uint8List.fromList(bytes).buffer);
      },
    );

    await tester.tap(find.text(uz.retryButton));
    await pumpFrames(tester, 10);

    expect(find.byType(LevelNode), findsNWidgets(36));
    expect(find.text(uz.retryButton), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
