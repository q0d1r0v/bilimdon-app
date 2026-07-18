import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';

/// Molxona ikonkasi (DESIGN_SPEC "Bob banneri"): baza 40×36.
/// Tom — 42×15 uchburchak (tepaga, #E3B778) yuqori-markazda;
/// devor — 34×20 #FFF6DE, pastki radius 5, left:3, top:14;
/// eshik — 12×13 #C22F2C, yuqori radius 6, markazda bottom:2.
class BarnIcon extends StatelessWidget {
  const BarnIcon({super.key, this.width = 40, this.height = 36});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final sx = width / 40;
    final sy = height / 36;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 3 * sx,
            top: 14 * sy,
            child: Container(
              width: 34 * sx,
              height: 20 * sy,
              decoration: BoxDecoration(
                color: FarmColors.barnWall,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(5 * sx),
                ),
              ),
            ),
          ),
          Positioned(
            left: (width - 42 * sx) / 2,
            top: 0,
            child: TriangleWidget(
              width: 42 * sx,
              height: 15 * sy,
              color: FarmColors.barnRoof,
              direction: TriangleDirection.up,
            ),
          ),
          Positioned(
            left: (width - 12 * sx) / 2,
            bottom: 2 * sy,
            child: Container(
              width: 12 * sx,
              height: 13 * sy,
              decoration: BoxDecoration(
                color: FarmColors.barnDoor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(6 * sx),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
