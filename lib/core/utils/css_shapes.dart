import 'package:flutter/material.dart';

/// CSS border-radius foizlarini Flutter elliptik radiuslariga o'giradi:
/// CSS `border-radius: a% b% c% d%` (TL TR BR BL) == Radius.elliptical(w*p, h*p).
BorderRadius cssPercentRadius(
  double w,
  double h, {
  required double tl,
  required double tr,
  required double br,
  required double bl,
}) {
  return BorderRadius.only(
    topLeft: Radius.elliptical(w * tl, h * tl),
    topRight: Radius.elliptical(w * tr, h * tr),
    bottomRight: Radius.elliptical(w * br, h * br),
    bottomLeft: Radius.elliptical(w * bl, h * bl),
  );
}

enum TriangleDirection { up, down, left, right }

/// CSS border-uchburchak ekvivalenti (masalan: tumshuq, pufak dumi, tom).
/// [width]/[height] — uchburchakning to'liq o'lchami.
class TriangleWidget extends StatelessWidget {
  const TriangleWidget({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.direction = TriangleDirection.down,
  });

  final double width;
  final double height;
  final Color color;
  final TriangleDirection direction;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _TrianglePainter(color: color, direction: direction),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color, required this.direction});

  final Color color;
  final TriangleDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path();
    switch (direction) {
      case TriangleDirection.down:
        path
          ..moveTo(0, 0)
          ..lineTo(w, 0)
          ..lineTo(w / 2, h);
      case TriangleDirection.up:
        path
          ..moveTo(w / 2, 0)
          ..lineTo(w, h)
          ..lineTo(0, h);
      case TriangleDirection.left:
        path
          ..moveTo(w, 0)
          ..lineTo(w, h)
          ..lineTo(0, h / 2);
      case TriangleDirection.right:
        path
          ..moveTo(0, 0)
          ..lineTo(w, h / 2)
          ..lineTo(0, h);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) =>
      old.color != color || old.direction != direction;
}

/// CSS `box-shadow: dx dy 0 spread color` klon-texnikasi uchun qulay yordamchi —
/// blursiz, faqat offset+spread (butalar, gullar, bulut bo'laklari).
BoxShadow cloneShadow(double dx, double dy, double spread, Color color) =>
    BoxShadow(
      color: color,
      offset: Offset(dx, dy),
      blurRadius: 0,
      spreadRadius: spread,
    );
