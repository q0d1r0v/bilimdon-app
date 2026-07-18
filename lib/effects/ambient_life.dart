import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';
import '../core/utils/dotted_path_painter.dart';

/// Xarita «nozik ambient» qatlami — gulchang zarralari, kapalaklar, uchib
/// o'tuvchi qush, yo'lak shimmer'i va yengil tebranish. Barchasi QO'SHIMCHA
/// (additiv) qatlam: personaj geometriyasi/dizayn o'zgarmaydi, golden testlar
/// buzilmaydi. Har biri `RepaintBoundary` + `IgnorePointer` (tegishlarni
/// bloklamaydi) va `MediaQuery.disableAnimations` (reduce-motion) hurmatida.
///
/// Ranglar faqat [FarmColors] dan (tokens.dart qoidasi).

const double _tau = math.pi * 2;

bool _reduceMotion(BuildContext c) => MediaQuery.of(c).disableAnimations;

// ── Yengil tebranish (gullar/dekor) ─────────────────────────────────────────

/// Bolasini pastki markazdan yengil chayqaydi (shabada taassuroti).
class Sway extends StatefulWidget {
  const Sway({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 4),
    this.angle = 0.03,
    this.phase = 0,
  });

  final Widget child;
  final Duration period;

  /// Maksimal burilish (radian) — juda kichik, «nozik».
  final double angle;
  final double phase;

  @override
  State<Sway> createState() => _SwayState();
}

class _SwayState extends State<Sway> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: widget.period,
      value: widget.phase,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
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
        builder: (context, child) => Transform.rotate(
          alignment: Alignment.bottomCenter,
          angle: math.sin(_c.value * _tau) * widget.angle,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ── Gulchang zarralari ───────────────────────────────────────────────────────

class _Mote {
  const _Mote(this.x, this.r, this.speed, this.sway, this.swayFreq, this.phase,
      this.white, this.alpha);
  final double x, r, speed, sway, swayFreq, phase, alpha;
  final bool white;
}

/// Yuqoriga sekin suzuvchi yumshoq zarralar (gulchang / quyosh chang'i).
class AmbientPollen extends StatefulWidget {
  const AmbientPollen({
    super.key,
    required this.width,
    required this.height,
    this.count = 14,
  });

  final double width;
  final double height;
  final int count;

  @override
  State<AmbientPollen> createState() => _AmbientPollenState();
}

class _AmbientPollenState extends State<AmbientPollen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Mote> _motes;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    );
    final rng = math.Random(7);
    _motes = List.generate(widget.count, (_) {
      return _Mote(
        rng.nextDouble() * widget.width,
        1.0 + rng.nextDouble() * 1.6,
        0.5 + rng.nextDouble() * 0.7,
        5 + rng.nextDouble() * 11,
        0.6 + rng.nextDouble() * 1.0,
        rng.nextDouble(),
        rng.nextBool(),
        0.20 + rng.nextDouble() * 0.30,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _PollenPainter(_c.value, _motes),
          ),
        ),
      ),
    );
  }
}

class _PollenPainter extends CustomPainter {
  _PollenPainter(this.t, this.motes);
  final double t;
  final List<_Mote> motes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final prog = (t * m.speed + m.phase) % 1.0;
      final y = size.height * (1.0 - prog);
      final x = m.x + math.sin((prog + m.phase) * _tau * m.swayFreq) * m.sway;
      final a = m.alpha * math.sin(prog * math.pi); // chekkalarda so'nadi
      if (a <= 0.01) continue;
      final base = m.white ? Colors.white : FarmColors.coin;
      canvas.drawCircle(
        Offset(x, y),
        m.r,
        Paint()..color = base.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_PollenPainter old) => old.t != t;
}

// ── Kapalaklar + uchuvchi qush (bitta qatlam) ────────────────────────────────

/// Kapalaklar (2) va vaqti-vaqti bilan osmonni kesib o'tuvchi qush — bitta
/// samarali CustomPaint qatlamida.
class AmbientFliers extends StatefulWidget {
  const AmbientFliers({super.key, required this.width, required this.height});

  final double width;
  final double height;

  @override
  State<AmbientFliers> createState() => _AmbientFliersState();
}

class _AmbientFliersState extends State<AmbientFliers>
    with TickerProviderStateMixin {
  late final AnimationController _roam; // kapalak sayohati
  late final AnimationController _flap; // qanot qoqishi
  late final AnimationController _bird; // qush davri

  @override
  void initState() {
    super.initState();
    _roam = AnimationController(vsync: this, duration: const Duration(seconds: 17));
    _flap = AnimationController(vsync: this, duration: const Duration(milliseconds: 190));
    _bird = AnimationController(vsync: this, duration: const Duration(seconds: 24));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = _reduceMotion(context);
    for (final c in [_roam, _flap, _bird]) {
      if (reduce) {
        c.stop();
      }
    }
    if (!reduce) {
      if (!_roam.isAnimating) _roam.repeat();
      if (!_flap.isAnimating) _flap.repeat(reverse: true);
      if (!_bird.isAnimating) _bird.repeat();
    }
  }

  @override
  void dispose() {
    _roam.dispose();
    _flap.dispose();
    _bird.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_reduceMotion(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: Listenable.merge([_roam, _flap, _bird]),
          builder: (context, _) => CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _FliersPainter(_roam.value, _flap.value, _bird.value),
          ),
        ),
      ),
    );
  }
}

class _FliersPainter extends CustomPainter {
  _FliersPainter(this.roam, this.flap, this.bird);
  final double roam, flap, bird;

  void _butterfly(Canvas canvas, Offset c, double s, Color color, double fl) {
    final ww = s * (0.2 + 0.6 * fl); // qanot yoyilishi (qoqishga qarab)
    final wing = Paint()..color = color.withValues(alpha: 0.85);
    final wing2 = Paint()..color = color.withValues(alpha: 0.6);
    // Yuqori qanotlar
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(-ww, -s * .18), width: ww * 1.5, height: s), wing);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(ww, -s * .18), width: ww * 1.5, height: s), wing);
    // Pastki qanotlar
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(-ww * .7, s * .3), width: ww * 1.1, height: s * .7), wing2);
    canvas.drawOval(
        Rect.fromCenter(center: c + Offset(ww * .7, s * .3), width: ww * 1.1, height: s * .7), wing2);
    // Tana
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: s * .18, height: s * .9),
        Radius.circular(s * .09),
      ),
      Paint()..color = FarmColors.outline.withValues(alpha: 0.7),
    );
  }

  void _birdAt(Canvas canvas, Offset c, double wing) {
    final paint = Paint()
      ..color = FarmColors.inkGray.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    const span = 9.0;
    final dip = 2.5 + 3.5 * wing;
    final path = Path()
      ..moveTo(c.dx - span, c.dy)
      ..quadraticBezierTo(c.dx - span * .5, c.dy - dip, c.dx, c.dy)
      ..quadraticBezierTo(c.dx + span * .5, c.dy - dip, c.dx + span, c.dy);
    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Kapalak A
    final aPos = Offset(
      size.width * .60 + math.sin(_tau * roam) * (size.width * .16),
      size.height * .30 + math.sin(_tau * 2 * roam) * (size.height * .10),
    );
    _butterfly(canvas, aPos, 13, FarmColors.coin, flap);
    // Kapalak B (boshqa faza/tezlik)
    final rb = (roam + .37) % 1.0;
    final bPos = Offset(
      size.width * .34 + math.sin(_tau * rb + 1.0) * (size.width * .15),
      size.height * .52 + math.cos(_tau * 1.6 * rb) * (size.height * .14),
    );
    _butterfly(canvas, bPos, 12, FarmColors.redGradTop, flap * 0.9 + 0.05);
    // Qush — davrning boshida (~7s) chapdan o'ngga uchadi, keyin uzoq tanaffus.
    if (bird < 0.3) {
      final p = bird / 0.3;
      final x = -20 + p * (size.width + 40);
      final y = 46 + math.sin(p * math.pi * 2) * 6;
      final wing = (math.sin(bird * _tau * 9) + 1) / 2;
      _birdAt(canvas, Offset(x, y), wing);
    }
  }

  @override
  bool shouldRepaint(_FliersPainter old) =>
      old.roam != roam || old.flap != flap || old.bird != bird;
}

// ── Yo'lak shimmer'i (nuqta-yo'l bo'ylab yuguruvchi yorug'lik) ────────────────

/// Nuqta-yo'l bo'ylab boshdan oxirga qarab yuguradigan «kometa» yorug'lik —
/// yo'l geometriyasi [DottedPathPainter.pathFor] dan (yagona manba).
class DottedPathGlow extends StatefulWidget {
  const DottedPathGlow({super.key});

  @override
  State<DottedPathGlow> createState() => _DottedPathGlowState();
}

class _DottedPathGlowState extends State<DottedPathGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion(context)) {
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
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _GlowPainter(_c.value),
          ),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final path = DottedPathPainter.pathFor(size);
    for (final metric in path.computeMetrics()) {
      final total = metric.length;
      final head = t * total;
      // Kometa: bosh eng yorqin, orqasi so'nadi.
      for (var k = 0; k < 5; k++) {
        final d = head - k * 15.0;
        if (d < 0 || d > total) continue;
        final tan = metric.getTangentForOffset(d);
        if (tan == null) continue;
        final frac = 1.0 - k / 5.0;
        canvas.drawCircle(
          tan.position,
          5.0 * frac,
          Paint()..color = Colors.white.withValues(alpha: 0.30 * frac),
        );
        canvas.drawCircle(
          tan.position,
          3.0 * frac + 1,
          Paint()..color = FarmColors.coin.withValues(alpha: 0.85 * frac),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.t != t;
}
