import 'package:flutter/material.dart';

import '../../characters/sheep.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/hill.dart';
import '../../scene/sky.dart';
import '../../widgets/icons.dart';
import '../../widgets/pill.dart';
import '../../widgets/speech_bubble.dart';
import 'shop_catalog.dart';
import 'shop_item_card.dart';

/// Do‘kon ekrani: osmon gradientli tepa panel (qo‘y sotuvchi + tanga pill),
/// pastda krem fonda ikki bo‘lim — bezaklar va aksessuarlar.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final powerupItems = shopCatalog.where((i) => i.isPowerup).toList();
    final decorItems = shopCatalog.where((i) => i.isDecor).toList();
    final accessoryItems = shopCatalog.where((i) => i.isAccessory).toList();

    return Container(
      color: FarmColors.gameBg,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Column(
          children: [
            _SkyHeader(coins: store.coins, greeting: l10n.shopKeeperHi),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(title: l10n.shopCatPowerup),
                    const SizedBox(height: 8),
                    _ItemGrid(items: powerupItems, store: store),
                    const SizedBox(height: 20),
                    _SectionHeader(title: l10n.shopCatDecor),
                    const SizedBox(height: 8),
                    _ItemGrid(items: decorItems, store: store),
                    const SizedBox(height: 20),
                    _SectionHeader(title: l10n.shopCatAccessory),
                    const SizedBox(height: 8),
                    _ItemGrid(items: accessoryItems, store: store),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Osmon gradientli tepa panel: qo‘y + pufak + tanga pill, ostida tepalik.
class _SkyHeader extends StatelessWidget {
  const _SkyHeader({required this.coins, required this.greeting});

  final int coins;
  final String greeting;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: farmSkyGradient(),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                children: [
                  const SheepWidget(size: 64),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SpeechBubble(
                        text: greeting,
                        fontSize: 12,
                        tail: BubbleTail.leftBottom,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  StatPill(
                    children: [
                      const CoinIcon(size: 14),
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: FarmColors.coinText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Yashil tepalik chizig'i — osmon va krem kontent orasida.
            SizedBox(
              height: 30,
              width: double.infinity,
              child: ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) => OverflowBox(
                    maxWidth: constraints.maxWidth * 1.5,
                    maxHeight: 90,
                    alignment: Alignment.topCenter,
                    child: Hill(
                      width: constraints.maxWidth * 1.5,
                      height: 90,
                      color: FarmColors.grass,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 12px w700 inkOlive bosh harfli bo‘lim sarlavhasi.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: FarmColors.inkOlive,
      ),
    );
  }
}

/// 2 ustunli karta to‘ri (Column of Rows — shrinkWrap gridsiz).
class _ItemGrid extends StatelessWidget {
  const _ItemGrid({required this.items, required this.store});

  final List<ShopItem> items;
  final ProgressStore store;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ShopItemCard(item: items[i], store: store)),
            const SizedBox(width: 12),
            Expanded(
              child: i + 1 < items.length
                  ? ShopItemCard(item: items[i + 1], store: store)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
    }
    return Column(children: rows);
  }
}
