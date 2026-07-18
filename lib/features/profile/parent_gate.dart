import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/audio/audio_service.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chunky_button.dart';

/// Ota-onalar darvozasi: 6..9 oralig‘idagi ko‘paytirish savoli.
/// To‘g‘ri javob — `true` bilan yopiladi; noto‘g‘ri — yangi sonlar.
/// Fon bosilsa dialog bekor qilinadi (`null`).
Future<bool?> showParentGate(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (context) => const ParentGateDialog(),
  );
}

/// Ko‘paytirish savolli dialog kartasi.
class ParentGateDialog extends StatefulWidget {
  const ParentGateDialog({super.key});

  @override
  State<ParentGateDialog> createState() => _ParentGateDialogState();
}

class _ParentGateDialogState extends State<ParentGateDialog> {
  final _rng = Random();
  late int _a;
  late int _b;
  late List<int> _options;
  bool _wrong = false;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  /// Yangi sonlar va 4 ta variant (bittasi to‘g‘ri ko‘paytma).
  void _roll() {
    _a = 6 + _rng.nextInt(4);
    _b = 6 + _rng.nextInt(4);
    final correct = _a * _b;
    final set = <int>{correct};
    final candidates = [
      correct + _a,
      correct - _b,
      correct + _b,
      correct - _a,
      (_a + 1) * _b,
      _a * (_b - 1),
      correct + 2,
      correct - 3,
    ];
    for (final c in candidates) {
      if (set.length >= 4) break;
      if (c > 0) set.add(c);
    }
    _options = set.toList()..shuffle(_rng);
  }

  void _onPick(int value) {
    if (value == _a * _b) {
      AudioService.instance.play(Sfx.correct);
      Navigator.of(context).pop(true);
    } else {
      AudioService.instance.play(Sfx.thunk);
      setState(() {
        _wrong = true;
        _roll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: FarmColors.cardBorder, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.parentGateTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: FarmColors.inkOlive,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.parentGatePrompt(_a, _b),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: FarmColors.inkDark,
              ),
            ),
            if (_wrong) ...[
              const SizedBox(height: 6),
              Text(
                l10n.parentGateWrong,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: FarmColors.red,
                ),
              ),
            ],
            const SizedBox(height: 16),
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) const SizedBox(height: 10),
              Row(
                children: [
                  for (var col = 0; col < 2; col++) ...[
                    if (col > 0) const SizedBox(width: 10),
                    Expanded(child: _optionButton(_options[row * 2 + col])),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _optionButton(int value) {
    return ChunkyButton(
      color: FarmColors.blue,
      darkColor: FarmColors.blueDark,
      borderRadius: 14,
      ledge: 4,
      minHeight: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      onPressed: () => _onPick(value),
      child: Text(
        '$value',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
