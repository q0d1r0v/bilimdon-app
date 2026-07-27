import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import 'hint_animator.dart';

/// O‘nlik ramka ([VisualKind.tenFrame]) — 12 dan katta qo‘shish/ayirish uchun.
///
/// Nega kerak: hayvonli vizuallar `count` 0..12 bilan cheklangan, katta
/// sonlarda hayvon qatori sig‘maydi. O‘nlik ramka esa 20 gacha sonni ikki
/// 2×5 blokda ko‘rsatadi — bola «bitta to‘liq o‘nlik + 4» deb o‘qiydi.
///
/// Katak holatlari:
/// * `groups[0]` tasi — qizil (birinchi qo‘shiluvchi yoki kamayuvchi);
/// * qolgan `groups[1]` tasi — ko‘k (ikkinchi qo‘shiluvchi);
/// * oxirgi [VisualHint.faded] tasi xira (.25) — ayirishda «olib tashlandi»;
/// * [VisualHint.target] berilsa, yig‘indidan keyingi kataklar sariq halqa
///   bilan («yana qancha kerak?» — yetishmayotgan operand savoli);
/// * qolganlari bo‘sh.
///
/// Rang yagona kanal EMAS: bloklar tutash joylashadi va 5-katakli ramka
/// chegarasi bilan ajraladi, ya‘ni pozitsiya ham ma‘no beradi.
class TenFrameHint extends StatelessWidget {
  const TenFrameHint({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;
  final int pulseTick;

  static const _perRow = 5;
  static const _rows = 2;
  static const _cellGap = 3.0;
  static const _framePad = 3.0;
  static const _frameBorder = 2.0;
  static const _frameGap = 10.0;
  static const _minCell = 14.0;
  static const _maxCell = 26.0;
  static const _cardFallbackWidth = 250.0;

  /// Ramka atrofidagi «bezak» kengligi: padding + jant (ikki tomondan).
  static const _chrome = (_framePad + _frameBorder) * 2;

  /// Katak diametri — mavjud kenglikdan deterministik hisoblanadi.
  static double cellSize(double maxWidth, int frames) {
    if (frames <= 0) return _minCell;
    final innerGaps = _cellGap * (_perRow - 1);
    final free = (maxWidth - 2) -
        _frameGap * (frames - 1) -
        frames * (_chrome + innerGaps);
    return (free / (frames * _perRow)).clamp(_minCell, _maxCell);
  }

  /// Bitta ramka sig'imi (2×5 = 10).
  static const _perFrame = _perRow * _rows;

  /// Nechta ramka kerak: 10 dan oshsa ikkita.
  static int framesFor(int needed) => needed > _perFrame ? 2 : 1;

  @override
  Widget build(BuildContext context) {
    final groups = visual.groups ?? const [];
    if (groups.isEmpty) return const SizedBox.shrink();
    final sum = groups.reduce((a, b) => a + b);
    final first = groups[0];
    final faded = visual.faded ?? 0;
    final target = visual.target;
    final needed = math.max(sum, target ?? sum);
    final frames = framesFor(needed);
    final filled = sum;
    final pulsing = math.max(0, sum - faded);

    return HintFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _cardFallbackWidth;
          final cell = cellSize(width, frames);
          return HintAnimator(
            itemCount: filled,
            pulseCount: pulsing,
            pulseTick: pulseTick,
            builder: (context, item) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var f = 0; f < frames; f++) ...[
                  if (f > 0) const SizedBox(width: _frameGap),
                  _frame(item, f, cell, first, sum, faded, target),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _frame(
    HintItem item,
    int frameIndex,
    double cell,
    int first,
    int sum,
    int faded,
    int? target,
  ) =>
      Container(
        padding: const EdgeInsets.all(_framePad),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: FarmColors.lockedDark,
            width: _frameBorder,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var r = 0; r < _rows; r++) ...[
              if (r > 0) const SizedBox(height: _cellGap),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var c = 0; c < _perRow; c++) ...[
                    if (c > 0) const SizedBox(width: _cellGap),
                    _cellAt(
                      item,
                      frameIndex * _perFrame + r * _perRow + c,
                      cell,
                      first,
                      sum,
                      faded,
                      target,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      );

  /// [index] — global to‘ldirish tartibi (ramka → qator → katak).
  Widget _cellAt(
    HintItem item,
    int index,
    double cell,
    int first,
    int sum,
    int faded,
    int? target,
  ) {
    if (index < sum) {
      final isFaded = faded > 0 && index >= sum - faded;
      final dot = _dot(
        cell,
        fill: index < first ? FarmColors.red : FarmColors.blue,
        faded: isFaded,
      );
      // Pop tartibi to'ldirish tartibi bilan bir xil; xira kataklar
      // pulsatsiya qilmaydi (ular «olib tashlangan»).
      return item(
        index,
        pulseOrder: isFaded ? null : index,
        child: dot,
      );
    }
    if (target != null && index < target) {
      // «Yana qancha kerak» — sariq halqa, ichi bo'sh.
      return _dot(cell, ring: FarmColors.yellow, ringWidth: 2.5);
    }
    return _dot(cell, ring: FarmColors.cardBorder, ringWidth: 2);
  }

  Widget _dot(
    double size, {
    Color? fill,
    Color? ring,
    double ringWidth = 2,
    bool faded = false,
  }) {
    final Widget dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: fill ?? Colors.white,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring, width: ringWidth),
      ),
    );
    return faded ? Opacity(opacity: .25, child: dot) : dot;
  }
}
