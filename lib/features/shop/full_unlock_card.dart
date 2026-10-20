import 'package:flutter/material.dart';

import '../../core/persistence/progress_store.dart';
import '../../core/purchases/purchase_service.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/barn.dart';
import '../../widgets/chunky_button.dart';
import '../purchase/full_unlock_sheet.dart';

/// Do‘kon tepasidagi to‘liq kenglikdagi «To‘liq versiya» kartasi (haqiqiy
/// pul — tanga katalogidan alohida). Sotib olingach «Sotib olingan» bo‘ladi.
class FullUnlockCard extends StatelessWidget {
  const FullUnlockCard({
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
      listenable: purchases,
      builder: (context, _) {
        final owned = store.fullUnlocked;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [FarmColors.bannerGradTop, FarmColors.red],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 3),
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
                      l10n.unlockTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      owned ? l10n.unlockOwned : l10n.unlockSubtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: FarmColors.bannerSub,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (owned)
                Text(
                  '${l10n.unlockOwnedShort} ✓',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                )
              else
                ChunkyButton(
                  color: FarmColors.yellow,
                  darkColor: FarmColors.yellowDark,
                  borderRadius: 14,
                  ledge: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onPressed: () => showFullUnlockSheet(
                    context,
                    store: store,
                    purchases: purchases,
                  ),
                  child: Text(
                    purchases.priceLabel ?? l10n.unlockOpen,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: FarmColors.inkDark,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
