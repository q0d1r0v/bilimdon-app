import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/css_shapes.dart';
import 'hint_animator.dart';

/// Son chizig‘i ([VisualKind.numberLine]) — ketma-ketlik savollari uchun.
///
/// `2 —+2→ 4 —+2→ 6 —+2→ ?` ko‘rinishida: hadlar doira tugunlarda, ular
/// orasida qadam yorlig‘i va strelka. Oxirgi tugun — sariq «?».
///
/// Savol matni (`prompt_text.dart`) hadlarni allaqachon yozadi; chiziq ularni
/// takrorlaydi — bu ATAYLAB (dual coding). Qo‘shimcha qiymat strelkalardagi
/// qadamda: bola naqshni ko‘radi, sonlarni o‘qishi shart emas.
class NumberLineHint extends StatelessWidget {
  const NumberLineHint({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;
  final int pulseTick;

  static const _height = 50.0;
  static const _node = 34.0;

  /// Chiziq markazi: tugun (34) shu balandlikda vertikal markazlashadi.
  static const _lineCenterY = 33.0;

  @override
  Widget build(BuildContext context) {
    final terms = visual.terms ?? const [];
    final step = visual.step ?? 0;
    if (terms.isEmpty || step == 0) return const SizedBox.shrink();

    // U+2212 (haqiqiy minus) — `prompt_text.dart` bilan izchil.
    final label = step > 0 ? '+$step' : '−${-step}';
    // Elementlar: tugun, konnektor, tugun, ... , konnektor, «?» tugun.
    final itemCount = terms.length * 2 + 1;

    return HintFrame(
      child: HintAnimator(
        itemCount: itemCount,
        pulseCount: terms.length,
        pulseTick: pulseTick,
        builder: (context, item) {
          final children = <Widget>[];
          var index = 0;
          for (var i = 0; i < terms.length; i++) {
            children.add(item(index++, child: _node0('${terms[i]}')));
            children.add(
              Expanded(
                child: item(
                  index++,
                  pulseOrder: i,
                  child: _connector(label),
                ),
              ),
            );
          }
          children.add(item(index++, child: _node0('?', unknown: true)));
          // MainAxisSize.max (default) — chiziq karta kengligini to‘liq
          // egallashi kerak, konnektorlar `Expanded` bilan bo‘shliqni bo‘ladi.
          return SizedBox(height: _height, child: Row(children: children));
        },
      ),
    );
  }

  /// Had tuguni. [unknown] — izlanayotgan son (sariq, ajralib turadi).
  Widget _node0(String text, {bool unknown = false}) => Padding(
        // Tugun markazi chiziq markaziga tushishi uchun.
        padding: const EdgeInsets.only(top: _lineCenterY - _node / 2),
        child: Container(
          width: _node,
          height: _node,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: unknown ? FarmColors.yellow : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: unknown ? FarmColors.yellowDark : FarmColors.cardBorder,
              width: 3,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              // Sariqda oq matn kontrasti yetmaydi (1.61:1) — inkDark.
              color: FarmColors.inkDark,
            ),
          ),
        ),
      );

  /// Qadam yorlig‘i + chiziq + strelka uchi.
  Widget _connector(String label) => SizedBox(
        height: _height,
        child: Stack(
          children: [
            Positioned(
              top: 4,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: FarmColors.red,
                  ),
                ),
              ),
            ),
            Positioned(
              // Row balandligi 8 (strelka) → markazi _lineCenterY ga tushadi.
              top: _lineCenterY - 4,
              left: 2,
              right: 2,
              child: Row(
                children: [
                  Expanded(
                    child: Container(height: 3, color: FarmColors.cardBorder),
                  ),
                  const TriangleWidget(
                    width: 7,
                    height: 8,
                    color: FarmColors.cardBorder,
                    direction: TriangleDirection.right,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
