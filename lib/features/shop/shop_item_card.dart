import 'dart:async';

import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../characters/chick.dart';
import '../../characters/cow.dart';
import '../../characters/pig.dart';
import '../../characters/sheep.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/decorations.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/icons.dart';
import '../../widgets/speech_bubble.dart';
import 'shop_catalog.dart';

/// Do‘kon buyum kartasi: oq karta, 72px preview, nom va holat tugmasi
/// (sotib olish / kiyish / yechish). Pul yetmasa — shake + pufak.
class ShopItemCard extends StatefulWidget {
  const ShopItemCard({super.key, required this.item, required this.store});

  final ShopItem item;
  final ProgressStore store;

  @override
  State<ShopItemCard> createState() => _ShopItemCardState();
}

class _ShopItemCardState extends State<ShopItemCard>
    with TickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final AnimationController _popController;
  late final Animation<double> _shakeX;
  late final Animation<double> _popScale;
  Timer? _tooltipTimer;
  bool _showNotEnough = false;

  @override
  void initState() {
    super.initState();
    _shakeController =
        AnimationController(vsync: this, duration: FarmAnim.shakeX);
    // DESIGN_SPEC shakeX: 0/−7/+7/−7/+7/0 (20/40/60/80%).
    _shakeX = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 7, end: -7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -7, end: 7), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 7, end: 0), weight: 20),
    ]).animate(_shakeController);
    _popController =
        AnimationController(vsync: this, duration: FarmAnim.popIn);
    // Kichik popIn: 1 → 1.12 → 1 (sotib olingandan keyin).
    _popScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1, end: 1.12), weight: 70),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 1), weight: 30),
    ]).animate(
      CurvedAnimation(parent: _popController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    _shakeController.dispose();
    _popController.dispose();
    super.dispose();
  }

  void _onBuy() {
    final item = widget.item;
    if (widget.store.coins >= item.price) {
      if (item.isPowerup) {
        widget.store.buyConsumable(item.id, item.price);
      } else {
        widget.store.buyItem(item.id, item.price);
      }
      AudioService.instance.play(Sfx.coin);
      _popController.forward(from: 0);
    } else {
      AudioService.instance.play(Sfx.thunk);
      _shakeController.forward(from: 0);
      _tooltipTimer?.cancel();
      setState(() => _showNotEnough = true);
      _tooltipTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showNotEnough = false);
      });
    }
  }

  void _onEquip() {
    AudioService.instance.play(Sfx.tap);
    widget.store.setEquipped(widget.item.slot, widget.item.id);
  }

  void _onUnequip() {
    AudioService.instance.play(Sfx.tap);
    widget.store.setEquipped(widget.item.slot, null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final owned = widget.store.ownedItems.contains(item.id);
    final equippedNow = widget.store.equippedFor(item.slot) == item.id;

    final card = AnimatedBuilder(
      animation: Listenable.merge([_shakeController, _popController]),
      builder: (context, child) => Transform.translate(
        offset: Offset(_shakeX.value, 0),
        child: Transform.scale(scale: _popScale.value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FarmColors.cardBorder, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 72, child: Center(child: _preview(item.id))),
            const SizedBox(height: 8),
            SizedBox(
              height: 34,
              child: Center(
                child: Text(
                  _itemName(l10n, item.id),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: FarmColors.inkDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (item.isPowerup) ...[
              _buyButton(item),
              const SizedBox(height: 4),
              Text(
                l10n.shopOwnedCount(widget.store.powerupCount(item.id)),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: FarmColors.inkOlive,
                ),
              ),
            ] else if (!owned)
              _buyButton(item)
            else if (!equippedNow)
              _stateButton(
                label: item.isDecor ? l10n.shopPlace : l10n.shopEquip,
                color: FarmColors.blue,
                darkColor: FarmColors.blueDark,
                textColor: Colors.white,
                onPressed: _onEquip,
              )
            else
              _stateButton(
                label: item.isDecor ? l10n.shopRemove : l10n.shopUnequip,
                color: FarmColors.yellow,
                darkColor: FarmColors.yellowDark,
                textColor: FarmColors.inkDark,
                onPressed: _onUnequip,
              ),
          ],
        ),
      ),
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        if (_showNotEnough)
          Positioned(
            left: 0,
            right: 0,
            top: -10,
            child: Center(
              child: SpeechBubble(
                text: l10n.shopNotEnough,
                background: FarmColors.wrongBg,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  /// Yashil «sotib olish» tugmasi: tanga + narx.
  Widget _buyButton(ShopItem item) {
    return ChunkyButton(
      color: FarmColors.green,
      darkColor: FarmColors.greenDark,
      borderRadius: 14,
      ledge: 4,
      minHeight: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: _onBuy,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CoinIcon(size: 12),
          const SizedBox(width: 5),
          Text(
            '${item.price}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Kiyish/yechish holat tugmasi.
  Widget _stateButton({
    required String label,
    required Color color,
    required Color darkColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return ChunkyButton(
      color: color,
      darkColor: darkColor,
      borderRadius: 14,
      ledge: 4,
      minHeight: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onPressed,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  /// 72px preview: dekor — bezak widgeti, aksessuar — hayvon buyum bilan.
  Widget _preview(String id) {
    return switch (id) {
      'flowerBed' => const FlowerBed(size: 56),
      'tree' => const AppleTree(size: 64),
      'hay' => const HayStack(size: 52),
      'pond' => const Pond(size: 58),
      'cowHat' =>
        const CowWidget(size: 56, accessory: AnimalAccessory.cowHat),
      'chickBow' =>
        const ChickWidget(size: 44, accessory: AnimalAccessory.chickBow),
      'pigGlasses' =>
        const PigWidget(size: 52, accessory: AnimalAccessory.pigGlasses),
      'sheepScarf' =>
        const SheepWidget(size: 50, accessory: AnimalAccessory.sheepScarf),
      'powerHeart' => const HeartIcon(size: 46, filled: true),
      'powerHint' =>
        const Icon(Icons.lightbulb, size: 44, color: FarmColors.yellow),
      'powerSkip' => const Icon(
          Icons.fast_forward_rounded,
          size: 44,
          color: FarmColors.blue,
        ),
      'powerCoinX2' => const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoinIcon(size: 40),
            SizedBox(width: 4),
            Text(
              '×2',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: FarmColors.coinText,
              ),
            ),
          ],
        ),
      _ => const SizedBox.shrink(),
    };
  }

  /// id → l10n nomi.
  static String _itemName(AppLocalizations l10n, String id) {
    return switch (id) {
      'flowerBed' => l10n.itemFlowerBed,
      'tree' => l10n.itemTree,
      'hay' => l10n.itemHay,
      'pond' => l10n.itemPond,
      'cowHat' => l10n.itemCowHat,
      'chickBow' => l10n.itemChickBow,
      'pigGlasses' => l10n.itemPigGlasses,
      'sheepScarf' => l10n.itemSheepScarf,
      'powerHeart' => l10n.itemPowerHeart,
      'powerHint' => l10n.itemPowerHint,
      'powerSkip' => l10n.itemPowerSkip,
      'powerCoinX2' => l10n.itemPowerCoinX2,
      _ => id,
    };
  }
}
