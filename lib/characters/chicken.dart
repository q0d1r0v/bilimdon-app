import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Tovuq (DESIGN_SPEC "TOVUQ") — baza 72×84. Toj va oyoqlar tana
/// orqasida (avval chiziladi). Aksessuari yo‘q — parametr faqat yagona
/// imzo uchun qabul qilinadi.
class ChickenWidget extends StatelessWidget {
  const ChickenWidget({
    super.key,
    this.size = 72,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 84/72 nisbatda.
  final double size;
  final AnimalExpression expression;
  final AnimalAccessory accessory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 84 / 72,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 72,
          height: 84,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Toj — uch qizil doira.
              cssBox(
                left: 24,
                top: -2,
                width: 11,
                height: 11,
                color: FarmColors.chickenComb,
                border: 2.5,
                radius: cssPercentRadius(
                  11,
                  11,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
              cssBox(
                left: 31,
                top: -7,
                width: 12,
                height: 13,
                color: FarmColors.chickenComb,
                border: 2.5,
                radius: cssPercentRadius(
                  12,
                  13,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
              cssBox(
                left: 40,
                top: -2,
                width: 11,
                height: 11,
                color: FarmColors.chickenComb,
                border: 2.5,
                radius: cssPercentRadius(
                  11,
                  11,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
              // Oyoqlar.
              cssBox(
                left: 24,
                top: 72,
                width: 4,
                height: 11,
                color: FarmColors.chickBeak,
                radius: BorderRadius.circular(2),
              ),
              cssBox(
                right: 24,
                top: 72,
                width: 4,
                height: 11,
                color: FarmColors.chickBeak,
                radius: BorderRadius.circular(2),
              ),
              // Tana.
              cssBox(
                left: 4,
                top: 6,
                width: 64,
                height: 68,
                color: FarmColors.chickenBody,
                border: 3,
                radius: cssPercentRadius(
                  64,
                  68,
                  tl: .50,
                  tr: .50,
                  br: .46,
                  bl: .46,
                ),
              ),
              // Ko‘zlar.
              cssBox(
                left: 22,
                top: 28,
                width: 6,
                height: 8,
                child: AnimalEye(width: 6, height: 8, expression: expression),
              ),
              cssBox(
                right: 22,
                top: 28,
                width: 6,
                height: 8,
                child: AnimalEye(width: 6, height: 8, expression: expression),
              ),
              // Tumshuq — markazda, pastga qaragan uchburchak.
              cssBox(
                left: 30,
                top: 38,
                width: 12,
                height: 9,
                child: const TriangleWidget(
                  width: 12,
                  height: 9,
                  color: FarmColors.chickBeak,
                  direction: TriangleDirection.down,
                ),
              ),
              // Soqol (wattle) — markazda.
              cssBox(
                left: 31.5,
                top: 46,
                width: 9,
                height: 11,
                color: FarmColors.chickenComb,
                radius: cssPercentRadius(9, 11, tl: .5, tr: .5, br: .5, bl: .5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
