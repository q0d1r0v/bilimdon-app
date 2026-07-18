import 'package:flutter/material.dart';

import 'tokens.dart';

/// Fredoka — uz/en; Nunito — ru (Fredoka'da kirill glifi yo'q).
String fontFamilyFor(Locale locale) =>
    locale.languageCode == 'ru' ? 'Nunito' : 'Fredoka';

ThemeData buildFarmTheme(Locale locale) {
  final family = fontFamilyFor(locale);
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: family,
    scaffoldBackgroundColor: FarmColors.cream,
    colorScheme: ColorScheme.fromSeed(
      seedColor: FarmColors.red,
      primary: FarmColors.red,
      secondary: FarmColors.green,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: family,
      bodyColor: FarmColors.inkDark,
      displayColor: FarmColors.inkDark,
    ),
  );
}
