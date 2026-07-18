import 'package:flutter/material.dart';

import '../theme/tokens.dart';

/// Xaritadagi nuqtali yo'l — prototipdagi SVG path'ning aynan ko'chirmasi:
/// viewBox 0 0 390 500, stroke-dasharray "1 15" + round cap == har 16px'da nuqta.
class DottedPathPainter extends CustomPainter {
  const DottedPathPainter({this.color = FarmColors.pathDot});

  final Color color;

  /// Ambient shimmer (DottedPathGlow) shu yo'lni ustma-ust ishlatishi uchun
  /// ochiq kirish — yagona manba, ikki chizuvchi bir xil egri chiziqni oladi.
  static Path pathFor(Size size) => _buildPath(size);

  static Path _buildPath(Size size) {
    final sx = size.width / 390;
    final sy = size.height / 500;
    final p = Path()..moveTo(71 * sx, 441 * sy);
    p.cubicTo(130 * sx, 440 * sy, 190 * sx, 420 * sy, 191 * sx, 381 * sy);
    p.cubicTo(192 * sx, 340 * sy, 110 * sx, 330 * sy, 98 * sx, 288 * sy);
    p.cubicTo(88 * sx, 250 * sy, 200 * sx, 250 * sy, 241 * sx, 211 * sy);
    p.cubicTo(280 * sx, 175 * sy, 140 * sx, 160 * sy, 121 * sx, 120 * sy);
    p.cubicTo(105 * sx, 85 * sy, 220 * sx, 80 * sy, 261 * sx, 40 * sy);
    return p;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = _buildPath(size);
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 16) {
        final pos = metric.getTangentForOffset(d)?.position;
        if (pos != null) canvas.drawCircle(pos, 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(DottedPathPainter old) => old.color != color;
}
