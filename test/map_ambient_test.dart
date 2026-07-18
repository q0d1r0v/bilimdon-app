import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/characters/animal.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/effects/ambient_life.dart';
import 'package:math_farm/effects/animal_life.dart';
import 'package:math_farm/features/game/game_screen.dart';
import 'package:math_farm/features/map/map_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';

/// Ambient looplar (kapalak/gulchang/shimmer) cheksiz — pumpAndSettle
/// hech qachon tinchimaydi. Chegaralangan pump ishlatamiz.
Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

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

  setUp(() {
    mockAudioChannels(binding.defaultBinaryMessenger);
    AudioService.instance
      ..soundOn = false
      ..musicOn = false;
  });

  testWidgets('xarita ambient qatlamlari (gulchang, kapalak, shimmer, uchqun) '
      'xatosiz render bo\'ladi', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    rootBundle.clear();

    await tester.pumpWidget(wrap(MapScreen(store: store)));
    await pumpFrames(tester, 10);

    expect(tester.takeException(), isNull);
    // Ambient (gulchang/kapalak/shimmer) faqat eng tepadagi bob seksiyasida
    // (bir marta) — scroll-xaritada takrorlanmaydi.
    expect(find.byType(AmbientPollen), findsOneWidget);
    expect(find.byType(AmbientFliers), findsOneWidget);
    expect(find.byType(DottedPathGlow), findsOneWidget);

    // Yana bir necha kadr — cheksiz ambient looplar xato bermasin.
    await pumpFrames(tester, 8);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oldingi ambient qatlamlar (kapalak/uchqun) teginishni '
      'BLOKLAMAYDI: hayvon bosiladi va BOSHLA! ishlaydi', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    rootBundle.clear();

    await tester.pumpWidget(wrap(MapScreen(store: store)));
    await pumpFrames(tester, 10);

    // Sigirga tegish — IgnorePointer qatlamlari ustida bo'lsa ham teginish
    // o'tadi; crash yo'q. (Sigir bir necha bobda bor — pastdagi, 1-bobniki
    // ko'rinadi.)
    final cow = find.byWidgetPredicate(
      (w) => w is LivingAnimal && w.kind == FarmAnimal.cow,
    );
    expect(cow, findsWidgets);
    await tester.tap(cow.last, warnIfMissed: false);
    // «Quvnoq» ifoda ~0.75s — taymer o'z ichida tugaydi (kutilayotgan Timer yo'q).
    await pumpFrames(tester, 9);
    expect(tester.takeException(), isNull);

    // Eng muhim regressiya: fliers + uchqun-overlay tugunlar USTIDA bo'lsa ham
    // BOSHLA! bosiladi (IgnorePointer to'g'ri).
    await tester.tap(find.text('BOSHLA!'));
    await pumpFrames(tester, 8);

    expect(find.byType(GameScreen), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Toza teardown — daraxtni yo'q qilib barcha widget-timerlarini
    // (LivingAnimal blink, _celebrate, Flame) bekor qilamiz; yuqori
    // konkurensiyada teardown poygasidagi «!timersPending» oldini oladi.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });

  testWidgets('reduce-motion: kapalak/qush qatlami harakatsiz, xato yo\'q',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    rootBundle.clear();

    // disableAnimations=true → AmbientFliers SizedBox.shrink qaytaradi,
    // pollen/shimmer statik turadi.
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: wrap(MapScreen(store: store)),
      ),
    );
    await pumpFrames(tester, 8);

    expect(tester.takeException(), isNull);
    // Fliers hali daraxtda (widget bor), lekin ichida bo'sh (harakatsiz).
    expect(find.byType(AmbientFliers), findsOneWidget);
    expect(find.byType(MapScreen), findsOneWidget);
  });
}
