import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../characters/animal.dart';

/// «Tirik» personaj: nafas olish (scale 1<->1.02) + tasodifiy pirpirash
/// (2-6s) + ixtiyoriy sakrash triggeri. Qo'shimcha (additiv) harakat —
/// personaj geometriyasi o'zgarmaydi, dizayn buzilmaydi.
///
/// Har nusxa tasodifiy fazada nafas oladi — hech qachon sinxron emas.
class LivingAnimal extends StatefulWidget {
  const LivingAnimal({
    super.key,
    required this.kind,
    this.size = 60,
    this.expression = AnimalExpression.idle,
    this.accessory = AnimalAccessory.none,
    this.mirrored = false,
    this.jumpTrigger,
  });

  final FarmAnimal kind;
  final double size;

  /// Tashqi ifoda (happy/sad) pirpirashdan ustun turadi.
  final AnimalExpression expression;
  final AnimalAccessory accessory;
  final bool mirrored;

  /// Qiymati o'zgarganda personaj bir marta quvnoq sakraydi
  /// (squash-stretch). Masalan: to'g'ri javoblar soni.
  final Object? jumpTrigger;

  @override
  State<LivingAnimal> createState() => _LivingAnimalState();
}

class _LivingAnimalState extends State<LivingAnimal>
    with TickerProviderStateMixin {
  static final _rng = math.Random();

  late final AnimationController _breath;
  late final AnimationController _jump;
  Timer? _blinkTimer;
  bool _blinking = false;
  int _blinksLeft = 0;

  /// Har tur o'ziga xos tezlikda nafas oladi (kichiklar tezroq).
  static const _breathMs = {
    FarmAnimal.cow: 2600,
    FarmAnimal.pig: 2200,
    FarmAnimal.sheep: 2000,
    FarmAnimal.chicken: 1800,
    FarmAnimal.chick: 1400,
    FarmAnimal.duck: 1900,
    FarmAnimal.rabbit: 1600,
  };

  @override
  void initState() {
    super.initState();
    _breath = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _breathMs[widget.kind]!),
      // Tasodifiy faza — hamma bir xil nafas olmasin.
      value: _rng.nextDouble(),
    );
    _jump = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 630),
    );
    _scheduleBlink();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _breath.stop();
    } else if (!_breath.isAnimating) {
      _breath.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LivingAnimal old) {
    super.didUpdateWidget(old);
    if (old.jumpTrigger != widget.jumpTrigger && widget.jumpTrigger != null) {
      _jump.forward(from: 0);
    }
  }

  void _scheduleBlink() {
    _blinkTimer = Timer(
      Duration(milliseconds: 2000 + _rng.nextInt(4000)),
      () {
        // 15% hollarda qo'sh pirpirash.
        _blinksLeft = _rng.nextDouble() < .15 ? 2 : 1;
        _doBlink();
      },
    );
  }

  /// Ko'zni bir marta yumib-ochadi va keyingisini rejalashtiradi. Barcha
  /// kechikishlar YAGONA bekor qilinadigan `_blinkTimer` orqali — `Future.delayed`
  /// EMAS. Aks holda dispose paytida uchib ketgan kechikish bekor qilinmay,
  /// tasodifiy «pending timer» (test flake) qoldirar edi.
  void _doBlink() {
    if (!mounted) return;
    setState(() => _blinking = true);
    _blinkTimer = Timer(const Duration(milliseconds: 160), () {
      if (!mounted) return;
      setState(() => _blinking = false);
      _blinksLeft--;
      if (_blinksLeft > 0) {
        _blinkTimer = Timer(const Duration(milliseconds: 250), _doBlink);
      } else {
        _scheduleBlink();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _breath.dispose();
    _jump.dispose();
    super.dispose();
  }

  /// Squash-stretch sakrash egri chizig'i: cho'kish -> uchish -> qo'nish.
  static double _jumpDy(double t) {
    if (t < .15) return 0; // anticipation cho'kish (scale bilan)
    if (t < .55) {
      final p = (t - .15) / .4;
      return -18 * math.sin(p * math.pi / 2);
    }
    if (t < .8) {
      final p = (t - .55) / .25;
      return -18 * math.cos(p * math.pi / 2);
    }
    return 0;
  }

  static (double, double) _jumpScale(double t) {
    if (t < .15) return (1 + .06 * (t / .15), 1 - .12 * (t / .15));
    if (t < .55) return (.95, 1.08);
    if (t < .8) return (1, 1);
    if (t < .9) {
      final p = (t - .8) / .1;
      return (1 + .08 * p, 1 - .1 * p);
    }
    final p = (t - .9) / .1;
    return (1.08 - .08 * p, .9 + .1 * p);
  }

  @override
  Widget build(BuildContext context) {
    final expression = _blinking && widget.expression == AnimalExpression.idle
        ? AnimalExpression.blink
        : widget.expression;
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([_breath, _jump]),
        builder: (context, child) {
          final b = Curves.easeInOut.transform(_breath.value);
          final breathScaleY = 1 + .02 * b;
          final breathScaleX = 1 - .005 * b;
          final t = _jump.value;
          final (jsx, jsy) = _jump.isAnimating ? _jumpScale(t) : (1.0, 1.0);
          final dy = _jump.isAnimating ? _jumpDy(t) : 0.0;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.diagonal3Values(
                breathScaleX * jsx,
                breathScaleY * jsy,
                1,
              ),
              child: child,
            ),
          );
        },
        child: buildAnimal(
          widget.kind,
          size: widget.size,
          expression: expression,
          accessory: widget.accessory,
          mirrored: widget.mirrored,
        ),
      ),
    );
  }
}

/// Doimiy suzuvchi bulut: ekran bo'ylab chapdan o'ngga, wrap-around.
class DriftingCloud extends StatefulWidget {
  const DriftingCloud({
    super.key,
    required this.child,
    required this.travelWidth,
    this.period = const Duration(seconds: 55),
    this.initialPhase = 0,
  });

  final Widget child;

  /// Sayohat masofasi (odatda sahna kengligi + bulut kengligi).
  final double travelWidth;
  final Duration period;

  /// 0..1 — boshlang'ich pozitsiya (bulutlar bir joydan boshlanmasin).
  final double initialPhase;

  @override
  State<DriftingCloud> createState() => _DriftingCloudState();
}

class _DriftingCloudState extends State<DriftingCloud>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.period,
      value: widget.initialPhase,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, child) => Transform.translate(
          // -bulut kengligidan boshlab o'ng chetgacha, keyin qaytadan.
          offset: Offset(_c.value * widget.travelWidth - 60, 0),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
