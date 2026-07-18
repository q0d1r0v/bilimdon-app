import 'package:flutter/material.dart';

import '../../characters/pig.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/cloud.dart';
import '../../scene/lock_icon.dart';
import '../../scene/sky.dart';
import '../../scene/sun.dart';
import '../../widgets/pill.dart';
import '../../widgets/speech_bubble.dart';

/// Reyting ekrani (stub): osmon fonida cho‘chqa «tez kunda» deydi,
/// ostida uchta qulfli sirli pill. Cho‘chqa bosilsa xur-xur qiladi.
class RatingScreen extends StatelessWidget {
  const RatingScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: farmSkyGradient(),
      child: SafeArea(
        child: Stack(
          children: [
            const Positioned(left: 20, top: 14, child: Sun()),
            const Positioned(right: 40, top: 40, child: Cloud.big()),
            const Positioned(left: 60, top: 90, child: Cloud.small()),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SpeechBubble(
                    text: l10n.ratingSoonBubble,
                    fontSize: 12.5,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => AudioService.instance.play(Sfx.pigOink),
                    child: const PigWidget(size: 100),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.comingSoon,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: FarmColors.inkDark,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: 10),
                    const _TeaserPill(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kulrang sirli pill: kichik qulf + «???».
class _TeaserPill extends StatelessWidget {
  const _TeaserPill();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: .7,
      child: StatPill(
        background: FarmColors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        children: [
          SizedBox(
            height: 15,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 18,
                height: 22,
                child: LockIcon(color: FarmColors.inkGray),
              ),
            ),
          ),
          const Text(
            '???',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkGray,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}
