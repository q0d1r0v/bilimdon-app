import 'package:flutter/material.dart';

/// Oq stat-pill (streak/tanga/yurak/savol hisoblagichi) — prototip stili.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    this.background = Colors.white,
    this.gap = 5,
  });

  final List<Widget> children;
  final EdgeInsets padding;
  final Color background;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 60, 20, .15),
            offset: Offset(0, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            children[i],
          ],
        ],
      ),
    );
  }
}
