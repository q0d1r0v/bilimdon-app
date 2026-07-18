import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// Flame partikl-qatlami: ekran ustidagi shaffof overlay.
/// FAQAT effektlar uchun — o'yin logikasi/UI bunga bog'lanmaydi.
/// Ranglar: faqat javob-tugma ranglari + oq + tanga oltinі (dizayn palitrasи).
class EffectsGame extends FlameGame {
  /// Partikl yo'q payt dvigatel pauzada turadi — aks holda Flame'ning
  /// GameRenderBox'i bo'sh shaffof qatlamni har kadr (60fps) qayta chizib,
  /// past quvvatli qurilmalarda kadr byudjetini bekorga yeydi. Har effekt
  /// chaqiruvi [_wake] bilan uyg'otadi; partikllar tugagach [update]
  /// o'zi yana pauza qiladi. Konstruktorda pauza xavfsiz: attach paytida
  /// GameRenderBox `game.paused` bo'lsa gameLoop'ni ishga tushirmaydi.
  EffectsGame() {
    pauseEngine();
  }

  static const _confettiColors = [
    FarmColors.red,
    FarmColors.green,
    FarmColors.blue,
    FarmColors.yellow,
    Colors.white,
    FarmColors.coin,
  ];

  final _rng = math.Random();

  @override
  Color backgroundColor() => const Color(0x00000000);

  void _wake() {
    if (paused) resumeEngine();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Partikllar qolmadi (children'da faqat camera/world bor) va navbatda
    // qayta ishlanmagan qo'shish/olib tashlash yo'q — keyingi effektgacha
    // uxlaymiz. Tekshiruv ATAYIN super.update'dan KEYIN: yangi qo'shilgan
    // partikl lifecycle navbatidan children'ga aynan shu yerda o'tadi.
    if (!hasLifecycleEvents &&
        children.whereType<ParticleSystemComponent>().isEmpty) {
      pauseEngine();
    }
  }

  /// Konfetti portlashi — 24 partikl, yuqoriga konus, gravitatsiya bilan.
  void confettiBurst(Offset at) {
    _wake();
    final position = Vector2(at.dx, at.dy);
    add(
      ParticleSystemComponent(
        position: position,
        particle: Particle.generate(
          count: 24,
          lifespan: 0.85,
          generator: (i) {
            // -30°..-150° — yuqoriga konus
            final angle = (-30 - _rng.nextDouble() * 120) * math.pi / 180;
            final speed = 180 + _rng.nextDouble() * 140;
            final velocity =
                Vector2(math.cos(angle), math.sin(angle)) * speed;
            final color = _confettiColors[i % _confettiColors.length];
            final isSquare = i.isEven;
            final size = 3 + _rng.nextDouble() * 3;
            final spin = (_rng.nextDouble() - .5) * 12;
            return AcceleratedParticle(
              speed: velocity,
              acceleration: Vector2(0, 600),
              child: ComputedParticle(
                renderer: (canvas, particle) {
                  final opacity = (1 - particle.progress).clamp(0.0, 1.0);
                  final paint = Paint()
                    ..color = color.withValues(alpha: opacity);
                  if (isSquare) {
                    canvas.save();
                    canvas.rotate(spin * particle.progress);
                    canvas.drawRect(
                      Rect.fromCenter(
                        center: Offset.zero,
                        width: size,
                        height: size,
                      ),
                      paint,
                    );
                    canvas.restore();
                  } else {
                    canvas.drawCircle(Offset.zero, size / 2, paint);
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  /// Yulduz uchqunlari — 3 ta to'rt-qirrali uchqun, stagger bilan.
  void starSparkle(Offset at) {
    _wake();
    for (var i = 0; i < 3; i++) {
      final jitter = Offset(
        (_rng.nextDouble() - .5) * 50,
        (_rng.nextDouble() - .5) * 36,
      );
      add(
        ParticleSystemComponent(
          position: Vector2(at.dx + jitter.dx, at.dy + jitter.dy),
          particle: ComputedParticle(
            lifespan: 0.45 + i * 0.09,
            renderer: (canvas, particle) {
              // scale 0 -> 1 -> 0
              final p = particle.progress;
              final scale = p < .5 ? p * 2 : (1 - p) * 2;
              final color = i.isEven ? FarmColors.coin : Colors.white;
              final paint = Paint()..color = color;
              final len = 7.0 * scale;
              const thick = 2.0;
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: len * 2,
                    height: thick,
                  ),
                  const Radius.circular(1),
                ),
                paint,
              );
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromCenter(
                    center: Offset.zero,
                    width: thick,
                    height: len * 2,
                  ),
                  const Radius.circular(1),
                ),
                paint,
              );
            },
          ),
        ),
      );
    }
  }

  /// Tanga-parvoz: 5 tanga tugmadan hisoblagichga Bézier bo'ylab uchadi.
  /// [onArrive] har tanga yetib kelganda chaqiriladi (hisoblagich bump + SFX).
  void coinFly(
    Offset from,
    Offset to, {
    int count = 5,
    void Function()? onArrive,
  }) {
    _wake();
    for (var i = 0; i < count; i++) {
      final delaySec = i * 0.06;
      final control = Offset(
        (from.dx + to.dx) / 2 + (_rng.nextDouble() - .5) * 80,
        math.min(from.dy, to.dy) - 80,
      );
      var arrived = false;
      add(
        ParticleSystemComponent(
          position: Vector2.zero(),
          particle: ComputedParticle(
            lifespan: 0.55 + delaySec,
            renderer: (canvas, particle) {
              final raw = particle.progress;
              final total = 0.55 + delaySec;
              final t0 = delaySec / total;
              if (raw < t0) return; // stagger kutish
              final t = Curves.easeIn
                  .transform(((raw - t0) / (1 - t0)).clamp(0.0, 1.0));
              // Kvadratik Bézier
              final p = Offset(
                _bez(from.dx, control.dx, to.dx, t),
                _bez(from.dy, control.dy, to.dy, t),
              );
              final scale = 1 - 0.3 * t;
              final r = 6.0 * scale;
              canvas.drawCircle(
                p,
                r,
                Paint()..color = FarmColors.coinBorder,
              );
              canvas.drawCircle(
                p,
                r - 1.6,
                Paint()..color = FarmColors.coin,
              );
              if (t >= 1 && !arrived) {
                arrived = true;
                onArrive?.call();
              }
            },
          ),
        ),
      );
    }
  }

  static double _bez(double a, double c, double b, double t) =>
      (1 - t) * (1 - t) * a + 2 * (1 - t) * t * c + t * t * b;
}

/// Ekran ustiga qo'yiladigan shaffof effekt-overlay.
class EffectsOverlay extends StatelessWidget {
  const EffectsOverlay({super.key, required this.game});

  final EffectsGame game;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: GameWidget(game: game),
      ),
    );
  }
}
