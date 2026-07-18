import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/contents/contents_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';

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
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;
  });

  testWidgets('Mundarija: 3 bob, daraja mavzulari va joriy o\'rin ko\'rinadi',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    await tester.pumpWidget(wrap(ContentsScreen(store: store)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text(uz.contentsTitle), findsOneWidget);

    // 3 bob subtit'lari.
    expect(find.text(uz.chapter1Sub), findsOneWidget);
    expect(find.text(uz.chapter2Sub), findsOneWidget);
    expect(find.text(uz.chapter3Sub), findsOneWidget);

    // Daraja mavzulari (birinchi va oxirgi — noyob nomlar). ContentsScreen
    // SingleChildScrollView'ni to'liq quradi, shuning uchun hammasi daraxtda.
    expect(find.text(uz.topic_1_1), findsOneWidget);
    expect(find.text(uz.topic_3_6), findsOneWidget);
  });

  testWidgets('yangi profil: faqat 1-1 joriy, qolgani qulf; jarayon o\'sadi',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1-1 ni 3 yulduz bilan tugatilgan deb belgilaymiz.
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await store.commitLevelResult(
      levelId: '1-1',
      stars: 3,
      coinsEarned: 30,
      skills: const {},
    );

    await tester.pumpWidget(wrap(ContentsScreen(store: store)));
    await tester.pump();

    expect(tester.takeException(), isNull);
    // Bob jarayoni matni (masalan "3/18") ko'rinadi.
    expect(find.text(uz.starsProgress(3, 18)), findsOneWidget);
  });
}
