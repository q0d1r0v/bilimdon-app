import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/app.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/onboarding/onboarding_screen.dart';
import 'package:math_farm/features/shell/root_shell.dart';
import 'package:math_farm/l10n/app_localizations.dart';

/// Onboarding cheksiz animatsiyasi yo'q, lekin RootShell (xarita) bor —
/// pumpAndSettle ISHLATILMAYDI.
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

  testWidgets('yangi profil: MathFarmApp onboarding ekranini ko\'rsatadi',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    expect(store.onboarded, isFalse);

    await tester.pumpWidget(MathFarmApp(store: store));
    await tester.pump();
    // SplashGate ~2.2s kirish splashini ko'rsatadi — undan o'tamiz.
    await pumpFrames(tester, 30);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(RootShell), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oqim: til -> ism(ixtiyoriy)+yosh(majburiy)+avatar -> Boshlash saqlaydi',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();

    await tester.pumpWidget(wrap(OnboardingScreen(store: store)));
    await tester.pump();

    // 1-qadam: til. Ism maydoni hali yo'q.
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('English'));
    await tester.pump();

    // 2-qadam: ism maydoni paydo bo'ldi.
    expect(find.byType(TextField), findsOneWidget);

    // Yosh hali tanlanmagan — "Boshlash!" ishlamaydi. (Ism ixtiyoriy:
    // yagona majburiy maydon — yosh; test/ui_fixes_test.dart buni qulflaydi.)
    await tester.tap(find.text('Boshlash!'));
    await tester.pump();
    expect(store.onboarded, isFalse);

    // Ism + yosh to'ldiramiz (avatar default = sigir, o'zgartirmaymiz).
    await tester.enterText(find.byType(TextField), 'Dilnoza');
    await tester.pump();
    await tester.tap(find.text('5')); // yosh
    await tester.pump();

    await tester.tap(find.text('Boshlash!'));
    await tester.pump();
    await tester.pump();

    expect(store.playerName, 'Dilnoza');
    expect(store.age, 5);
    expect(store.avatar, 'cow'); // default sigir
    expect(store.onboarded, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('onboarded=true bo\'lsa MathFarmApp to\'g\'ridan RootShell',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final store = await ProgressStore.load();
    await store.setOnboarded(true);
    rootBundle.clear();

    await tester.pumpWidget(MathFarmApp(store: store));
    // SplashGate ~2.2s kirish splashini ko'rsatadi — undan o'tamiz.
    await pumpFrames(tester, 30);

    expect(find.byType(RootShell), findsOneWidget);
    expect(find.byType(OnboardingScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
