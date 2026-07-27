import 'package:flutter/material.dart';

import '../../content/models.dart';
import 'visual_hint_animals.dart';
import 'visual_hint_bars.dart';
import 'visual_hint_frame.dart';
import 'visual_hint_multiply.dart';
import 'visual_hint_numberline.dart';

/// Savol kartasidagi vizual ko‘rsatma — [VisualHint.kind] bo‘yicha mos
/// vidjetga yo‘naltiradi.
///
/// Har bir tur o‘z faylida yashaydi va o‘z ichida [HintFrame] bilan
/// o‘raladi (min balandlik 44, markazda). Bo‘sh natijada `SizedBox.shrink()`
/// qaytariladi — 44px joy REZERV QILINMAYDI, shuning uchun vizualsiz savolda
/// karta shunchaki qisqaradi.
///
/// Yangi tur qo‘shilganda `switch` shu yerda kompilyatsiya xatosi beradi —
/// `default` ATAYLAB yozilmagan.
class VisualHintRow extends StatelessWidget {
  const VisualHintRow({super.key, required this.visual, this.pulseTick = 0});

  final VisualHint visual;

  /// Har oshirilganda «birga sanaymiz» pulsi qayta ishga tushadi.
  final int pulseTick;

  @override
  Widget build(BuildContext context) {
    switch (visual.kind) {
      case VisualKind.count:
      case VisualKind.grouped:
      case VisualKind.faded:
        return AnimalHintRow(visual: visual, pulseTick: pulseTick);
      case VisualKind.numberLine:
        return NumberLineHint(visual: visual, pulseTick: pulseTick);
      case VisualKind.bars:
        return CompareBarsHint(visual: visual, pulseTick: pulseTick);
      case VisualKind.tenFrame:
        return TenFrameHint(visual: visual, pulseTick: pulseTick);
      case VisualKind.groupRows:
        return GroupRowsHint(visual: visual, pulseTick: pulseTick);
      case VisualKind.none:
        return const SizedBox.shrink();
    }
  }
}
