import 'package:flutter/material.dart';

import '../core/utils/css_shapes.dart';

/// Tepalik (DESIGN_SPEC "Sahna elementlari"): to‘q rangli katta blok,
/// CSS `border-radius: 50% 50% 0 0` — faqat yuqori burchaklar elliptik
/// (`Radius.elliptical(w/2, h/2)`).
class Hill extends StatelessWidget {
  const Hill({
    super.key,
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: cssPercentRadius(
          width,
          height,
          tl: .5,
          tr: .5,
          br: 0,
          bl: 0,
        ),
      ),
    );
  }
}
