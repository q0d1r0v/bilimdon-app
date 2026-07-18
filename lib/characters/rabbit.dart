import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';
import 'parts.dart';

/// Quyon (yangi tur) — baza 48×56 (quloqlar tufayli bo‘yi kengidan katta).
/// Iliq kulrang-oq tana, ikki tik quloq (ichi pushti), yumaloq oq dum va
/// pushti burun. Oldinga qaragan — ikki ko‘z simmetrik.
class RabbitWidget extends StatelessWidget {
  const RabbitWidget({
    super.key,
    this.size = 48,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
  });

  /// Kenglik px; balandlik avtomatik 56/48 nisbatda.
  final double size;
  final AnimalExpression expression;

  /// Quyonda mos aksessuar yo‘q — imzo bir xil bo‘lishi uchun qabul qilinadi.
  final AnimalAccessory accessory;

  Widget _ear({required double left, required double rotateDeg}) {
    // Tik quloq: tashqi tana rangli stadion + ichida pushti stadion.
    return cssBox(
      left: left,
      top: -6,
      width: 10,
      height: 26,
      color: FarmColors.rabbitBody,
      border: 2.5,
      radius: BorderRadius.circular(99),
      rotateDeg: rotateDeg,
      child: Center(
        child: Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: FarmColors.rabbitEar,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }

  Widget _eye(double left) => cssBox(
        left: left,
        top: 8,
        width: 5,
        height: 7,
        child: AnimalEye(width: 5, height: 7, expression: expression),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 56 / 48,
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(
          width: 48,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Quloqlar — bosh ortida (avval chiziladi).
              _ear(left: 13, rotateDeg: -12),
              _ear(left: 25, rotateDeg: 12),
              // Dumaloq oq dum — pastda o‘ngda, tana ortida.
              cssBox(
                right: 2,
                bottom: 2,
                width: 13,
                height: 13,
                color: FarmColors.cowWhite,
                border: 2.5,
                radius: BorderRadius.circular(99),
              ),
              // Tana — yumaloq oval.
              cssBox(
                left: 7,
                top: 26,
                width: 34,
                height: 28,
                color: FarmColors.rabbitBody,
                border: 2.5,
                radius: cssPercentRadius(34, 28, tl: .6, tr: .6, br: .5, bl: .5),
              ),
              // Bosh — tana ustida yumaloq.
              cssBox(
                left: 9,
                top: 14,
                width: 30,
                height: 26,
                color: FarmColors.rabbitBody,
                border: 2.5,
                radius: cssPercentRadius(30, 26, tl: .5, tr: .5, br: .5, bl: .5),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _eye(7),
                    _eye(18),
                    // Burun — markazda pushti kichik uchburchak.
                    cssBox(
                      left: 12,
                      top: 16,
                      width: 6,
                      height: 5,
                      child: const TriangleWidget(
                        width: 6,
                        height: 5,
                        color: FarmColors.rabbitNose,
                        direction: TriangleDirection.down,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
