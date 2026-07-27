import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import 'hint_animator.dart';

/// Hayvon qatoridagi bitta element: hayvon yoki «+» belgisi.
class _HintEntry {
  const _HintEntry.animal(this.animal, {this.faded = false}) : isPlus = false;

  const _HintEntry.plus()
      : animal = null,
        faded = false,
        isPlus = true;

  final FarmAnimal? animal;
  final bool faded;
  final bool isPlus;
}

/// Hayvonli vizual ko‘rsatmalar: [VisualKind.count], [VisualKind.grouped],
/// [VisualKind.faded]. Wrap, gap 8, markazda (DESIGN_SPEC «Ekran 2»).
///
/// Xira hayvonlar pulsatsiya qilmaydi — ayirishda «olib tashlanganlar»
/// urg‘ulanmasligi kerak.
class AnimalHintRow extends StatelessWidget {
  const AnimalHintRow({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;
  final int pulseTick;

  static FarmAnimal _toFarmAnimal(HintAnimal a) => switch (a) {
        HintAnimal.chick => FarmAnimal.chick,
        HintAnimal.pig => FarmAnimal.pig,
        HintAnimal.sheep => FarmAnimal.sheep,
      };

  /// Prototip o‘lchamlari: jo‘ja 40, cho‘chqa 45 (scale .5), qo‘y 46.
  static double _hintSize(FarmAnimal a) => switch (a) {
        FarmAnimal.chick => 40,
        FarmAnimal.pig => 45,
        FarmAnimal.sheep => 46,
        _ => 44,
      };

  static List<_HintEntry> _buildEntries(VisualHint v) {
    final animal = v.animal == null ? null : _toFarmAnimal(v.animal!);
    if (animal == null) return const [];
    switch (v.kind) {
      case VisualKind.count:
        return [
          for (var i = 0; i < (v.count ?? 0); i++) _HintEntry.animal(animal),
        ];
      case VisualKind.grouped:
        final groups = v.groups ?? const [];
        if (groups.length < 2) return const [];
        return [
          for (var i = 0; i < groups[0]; i++) _HintEntry.animal(animal),
          const _HintEntry.plus(),
          for (var i = 0; i < groups[1]; i++) _HintEntry.animal(animal),
        ];
      case VisualKind.faded:
        final count = v.count ?? 0;
        final faded = v.faded ?? 0;
        return [
          for (var i = 0; i < count; i++)
            _HintEntry.animal(animal, faded: i >= count - faded),
        ];
      // Bu turlar dispatcher tomonidan boshqa vidjetlarga yo‘naltiriladi va
      // bu yerga umuman kelmaydi (`groupRows` ham hayvonli, lekin qator-qator
      // joylashuvi `Wrap` ga sig‘maydi — o‘z vidjeti bor).
      case VisualKind.groupRows:
      case VisualKind.tenFrame:
      case VisualKind.numberLine:
      case VisualKind.bars:
      case VisualKind.none:
        return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = _buildEntries(visual);
    if (entries.isEmpty) return const SizedBox.shrink();
    final solidCount = entries.where((e) => !e.isPlus && !e.faded).length;

    return HintFrame(
      child: HintAnimator(
        itemCount: entries.length,
        pulseCount: solidCount,
        pulseTick: pulseTick,
        builder: (context, item) {
          final children = <Widget>[];
          var solidOrder = 0;
          for (var i = 0; i < entries.length; i++) {
            final e = entries[i];
            final Widget content;
            if (e.isPlus) {
              content = const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '+',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: FarmColors.red,
                  ),
                ),
              );
            } else {
              content = buildAnimal(
                e.animal!,
                size: _hintSize(e.animal!),
                faded: e.faded,
              );
            }
            final pulses = !e.isPlus && !e.faded;
            children.add(
              item(
                i,
                pulseOrder: pulses ? solidOrder++ : null,
                child: content,
              ),
            );
          }
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: children,
          );
        },
      ),
    );
  }
}
