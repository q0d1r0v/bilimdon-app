import 'dart:math' as math;

import 'package:flutter/material.dart';

/// «Bilimdon — brend» (manba: Matematika Oyini.dc.html). 1+2=3 chunky
/// plitkalar brend belgisi + to'liq splash sahnasi (osmon, quyosh, bulutlar,
/// o't tepaligi, panjara). Ranglar dizayndan AYNAN olingan.
class BrandPalette {
  static const red = Color(0xFFE8433F);
  static const redDark = Color(0xFFC22F2C);
  static const blue = Color(0xFF3D9BE9);
  static const blueDark = Color(0xFF2C79BD);
  static const green = Color(0xFF58B94A);
  static const greenDark = Color(0xFF3F8F33);
  static const skyTop = Color(0xFF57ADEE);
  static const skyMid = Color(0xFF7FC6F5);
  static const skyLow = Color(0xFFA9DEFC);
  static const sun = Color(0xFFFFD43C);
  static const sunLight = Color(0xFFFFE47A);
  static const grass = Color(0xFF6FC93F);
  static const fence = Color(0xFFFFFDF6);
}

/// Chunky raqamli plitka (3D pastki qirra + burilish + soya).
class BrandTile extends StatelessWidget {
  const BrandTile({
    super.key,
    required this.text,
    required this.color,
    required this.darkColor,
    required this.size,
    this.rotationDeg = 0,
  });

  final String text;
  final Color color;
  final Color darkColor;
  final double size;
  final double rotationDeg;

  @override
  Widget build(BuildContext context) {
    final r = size * 0.29;
    final ledge = size * 0.105;
    final radius = BorderRadius.circular(r);
    return Transform.rotate(
      angle: rotationDeg * math.pi / 180,
      child: SizedBox(
        width: size,
        height: size + ledge,
        child: Stack(
          children: [
            // Pastki qirra (quyuq) + tashqi soya.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: darkColor,
                  borderRadius: radius,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(20, 60, 110, .28),
                      offset: Offset(0, 8),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
            ),
            // Ustki yuza (asosiy rang) + markazda raqam.
            Positioned(
              top: 0,
              left: 0,
              width: size,
              height: size,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: color, borderRadius: radius),
                child: Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Fredoka',
                    fontSize: size * 0.56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «1 + 2 = 3» tenglama qatori. [tileSize] plitka o'lchami.
class BrandEquation extends StatelessWidget {
  const BrandEquation({super.key, required this.tileSize, this.signColor});

  final double tileSize;
  final Color? signColor;

  @override
  Widget build(BuildContext context) {
    Widget sign(String s) => Text(
          s,
          style: TextStyle(
            fontFamily: 'Fredoka',
            fontSize: tileSize * 0.47,
            fontWeight: FontWeight.w700,
            color: signColor ?? Colors.white,
            shadows: signColor == null
                ? const [
                    Shadow(
                      color: Color.fromRGBO(20, 60, 110, .35),
                      offset: Offset(0, 3),
                      blurRadius: 6,
                    ),
                  ]
                : null,
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BrandTile(
          text: '1',
          color: BrandPalette.red,
          darkColor: BrandPalette.redDark,
          size: tileSize,
          rotationDeg: -7,
        ),
        SizedBox(width: tileSize * 0.18),
        sign('+'),
        SizedBox(width: tileSize * 0.18),
        BrandTile(
          text: '2',
          color: BrandPalette.blue,
          darkColor: BrandPalette.blueDark,
          size: tileSize,
          rotationDeg: 5,
        ),
        SizedBox(width: tileSize * 0.18),
        sign('='),
        SizedBox(width: tileSize * 0.18),
        BrandTile(
          text: '3',
          color: BrandPalette.green,
          darkColor: BrandPalette.greenDark,
          size: tileSize,
          rotationDeg: -4,
        ),
      ],
    );
  }
}

/// 1+2=3 plitkalari kaskadi (kompakt guruh, bounding 132×128). Adaptiv
/// ikonka oldingi qatlami shu guruhni markazlab/masshtablab ishlatadi.
class BrandTilesGroup extends StatelessWidget {
  const BrandTilesGroup({super.key, this.tile = 56});
  final double tile;

  @override
  Widget build(BuildContext context) {
    final off = tile * 38 / 56; // dizayn kaskad qadami.
    final ledge = tile * 0.105;
    return SizedBox(
      width: tile + off * 2,
      height: tile + off * 2 + ledge,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: BrandTile(
              text: '1',
              color: BrandPalette.red,
              darkColor: BrandPalette.redDark,
              size: tile,
              rotationDeg: -8,
            ),
          ),
          Positioned(
            left: off,
            top: off,
            child: BrandTile(
              text: '2',
              color: BrandPalette.blue,
              darkColor: BrandPalette.blueDark,
              size: tile,
              rotationDeg: 5,
            ),
          ),
          Positioned(
            left: off * 2,
            top: off * 2,
            child: BrandTile(
              text: '3',
              color: BrandPalette.green,
              darkColor: BrandPalette.greenDark,
              size: tile,
              rotationDeg: -5,
            ),
          ),
        ],
      ),
    );
  }
}

/// App ikonka arti (dizayn: 160×160 sahna). [withBg] — osmon/quyosh/o't foni;
/// [withTiles] — 1+2=3 kaskadi. Adaptiv qatlamlar uchun alohida chaqiriladi.
class BrandIconArt extends StatelessWidget {
  const BrandIconArt({super.key, this.withBg = true, this.withTiles = true});
  final bool withBg;
  final bool withTiles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 160,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (withBg) ...[
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [BrandPalette.skyTop, BrandPalette.skyMid],
                    stops: [0, .6],
                  ),
                ),
              ),
            ),
            // Quyosh (o'ng-tepa) — adaptiv niqob kesmasligi uchun ichkariroq.
            Positioned(
              right: 26,
              top: 26,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: BrandPalette.sun,
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(255, 212, 60, .30),
                      spreadRadius: 7,
                    ),
                  ],
                ),
              ),
            ),
            // O't tepaligi (pastki gumbaz) — niqobda ko'rinishi uchun balandroq.
            Positioned(
              left: -24,
              right: -24,
              bottom: -30,
              height: 92,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: BrandPalette.grass,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.elliptical(150, 66),
                  ),
                ),
              ),
            ),
            // Urug' nuqtalari.
            const Positioned(
              left: 34,
              bottom: 26,
              child: _IconDot(color: Colors.white),
            ),
            const Positioned(
              left: 116,
              bottom: 30,
              child: _IconDot(color: BrandPalette.sun),
            ),
          ],
          // Plitkalar — yanada kichik va MARKAZDA (aylanma niqob burchaklari
          // «1» va «3» ni kesmasligi uchun; sigir/o't/quyosh atrofni to'ldiradi).
          if (withTiles)
            const Positioned(
              left: 37,
              top: 34,
              child: BrandTilesGroup(tile: 38),
            ),
        ],
      ),
    );
  }
}

class _IconDot extends StatelessWidget {
  const _IconDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Quyosh (radial gradient + ikki halqa).
class BrandSun extends StatelessWidget {
  const BrandSun({super.key, this.size = 76});
  final double size;

  @override
  Widget build(BuildContext context) {
    final k = size / 76;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [BrandPalette.sunLight, BrandPalette.sun],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(255, 212, 60, .12),
            spreadRadius: 38 * k,
          ),
          BoxShadow(
            color: const Color.fromRGBO(255, 212, 60, .25),
            spreadRadius: 18 * k,
          ),
        ],
      ),
    );
  }
}

/// Yumshoq oq bulut (stadion + ikkita tepa).
class BrandCloud extends StatelessWidget {
  const BrandCloud({
    super.key,
    required this.width,
    required this.height,
    this.opacity = 1,
  });
  final double width;
  final double height;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        width: width,
        height: height * 2,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Positioned(
              left: width * 0.18,
              bottom: height * 0.5,
              child: _puff(height * 1.0),
            ),
            Positioned(
              right: width * 0.18,
              bottom: height * 0.45,
              child: _puff(height * 0.78),
            ),
          ],
        ),
      ),
    );
  }

  Widget _puff(double d) => Container(
        width: d,
        height: d,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      );
}

/// O't tepaligi + oq panjara + urug' nuqtalari (splash pastki qismi).
class BrandGrass extends StatelessWidget {
  const BrandGrass({super.key, this.height = 230});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // O't tepaligi (keng gumbaz).
              Positioned(
                left: -w * 0.15,
                right: -w * 0.15,
                top: 0,
                height: height + 120,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: BrandPalette.grass,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.elliptical(w * 0.9, 90),
                      topRight: Radius.elliptical(w * 0.9, 90),
                    ),
                  ),
                ),
              ),
              // Panjara (ikki ufqiy reyka + tik ustunlar).
              Positioned(
                left: 14,
                right: 14,
                top: height * 0.20,
                height: 44,
                child: const _Fence(),
              ),
              // Urug'/gul nuqtalari.
              Positioned(
                left: w * 0.10,
                top: height * 0.62,
                child: _dot(BrandPalette.fence),
              ),
              Positioned(
                left: w * 0.34,
                top: height * 0.80,
                child: _dot(BrandPalette.sun),
              ),
              Positioned(
                left: w * 0.55,
                top: height * 0.58,
                child: _dot(BrandPalette.fence),
              ),
              Positioned(
                left: w * 0.78,
                top: height * 0.82,
                child: _dot(BrandPalette.sun),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

class _Fence extends StatelessWidget {
  const _Fence();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Ikki ufqiy reyka.
        Positioned(left: 0, right: 0, top: 8, child: _rail()),
        Positioned(left: 0, right: 0, top: 24, child: _rail()),
        // Tik ustunlar — teng oraliqda.
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, c) {
              const gap = 42.0;
              final n = (c.maxWidth / gap).floor() + 1;
              return Stack(
                children: [
                  for (var i = 0; i < n; i++)
                    Positioned(
                      left: i * gap,
                      top: 0,
                      bottom: 0,
                      child: Container(width: 7, color: BrandPalette.fence),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _rail() => Container(
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5EE),
          borderRadius: BorderRadius.circular(3),
        ),
      );
}

/// To'liq splash sahnasi (kirish oynasi). [dotPhase] pulsli nuqtalar
/// animatsiyasi uchun 0..1 fazasi.
class SplashScene extends StatelessWidget {
  const SplashScene({super.key, this.dotPhase = 0});

  final double dotPhase;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final tile = (w * 0.16).clamp(52.0, 76.0);
        final grassH = (c.maxHeight * 0.26).clamp(190.0, 300.0);
        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                BrandPalette.skyTop,
                BrandPalette.skyMid,
                BrandPalette.skyLow,
                BrandPalette.skyLow,
              ],
              stops: [0, .34, .52, 1],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(left: 30, top: 84, child: const BrandSun()),
              Positioned(
                right: 24,
                top: 92,
                child: const BrandCloud(width: 66, height: 26),
              ),
              Positioned(
                right: 120,
                top: 176,
                child: const BrandCloud(width: 48, height: 19, opacity: .95),
              ),
              Positioned(
                left: 36,
                top: 212,
                child: const BrandCloud(width: 40, height: 16, opacity: .85),
              ),
              Positioned(
                right: 40,
                top: 286,
                child: const BrandCloud(width: 34, height: 14, opacity: .7),
              ),
              // Markaz: tenglama + Bilimdon.
              Align(
                alignment: const Alignment(0, -0.12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    BrandEquation(tileSize: tile.toDouble()),
                    SizedBox(height: tile * 0.32),
                    Text(
                      'Bilimdon',
                      style: TextStyle(
                        fontFamily: 'Fredoka',
                        fontSize: (w * 0.135).clamp(40.0, 60.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
              // Pulsli yuklanish nuqtalari.
              Positioned(
                left: 0,
                right: 0,
                bottom: grassH + 24,
                child: _LoadingDots(phase: dotPhase),
              ),
              // O't + panjara.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BrandGrass(height: grassH.toDouble()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots({required this.phase});
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _dot(i),
        ],
      ],
    );
  }

  Widget _dot(int i) {
    // Har nuqta 0.15 fazaga siljigan sinus pulsi (1.0→1.35→1.0).
    final t = (phase - i * 0.15) % 1.0;
    final scale = 1 + 0.35 * (0.5 - 0.5 * math.cos(t * 2 * math.pi));
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 15,
        height: 15,
        decoration: BoxDecoration(
          color: BrandPalette.sun,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
        ),
      ),
    );
  }
}
