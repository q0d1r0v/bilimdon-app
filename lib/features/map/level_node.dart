import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/lock_icon.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/icons.dart';

/// Tugun holati (DESIGN_SPEC "Ekran 1", Tugunlar).
enum LevelNodeState { completed, active, locked }

/// Xaritadagi bitta daraja tuguni: doira + pastki jant, holatga qarab
/// yashil (bajarilgan, ostида ★-pill), qizil pulsli (faol, BOSHLA! bilan)
/// yoki bej qulflangan (bosilsa wiggle + thunk).
///
/// Qulflangan/bajarilgan tugun o’lchami — aynan doira diametri (★-pill
/// interaktiv emas, `Clip.none` bilan tashqariga chiqadi). Faol tugunda
/// BOSHLA! tugmasi widget chegarasi ICHIDA turadi — Flutter hit-test
/// RenderBox chegarasidan tashqaridagi bolalarga tushmaydi, shuning uchun
/// umumiy o’lcham [sizeFor], doira diametri esa [diameterFor] orqali
/// olinadi (xarita langarlari — doira markazlari).
class LevelNode extends StatefulWidget {
  const LevelNode({
    super.key,
    required this.number,
    required this.state,
    this.stars = 0,
    this.onPlay,
    this.ctaBelow = false,
  });

  /// Ko’rsatiladigan daraja raqami (1..6).
  final int number;

  final LevelNodeState state;

  /// Bajarilgan tugun uchun yulduzlar (0..3).
  final int stars;

  /// Faol/bajarilgan tugun bosilganda (Sfx.tap dan keyin) chaqiriladi.
  final VoidCallback? onPlay;

  /// BOSHLA! tugmasi doira OSTIDA chizilsin (odatda tugma ustida turadi;
  /// dizayn-fazoning yuqori qatoridagi tugunlarda tepada joy yo’q —
  /// y<0 hudud hit-testdan o’tmaydi).
  final bool ctaBelow;

  /// Holatga mos doira diametri: 66 / 86 / 58 (DESIGN_SPEC).
  static double diameterFor(LevelNodeState state) => switch (state) {
        LevelNodeState.completed => 66,
        LevelNodeState.active => 86,
        LevelNodeState.locked => 58,
      };

  /// BOSHLA! tugmasi uchun qo’shimcha balandlik: 8px oraliq + tugma
  /// balandligiga zaxira (vizual oraliq baribir 8px bo’lib qoladi).
  static const double ctaExtent = 42;

  /// Faol tugun uchun minimal kenglik — BOSHLA! tugmasi sig’ishi uchun.
  static const double _ctaWidth = 130;

  /// Widgetning to’liq layout o’lchami. Faol tugunda doira + CTA bandi,
  /// qolganlarida — doiraning o’zi.
  static Size sizeFor(LevelNodeState state) {
    final d = diameterFor(state);
    if (state != LevelNodeState.active) return Size(d, d);
    return Size(math.max(d, _ctaWidth), d + ctaExtent);
  }

  @override
  State<LevelNode> createState() => _LevelNodeState();
}

class _LevelNodeState extends State<LevelNode>
    with TickerProviderStateMixin {
  /// pulseNode: scale 1→1.07→1, 1.6s ease-in-out infinite.
  late final AnimationController _pulse;
  late final Animation<double> _pulseScale;

  /// Qulflangan tugun wiggle: rotate 0/−4/4/−3/3/0 gradus, 420ms.
  late final AnimationController _wiggle;
  late final Animation<double> _wiggleDeg;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: FarmAnim.pulseNode);
    _pulseScale = Tween<double>(begin: 1, end: 1.07).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _wiggleDeg = TweenSequence<double>([
      for (final (a, b) in const [(0.0, -4.0), (-4.0, 4.0), (4.0, -3.0), (-3.0, 3.0), (3.0, 0.0)])
        TweenSequenceItem(tween: Tween(begin: a, end: b), weight: 1),
    ]).animate(_wiggle);
    _syncPulse();
  }

  @override
  void didUpdateWidget(LevelNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == LevelNodeState.active) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _wiggle.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.state == LevelNodeState.locked) {
      AudioService.instance.play(Sfx.thunk);
      _wiggle.forward(from: 0);
      return;
    }
    AudioService.instance.play(Sfx.tap);
    widget.onPlay?.call();
  }

  @override
  Widget build(BuildContext context) {
    final d = LevelNode.diameterFor(widget.state);

    Widget circle = Container(
      width: d,
      height: d,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: switch (widget.state) {
          LevelNodeState.completed => FarmColors.green,
          LevelNodeState.locked => FarmColors.lockedBeige,
          LevelNodeState.active => null,
        },
        gradient: widget.state == LevelNodeState.active
            ? const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [FarmColors.redGradTop, FarmColors.red],
              )
            : null,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          // Pastki jant — CSS border-bottom ekvivalenti (blursiz).
          BoxShadow(
            color: switch (widget.state) {
              LevelNodeState.completed => FarmColors.greenDark,
              LevelNodeState.active => FarmColors.redDark,
              LevelNodeState.locked => FarmColors.lockedDark,
            },
            offset: Offset(0, widget.state == LevelNodeState.active ? 7 : 6),
            blurRadius: 0,
          ),
          if (widget.state == LevelNodeState.active)
            const BoxShadow(
              color: Color.fromRGBO(190, 45, 40, .45),
              offset: Offset(0, 6),
              blurRadius: 14,
            ),
        ],
      ),
      child: Center(
        child: widget.state == LevelNodeState.locked
            ? const LockIcon()
            : Text(
                '${widget.number}',
                style: TextStyle(
                  fontSize:
                      widget.state == LevelNodeState.active ? 34 : 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );

    if (widget.state == LevelNodeState.active) {
      circle = ScaleTransition(scale: _pulseScale, child: circle);
    } else if (widget.state == LevelNodeState.locked) {
      circle = AnimatedBuilder(
        animation: _wiggleDeg,
        builder: (context, child) => Transform.rotate(
          angle: _wiggleDeg.value * math.pi / 180,
          child: child,
        ),
        child: circle,
      );
    }

    final tappableCircle = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      child: circle,
    );

    if (widget.state != LevelNodeState.active) {
      return SizedBox(
        width: d,
        height: d,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            tappableCircle,
            if (widget.state == LevelNodeState.completed)
              Positioned(
                left: -30,
                right: -30,
                top: d + 4,
                child: Center(child: StarRatingPill(stars: widget.stars)),
              ),
          ],
        ),
      );
    }

    // Faol tugun: BOSHLA! widget chegarasi ICHIDA — tashqarida qolgan
    // tugma hit-testdan o’tmasdi (bosib bo’lmas edi). Doira markazi
    // xarita langariga tushishi uchun joylash matematikasi map_screen'da.
    final size = LevelNode.sizeFor(widget.state);
    final below = widget.ctaBelow;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: (size.width - d) / 2,
            top: below ? 0 : LevelNode.ctaExtent,
            width: d,
            height: d,
            child: tappableCircle,
          ),
          Positioned(
            left: 0,
            right: 0,
            top: below ? d + 8 : null,
            bottom: below ? null : d + 8,
            child: Center(
              child: ChunkyButton(
                color: FarmColors.brown,
                darkColor: FarmColors.brownDark,
                borderRadius: 10,
                ledge: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                onPressed: () {
                  AudioService.instance.play(Sfx.tap);
                  widget.onPlay?.call();
                },
                child: Text(
                  AppLocalizations.of(context).startButton,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: .5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
