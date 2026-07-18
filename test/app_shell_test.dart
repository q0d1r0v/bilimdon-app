import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:math_farm/app.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/map/map_screen.dart';
import 'package:math_farm/features/contents/contents_screen.dart';
import 'package:math_farm/features/profile/profile_screen.dart';
import 'package:math_farm/features/shell/root_shell.dart';
import 'package:math_farm/features/shop/shop_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';

/// MathFarmApp.resolveLocale matritsasi + RootShell qobig'i:
/// 4 tab, IndexedStack almashinuvi, TickerMode va profil epoch kaliti.
///
/// Faol tab animatsiyalari cheksiz — pumpAndSettle hech qachon tinchimaydi,
/// shuning uchun chegaralangan pump qadamlari ishlatiladi.
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

/// Pastki nav yorlig'ini bosadi. Ekran sarlavhalari tab matnini
/// takrorlashi mumkin (masalan «Do’kon» ham tab, ham sarlavha) —
/// eng PASTDAGI mos matn tanlanadi (nav doim eng pastda).
Future<void> tapTab(WidgetTester tester, String label) async {
  final matches = find.text(label);
  var target = matches.first;
  var maxY = double.negativeInfinity;
  for (var i = 0; i < matches.evaluate().length; i++) {
    final candidate = matches.at(i);
    final y = tester.getCenter(candidate).dy;
    if (y > maxY) {
      maxY = y;
      target = candidate;
    }
  }
  await tester.tap(target);
  await pumpFrames(tester, 2);
}

/// RootShell ichidagi tab-IndexedStack (ekranlardagi boshqa stacklarga
/// adashmaslik uchun descendant orqali, birinchi topilgani — qobiqniki).
IndexedStack shellStack(WidgetTester tester) {
  return tester.widget<IndexedStack>(
    find
        .descendant(
          of: find.byType(RootShell),
          matching: find.byType(IndexedStack),
        )
        .first,
  );
}

/// Berilgan ekran turining TickerMode holati (yashirin tabda false).
bool tickerEnabledOf(WidgetTester tester, Type screenType) {
  final element =
      tester.element(find.byType(screenType, skipOffstage: false));
  return TickerMode.valuesOf(element).enabled;
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final uz = AppLocalizationsUz();

  group('MathFarmApp.resolveLocale', () {
    const supported = AppLocalizations.supportedLocales;

    test('explicit override always wins over device locales', () {
      expect(
        MathFarmApp.resolveLocale('ru', const [Locale('en')], supported),
        const Locale('ru'),
      );
      expect(
        MathFarmApp.resolveLocale('en', null, supported),
        const Locale('en'),
      );
      expect(
        MathFarmApp.resolveLocale('uz', const [Locale('fr')], supported),
        const Locale('uz'),
      );
    });

    test('unsupported device language falls back to uz', () {
      expect(
        MathFarmApp.resolveLocale(null, const [Locale('fr')], supported),
        const Locale('uz'),
      );
    });

    test('device ru-RU matches ru by language code', () {
      expect(
        MathFarmApp.resolveLocale(
          null,
          const [Locale('ru', 'RU')],
          supported,
        ),
        const Locale('ru'),
      );
    });

    test('first supported device locale wins: [en, ru] -> en', () {
      expect(
        MathFarmApp.resolveLocale(
          null,
          const [Locale('en'), Locale('ru')],
          supported,
        ),
        const Locale('en'),
      );
      // Qurilma tartibi hal qiladi: birinchi mos keladigani olinadi.
      expect(
        MathFarmApp.resolveLocale(
          null,
          const [Locale('fr'), Locale('ru'), Locale('en')],
          supported,
        ),
        const Locale('ru'),
      );
    });

    test('empty and null device lists default to uz', () {
      expect(
        MathFarmApp.resolveLocale(null, const <Locale>[], supported),
        const Locale('uz'),
      );
      expect(
        MathFarmApp.resolveLocale(null, null, supported),
        const Locale('uz'),
      );
    });
  });

  group('RootShell', () {
    setUp(() {
      mockAudioChannels(binding.defaultBinaryMessenger);
      AudioService.instance
        ..soundOn = false
        ..musicOn = false;
    });

    Future<ProgressStore> pumpShell(WidgetTester tester) async {
      // Portret telefon yuzasi — xarita ekrani landshaftda toshib ketadi.
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load(
        nowProvider: () => DateTime(2026, 7, 16, 12),
      );

      // Boshqa testlarning fake-async zonasida yaratilgan rootBundle kesh
      // future'laridan qochamiz — kontent shu testning o'z zonasida yuklansin.
      rootBundle.clear();

      await tester.pumpWidget(wrap(RootShell(store: store)));
      await pumpFrames(tester, 10);
      return store;
    }

    testWidgets('renders 4 tab labels and keeps all screens alive in the '
        'IndexedStack', (tester) async {
      await pumpShell(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(uz.tabMap), findsOneWidget);
      expect(find.text(uz.tabShop), findsOneWidget);
      expect(find.text(uz.tabContents), findsOneWidget);
      expect(find.text(uz.tabProfile), findsOneWidget);

      // IndexedStack barcha 4 ekranni tirik saqlaydi (yashirinlari offstage).
      expect(shellStack(tester).index, 0);
      expect(find.byType(MapScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ShopScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ContentsScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(ProfileScreen, skipOffstage: false), findsOneWidget);

      // Faqat faol tab sahnada.
      expect(find.byType(MapScreen), findsOneWidget);
      expect(find.byType(ShopScreen), findsNothing);
    });

    testWidgets('tapping tabs switches the IndexedStack index', (tester) async {
      await pumpShell(tester);
      expect(shellStack(tester).index, 0);

      await tapTab(tester, uz.tabShop);
      expect(shellStack(tester).index, 1);
      expect(find.byType(ShopScreen), findsOneWidget);
      expect(find.byType(MapScreen), findsNothing);

      await tapTab(tester, uz.tabContents);
      expect(shellStack(tester).index, 2);
      expect(find.byType(ContentsScreen), findsOneWidget);

      await tapTab(tester, uz.tabProfile);
      expect(shellStack(tester).index, 3);
      expect(find.byType(ProfileScreen), findsOneWidget);

      await tapTab(tester, uz.tabMap);
      expect(shellStack(tester).index, 0);
      expect(find.byType(MapScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TickerMode disables tickers of hidden tabs only',
        (tester) async {
      await pumpShell(tester);

      // Tab 0 faol: faqat xarita tikerlari yoqiq.
      expect(tickerEnabledOf(tester, MapScreen), isTrue);
      expect(tickerEnabledOf(tester, ShopScreen), isFalse);
      expect(tickerEnabledOf(tester, ContentsScreen), isFalse);
      expect(tickerEnabledOf(tester, ProfileScreen), isFalse);

      await tapTab(tester, uz.tabShop);

      // Endi do'kon yoqiq, xarita o'chiq.
      expect(tickerEnabledOf(tester, MapScreen), isFalse);
      expect(tickerEnabledOf(tester, ShopScreen), isTrue);
      expect(tickerEnabledOf(tester, ContentsScreen), isFalse);
      expect(tickerEnabledOf(tester, ProfileScreen), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileScreen gets a NEW ValueKey after leaving the profile '
        'tab', (tester) async {
      await pumpShell(tester);

      Key? profileKey() => tester
          .widget<ProfileScreen>(
            find.byType(ProfileScreen, skipOffstage: false),
          )
          .key;

      final initialKey = profileKey();
      expect(initialKey, isA<ValueKey<int>>());

      // Profil tabiga KIRISH kalitni o'zgartirmaydi (holat saqlanadi).
      await tapTab(tester, uz.tabProfile);
      expect(profileKey(), initialKey);

      // Profildan CHIQISH epoch'ni oshiradi — yangi kalit, holat tiklanadi.
      await tapTab(tester, uz.tabMap);
      final afterLeave = profileKey();
      expect(afterLeave, isNot(initialKey));

      // Profilga aloqasi yo'q almashinuvlar kalitga tegmaydi.
      await tapTab(tester, uz.tabShop);
      await tapTab(tester, uz.tabContents);
      expect(profileKey(), afterLeave);

      // Yana kirib-chiqish — yana yangi kalit.
      await tapTab(tester, uz.tabProfile);
      await tapTab(tester, uz.tabMap);
      expect(profileKey(), isNot(afterLeave));
      expect(tester.takeException(), isNull);

      await _disposeTree(tester);
    });
  });
}

/// Toza teardown — daraxtni yo'q qilib barcha widget-timerlarini bekor qiladi
/// (yuqori konkurensiyada teardown poygasidagi «!timersPending» oldini oladi).
Future<void> _disposeTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}
