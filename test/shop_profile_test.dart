import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/core/audio/audio_service.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:math_farm/features/profile/profile_screen.dart';
import 'package:math_farm/features/shop/shop_screen.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// audioplayers plagin kanallarini jim mock qiladi — testda AudioPlayer
/// yaratilishi va SFX chaqiruvlari xatosiz o'tadi.
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

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final uz = AppLocalizationsUz();

  setUp(() {
    mockAudioChannels(binding.defaultBinaryMessenger);
    // SFX chaqiruvlari platformaga chiqmasin.
    AudioService.instance.soundOn = false;
  });

  group('ShopScreen', () {
    testWidgets('buying flowerBed spends coins and flips button to place',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile_v1': '{"schemaVersion":1,"coins":500}',
      });
      final store = await ProgressStore.load(
        nowProvider: () => DateTime(2026, 7, 16, 12),
      );
      expect(store.coins, 500);

      await tester.pumpWidget(wrap(ShopScreen(store: store)));
      await tester.pump();

      // flowerBed narxi 100 — yagona '100' tugma. (Do'kon scroll — power-up
      // seksiyasi tepada, dekor pastroqda, shuning uchun ko'rinadigan qilamiz.)
      expect(find.text('100'), findsOneWidget);
      await tester.ensureVisible(find.text('100'));
      await tester.pump();
      await tester.tap(find.text('100'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500)); // popIn tugashi

      expect(store.coins, 400);
      expect(store.ownedItems.contains('flowerBed'), isTrue);
      // Tugma endi dekor uchun «qo'yish» yorlig'ini ko'rsatadi.
      expect(find.text('100'), findsNothing);
      expect(find.text(uz.shopPlace), findsOneWidget);
      // Tanga pill yangilangan ('400' pillda + pichan narxida ham bor).
      expect(find.text('400'), findsNWidgets(2));
    });

    testWidgets('not enough coins shows tooltip and keeps balance',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'profile_v1': '{"schemaVersion":1,"coins":50}',
      });
      final store = await ProgressStore.load(
        nowProvider: () => DateTime(2026, 7, 16, 12),
      );

      await tester.pumpWidget(wrap(ShopScreen(store: store)));
      await tester.pump();

      await tester.ensureVisible(find.text('100'));
      await tester.pump();
      await tester.tap(find.text('100'));
      await tester.pump();
      expect(find.text(uz.shopNotEnough), findsOneWidget);
      expect(store.coins, 50);
      expect(store.ownedItems, isEmpty);

      // Pufak 1.2s dan keyin yo'qoladi (shake ham tugaydi).
      await tester.pump(const Duration(milliseconds: 1300));
      expect(find.text(uz.shopNotEnough), findsNothing);
    });
  });

  group('ProfileScreen', () {
    testWidgets('sound switch toggles store.soundOn', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load(
        nowProvider: () => DateTime(2026, 7, 16, 12),
      );
      expect(store.soundOn, isTrue);

      await tester.pumpWidget(wrap(ProfileScreen(store: store)));
      await tester.pump();

      // Birinchi switch — ovoz.
      await tester.tap(find.byType(Switch).first);
      await tester.pump(const Duration(milliseconds: 300));

      expect(store.soundOn, isFalse);
      expect(AudioService.instance.soundOn, isFalse);
    });

    testWidgets('avatar picker updates store.avatar', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final store = await ProgressStore.load(
        nowProvider: () => DateTime(2026, 7, 16, 12),
      );
      expect(store.avatar, 'cow');

      await tester.pumpWidget(wrap(ProfileScreen(store: store)));
      await tester.pump();

      // Ism header'da HAM, tahrir maydonida HAM ko'rinadi (2 marta).
      expect(find.text('Aziza'), findsNWidgets(2));
      expect(find.text(uz.levelBadge(1)), findsOneWidget);
    });
  });
}
