import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// O‘rdak (yangi tur) — baza 60×54. Oq (Pekin) tana, to‘q sariq yapaloq
/// tumshuq va oyoqlar. Boshi chap-tepada, tumshug‘i chapga qaragan; dumi
/// o‘ngda ko‘tarilgan. Jo‘ja/tovuqdan farqli — sariq emas, oq va yumaloq.
class DuckWidget extends StatelessWidget {
  const DuckWidget({
    super.key,
    this.size = 60,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 54/60 nisbatda.
  final double size;
  final AnimalExpression expression;

  /// O‘rdakda mos aksessuar yo‘q — imzo bir xil bo‘lishi uchun qabul qilinadi.
  final AnimalAccessory accessory;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 54 / 60,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 60,
          height: 54,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Oyoqlar — tana ostidan chiqadigan ikki kalta eshkak.
              cssBox(
                left: 18,
                top: 47,
                width: 9,
                height: 7,
                color: FarmColors.duckBill,
                border: 2,
                radius: cssPercentRadius(9, 7, tl: .3, tr: .3, br: .6, bl: .6),
              ),
              cssBox(
                left: 30,
                top: 47,
                width: 9,
                height: 7,
                color: FarmColors.duckBill,
                border: 2,
                radius: cssPercentRadius(9, 7, tl: .3, tr: .3, br: .6, bl: .6),
              ),
              // Dum — o‘ngda ko‘tarilgan uchburchak.
              cssBox(
                right: 0,
                top: 16,
                width: 14,
                height: 12,
                child: const TriangleWidget(
                  width: 14,
                  height: 12,
                  color: FarmColors.duckBody,
                  direction: TriangleDirection.up,
                ),
                rotateDeg: 28,
              ),
              // Tana — katta yumaloq oval.
              cssBox(
                left: 6,
                top: 20,
                width: 44,
                height: 30,
                color: FarmColors.duckBody,
                border: 2.5,
                radius: cssPercentRadius(44, 30, tl: .6, tr: .5, br: .5, bl: .6),
              ),
              // Qanot — tana ustida yotgan iliq soya yoy.
              cssBox(
                left: 22,
                top: 27,
                width: 22,
                height: 15,
                color: FarmColors.duckWing,
                border: 2.5,
                radius: cssPercentRadius(22, 15, tl: .7, tr: .5, br: .7, bl: .5),
                rotateDeg: -6,
              ),
              // Bosh — chap-tepada dumaloq.
              cssBox(
                left: 4,
                top: 4,
                width: 26,
                height: 24,
                color: FarmColors.duckBody,
                border: 2.5,
                radius: cssPercentRadius(26, 24, tl: .5, tr: .5, br: .5, bl: .5),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Ko‘z — bosh ichida, chapga yaqin.
                    cssBox(
                      left: 12,
                      top: 8,
                      width: 5,
                      height: 7,
                      child: AnimalEye(
                        width: 5,
                        height: 7,
                        expression: expression,
                      ),
                    ),
                  ],
                ),
              ),
              // Tumshuq — chapga chiqib turgan yapaloq to‘q sariq stadion.
              cssBox(
                left: -9,
                top: 15,
                width: 18,
                height: 9,
                color: FarmColors.duckBill,
                border: 2.5,
                radius: BorderRadius.circular(99),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
