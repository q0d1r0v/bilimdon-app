import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/features/splash/splash_scene.dart';

/// Brend rasmlari generatori (1+2=3 ikonka + splash sahnasi). Ilovaning O'Z
/// brend widgetlaridan (splash_scene.dart) render qilinadi — manba dizayn
/// «Matematika Oyini.dc.html» ga AYNAN mos. Ishga tushirish:
/// `flutter test test/brand/generate_brand_test.dart`. Chiqish `assets/brand/`.

Future<void> _loadFredoka() async {
  final loader = FontLoader('Fredoka');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Fredoka-$w.ttf').readAsBytesSync();
    loader.addFont(Future.value(bytes.buffer.asByteData()));
  }
  await loader.load();
}

void main() {
  const outDir = 'assets/brand';

  testWidgets('brend rasmlarini yaratadi (1+2=3 ikonka + splash)',
      (tester) async {
    await _loadFredoka();
    tester.view.physicalSize = const Size(2000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Future<void> shoot({
      required Widget child,
      required double width,
      required double height,
      required double pixelRatio,
      required String name,
    }) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: RepaintBoundary(
              key: key,
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ),
      );
      await tester.pump();
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      late ui.Image image;
      await tester.runAsync(() async {
        image = await boundary.toImage(pixelRatio: pixelRatio);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$outDir/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
      image.dispose();
    }

    // 1) To'liq ikonka (osmon + quyosh + o't + 1+2=3) — 1024x1024.
    await shoot(
      child: const BrandIconArt(withBg: true, withTiles: true),
      width: 160,
      height: 160,
      pixelRatio: 6.4,
      name: 'icon_full.png',
    );
    // 2) Adaptiv ikonka foni (osmon + quyosh + o't, plitkasiz) — 1024x1024.
    await shoot(
      child: const BrandIconArt(withBg: true, withTiles: false),
      width: 160,
      height: 160,
      pixelRatio: 6.4,
      name: 'icon_bg.png',
    );
    // 3) Adaptiv ikonka oldingi qatlami — plitkalar AYNAN dizayn joyida
    //    (fon = icon_bg, ular birlashsa icon_full = dizayn hosil bo'ladi).
    await shoot(
      child: const BrandIconArt(withBg: false, withTiles: true),
      width: 160,
      height: 160,
      pixelRatio: 6.4,
      name: 'icon_foreground.png',
    );
    // 3b) To'liq shaffof oldingi qatlam — MIUI adaptiv FOREGROUND'ni zoom
    //     qiladi (plitkani kattalab, quyosh/o't'ni kesadi). Butun dizaynni
    //     BACKGROUND (icon_full) ga qo'yib, foreground'ni bo'sh qoldiramiz.
    await shoot(
      child: const SizedBox.expand(),
      width: 160,
      height: 160,
      pixelRatio: 6.4,
      name: 'icon_transparent.png',
    );
    // 4) Native splash markaziy belgisi (1+2=3, shaffof) — brief OS splash.
    await shoot(
      child: const Center(child: BrandEquation(tileSize: 72)),
      width: 360,
      height: 200,
      pixelRatio: 4,
      name: 'splash_mark.png',
    );
    // 5) To'liq splash sahnasi — faqat vizual tekshiruv uchun (preview).
    await shoot(
      child: const SplashScene(dotPhase: .35),
      width: 412,
      height: 892,
      pixelRatio: 2,
      name: 'splash_preview.png',
    );
    // 6) Play do'kon FEATURE grafikasi (MAJBURIY, aynan 1024x500).
    await shoot(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BrandPalette.skyTop,
              BrandPalette.skyMid,
              BrandPalette.skyLow,
            ],
            stops: [0, .5, 1],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(left: 44, top: 40, child: BrandSun(size: 96)),
            const Positioned(
              right: 90,
              top: 54,
              child: BrandCloud(width: 96, height: 36),
            ),
            const Positioned(
              right: 330,
              top: 120,
              child: BrandCloud(width: 64, height: 24, opacity: .9),
            ),
            const Positioned(
              left: 150,
              top: 116,
              child: BrandCloud(width: 52, height: 20, opacity: .85),
            ),
            Align(
              alignment: const Alignment(0, -0.22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandEquation(tileSize: 92),
                  const SizedBox(height: 18),
                  const Text(
                    'Bilimdon',
                    style: TextStyle(
                      fontFamily: 'Fredoka',
                      fontSize: 80,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: BrandGrass(height: 120),
            ),
          ],
        ),
      ),
      width: 1024,
      height: 500,
      pixelRatio: 1,
      name: 'feature_graphic.png',
    );

    for (final f in [
      'icon_full.png',
      'icon_bg.png',
      'icon_foreground.png',
      'splash_mark.png',
      'splash_preview.png',
      'feature_graphic.png',
    ]) {
      expect(File('$outDir/$f').existsSync(), isTrue, reason: f);
    }
  });
}
