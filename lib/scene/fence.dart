import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Panjara ustuni kengligi (DESIGN_SPEC: repeating 7px ustun).
const double _postWidth = 7;

/// Ustunlar orasidagi bo‘shliq (DESIGN_SPEC: 35px oraliq).
const double _postGap = 35;

/// Panjara chizig‘i (DESIGN_SPEC "Sahna elementlari"): 2 gorizontal rels
/// (top:8 va top:24, h:5, radius 3, opacity .95) + takrorlanuvchi ustunlar
/// (7px ustun + 35px oraliq, butun balandlik). Xarita/o‘yin ranglari [game]
/// bilan tanlanadi.
class FenceStrip extends StatelessWidget {
  const FenceStrip({super.key, this.height = 40, this.game = false});

  final double height;
  final bool game;

  @override
  Widget build(BuildContext context) {
    final rail = (game ? FarmColors.fenceRailGame : FarmColors.fenceRail)
        .withValues(alpha: .95);
    final post = game ? FarmColors.fencePostGame : FarmColors.fencePost;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          for (final top in const [8.0, 24.0])
            Positioned(
              left: 0,
              right: 0,
              top: top,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: rail,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          Positioned.fill(
            child: ClipRect(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const unit = _postWidth + _postGap;
                  final count = constraints.maxWidth.isFinite
                      ? (constraints.maxWidth / unit).ceil() + 1
                      : 1;
                  return OverflowBox(
                    alignment: Alignment.centerLeft,
                    maxWidth: double.infinity,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < count; i++) ...[
                          if (i > 0) const SizedBox(width: _postGap),
                          Container(
                            width: _postWidth,
                            height: height,
                            color: post,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
