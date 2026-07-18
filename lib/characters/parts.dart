import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';
import 'animal.dart';

/// CSS content-box divni Positioned+Container juftiga AYNAN o‘girish
/// qoidasi (prototip divlari content-box):
/// - CSS `left/top` border-box chetini joylashtiradi → Positioned left/top
///   = css left/top, o‘zgarishsiz;
/// - CSS `width/height` — kontent o‘lchami, border TAShQARIGA qo‘shiladi →
///   Container o‘lchami = css o‘lcham + 2×border (masalan CSS 16×15 div,
///   border 3 → 22×21 umumiy).
/// Barcha personaj qismlari faqat shu yordamchi orqali quriladi —
/// semantika har turda bir xil bo‘lishi uchun. [rotateDeg] — CSS rotate
/// (musbat = soat mili), markaz atrofida.
Widget cssBox({
  double? left,
  double? right,
  double? top,
  double? bottom,
  required double width,
  required double height,
  double border = 0,
  Color borderColor = FarmColors.outline,
  Color? color,
  BorderRadius? radius,
  double rotateDeg = 0,
  double opacity = 1,
  Widget? child,
}) {
  Widget box = Container(
    width: width + 2 * border,
    height: height + 2 * border,
    decoration: BoxDecoration(
      color: color,
      border: border > 0 ? Border.all(color: borderColor, width: border) : null,
      borderRadius: radius,
    ),
    child: child,
  );
  if (rotateDeg != 0) {
    box = Transform.rotate(angle: rotateDeg * math.pi / 180, child: box);
  }
  if (opacity != 1) {
    box = Opacity(opacity: opacity, child: box);
  }
  return Positioned(
    left: left,
    right: right,
    top: top,
    bottom: bottom,
    child: box,
  );
}

/// Ko‘z: #4A3B28 ellips + oq nur. Etalon — sigir: 11×14 ko‘z, 4×4 nur
/// left:2,top:2; boshqa o‘lchamlarda nur proporsional masshtablanadi.
/// Ifodalar: idle — to‘liq ellips; blink — scaleY .1 (yig‘ilgan chiziq);
/// happy — yuqoriga qaragan qalin yoy; sad — scaleY .8 ellips + tepada
/// −15° burilgan qoshcha.
class AnimalEye extends StatelessWidget {
  const AnimalEye({
    super.key,
    required this.width,
    required this.height,
    this.expression = AnimalExpression.idle,
  });

  final double width;
  final double height;
  final AnimalExpression expression;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: switch (expression) {
        AnimalExpression.idle => _openEye(),
        AnimalExpression.blink => Transform.scale(
          scaleY: .1,
          child: _openEye(),
        ),
        AnimalExpression.happy => const CustomPaint(
          painter: _HappyEyePainter(),
        ),
        AnimalExpression.sad => _sadEye(),
      },
    );
  }

  /// To‘liq ochiq ko‘z: ellips + proporsional oq nur.
  Widget _openEye() {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: FarmColors.outline,
                borderRadius: cssPercentRadius(
                  width,
                  height,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
            ),
          ),
          Positioned(
            left: width * 2 / 11,
            top: height * 2 / 14,
            child: Container(
              width: width * 4 / 11,
              height: height * 4 / 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: cssPercentRadius(
                  width * 4 / 11,
                  height * 4 / 14,
                  tl: .5,
                  tr: .5,
                  br: .5,
                  bl: .5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Xafa ko‘z: biroz yig‘ilgan ellips + tepada −15° qoshcha.
  Widget _sadEye() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.scale(scaleY: .8, child: _openEye()),
        Positioned(
          left: -width * .05,
          top: -height * .25,
          child: Transform.rotate(
            angle: -15 * math.pi / 180,
            child: Container(
              width: width * 1.1,
              height: math.max(height * .15, 1.5),
              decoration: BoxDecoration(
                color: FarmColors.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Xursand ko‘z: qalin chetli doiraning yuqori yarmi — yoy shtrix,
/// uchlari yumaloq.
class _HappyEyePainter extends CustomPainter {
  const _HappyEyePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * .3;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    canvas.drawArc(
      rect,
      math.pi,
      math.pi,
      false,
      Paint()
        ..color = FarmColors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_HappyEyePainter old) => false;
}
