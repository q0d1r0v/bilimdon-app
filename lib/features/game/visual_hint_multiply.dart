import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import 'hint_animator.dart';

/// Guruhlar ([VisualKind.groupRows]) — ko‘paytirish savollari uchun.
///
/// `3 × 2` → uchta guruh, har birida ikkita jo‘ja. Bu takroriy qo‘shishdan
/// ko‘paytirishga ko‘prik: bola guruhlarni sanaydi, keyin belgini o‘qiydi.
///
/// **`Wrap` ATAYLAB ishlatilmaydi**: u guruhni ikki qatorga bo‘lib yuborishi
/// mumkin va ko‘paytirish ma‘nosi buzilardi. Har guruh — o‘z `Row`i, ular
/// `Column` ichida; guruh yaxlitligi konstruksiya bo‘yicha kafolatlangan.
class GroupRowsHint extends StatelessWidget {
  const GroupRowsHint({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;
  final int pulseTick;

  static const _rowGap = 6.0;
  static const _boxPadH = 6.0;
  static const _boxPadV = 3.0;

  /// Jo‘jalar orasidagi bo‘shliq. 4 dan kichik BO‘LMASIN — `ChickWidget`
  /// tuki `Clip.none` bilan quti tashqarisiga chiqadi va ustma-ust tushadi.
  static const _chickGap = 4.0;

  static const _minChick = 18.0;
  static const _maxChick = 34.0;
  static const _heightBudget = 96.0;
  static const _cardFallbackWidth = 250.0;

  /// Jo‘ja balandligi/kengligi nisbati (`FarmAnimal.chick` — 40×44).
  static final double _aspect = FarmAnimal.chick.aspect;

  /// Jo‘ja kengligi — kenglik VA balandlik budjetidan deterministik.
  static double chickSize(double maxWidth, int rows, int cols) {
    if (rows <= 0 || cols <= 0) return _minChick;
    final wLimit =
        ((maxWidth - 2) - _boxPadH * 2 - _chickGap * (cols - 1)) / cols;
    final hLimit =
        ((_heightBudget - _rowGap * (rows - 1) - rows * _boxPadV * 2) / rows) /
            _aspect;
    return math.min(wLimit, hLimit).clamp(_minChick, _maxChick);
  }

  @override
  Widget build(BuildContext context) {
    final groups = visual.groups ?? const [];
    if (groups.isEmpty) return const SizedBox.shrink();
    final animal = visual.animal;
    if (animal == null) return const SizedBox.shrink();
    final cols = groups.reduce(math.max);
    final total = groups.reduce((a, b) => a + b);

    return HintFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _cardFallbackWidth;
          final size = chickSize(width, groups.length, cols);
          return HintAnimator(
            itemCount: total,
            pulseCount: total,
            pulseTick: pulseTick,
            builder: (context, item) {
              var index = 0;
              final rows = <Widget>[];
              for (var g = 0; g < groups.length; g++) {
                if (g > 0) rows.add(const SizedBox(height: _rowGap));
                final chicks = <Widget>[];
                for (var i = 0; i < groups[g]; i++) {
                  if (i > 0) chicks.add(const SizedBox(width: _chickGap));
                  chicks.add(
                    item(
                      index,
                      pulseOrder: index,
                      child: buildAnimal(_farmAnimal(animal), size: size),
                    ),
                  );
                  index++;
                }
                rows.add(
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: _boxPadH,
                      vertical: _boxPadV,
                    ),
                    decoration: BoxDecoration(
                      // Savol tegi bilan bir xil yumshoq yashil — bir dizayn tili.
                      color: FarmColors.tagGreenBg,
                      borderRadius: BorderRadius.circular(FarmRadius.bubble),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: chicks),
                  ),
                );
              }
              return Column(mainAxisSize: MainAxisSize.min, children: rows);
            },
          );
        },
      ),
    );
  }

  static FarmAnimal _farmAnimal(HintAnimal a) => switch (a) {
        HintAnimal.chick => FarmAnimal.chick,
        HintAnimal.pig => FarmAnimal.pig,
        HintAnimal.sheep => FarmAnimal.sheep,
      };
}
