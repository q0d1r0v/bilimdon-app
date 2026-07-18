import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';

/// Do‘kon uchun sotib olinadigan dekor elementlari — sahna bilan bir xil
/// san’at tili (Container + border + cloneShadow, faqat FarmColors palitrasi).

/// Olma daraxti: jigarrang tana (10×26, radius 3) + #4CA82E shox-barg
/// doirasi 2 shadow-klon bilan + 3 ta 6px qizil olma. Baza 80×80.
class AppleTree extends StatelessWidget {
  const AppleTree({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 80;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (size - 10 * s) / 2,
            bottom: 0,
            child: Container(
              width: 10 * s,
              height: 26 * s,
              decoration: BoxDecoration(
                color: FarmColors.brown,
                borderRadius: BorderRadius.circular(3 * s),
              ),
            ),
          ),
          Positioned(
            left: (size - 46 * s) / 2,
            top: 4 * s,
            child: Container(
              width: 46 * s,
              height: 46 * s,
              decoration: BoxDecoration(
                color: FarmColors.bushDark,
                shape: BoxShape.circle,
                boxShadow: [
                  cloneShadow(-17 * s, 12 * s, -8 * s, FarmColors.bushDark),
                  cloneShadow(17 * s, 12 * s, -8 * s, FarmColors.bushDark),
                ],
              ),
            ),
          ),
          for (final (dx, dy) in const [(26.0, 22.0), (46.0, 16.0), (37.0, 36.0)])
            Positioned(
              left: dx * s,
              top: dy * s,
              child: Container(
                width: 6 * s,
                height: 6 * s,
                decoration: const BoxDecoration(
                  color: FarmColors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pichan g‘arami: #F2D8A0 gumbaz (radius 50%/50%/8/8) + kontur rangida
/// 2 ingichka qiya chiziq. Baza 64×44.
class HayStack extends StatelessWidget {
  const HayStack({super.key, this.size = 64});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 64;
    final w = size;
    final h = 44 * s;
    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: FarmColors.horn,
        borderRadius: BorderRadius.only(
          topLeft: Radius.elliptical(w / 2, h / 2),
          topRight: Radius.elliptical(w / 2, h / 2),
          bottomLeft: Radius.circular(8 * s),
          bottomRight: Radius.circular(8 * s),
        ),
      ),
      child: Stack(
        children: [
          for (final (dx, angle) in const [(20.0, .35), (38.0, -.3)])
            Positioned(
              left: dx * s,
              top: 12 * s,
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 2 * s,
                  height: 22 * s,
                  color: FarmColors.outline.withValues(alpha: .35),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hovuz: #8FD0F8 ellips (w × h·0.55) + ichida #B8E6FF yorug‘lik ellipsi.
class Pond extends StatelessWidget {
  const Pond({super.key, this.size = 70});

  final double size;

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = size * 0.55;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: FarmColors.skyMid,
        borderRadius: BorderRadius.all(Radius.elliptical(w / 2, h / 2)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: w * 0.16,
            top: h * 0.18,
            child: Container(
              width: w * 0.5,
              height: h * 0.38,
              decoration: BoxDecoration(
                color: FarmColors.skyLow,
                borderRadius: BorderRadius.all(
                  Radius.elliptical(w * 0.25, h * 0.19),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gulzor: #8ED95E stadium asos + gul-nuqtalar (qizil/oq/tanga aralash)
/// cloneShadow klonlari bilan. Baza 70×35.
class FlowerBed extends StatelessWidget {
  const FlowerBed({super.key, this.size = 70});

  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / 70;
    final w = size;
    final h = 25 * s;
    return SizedBox(
      width: w,
      height: 35 * s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: h,
              decoration: BoxDecoration(
                color: FarmColors.grassLight,
                borderRadius: BorderRadius.circular(FarmRadius.pill),
              ),
            ),
          ),
          Positioned(
            left: 12 * s,
            top: 6 * s,
            child: Container(
              width: 6 * s,
              height: 6 * s,
              decoration: BoxDecoration(
                color: FarmColors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  cloneShadow(16 * s, 8 * s, 0, Colors.white),
                  cloneShadow(32 * s, 2 * s, 0, FarmColors.coin),
                  cloneShadow(46 * s, 10 * s, 0, FarmColors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
