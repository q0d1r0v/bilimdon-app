import 'package:flutter/material.dart';

import '../core/theme/tokens.dart';

/// O‘yin ekranida osmon #8FD0F8 ga o‘tadigan piksel nuqtasi (DESIGN_SPEC).
const double gameSkyMidPx = 166;

/// O‘yin ekranida osmon #FDF6E3 fonga o‘tadigan piksel nuqtasi (DESIGN_SPEC).
const double gameSkyEndPx = 170;

/// Xarita gradienti balandligi noma’lum bo‘lganda o‘yin varianti uchun
/// taxminiy ekran balandligi (aniq px kerak bo‘lsa [farmGameSkyGradient]).
const double _gameSkyFallbackHeight = 844;

/// Osmon foni (DESIGN_SPEC "Ekran 1"):
/// tepadan pastga #57ADEE 0% → #8FD0F8 46% → #B8E6FF 60% (pastgacha B8E6FF).
///
/// [game] true bo‘lsa o‘yin ekrani varianti qaytadi — lekin px-aniq stoplar
/// uchun balandlik kerak, shuning uchun [farmGameSkyGradient] afzal.
BoxDecoration farmSkyGradient({bool game = false}) {
  if (game) return farmGameSkyGradient(_gameSkyFallbackHeight);
  return const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        FarmColors.skyTop,
        FarmColors.skyMid,
        FarmColors.skyLow,
        FarmColors.skyLow,
      ],
      stops: [0, .46, .60, 1],
    ),
  );
}

/// O‘yin ekrani osmoni (DESIGN_SPEC "Ekran 2"):
/// #57ADEE 0px → #8FD0F8 166px → #FDF6E3 170px, [height] — umumiy balandlik.
BoxDecoration farmGameSkyGradient(double height) {
  final h = height <= gameSkyEndPx ? gameSkyEndPx : height;
  return BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        FarmColors.skyTop,
        FarmColors.skyMid,
        FarmColors.gameBg,
        FarmColors.gameBg,
      ],
      stops: [0, gameSkyMidPx / h, gameSkyEndPx / h, 1],
    ),
  );
}
