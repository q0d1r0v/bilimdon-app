import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/icons.dart';
import '../../widgets/pill.dart';

/// Xarita sarlavhasi (DESIGN_SPEC "Ekran 1", Header): avatar + ism/daraja +
/// streak/tanga/yurak pill’lari. Store o’zgarganda o’zi qayta chiziladi.
class MapHeader extends StatelessWidget {
  const MapHeader({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Padding(
          // CSS padding: 8px 16px 0.
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _Avatar(avatar: store.avatar),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store.playerName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(0, 1),
                          blurRadius: 2,
                          color: Color.fromRGBO(20, 60, 110, .35),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    l10n.levelBadge(store.displayLevel),
                    style: const TextStyle(
                      fontSize: 11,
                      color: FarmColors.headerSub,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              StatPill(
                children: [
                  const StreakFlameIcon(size: 13),
                  Text(
                    '${store.streakCurrent}',
                    style: _pillTextStyle(FarmColors.streakText),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              StatPill(
                children: [
                  const CoinIcon(size: 14),
                  Text(
                    '${store.coins}',
                    style: _pillTextStyle(FarmColors.coinText),
                  ),
                ],
              ),
              const SizedBox(width: 6),
              StatPill(
                children: [
                  const HeartIcon(size: 14),
                  Text(
                    '${FarmRules.maxHearts}',
                    style: _pillTextStyle(FarmColors.red),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static TextStyle _pillTextStyle(Color color) =>
      TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color);
}

/// 46×46 doira avatar: #FFF6DE fon, 3px oq jant, ichida tanlangan hayvon
/// yuzi (doira ichiga qirqilgan).
class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar});

  final String avatar;

  @override
  Widget build(BuildContext context) {
    final kind = FarmAnimal.values.firstWhere(
      (a) => a.name == avatar,
      orElse: () => FarmAnimal.cow,
    );
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: FarmColors.creamAvatar,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 60, 20, .18),
            offset: Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipOval(
        child: OverflowBox(
          maxWidth: 46,
          maxHeight: 46,
          child: Center(child: buildAnimal(kind, size: 38)),
        ),
      ),
    );
  }
}
