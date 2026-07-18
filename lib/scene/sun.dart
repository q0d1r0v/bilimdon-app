import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Quyosh (DESIGN_SPEC "Sahna elementlari"): 44×44 doira #FFD43C +
/// halo halqa `box-shadow: 0 0 0 12px rgba(255,212,60,.25)`.
///
/// Asosiy doira va halo AYNAN prototipdagidek qoladi. Qo'shimcha jonlilik:
/// orqasida asta aylanuvchi yumshoq nurlar + yengil «nafas oluvchi» yorug'lik.
/// Nurlar 44px qutidan chiqadi — ota Stack `clipBehavior: Clip.none` bo'lishi
/// kerak (xarita sahnasida shunday). Reduce-motion'da nurlar statik turadi.
class Sun extends StatefulWidget {
  const Sun({super.key, this.size = 44});

  final double size;

  @override
  State<Sun> createState() => _SunState();
}

class _SunState extends State<Sun> with TickerProviderStateMixin {
  late final AnimationController _spin;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 44),
    );
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3400),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _spin.stop();
      _pulse.stop();
    } else {
      if (!_spin.isAnimating) _spin.repeat();
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final rayBox = size * 2.6;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Aylanuvchi nurlar — doira markaziga markazlashadi, qutidan chiqadi.
          Positioned(
            left: (size - rayBox) / 2,
            top: (size - rayBox) / 2,
            width: rayBox,
            height: rayBox,
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_spin, _pulse]),
                builder: (context, _) => Transform.rotate(
                  angle: _spin.value * math.pi * 2,
                  child: CustomPaint(
                    painter: _SunRaysPainter(
                      0.6 + 0.4 * _pulse.value, // yengil «nafas»
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Asosiy doira + halo — prototipdan aynan (o'zgarmaydi).
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: FarmColors.coin,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: FarmColors.coin.withValues(alpha: .25),
                  spreadRadius: 12,
                  blurRadius: 0,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunRaysPainter extends CustomPainter {
  _SunRaysPainter(this.intensity);

  /// 0..1 — nurlar yorqinligi/uzunligi (nafas puls'i).
  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final inner = size.width * 0.24;
    final outer = size.width * (0.40 + 0.06 * intensity);
    final paint = Paint()
      ..color = FarmColors.coin.withValues(alpha: 0.22 * intensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round;
    const rays = 12;
    for (var i = 0; i < rays; i++) {
      final a = (_tau * i) / rays;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * inner, c + d * outer, paint);
    }
  }

  @override
  bool shouldRepaint(_SunRaysPainter old) => old.intensity != intensity;
}

const double _tau = math.pi * 2;
