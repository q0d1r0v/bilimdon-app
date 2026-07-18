import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Qo‘y (DESIGN_SPEC "QO‘Y") — baza 46×42. Jun tepa va quloqlar tana
/// orqasida (avval chiziladi); ko‘zlar yuz ichida.
class SheepWidget extends StatelessWidget {
  const SheepWidget({
    super.key,
    this.size = 46,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 42/46 nisbatda.
  final double size;
  final AnimalExpression expression;
  final AnimalAccessory accessory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 42 / 46,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 46,
          height: 42,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Jun tepa.
              cssBox(
                left: 17,
                top: -2,
                width: 12,
                height: 10,
                color: FarmColors.sheepWool,
                border: 2.5,
                radius: cssPercentRadius(
                  12,
                  10,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
              // Quloqlar.
              cssBox(
                left: -2,
                top: 14,
                width: 11,
                height: 8,
                color: FarmColors.sheepFace,
                border: 2.5,
                radius: BorderRadius.circular(99),
                rotateDeg: -24,
              ),
              cssBox(
                right: -2,
                top: 14,
                width: 11,
                height: 8,
                color: FarmColors.sheepFace,
                border: 2.5,
                radius: BorderRadius.circular(99),
                rotateDeg: 24,
              ),
              // Tana (jun).
              cssBox(
                left: 2,
                top: 2,
                width: 42,
                height: 32,
                color: FarmColors.sheepWool,
                border: 2.5,
                radius: cssPercentRadius(
                  42,
                  32,
                  tl: .60,
                  tr: .60,
                  br: .52,
                  bl: .52,
                ),
              ),
              // Yuz — ichida ko‘zlar.
              cssBox(
                left: 11,
                top: 16,
                width: 24,
                height: 19,
                color: FarmColors.sheepFace,
                border: 2.5,
                radius: cssPercentRadius(
                  24,
                  19,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    cssBox(
                      left: 5,
                      top: 6,
                      width: 4,
                      height: 6,
                      child: AnimalEye(
                        width: 4,
                        height: 6,
                        expression: expression,
                      ),
                    ),
                    cssBox(
                      right: 5,
                      top: 6,
                      width: 4,
                      height: 6,
                      child: AnimalEye(
                        width: 4,
                        height: 6,
                        expression: expression,
                      ),
                    ),
                  ],
                ),
              ),
              // Sharf — yuz ostida qizil stadium tasma.
              if (accessory == AnimalAccessory.sheepScarf)
                cssBox(
                  left: 15.5,
                  top: 38,
                  width: 20,
                  height: 6,
                  color: FarmColors.red,
                  radius: BorderRadius.circular(99),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
