import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Bitta elementni pop-in va pulsatsiya transformiga o‘raydi.
///
/// [i] — pop tartibi (0 dan; stagger shu bo‘yicha hisoblanadi).
/// [pulseOrder] — pulsatsiya navbati; `null` bo‘lsa element pulslamaydi.
/// [alignment] — `Transform.scale` tayanch nuqtasi (ustunlar uchun
/// `Alignment.bottomCenter` — ular asosdan o‘sadi, markazdan emas).
typedef HintItem = Widget Function(
  int i, {
  int? pulseOrder,
  Alignment alignment,
  required Widget child,
});

/// Barcha vizual ko‘rsatmalar uchun umumiy ramka (DESIGN_SPEC «Ekran 2»):
/// min balandlik 44, markazda.
class HintFrame extends StatelessWidget {
  const HintFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(child: child),
      );
}

/// Vizual ko‘rsatma animatsiyalari (DESIGN_SPEC «Ekran 2» taymingi).
///
/// Yangi savolda har element 60ms stagger bilan «pop-in» qiladi
/// (scale .6→1, easeOutBack) — sanashga pedagogik kirish. [pulseTick]
/// o‘zgarganda (2-urinish hinti) elementlar ketma-ket 250ms oraliqda
/// pulsatsiya qiladi — «kel, birga sanaymiz» effekti.
///
/// Element soni 13 dan oshsa stagger qisqaradi (aks holda 20 katakli o‘nlik
/// ramka juda sekin to‘lardi). 13 va undan kichik holatlarda — ya‘ni hayvon
/// qatorining barcha mumkin holatlarida (max 12 hayvon + «+») — tayming
/// AYNAN saqlanadi.
class HintAnimator extends StatefulWidget {
  const HintAnimator({
    super.key,
    required this.itemCount,
    required this.pulseCount,
    required this.pulseTick,
    required this.builder,
  });

  /// Pop tartibidagi elementlar soni (stagger davomiyligini belgilaydi).
  final int itemCount;

  /// Pulsatsiya qiladigan elementlar soni (0 — pulsatsiya yo‘q).
  final int pulseCount;

  /// Har oshirilganda «birga sanaymiz» pulsi qayta ishga tushadi.
  final int pulseTick;

  final Widget Function(BuildContext context, HintItem item) builder;

  @override
  State<HintAnimator> createState() => _HintAnimatorState();
}

class _HintAnimatorState extends State<HintAnimator>
    with TickerProviderStateMixin {
  static const _staggerMs = 60;
  static const _popMs = 180;
  static const _pulseStepMs = 250;

  /// 13 tagacha — prototip taymingi (60ms). Undan keyin butun pop ~780ms
  /// ichida sig‘adigan qilib siqiladi, lekin 20ms dan pastga tushmaydi.
  static int _staggerFor(int n) =>
      n <= 13 ? _staggerMs : math.max(20, (780 / (n - 1)).round());

  late final AnimationController _popCtrl;
  late final AnimationController _pulseCtrl;
  late final int _stagger = _staggerFor(widget.itemCount);

  @override
  void initState() {
    super.initState();
    final n = widget.itemCount;
    _popCtrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: math.max(1, _stagger * (n - 1) + _popMs),
      ),
    )..forward();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: math.max(1, _pulseStepMs * widget.pulseCount),
      ),
    );
  }

  @override
  void didUpdateWidget(HintAnimator old) {
    super.didUpdateWidget(old);
    if (widget.pulseTick != old.pulseTick && widget.pulseCount > 0) {
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  /// Pop-in shkalasi: i-element [i*stagger, i*stagger+180ms] oralig‘ida
  /// .6→1 (easeOutBack).
  double _popScale(int i) {
    final totalMs = _popCtrl.duration!.inMilliseconds;
    final start = _stagger * i / totalMs;
    final end = (_stagger * i + _popMs) / totalMs;
    final t = ((_popCtrl.value - start) / (end - start)).clamp(0.0, 1.0);
    return 0.6 + 0.4 * Curves.easeOutBack.transform(t);
  }

  /// Pulsatsiya shkalasi: j-element o‘z 250ms oynasida 1→1.15→1.
  double _pulseScale(int order) {
    if (!_pulseCtrl.isAnimating && _pulseCtrl.value == 0) return 1;
    final count = widget.pulseCount;
    if (count == 0) return 1;
    final start = order / count;
    final end = (order + 1) / count;
    final t = ((_pulseCtrl.value - start) / (end - start)).clamp(0.0, 1.0);
    return 1 + 0.15 * math.sin(math.pi * t);
  }

  @override
  Widget build(BuildContext context) {
    // `child:` ATAYLAB beriladi — Transform paint-only, shuning uchun bola
    // vidjetlar har kadr qayta qurilmaydi (zich vizuallarda muhim).
    Widget item(
      int i, {
      int? pulseOrder,
      Alignment alignment = Alignment.center,
      required Widget child,
    }) {
      return AnimatedBuilder(
        // Key testlar elementni deterministik topishi uchun (vizual
        // ichida ham `Transform` bo‘lishi mumkin — masalan `cssBox` burchagi).
        key: ValueKey('hint-item-$i'),
        animation: Listenable.merge([_popCtrl, _pulseCtrl]),
        builder: (context, inner) => Transform.scale(
          scale: _popScale(i) * (pulseOrder == null ? 1 : _pulseScale(pulseOrder)),
          alignment: alignment,
          child: inner,
        ),
        child: child,
      );
    }

    return widget.builder(context, item);
  }
}
