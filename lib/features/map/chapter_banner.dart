import 'package:flutter/material.dart';

import '../../characters/chick.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/barn.dart';

/// Bob raqami (1..6) → (NOM, mavzu). Banner/xarita/mundarija shu yagona
/// manbadan foydalanadi.
(String, String) chapterNames(AppLocalizations l10n, int id) => switch (id) {
      1 => (l10n.chapter1Name, l10n.chapter1Sub),
      2 => (l10n.chapter2Name, l10n.chapter2Sub),
      3 => (l10n.chapter3Name, l10n.chapter3Sub),
      4 => (l10n.chapter4Name, l10n.chapter4Sub),
      5 => (l10n.chapter5Name, l10n.chapter5Sub),
      _ => (l10n.chapter6Name, l10n.chapter6Sub),
    };

/// Bob banneri (DESIGN_SPEC "Ekran 1", Bob banneri): 135° qizil gradient,
/// 3px oq jant, radius 18; molxona ikonkasi + bob nomi + jo’ja.
class ChapterBanner extends StatelessWidget {
  const ChapterBanner({
    super.key,
    required this.chapterNumber,
    this.levelIndex,
    this.levelTotal = 6,
  });

  /// Ko’rsatilayotgan bob raqami (1..3).
  final int chapterNumber;

  /// Joriy (faol) daraja raqami — banner "N/6-daraja" ko'rsatadi. `null` bo'lsa
  /// (bob tugagan) progress ko'rsatilmaydi.
  final int? levelIndex;
  final int levelTotal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (name, subtitle) = chapterNames(l10n, chapterNumber);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        // CSS linear-gradient(135deg, #F05A50, #E8433F).
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [FarmColors.bannerGradTop, FarmColors.red],
        ),
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(FarmRadius.banner),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(180, 40, 35, .35),
            offset: Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        children: [
          const BarnIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chapterTitle(chapterNumber, name),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    color: FarmColors.bannerSub,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (levelIndex != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .22),
                borderRadius: BorderRadius.circular(FarmRadius.pill),
              ),
              child: Text(
                l10n.levelOfChapter(levelIndex!, levelTotal),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            )
          else
            const ChickWidget(size: 40),
        ],
      ),
    );
  }
}
