import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../content/models.dart';
import '../../core/theme/tokens.dart';

/// Hint-qatordagi bitta element: hayvon yoki «+» belgisi.
class _HintEntry {
  const _HintEntry.animal(this.animal, {this.faded = false}) : isPlus = false;

  const _HintEntry.plus()
      : animal = null,
        faded = false,
        isPlus = true;

  final FarmAnimal? animal;
  final bool faded;
  final bool isPlus;
}

/// Savol kartasidagi vizual ko‘rsatma qatori (DESIGN_SPEC «Ekran 2»):
/// wrap, gap 8, min balandlik 44, markazda. Yangi savolda har hayvon
/// 60ms stagger bilan «pop-in» (scale .6→1, easeOutBack) — sanashga
/// pedagogik kirish. [pulseTick] o‘zgarganda (2-urinish hinti) xira
/// bo‘lmagan hayvonlar ketma-ket 250ms oraliqda pulsatsiya qiladi —
/// «kel, birga sanaymiz» effekti.
class VisualHintRow extends StatefulWidget {
  const VisualHintRow({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;

  /// Har oshirilganda «birga sanaymiz» pulsi qayta ishga tushadi.
  final int pulseTick;

  @override
  State<VisualHintRow> createState() => _VisualHintRowState();
}

class _VisualHintRowState extends State<VisualHintRow>
    with TickerProviderStateMixin {
  static const _staggerMs = 60;
  static const _popMs = 180;
  static const _pulseStepMs = 250;

  late final List<_HintEntry> _entries = _buildEntries(widget.visual);
  late final AnimationController _popCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    final n = _entries.length;
    _popCtrl = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: math.max(1, _staggerMs * (n - 1) + _popMs),
      ),
    )..forward();
    final solid = _solidCount;
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: math.max(1, _pulseStepMs * solid)),
    );
  }

  @override
  void didUpdateWidget(VisualHintRow old) {
    super.didUpdateWidget(old);
    if (widget.pulseTick != old.pulseTick && _solidCount > 0) {
      _pulseCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  int get _solidCount =>
      _entries.where((e) => !e.isPlus && !e.faded).length;

  static FarmAnimal _toFarmAnimal(HintAnimal a) => switch (a) {
        HintAnimal.chick => FarmAnimal.chick,
        HintAnimal.pig => FarmAnimal.pig,
        HintAnimal.sheep => FarmAnimal.sheep,
      };

  /// Prototip o‘lchamlari: jo‘ja 40, cho‘chqa 45 (scale .5), qo‘y 46.
  static double _hintSize(FarmAnimal a) => switch (a) {
        FarmAnimal.chick => 40,
        FarmAnimal.pig => 45,
        FarmAnimal.sheep => 46,
        _ => 44,
      };

  static List<_HintEntry> _buildEntries(VisualHint v) {
    final animal = v.animal == null ? null : _toFarmAnimal(v.animal!);
    if (animal == null) return const [];
    switch (v.kind) {
      case VisualKind.count:
        return [
          for (var i = 0; i < (v.count ?? 0); i++) _HintEntry.animal(animal),
        ];
      case VisualKind.grouped:
        final groups = v.groups ?? const [];
        if (groups.length < 2) return const [];
        return [
          for (var i = 0; i < groups[0]; i++) _HintEntry.animal(animal),
          const _HintEntry.plus(),
          for (var i = 0; i < groups[1]; i++) _HintEntry.animal(animal),
        ];
      case VisualKind.faded:
        final count = v.count ?? 0;
        final faded = v.faded ?? 0;
        return [
          for (var i = 0; i < count; i++)
            _HintEntry.animal(animal, faded: i >= count - faded),
        ];
      case VisualKind.none:
        return const [];
    }
  }

  /// Pop-in shkalasi: i-element [i*60ms, i*60ms+180ms] oralig‘ida
  /// .6→1 (easeOutBack).
  double _popScale(int i) {
    final totalMs = _popCtrl.duration!.inMilliseconds;
    final start = _staggerMs * i / totalMs;
    final end = (_staggerMs * i + _popMs) / totalMs;
    final t = ((_popCtrl.value - start) / (end - start)).clamp(0.0, 1.0);
    return 0.6 + 0.4 * Curves.easeOutBack.transform(t);
  }

  /// Pulsatsiya shkalasi: j-«solid» hayvon o‘z 250ms oynasida 1→1.15→1.
  double _pulseScale(int solidOrder) {
    if (!_pulseCtrl.isAnimating && _pulseCtrl.value == 0) return 1;
    final solid = _solidCount;
    if (solid == 0) return 1;
    final start = solidOrder / solid;
    final end = (solidOrder + 1) / solid;
    final t = ((_pulseCtrl.value - start) / (end - start)).clamp(0.0, 1.0);
    return 1 + 0.15 * math.sin(math.pi * t);
  }

  @override
  Widget build(BuildContext context) {
    if (_entries.isEmpty) return const SizedBox.shrink();
    final children = <Widget>[];
    var solidOrder = 0;
    for (var i = 0; i < _entries.length; i++) {
      final e = _entries[i];
      final Widget content;
      if (e.isPlus) {
        content = const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: FarmColors.red,
            ),
          ),
        );
      } else {
        content = buildAnimal(
          e.animal!,
          size: _hintSize(e.animal!),
          faded: e.faded,
        );
      }
      final order = (!e.isPlus && !e.faded) ? solidOrder++ : -1;
      children.add(
        AnimatedBuilder(
          animation: Listenable.merge([_popCtrl, _pulseCtrl]),
          builder: (context, child) => Transform.scale(
            scale: _popScale(i) * (order >= 0 ? _pulseScale(order) : 1),
            child: child,
          ),
          child: content,
        ),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Center(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: children,
        ),
      ),
    );
  }
}
