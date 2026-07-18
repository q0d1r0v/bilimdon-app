import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

enum BubbleTail { bottomLeft, leftBottom }

/// Gap pufagi — prototip: oq/rangli fon, radius 12-14, 45° kvadrat dum.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble({
    super.key,
    required this.text,
    this.background = Colors.white,
    this.fontSize = 11.5,
    this.maxWidth,
    this.tail = BubbleTail.bottomLeft,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
  });

  final String text;
  final Color background;
  final double fontSize;
  final double? maxWidth;
  final BubbleTail tail;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final bubble = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: padding,
      constraints:
          maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(FarmRadius.bubble),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(40, 70, 20, .22),
            offset: Offset(0, 3),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: FarmColors.outline,
          height: 1.25,
        ),
      ),
    );

    // Dum: 10x10 kvadrat, rotate 45°, radius 2 (prototip).
    final tailWidget = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 10,
      height: 10,
      transform: Matrix4.rotationZ(45 * 3.1415926 / 180),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    switch (tail) {
      case BubbleTail.bottomLeft:
        // Dum pastda, chapdan 16px (xarita pufaklari).
        return Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            Positioned(left: 16, bottom: -5, child: tailWidget),
          ],
        );
      case BubbleTail.leftBottom:
        // Dum chap tomonda, pastdan 8px (o'yin ekranidagi sigir pufagi).
        return Stack(
          clipBehavior: Clip.none,
          children: [
            bubble,
            Positioned(left: -4, bottom: 8, child: tailWidget),
          ],
        );
    }
  }
}
