import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Jo‘ja (DESIGN_SPEC "JO‘JA") — baza 40×44. Qanotlar bazadan chiqadi va
/// tana USTIda chiziladi (prototip DOM tartibi).
class ChickWidget extends StatelessWidget {
  const ChickWidget({
    super.key,
    this.size = 40,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 44/40 nisbatda.
  final double size;
  final AnimalExpression expression;
  final AnimalAccessory accessory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 44 / 40,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 40,
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Tuk — tomchi shakl, −45° burilgan.
              cssBox(
                left: 16,
                top: -3,
                width: 7,
                height: 7,
                color: FarmColors.chickBeak,
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(50),
                  topRight: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
                rotateDeg: -45,
              ),
              // Tana.
              cssBox(
                left: 2,
                top: 4,
                width: 36,
                height: 38,
                color: FarmColors.chickBody,
                border: 2.5,
                radius: cssPercentRadius(
                  36,
                  38,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
              // Ko‘zlar.
              cssBox(
                left: 12,
                top: 18,
                width: 5,
                height: 7,
                child: AnimalEye(width: 5, height: 7, expression: expression),
              ),
              cssBox(
                right: 12,
                top: 18,
                width: 5,
                height: 7,
                child: AnimalEye(width: 5, height: 7, expression: expression),
              ),
              // Tumshuq — markazda, pastga qaragan uchburchak.
              cssBox(
                left: 15,
                top: 27,
                width: 10,
                height: 8,
                child: const TriangleWidget(
                  width: 10,
                  height: 8,
                  color: FarmColors.chickBeak,
                  direction: TriangleDirection.down,
                ),
              ),
              // Qanotlar — tana ustida.
              cssBox(
                left: -2,
                top: 20,
                width: 10,
                height: 14,
                color: FarmColors.chickWing,
                border: 2.5,
                radius: cssPercentRadius(
                  10,
                  14,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
                rotateDeg: 16,
              ),
              cssBox(
                right: -2,
                top: 20,
                width: 10,
                height: 14,
                color: FarmColors.chickWing,
                border: 2.5,
                radius: cssPercentRadius(
                  10,
                  14,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
                rotateDeg: -16,
              ),
              // Bantik — tuk yonida: ikki uchburchak + markaziy nuqta.
              if (accessory == AnimalAccessory.chickBow) ...[
                cssBox(
                  left: 19.5,
                  top: -6,
                  width: 6,
                  height: 8,
                  child: const TriangleWidget(
                    width: 6,
                    height: 8,
                    color: FarmColors.red,
                    direction: TriangleDirection.right,
                  ),
                ),
                cssBox(
                  left: 28.5,
                  top: -6,
                  width: 6,
                  height: 8,
                  child: const TriangleWidget(
                    width: 6,
                    height: 8,
                    color: FarmColors.red,
                    direction: TriangleDirection.left,
                  ),
                ),
                cssBox(
                  left: 25,
                  top: -4,
                  width: 4,
                  height: 4,
                  color: FarmColors.red,
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
