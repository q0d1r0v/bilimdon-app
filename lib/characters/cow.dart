import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Sigir (DESIGN_SPEC "SIGIR") — baza 100×92. Shox va quloqlar bazadan
/// tashqariga chiqadi — Clip.none majburiy. Z-tartib prototip DOM
/// bo‘yicha: shoxlar va quloqlar bosh ORQAsida (avval chiziladi).
class CowWidget extends StatelessWidget {
  const CowWidget({
    super.key,
    this.size = 100,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 92/100 nisbatda.
  final double size;
  final AnimalExpression expression;
  final AnimalAccessory accessory;

  /// Bosh radiusi: CSS 46%/46%/44%/44% (84×76 kontent).
  static final BorderRadius _headRadius = cssPercentRadius(
    84,
    76,
    tl: .46,
    tr: .46,
    br: .44,
    bl: .44,
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 92 / 100,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 100,
          height: 92,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Shoxlar — bosh orqasida.
              cssBox(
                left: 8,
                top: 0,
                width: 16,
                height: 15,
                color: FarmColors.horn,
                border: 3,
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                rotateDeg: -14,
              ),
              cssBox(
                right: 8,
                top: 0,
                width: 16,
                height: 15,
                color: FarmColors.horn,
                border: 3,
                radius: const BorderRadius.only(
                  topLeft: Radius.circular(7),
                  topRight: Radius.circular(7),
                  bottomRight: Radius.circular(2),
                  bottomLeft: Radius.circular(2),
                ),
                rotateDeg: 14,
              ),
              // Quloqlar — bosh orqasida.
              cssBox(
                left: -5,
                top: 24,
                width: 20,
                height: 14,
                color: FarmColors.cowPink,
                border: 3,
                radius: BorderRadius.circular(99),
                rotateDeg: -20,
              ),
              cssBox(
                right: -5,
                top: 24,
                width: 20,
                height: 14,
                color: FarmColors.cowPink,
                border: 3,
                radius: BorderRadius.circular(99),
                rotateDeg: 20,
              ),
              // Bosh — ichida dog‘, ko‘zlar va tumshuq (overflow hidden).
              cssBox(
                left: 8,
                top: 10,
                width: 84,
                height: 76,
                color: FarmColors.cowWhite,
                border: 3,
                radius: _headRadius,
                child: ClipRRect(
                  borderRadius: _headRadius,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Dog‘ — burchakda kesiladi.
                      cssBox(
                        right: -14,
                        top: -12,
                        width: 40,
                        height: 36,
                        color: FarmColors.outline,
                        radius: cssPercentRadius(
                          40,
                          36,
                          tl: .5,
                          tr: .5,
                          br: .5,
                          bl: .5,
                        ),
                      ),
                      // Ko‘zlar.
                      cssBox(
                        left: 18,
                        top: 28,
                        width: 11,
                        height: 14,
                        child: AnimalEye(
                          width: 11,
                          height: 14,
                          expression: expression,
                        ),
                      ),
                      cssBox(
                        right: 18,
                        top: 28,
                        width: 11,
                        height: 14,
                        child: AnimalEye(
                          width: 11,
                          height: 14,
                          expression: expression,
                        ),
                      ),
                      // Tumshuq — gorizontal markazda, bottom:3.
                      cssBox(
                        left: 11,
                        bottom: 3,
                        width: 56,
                        height: 26,
                        color: FarmColors.cowPink,
                        border: 3,
                        radius: BorderRadius.circular(14),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            cssBox(
                              left: 12,
                              top: 7,
                              width: 6,
                              height: 9,
                              color: FarmColors.cowNostril,
                              radius: cssPercentRadius(
                                6,
                                9,
                                tl: .5,
                                tr: .5,
                                br: .5,
                                bl: .5,
                              ),
                            ),
                            cssBox(
                              right: 12,
                              top: 7,
                              width: 6,
                              height: 9,
                              color: FarmColors.cowNostril,
                              radius: cssPercentRadius(
                                6,
                                9,
                                tl: .5,
                                tr: .5,
                                br: .5,
                                bl: .5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Shlyapa — shoxlar orasida, bosh ustida.
              if (accessory == AnimalAccessory.cowHat) ...[
                cssBox(
                  left: 40,
                  top: -20,
                  width: 20,
                  height: 14,
                  color: FarmColors.brown,
                  radius: const BorderRadius.vertical(top: Radius.circular(3)),
                ),
                cssBox(
                  left: 33,
                  top: -6,
                  width: 34,
                  height: 5,
                  color: FarmColors.brownDark,
                  radius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
