import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Fredoka'da ★/♥/♡/alanga glifi YO'Q — barchasi widget sifatida chiziladi.

/// Tanga: #FFD43C doira, 3px #E3A81E jant (prototip).
class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 14});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FarmColors.coin,
        shape: BoxShape.circle,
        border: Border.all(color: FarmColors.coinBorder, width: size * 3 / 14),
      ),
    );
  }
}

/// Streak alanga: tomchi shakl rotate -45 (#FF8A3D), ichida #FFD43C (prototip).
class StreakFlameIcon extends StatelessWidget {
  const StreakFlameIcon({super.key, this.size = 13});

  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = Radius.circular(size);
    return SizedBox(
      width: size,
      height: size,
      child: Transform.rotate(
        angle: -45 * math.pi / 180,
        child: Container(
          decoration: BoxDecoration(
            color: FarmColors.streakOrange,
            borderRadius: BorderRadius.only(
              topLeft: radius,
              topRight: radius,
              bottomRight: radius,
            ),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: size * 4 / 13,
              top: size * 4 / 13,
              right: size * 2 / 13,
              bottom: size * 2 / 13,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: FarmColors.coin,
                borderRadius: BorderRadius.only(
                  topLeft: radius,
                  topRight: radius,
                  bottomRight: radius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yurak — chizilgan (matn ♥ emas).
class HeartIcon extends StatelessWidget {
  const HeartIcon({
    super.key,
    this.size = 14,
    this.filled = true,
    this.color = FarmColors.red,
  });

  final double size;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _HeartPainter(color: color, filled: filled),
    );
  }
}

class _HeartPainter extends CustomPainter {
  const _HeartPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w / 2, h * 0.32)
      ..cubicTo(w * 0.42, h * 0.02, 0, h * 0.06, 0, h * 0.36)
      ..cubicTo(0, h * 0.62, w * 0.24, h * 0.78, w / 2, h)
      ..cubicTo(w * 0.76, h * 0.78, w, h * 0.62, w, h * 0.36)
      ..cubicTo(w, h * 0.06, w * 0.58, h * 0.02, w / 2, h * 0.32)
      ..close();
    final paint = Paint()..color = color;
    if (filled) {
      paint.style = PaintingStyle.fill;
    } else {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.1;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_HeartPainter old) =>
      old.color != color || old.filled != filled;
}

/// Besh qirrali yulduz — chizilgan (matn ★ emas).
class StarIcon extends StatelessWidget {
  const StarIcon({
    super.key,
    this.size = 12,
    this.filled = true,
    this.color = FarmColors.starGold,
  });

  final double size;
  final bool filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _StarPainter(color: color, filled: filled),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, size.height / 2);
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final outer = -math.pi / 2 + i * 2 * math.pi / 5;
      final inner = outer + math.pi / 5;
      final po = c + Offset(math.cos(outer), math.sin(outer)) * r;
      final pi_ = c + Offset(math.cos(inner), math.sin(inner)) * (r * 0.45);
      if (i == 0) {
        path.moveTo(po.dx, po.dy);
      } else {
        path.lineTo(po.dx, po.dy);
      }
      path.lineTo(pi_.dx, pi_.dy);
    }
    path.close();
    final paint = Paint()..color = filled ? color : color.withValues(alpha: .35);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.filled != filled;
}

/// ★★☆ pill — tugun ostidagi reyting (prototip: oq pill, 10px, #FFB020).
class StarRatingPill extends StatelessWidget {
  const StarRatingPill({super.key, required this.stars, this.starSize = 10});

  final int stars;
  final double starSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(40, 70, 20, .2),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 1),
              child: StarIcon(size: starSize, filled: i < stars),
            ),
        ],
      ),
    );
  }
}
