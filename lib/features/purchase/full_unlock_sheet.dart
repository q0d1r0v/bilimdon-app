import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/lock_icon.dart';
import '../../widgets/chunky_button.dart';
import '../map/chapter_banner.dart';
import '../profile/parent_gate.dart';

/// «To'liq versiya» oynasi: pullik boblar ro'yxati, narx va sotib olish.
/// Har bir xariddan oldin ota-onalar darvozasi (Families / Kids talabi).
Future<void> showFullUnlockSheet(
  BuildContext context, {
  required ProgressStore store,
  required PurchaseService purchases,
}) {
  AudioService.instance.play(Sfx.tap);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FullUnlockSheet(store: store, purchases: purchases),
  );
}

/// Ota-onalar darvozasidan o'tilsa xaridni boshlaydi.
Future<void> buyFullUnlockWithGate(
  BuildContext context,
  PurchaseService purchases,
) async {
  AudioService.instance.play(Sfx.tap);
  final ok = await showParentGate(context);
  if (ok == true) await purchases.buyFullUnlock();
}

/// Darvozasiz tiklash (pul yechilmaydi) — natija SnackBar'da.
Future<void> restorePurchasesWithFeedback(
  BuildContext context,
  PurchaseService purchases,
) async {
  AudioService.instance.play(Sfx.tap);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  final restored = await purchases.restore();
  if (restored) AudioService.instance.play(Sfx.unlock);
  messenger?.showSnackBar(
    SnackBar(content: Text(restored ? l10n.restoreDone : l10n.restoreNothing)),
  );
}

class FullUnlockSheet extends StatelessWidget {
  const FullUnlockSheet({
    super.key,
    required this.store,
    required this.purchases,
  });

  final ProgressStore store;
  final PurchaseService purchases;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([store, purchases]),
      builder: (context, _) {
        final owned = store.fullUnlocked;
        return Container(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: FarmColors.cardBorder, width: 3),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.unlockTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: FarmColors.inkDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                owned ? l10n.unlockOwned : l10n.unlockSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: FarmColors.inkOlive,
                ),
              ),
              const SizedBox(height: 14),
              for (var ch = ProgressStore.freeChapters + 1; ch <= 6; ch++)
                _chapterRow(l10n, ch, owned),
              const SizedBox(height: 14),
              if (owned)
                _button(
                  label: l10n.unlockClose,
                  onPressed: () => Navigator.of(context).pop(),
                )
              else ...[
                _statusLine(l10n),
                _button(
                  label: purchases.priceLabel != null
                      ? l10n.unlockBuy(purchases.priceLabel!)
                      : l10n.unlockOpen,
                  enabled: purchases.available &&
                      purchases.status != UnlockStatus.busy &&
                      purchases.status != UnlockStatus.pending,
                  onPressed: () => buyFullUnlockWithGate(context, purchases),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.unlockForParents,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: FarmColors.inkOlive,
                  ),
                ),
                TextButton(
                  onPressed: purchases.status == UnlockStatus.busy
                      ? null
                      : () => restorePurchasesWithFeedback(context, purchases),
                  child: Text(
                    l10n.restorePurchases,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: FarmColors.blue,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _chapterRow(AppLocalizations l10n, int chapter, bool owned) {
    final (name, subtitle) = chapterNames(l10n, chapter);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: owned
                ? const Icon(Icons.check_circle, color: FarmColors.green)
                : const LockIcon(),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l10n.chapterTitle(chapter, name)} — $subtitle',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: FarmColors.inkDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Do'kon holati: kutilmoqda / xato / mavjud emas (idle'da — hech narsa).
  Widget _statusLine(AppLocalizations l10n) {
    final String? text = switch (purchases.status) {
      UnlockStatus.pending => l10n.unlockPending,
      UnlockStatus.error => l10n.unlockError,
      _ when !purchases.available => l10n.unlockUnavailable,
      _ => null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: purchases.status == UnlockStatus.pending
              ? FarmColors.inkOlive
              : FarmColors.red,
        ),
      ),
    );
  }

  Widget _button({
    required String label,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return ChunkyButton(
      color: FarmColors.green,
      darkColor: FarmColors.greenDark,
      borderRadius: 16,
      enabled: enabled,
      dimmed: !enabled,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}
