import 'package:flutter/material.dart';

import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/lock_icon.dart';
import '../../scene/sky.dart';
import '../../widgets/icons.dart';
import '../map/chapter_banner.dart';

/// Mundarija (Reyting o'rniga): butun kurikulum — boblar, ichidagi daraja
/// mavzulari, jarayon (yulduzlar) va joriy o'rin. Faqat ko'rish uchun
/// (o'ynash — xaritada).
class ContentsScreen extends StatelessWidget {
  const ContentsScreen({super.key, required this.store});

  final ProgressStore store;

  static const int _chapterCount = 6;
  static const int _levelsPerChapter = 6;
  static const int _starsPerLevel = 3;

  String _levelId(int ch, int idx) => '$ch-$idx';

  /// Birinchi qulfsiz + 0-yulduzli daraja idsi (joriy o'rin).
  String? _activeId() {
    for (var ch = 1; ch <= _chapterCount; ch++) {
      for (var idx = 1; idx <= _levelsPerChapter; idx++) {
        final id = _levelId(ch, idx);
        if (store.starsFor(id) == 0 && store.isLevelUnlocked(id)) return id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: FarmColors.gameBg,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          final activeId = _activeId();
          return Column(
            children: [
              _header(l10n),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var ch = 1; ch <= _chapterCount; ch++) ...[
                        if (ch > 1) const SizedBox(height: 12),
                        _chapterCard(l10n, ch, activeId),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(AppLocalizations l10n) {
    return Container(
      // Ko'k osmon ekranning ikkala yoniga to'liq cho'zilsin (tashqi Column
      // markazga tortmasin) — status bar ortiga ham kiradi.
      width: double.infinity,
      decoration: farmSkyGradient(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.contentsTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  // Kuchliroq soya — och ko'k osmonda oq matn aniq o'qilsin.
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(16, 58, 108, .55),
                      offset: Offset(0, 1.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                l10n.contentsSubtitle,
                // Xira headerSub o'rniga oq + soya (kontrast).
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Color.fromRGBO(16, 58, 108, .45),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chapterCard(AppLocalizations l10n, int ch, String? activeId) {
    final (name, subtitle) = _chapterNames(l10n, ch);
    var earned = 0;
    for (var idx = 1; idx <= _levelsPerChapter; idx++) {
      earned += store.starsFor(_levelId(ch, idx));
    }
    const total = _levelsPerChapter * _starsPerLevel;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.cardBorder, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.chapterTitle(ch, name),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: FarmColors.inkGray,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: FarmColors.inkDark,
                      ),
                    ),
                  ],
                ),
              ),
              const StarIcon(size: 15, filled: true),
              const SizedBox(width: 4),
              Text(
                l10n.starsProgress(earned, total),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: FarmColors.coinText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (var idx = 1; idx <= _levelsPerChapter; idx++)
            _levelRow(l10n, ch, idx, activeId),
        ],
      ),
    );
  }

  Widget _levelRow(AppLocalizations l10n, int ch, int idx, String? activeId) {
    final id = _levelId(ch, idx);
    final stars = store.starsFor(id);
    final done = stars > 0;
    final current = id == activeId;
    final locked = !done && !current;

    final Color numBg = done
        ? FarmColors.green
        : current
            ? FarmColors.red
            : FarmColors.lockedBeige;
    final Color numFg = locked ? FarmColors.lockIcon : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: current ? FarmColors.tagGreenBg : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: current
            ? Border.all(color: FarmColors.green, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: numBg, shape: BoxShape.circle),
            child: Text(
              '$idx',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: numFg,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _topic(l10n, ch, idx),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: locked ? FarmColors.inkFaded : FarmColors.inkDark,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (locked)
            const LockIcon()
          else
            StarRatingPill(stars: stars),
        ],
      ),
    );
  }

  (String, String) _chapterNames(AppLocalizations l10n, int id) =>
      chapterNames(l10n, id);

  String _topic(AppLocalizations l10n, int ch, int idx) => switch ('$ch-$idx') {
        '1-1' => l10n.topic_1_1,
        '1-2' => l10n.topic_1_2,
        '1-3' => l10n.topic_1_3,
        '1-4' => l10n.topic_1_4,
        '1-5' => l10n.topic_1_5,
        '1-6' => l10n.topic_1_6,
        '2-1' => l10n.topic_2_1,
        '2-2' => l10n.topic_2_2,
        '2-3' => l10n.topic_2_3,
        '2-4' => l10n.topic_2_4,
        '2-5' => l10n.topic_2_5,
        '2-6' => l10n.topic_2_6,
        '3-1' => l10n.topic_3_1,
        '3-2' => l10n.topic_3_2,
        '3-3' => l10n.topic_3_3,
        '3-4' => l10n.topic_3_4,
        '3-5' => l10n.topic_3_5,
        '3-6' => l10n.topic_3_6,
        '4-1' => l10n.topic_4_1,
        '4-2' => l10n.topic_4_2,
        '4-3' => l10n.topic_4_3,
        '4-4' => l10n.topic_4_4,
        '4-5' => l10n.topic_4_5,
        '4-6' => l10n.topic_4_6,
        '5-1' => l10n.topic_5_1,
        '5-2' => l10n.topic_5_2,
        '5-3' => l10n.topic_5_3,
        '5-4' => l10n.topic_5_4,
        '5-5' => l10n.topic_5_5,
        '5-6' => l10n.topic_5_6,
        '6-1' => l10n.topic_6_1,
        '6-2' => l10n.topic_6_2,
        '6-3' => l10n.topic_6_3,
        '6-4' => l10n.topic_6_4,
        '6-5' => l10n.topic_6_5,
        _ => l10n.topic_6_6,
      };
}
