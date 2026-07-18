import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chunky_button.dart';

/// 3 yurak tugaganda ko'rinadigan MULOYIM oyna: hamdard sigir + «Yana
/// urinamiz!» + qaytadan/chiqish. Qattiq "yutqazding" yo'q, jarima yo'q.
class FailOverlay extends StatelessWidget {
  const FailOverlay({super.key, required this.onRetry, required this.onExit});

  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: Container(
        color: const Color.fromRGBO(253, 246, 227, .94),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(FarmRadius.overlayCard),
              border: Border.all(color: FarmColors.cardBorder, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(180, 120, 40, .18),
                  offset: Offset(0, 6),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildAnimal(
                  FarmAnimal.cow,
                  size: 108,
                  expression: AnimalExpression.sad,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.failTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: FarmColors.inkDark,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ChunkyButton(
                    color: FarmColors.green,
                    darkColor: FarmColors.greenDark,
                    borderRadius: 16,
                    minHeight: 50,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    onPressed: onRetry,
                    child: Text(
                      l10n.failRetry,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onExit,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.failExit,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: FarmColors.inkGray,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
