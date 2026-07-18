import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Cho‘chqa (DESIGN_SPEC "CHO‘CHQA") — baza 90×82. Quloqlar tana
/// orqasida (avval chiziladi).
class PigWidget extends StatelessWidget {
  const PigWidget({
    super.key,
    this.size = 90,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 82/90 nisbatda.
  final double size;
  final AnimalExpression expression;
  final AnimalAccessory accessory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 82 / 90,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 90,
          height: 82,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Quloqlar — tana orqasida.
              cssBox(
                left: 8,
                top: 0,
                width: 20,
                height: 20,
                color: FarmColors.pigEar,
                border: 2.5,
                radius: cssPercentRadius(
                  20,
                  20,
                  tl: .30,
                  tr: .60,
                  br: .20,
                  bl: .60,
                ),
                rotateDeg: -16,
              ),
              cssBox(
                right: 8,
                top: 0,
                width: 20,
                height: 20,
                color: FarmColors.pigEar,
                border: 2.5,
                radius: cssPercentRadius(
                  20,
                  20,
                  tl: .60,
                  tr: .30,
                  br: .60,
                  bl: .20,
                ),
                rotateDeg: 16,
              ),
              // Tana/bosh.
              cssBox(
                left: 2,
                top: 8,
                width: 86,
                height: 70,
                color: FarmColors.pigBody,
                border: 3,
                radius: cssPercentRadius(
                  86,
                  70,
                  tl: .48,
                  tr: .48,
                  br: .48,
                  bl: .48,
                ),
              ),
              // Ko‘zlar.
              cssBox(
                left: 20,
                top: 30,
                width: 8,
                height: 11,
                child: AnimalEye(width: 8, height: 11, expression: expression),
              ),
              cssBox(
                right: 20,
                top: 30,
                width: 8,
                height: 11,
                child: AnimalEye(width: 8, height: 11, expression: expression),
              ),
              // Tumshuq — markazda, ichida ikki teshik.
              cssBox(
                left: 25,
                top: 38,
                width: 34,
                height: 25,
                color: FarmColors.pigSnout,
                border: 3,
                radius: cssPercentRadius(
                  34,
                  25,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    cssBox(
                      left: 7,
                      top: 6,
                      width: 5,
                      height: 9,
                      color: FarmColors.pigNostril,
                      radius: BorderRadius.circular(3),
                    ),
                    cssBox(
                      right: 7,
                      top: 6,
                      width: 5,
                      height: 9,
                      color: FarmColors.pigNostril,
                      radius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              // Yonoqlar.
              cssBox(
                left: 8,
                top: 48,
                width: 12,
                height: 9,
                color: FarmColors.pigBlush,
                radius: cssPercentRadius(12, 9, tl: .5, tr: .5, br: .5, bl: .5),
                opacity: .85,
              ),
              cssBox(
                right: 8,
                top: 48,
                width: 12,
                height: 9,
                color: FarmColors.pigBlush,
                radius: cssPercentRadius(12, 9, tl: .5, tr: .5, br: .5, bl: .5),
                opacity: .85,
              ),
              // Ko‘zoynak — ikki yupqa halqa + ko‘prikcha.
              if (accessory == AnimalAccessory.pigGlasses) ...[
                cssBox(
                  left: 31,
                  top: 33.5,
                  width: 28,
                  height: 4,
                  color: FarmColors.outline,
                  radius: BorderRadius.circular(2),
                ),
                cssBox(
                  left: 17,
                  top: 28.5,
                  width: 10,
                  height: 10,
                  border: 2,
                  radius: BorderRadius.circular(99),
                ),
                cssBox(
                  right: 17,
                  top: 28.5,
                  width: 10,
                  height: 10,
                  border: 2,
                  radius: BorderRadius.circular(99),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
