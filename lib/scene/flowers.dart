import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';

/// Bitta gul-kloni: asosiy nuqtadan [dx],[dy] siljigan, [color] rangli nusxa
/// (CSS `box-shadow: dx dy 0 color`).
typedef FlowerClone = ({double dx, double dy, Color color});

/// Gul to‘plami (DESIGN_SPEC "Sahna elementlari"): bitta [dotSize] doira
/// nuqta + box-shadow klonlar ro‘yxati. Tayyor to‘plamlar: [mapCluster1],
/// [mapCluster2], [gamePanelCluster].
class FlowerCluster extends StatelessWidget {
  const FlowerCluster({
    super.key,
    this.dotSize = 7,
    this.color = Colors.white,
    required this.clones,
  });

  /// Xarita to‘plami 1 (left:36, top:186): 7px oq nuqta +
  /// `52px 30px #FFD43C, 120px −6px #fff, 210px 40px #FFD43C, 300px 10px #fff`.
  static const mapCluster1 = FlowerCluster(
    clones: [
      (dx: 52, dy: 30, color: FarmColors.coin),
      (dx: 120, dy: -6, color: Colors.white),
      (dx: 210, dy: 40, color: FarmColors.coin),
      (dx: 300, dy: 10, color: Colors.white),
    ],
  );

  /// Xarita to‘plami 2 (left:70, top:330): 7px #FFD43C nuqta +
  /// `90px 46px #fff, 190px 20px #FFD43C, 250px 70px #fff`.
  static const mapCluster2 = FlowerCluster(
    color: FarmColors.coin,
    clones: [
      (dx: 90, dy: 46, color: Colors.white),
      (dx: 190, dy: 20, color: FarmColors.coin),
      (dx: 250, dy: 70, color: Colors.white),
    ],
  );

  /// O‘yin yer paneli to‘plami (left:150, top:18): 6px oq nuqta +
  /// `36px 12px #FFD43C, 80px 4px #fff, −16px 22px #FFD43C`.
  static const gamePanelCluster = FlowerCluster(
    dotSize: 6,
    clones: [
      (dx: 36, dy: 12, color: FarmColors.coin),
      (dx: 80, dy: 4, color: Colors.white),
      (dx: -16, dy: 22, color: FarmColors.coin),
    ],
  );

  final double dotSize;
  final Color color;
  final List<FlowerClone> clones;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: dotSize,
      height: dotSize,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          for (final c in clones) cloneShadow(c.dx, c.dy, 0, c.color),
        ],
      ),
    );
  }
}
