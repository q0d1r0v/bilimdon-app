import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Qulf ikonkasi (DESIGN_SPEC "Tugunlar", qulflangan): #B3A67E —
/// yoy (shackle) 12×9, chiziq 3px, yuqori radius 6, pastki chiziqsiz
/// (CustomPaint yoy bilan) + tana 18×13, radius 3.
class LockIcon extends StatelessWidget {
  const LockIcon({super.key, this.color = FarmColors.lockIcon});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: const Size(12, 9),
          painter: _ShacklePainter(color: color),
        ),
        Container(
          width: 18,
          height: 13,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ],
    );
  }
}

/// Yoy: 3px chiziq, yuqori tashqi radius 6 — chiziq markazi bo‘ylab
/// radius 4.5 yoy chiziladi, pastki tomoni ochiq.
class _ShacklePainter extends CustomPainter {
  const _ShacklePainter({required this.color});

  final Color color;

  static const double _stroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final half = _stroke / 2;
    final r = size.width / 2 - half; // 4.5 — chiziq markazidagi radius
    final path = Path()
      ..moveTo(half, size.height)
      ..lineTo(half, half + r)
      ..arcToPoint(
        Offset(size.width - half, half + r),
        radius: Radius.circular(r),
        clockwise: true,
      )
      ..lineTo(size.width - half, size.height);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke,
    );
  }

  @override
  bool shouldRepaint(_ShacklePainter old) => old.color != color;
}
