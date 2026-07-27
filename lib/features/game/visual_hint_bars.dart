import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import 'hint_animator.dart';

/// Taqqoslash ustunlari ([VisualKind.bars]) — «qaysi son eng katta/kichik?»
/// savollari uchun.
///
/// Ustun balandligi songa **proporsional** (matematik halol): 17 va 18 deyarli
/// teng ko‘rinadi, chunki ular haqiqatan yaqin. O‘rin bo‘yicha balandlik
/// (1-o‘rin eng baland, 2-o‘rin pastroq...) ATAYLAB rad etilgan — u bolaga
/// yolg‘on nisbat o‘rgatardi. Sonlar ustun ostida yozilgan — asosiy kanal shu.
///
/// Barcha ustunlar BIR XIL rangda va pulsatsiya KETMA-KET bo‘ladi: eng baland
/// ustunni urg‘ulash `biggest` savolida javobni oshkor qilar, `smallest` da
/// esa chalg‘itardi. Shu bilan vizual rejimga neytral qoladi.
class CompareBarsHint extends StatelessWidget {
  const CompareBarsHint({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;
  final int pulseTick;

  /// Eng baland ustun (eng katta son) shu balandlikni oladi.
  static const _barMax = 52.0;
  static const _gap = 14.0;
  static const _minBarW = 22.0;
  static const _maxBarW = 36.0;
  static const _labelGap = 6.0;

  /// Ustun kengligi — mavjud kenglikdan deterministik hisoblanadi.
  static double barWidth(double maxWidth, int count) {
    if (count <= 0) return _minBarW;
    final free = (maxWidth - 2) - _gap * (count - 1);
    return (free / count).clamp(_minBarW, _maxBarW);
  }

  /// Songa proporsional balandlik (0 ham ko‘rinishi uchun minimum 8).
  static double barHeight(int value, int maxValue) {
    if (maxValue <= 0) return 8;
    return (_barMax * value / maxValue).clamp(8.0, _barMax);
  }

  @override
  Widget build(BuildContext context) {
    final values = visual.values ?? const [];
    if (values.isEmpty) return const SizedBox.shrink();
    final maxValue = values.reduce((a, b) => a > b ? a : b);

    return HintFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : _cardFallbackWidth;
          final barW = barWidth(width, values.length);
          return HintAnimator(
            itemCount: values.length,
            pulseCount: values.length,
            pulseTick: pulseTick,
            // Balandlik KONTENT bilan belgilanadi (qattiq yozilmaydi):
            // yorliq qatori balandligi shriftga bog‘liq, shuning uchun
            // `Row` — Stack'ning pozitsiyalanmagan bolasi va o‘lchamni u beradi.
            builder: (context, item) => Stack(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < values.length; i++) ...[
                      if (i > 0) const SizedBox(width: _gap),
                      _column(item, i, values[i], barW, maxValue),
                    ],
                  ],
                ),
                // Asos chizig‘i — ustunlar shundan «o‘sadi». Tepadan
                // o‘lchanadi, shuning uchun yorliq balandligiga bog‘liq emas.
                Positioned(
                  top: _barMax,
                  left: 0,
                  right: 0,
                  child: Container(height: 3, color: FarmColors.cardBorder),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _column(
    HintItem item,
    int i,
    int value,
    double barW,
    int maxValue,
  ) {
    final h = barHeight(value, maxValue);
    return SizedBox(
      width: barW,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tepadan bo‘shliq — barcha ustunlar bir tekis asosdan boshlanadi.
          SizedBox(height: _barMax - h),
          item(
            i,
            pulseOrder: i,
            // Ustun asosdan o‘sadi, markazdan emas.
            alignment: Alignment.bottomCenter,
            child: Container(
              width: barW,
              height: h,
              decoration: const BoxDecoration(
                color: FarmColors.blue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ),
          ),
          const SizedBox(height: _labelGap),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkDark,
              // Aniq qator balandligi — umumiy balandlik shriftdan
              // qat'i nazar bir xil bo'lishi uchun.
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  /// `LayoutBuilder` cheklanmagan kenglik bergan holat uchun (320dp karta).
  static const _cardFallbackWidth = 250.0;
}
