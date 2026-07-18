import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// O'yin progress bar — oq track, yashil gradient, width transition .4s.
class GameProgressBar extends StatelessWidget {
  const GameProgressBar({super.key, required this.fraction});

  /// 0..1
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 60, 20, .15),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedFractionallySizedBox(
          duration: FarmAnim.progressFill,
          curve: Curves.easeOut,
          widthFactor: fraction.clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [FarmColors.green, FarmColors.greenLight],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }
}

/// Taymer bar — rgba(255,255,255,.6) track, olov gradient, scaleX 1->0 linear.
/// Paint-only transform (prototipdagi CSS scaleX semantikasi).
class TimerBar extends StatelessWidget {
  const TimerBar({super.key, required this.animation});

  /// 1.0 (to'liq) -> 0.0 (tugadi)
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Soat ikonkasi: 18x18 doira, 3px oq jant, mil.
        SizedBox(
          width: 18,
          height: 18,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
              ),
              Transform.translate(
                offset: const Offset(0, -2),
                child: Container(width: 2, height: 5, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .6),
              borderRadius: BorderRadius.circular(999),
            ),
            clipBehavior: Clip.antiAlias,
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, _) => Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.diagonal3Values(animation.value, 1, 1),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [FarmColors.chickBeak, FarmColors.coin],
                    ),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
