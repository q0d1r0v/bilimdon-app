import 'dart:async';

import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../characters/cow.dart';
import '../../core/audio/audio_service.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/icons.dart';

/// Daraja yakuni overleyi (DESIGN_SPEC «Finish overlay»): .94 alfa krem fon,
/// popIn karta (260px), sigir, ketma-ket ochiladigan yulduzlar, bonus pill
/// count-up bilan, «Qaytadan o‘ynash» va «Davom etish».
class FinishOverlay extends StatefulWidget {
  const FinishOverlay({
    super.key,
    required this.stars,
    required this.totalReward,
    required this.levelNumber,
    required this.onPlayAgain,
    required this.onContinue,
    this.onStarSparkle,
  });

  /// Yig‘ilgan yulduzlar (0..3).
  final int stars;

  /// Sessiyaning umumiy mukofoti (tangalar).
  final int totalReward;

  /// Bola ko‘radigan daraja raqami (bob ichida 1..6) — xaritadagi tugun
  /// yorlig‘i bilan bir xil. Ichki «1-3» ko‘rinishidagi id EMAS.
  final int levelNumber;
  final VoidCallback onPlayAgain;
  final VoidCallback onContinue;

  /// Yulduz ochilganda global koordinatadagi markazi bilan chaqiriladi —
  /// tepadagi effekt qatlami uchqun chizadi.
  final void Function(Offset globalCenter)? onStarSparkle;

  @override
  State<FinishOverlay> createState() => _FinishOverlayState();
}

class _FinishOverlayState extends State<FinishOverlay> {
  /// popIn keyframe (prototip): .4 → 1.12 (70%) → 1.
  static final _popIn = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(begin: 0.4, end: 1.12)
          .chain(CurveTween(curve: Curves.easeOut)),
      weight: 70,
    ),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
  ]);

  final _starKeys = List.generate(3, (_) => GlobalKey());
  Timer? _starTimer;
  int _shownStars = 0;

  @override
  void initState() {
    super.initState();
    AudioService.instance.play(Sfx.win);
    _starTimer = Timer.periodic(const Duration(milliseconds: 350), (t) {
      if (_shownStars >= widget.stars) {
        t.cancel();
        return;
      }
      final revealed = _shownStars;
      setState(() => _shownStars = revealed + 1);
      AudioService.instance.play(Sfx.star);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final box = _starKeys[revealed].currentContext?.findRenderObject();
        if (box is RenderBox && box.attached) {
          widget.onStarSparkle
              ?.call(box.localToGlobal(box.size.center(Offset.zero)));
        }
      });
    });
  }

  @override
  void dispose() {
    _starTimer?.cancel();
    super.dispose();
  }

  Widget _star(int i) {
    final earned = i < widget.stars;
    final star = KeyedSubtree(
      key: _starKeys[i],
      child: StarIcon(size: 32, filled: earned),
    );
    if (!earned) return star;
    if (i >= _shownStars) {
      // Hali ochilmagan — joyi saqlanadi, ko‘rinmaydi.
      return Opacity(opacity: 0, child: star);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      builder: (context, t, child) {
        // 0 → 1.3 → 1 keyframe.
        final scale = t < .6 ? (t / .6) * 1.3 : 1.3 - 0.3 * ((t - .6) / .4);
        return Transform.scale(scale: scale, child: child);
      },
      child: star,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: FarmColors.gameBg.withValues(alpha: .94),
        alignment: Alignment.center,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: FarmAnim.popIn,
          builder: (context, t, child) =>
              Transform.scale(scale: _popIn.transform(t), child: child),
          child: Container(
            width: 260,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: FarmColors.cardBorder, width: 3),
              borderRadius: BorderRadius.circular(FarmRadius.overlayCard),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(90, 80, 40, .2),
                  offset: Offset(0, 12),
                  blurRadius: 34,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CowWidget(
                  size: 100,
                  expression: AnimalExpression.happy,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
                        child: _star(i),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.finishTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: FarmColors.inkDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.finishSubtitle('${widget.levelNumber}'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: FarmColors.inkFaded,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: FarmColors.bonusPillBg,
                    borderRadius: BorderRadius.circular(FarmRadius.pill),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CoinIcon(size: 16),
                        const SizedBox(width: 6),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: widget.totalReward),
                          duration: const Duration(milliseconds: 700),
                          builder: (context, value, _) => Text(
                            l10n.plusCoins(value),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: FarmColors.coinText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                ChunkyButton(
                  gradient: const LinearGradient(
                    colors: [FarmColors.redGradTop, FarmColors.red],
                  ),
                  darkColor: FarmColors.redDark,
                  borderRadius: 18,
                  ledge: 5,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                  onPressed: widget.onPlayAgain,
                  child: Text(
                    l10n.playAgain,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onContinue,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    child: Text(
                      l10n.continueButton,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: FarmColors.inkOlive,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
