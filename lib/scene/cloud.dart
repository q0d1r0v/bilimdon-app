import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/css_shapes.dart';

/// Bulut (DESIGN_SPEC "Sahna elementlari"):
/// katta — 38×16 oq stadium, opacity .95 + 2 shadow-klon
/// (`26px 6px 0 -4px #fff, -20px 8px 0 -6px #fff`);
/// kichik — 30×13, opacity .8, klonsiz.
class Cloud extends StatelessWidget {
  const Cloud.big({super.key})
      : width = 38,
        height = 16,
        opacity = .95,
        withClones = true;

  const Cloud.small({super.key})
      : width = 30,
        height = 13,
        opacity = .8,
        withClones = false;

  final double width;
  final double height;
  final double opacity;
  final bool withClones;

  @override
  Widget build(BuildContext context) {
    final white = Colors.white.withValues(alpha: opacity);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(FarmRadius.pill),
        boxShadow: withClones
            ? [
                cloneShadow(26, 6, -4, white),
                cloneShadow(-20, 8, -6, white),
              ]
            : null,
      ),
    );
  }
}
