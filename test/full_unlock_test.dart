import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/map/chapter_banner.dart';
import 'package:math_farm/features/map/map_screen.dart';
import 'package:math_farm/features/profile/parent_gate.dart';
import 'package:math_farm/features/profile/profile_screen.dart';
import 'package:math_farm/features/purchase/full_unlock_sheet.dart';
import 'package:math_farm/features/shop/full_unlock_card.dart';
import 'package:math_farm/features/shop/shop_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fakes/fake_purchase_service.dart';

/// audioplayers plagin kanallarini jim mock qiladi.
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
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

/// Cheksiz animatsiyalar bor — pumpAndSettle EMAS.
Future<void> pumpFrames(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final uz = AppLocalizationsUz();

  setUp(() {
    mockAudioChannels(binding.defaultBinaryMessenger);
    AudioService.instance.soundOn = false;
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProgressStore> loadStore() =>
      ProgressStore.load(nowProvider: () => DateTime(2026, 7, 16, 12));

  void usePhonePortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// Ota-onalar darvozasini to'g'ri javob bilan o'tadi.
  Future<void> solveGate(WidgetTester tester) async {
    final prompt = tester
        .widget<Text>(find.descendant(
          of: find.byType(ParentGateDialog),
          matching: find.textContaining('×'),
        ))
        .data!;
    final m = RegExp(r'(\d+) × (\d+)').firstMatch(prompt)!;
    final answer = int.parse(m.group(1)!) * int.parse(m.group(2)!);
    await tester.tap(find.descendant(
      of: find.byType(ParentGateDialog),
      matching: find.text('$answer'),
    ));
    await pumpFrames(tester, 4);
  }

  Future<void> openSheetFromShop(WidgetTester tester) async {
    await tester.tap(find.descendant(
      of: find.byType(FullUnlockCard),
      matching: find.text(r'$1.99'),
    ));
    await pumpFrames(tester, 4);
    expect(find.byType(FullUnlockSheet), findsOneWidget);
  }

  testWidgets('shop card shows price, sheet buy goes through parent gate',
      (tester) async {
    usePhonePortrait(tester);
    final store = await loadStore();
    final purchases = FakePurchaseService(store);
    await tester.pumpWidget(wrap(ShopScreen(store: store, purchases: purchases)));
    await pumpFrames(tester, 2);

    expect(find.text(uz.unlockTitle), findsOneWidget);
    await openSheetFromShop(tester);

    // Darvoza bekor qilinsa — xarid boshlanmaydi.
    await tester.tap(find.text(uz.unlockBuy(r'$1.99')));
    await pumpFrames(tester, 4);
    expect(find.byType(ParentGateDialog), findsOneWidget);
    await tester.tapAt(const Offset(5, 5)); // fon — dialog yopiladi
    await pumpFrames(tester, 4);
    expect(find.byType(ParentGateDialog), findsNothing);
    expect(purchases.buyCalls, 0);
    expect(store.fullUnlocked, isFalse);

    // To'g'ri javob — xarid, karta «Sotib olingan» holatiga o'tadi.
    await tester.tap(find.text(uz.unlockBuy(r'$1.99')));
    await pumpFrames(tester, 4);
    await solveGate(tester);
    expect(purchases.buyCalls, 1);
    expect(store.fullUnlocked, isTrue);
    expect(find.text(uz.unlockClose), findsOneWidget);

    await tester.tap(find.text(uz.unlockClose));
    await pumpFrames(tester, 4);
    expect(find.text('${uz.unlockOwnedShort} ✓'), findsOneWidget);
    expect(store.isLevelUnlocked('3-1'), isFalse,
        reason: 'ketma-ketlik saqlanadi — 2-bob hali o’ynalmagan');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unavailable store disables buy and explains why',
      (tester) async {
    usePhonePortrait(tester);
    final store = await loadStore();
    final purchases =
        FakePurchaseService(store, available: false, priceLabel: null);
    await tester.pumpWidget(wrap(ShopScreen(store: store, purchases: purchases)));
    await pumpFrames(tester, 2);

    await tester.tap(find.descendant(
      of: find.byType(FullUnlockCard),
      matching: find.text(uz.unlockOpen),
    ));
    await pumpFrames(tester, 4);
    expect(find.text(uz.unlockUnavailable), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(FullUnlockSheet),
      matching: find.text(uz.unlockOpen),
    ));
    await pumpFrames(tester, 4);
    expect(find.byType(ParentGateDialog), findsNothing);
    expect(purchases.buyCalls, 0);
  });

  testWidgets('profile restore button restores and reports', (tester) async {
    usePhonePortrait(tester);
    final store = await loadStore();
    final purchases = FakePurchaseService(store, restorable: true);
    await tester.pumpWidget(
      wrap(ProfileScreen(store: store, purchases: purchases)),
    );
    await pumpFrames(tester, 2);

    final restore = find.text(uz.restorePurchases);
    await tester.ensureVisible(restore);
    await pumpFrames(tester, 2);
    await tester.tap(restore);
    await pumpFrames(tester, 4);

    expect(purchases.restoreCalls, 1);
    expect(store.fullUnlocked, isTrue);
    expect(find.text(uz.restoreDone), findsOneWidget);
  });

  testWidgets('screens without a purchase service hide IAP UI',
      (tester) async {
    usePhonePortrait(tester);
    final store = await loadStore();
    await tester.pumpWidget(wrap(ShopScreen(store: store)));
    await pumpFrames(tester, 2);
    expect(find.byType(FullUnlockCard), findsNothing);
  });

  testWidgets('map: free chapters done → banner offers unlock, opens sheet',
      (tester) async {
    usePhonePortrait(tester);
    SharedPreferences.setMockInitialValues({
      'profile_v1': jsonEncode({
        'schemaVersion': 1,
        'levels': {
          for (var ch = 1; ch <= 2; ch++)
            for (var l = 1; l <= 6; l++) '$ch-$l': {'stars': 3, 'attempts': 1},
        },
      }),
    });
    final store = await loadStore();
    final purchases = FakePurchaseService(store);
    rootBundle.clear();
    await tester.pumpWidget(wrap(MapScreen(store: store, purchases: purchases)));
    await pumpFrames(tester, 10);

    // Banner 6-bobni emas, xaridsiz yopiq 3-bobni ko'rsatadi.
    final banner = tester.widget<ChapterBanner>(find.byType(ChapterBanner));
    expect(banner.chapterNumber, 3);
    expect(banner.onUnlock, isNotNull);

    await tester.tap(find.descendant(
      of: find.byType(ChapterBanner),
      matching: find.text(uz.unlockOpen),
    ));
    await pumpFrames(tester, 4);
    expect(find.byType(FullUnlockSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
