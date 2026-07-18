import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';

/// Buta to‘plami (DESIGN_SPEC "Sahna elementlari"):
/// chap — 86×86 #4CA82E doira + shadow-klon `40px 18px 0 -12px`;
/// o‘ng — 104×104 + shadow-klon `−46px 22px 0 -16px`.
class BushCluster extends StatelessWidget {
  const BushCluster.left({super.key})
      : size = 86,
        cloneDx = 40,
        cloneDy = 18,
        cloneSpread = -12;

  const BushCluster.right({super.key})
      : size = 104,
        cloneDx = -46,
        cloneDy = 22,
        cloneSpread = -16;

  final double size;
  final double cloneDx;
  final double cloneDy;
  final double cloneSpread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FarmColors.bushDark,
        shape: BoxShape.circle,
        boxShadow: [
          cloneShadow(cloneDx, cloneDy, cloneSpread, FarmColors.bushDark),
        ],
      ),
    );
  }
}
