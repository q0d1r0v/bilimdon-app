import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/characters/chick.dart';
import 'package:math_farm/characters/pig.dart';
import 'package:math_farm/characters/sheep.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/core/theme/tokens.dart';
import 'package:math_farm/features/game/visual_hint_bars.dart';
import 'package:math_farm/features/game/visual_hint_frame.dart';
import 'package:math_farm/features/game/visual_hint_multiply.dart';
import 'package:math_farm/features/game/visual_hint_row.dart';

/// Savol kartasining haqiqiy ichki kengligi: 320dp ekranda `ekran − 70`.
const _cardWidth = 250.0;

/// Yangi vizuallar balandlik budjeti. 360×640 da javob tugmalari skrollsiz
/// yetishi uchun. Mavjud eng yomon holat (12 cho‘chqa) 139px — yangi turlar
/// undan yaxshi bo‘lishi kerak.
const _heightBudget = 96.0;

/// `GroupRowsHint` dagi jo‘ja maksimal kengligi.
const _maxChickSize = 34.0;

/// Ilovada cheksiz animatsiyalar bor — `pumpAndSettle` ISHLATILMAYDI
/// (README qoidasi). Faqat chegaralangan `pump(duration)`.
Future<void> _pumpHint(
  WidgetTester tester,
  VisualHint visual, {
  int pulseTick = 0,
}) async {
  await tester.pumpWidget(
    _harness(VisualHintRow(visual: visual, pulseTick: pulseTick)),
  );
  expect(tester.takeException(), isNull);
}

/// `question_card.dart:57-90` ni takrorlaydi: vizual `Column(mainAxisSize.min)`
/// ichida yashaydi, ya‘ni balandlik CHEKLANMAGAN. Bu muhim — cheklangan
/// balandlikda `HintFrame` ichidagi `Center` bo‘sh joyni to‘liq egallaydi.
Widget _harness(Widget hint) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _cardWidth,
            child: Column(mainAxisSize: MainAxisSize.min, children: [hint]),
          ),
        ),
      ),
    );

/// [i]-elementning pop/puls `Transform` shkalasi. `HintAnimator` har elementga
/// `hint-item-$i` kaliti qo‘yadi — vizual ichidagi boshqa `Transform` lar
/// (masalan `cssBox` burchagi) bilan chalkashmaslik uchun.
///
/// `storage[0]` (X shkalasi) o‘qiladi, `getMaxScaleOnAxis()` EMAS:
/// `Transform.scale` Z o‘qini 1.0 qoldiradi, shuning uchun 1 dan kichik
/// shkalalarda u noto‘g‘ri 1.0 qaytaradi.
double _scaleOf(WidgetTester tester, int i) {
  final transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byKey(ValueKey('hint-item-$i')),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.storage[0];
}

/// `pulseTick` ni tashqaridan oshirish uchun kichik harness.
class _TickHarness extends StatefulWidget {
  const _TickHarness({required this.visual});

  final VisualHint visual;

  @override
  State<_TickHarness> createState() => _TickHarnessState();
}

class _TickHarnessState extends State<_TickHarness> {
  int tick = 0;

  void bump() => setState(() => tick++);

  @override
  Widget build(BuildContext context) =>
      _harness(VisualHintRow(visual: widget.visual, pulseTick: tick));
}

void main() {
  group('hayvonli vizuallar (refaktor baseline)', () {
    testWidgets('count: n ta hayvon chiziladi, xira yo‘q', (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.count,
          animal: HintAnimal.chick,
          count: 4,
        ),
      );
      expect(find.byType(ChickWidget), findsNWidgets(4));
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('grouped: a + b hayvon va bitta «+» belgisi', (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.grouped,
          animal: HintAnimal.pig,
          groups: [3, 2],
        ),
      );
      expect(find.byType(PigWidget), findsNWidgets(5));
      expect(find.text('+'), findsOneWidget);
    });

    testWidgets('faded: oxirgi f ta hayvon Opacity .25 bilan', (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.faded,
          animal: HintAnimal.sheep,
          count: 5,
          faded: 2,
        ),
      );
      expect(find.byType(SheepWidget), findsNWidgets(5));
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities, hasLength(2));
      for (final o in opacities) {
        expect(o.opacity, .25);
      }
    });

    testWidgets('none: joy REZERV QILINMAYDI (balandlik 0)', (tester) async {
      await _pumpHint(tester, const VisualHint(kind: VisualKind.none));
      expect(
        tester.getSize(find.byType(VisualHintRow)).height,
        0,
        reason: 'vizualsiz savolda karta qisqarishi kerak, 44px rezerv emas',
      );
    });

    testWidgets('buzuq vizual jimgina bo‘sh qaytaradi (mudofaa guardlari)',
        (tester) async {
      // animal yo‘q — count chizilmaydi.
      await _pumpHint(tester, const VisualHint(kind: VisualKind.count, count: 3));
      expect(find.byType(ChickWidget), findsNothing);
      // grouped bitta guruh bilan.
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.grouped,
          animal: HintAnimal.pig,
          groups: [3],
        ),
      );
      expect(find.byType(PigWidget), findsNothing);
    });

    testWidgets('eng yomon holat: 12 cho‘chqa 3 qatorga, balandlik 139',
        (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.count,
          animal: HintAnimal.pig,
          count: 12,
        ),
      );
      expect(find.byType(PigWidget), findsNWidgets(12));
      final size = tester.getSize(find.byType(VisualHintRow));
      expect(size.width, lessThanOrEqualTo(_cardWidth));
      expect(
        size.height,
        closeTo(139, 1),
        reason: 'DESIGN_SPEC baseline — yangi vizuallar budjeti shundan kelib chiqadi',
      );
    });
  });

  group('numberLine', () {
    for (final (terms, step) in const [
      ([3, 4, 5], 1),
      ([2, 4, 6], 2),
      ([5, 10, 15], 5),
      ([10, 9, 8], -1),
      ([14, 16, 18], 2),
    ]) {
      testWidgets('terms=$terms step=$step budjetga sig‘adi', (tester) async {
        await _pumpHint(
          tester,
          VisualHint(
            kind: VisualKind.numberLine,
            terms: terms,
            step: step,
          ),
        );
        final size = tester.getSize(find.byType(VisualHintRow));
        expect(size.width, lessThanOrEqualTo(_cardWidth));
        expect(size.height, lessThanOrEqualTo(_heightBudget));
        // Har had + «?» ko‘rinadi.
        for (final t in terms) {
          expect(find.text('$t'), findsOneWidget);
        }
        expect(find.text('?'), findsOneWidget);
        // Qadam yorlig‘i har konnektorda.
        final label = step > 0 ? '+$step' : '−${-step}';
        expect(find.text(label), findsNWidgets(terms.length));
      });
    }

    testWidgets('manfiy qadam U+2212 minus bilan yoziladi', (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.numberLine,
          terms: [10, 9, 8],
          step: -1,
        ),
      );
      expect(find.text('−1'), findsNWidgets(3));
      expect(find.text('-1'), findsNothing, reason: 'ASCII defis emas');
    });
  });

  group('bars', () {
    for (final values in const [
      [16, 9, 17, 18],
      [5, 5, 5, 20],
      [19, 20, 18, 17],
      [12, 5, 9, 11],
      [0, 1, 19, 20],
    ]) {
      testWidgets('values=$values budjetga sig‘adi', (tester) async {
        await _pumpHint(
          tester,
          VisualHint(kind: VisualKind.bars, values: values),
        );
        final size = tester.getSize(find.byType(VisualHintRow));
        expect(size.width, lessThanOrEqualTo(_cardWidth));
        expect(size.height, lessThanOrEqualTo(_heightBudget));
        // Har son yorliq sifatida ko‘rinadi (takrorlar ham).
        for (final v in values.toSet()) {
          expect(
            find.text('$v'),
            findsNWidgets(values.where((x) => x == v).length),
          );
        }
      });
    }

    test('balandlik songa proporsional, o‘rin bo‘yicha EMAS', () {
      // 17 va 18 yaqin → balandliklari ham yaqin bo‘lishi shart.
      final h17 = CompareBarsHint.barHeight(17, 18);
      final h18 = CompareBarsHint.barHeight(18, 18);
      expect(h18 - h17, lessThan(5), reason: 'matematik halol nisbat');
      // Yarmi — yarim balandlik.
      expect(CompareBarsHint.barHeight(10, 20), closeTo(26, 0.01));
      // 0 ham ko‘rinadi (minimum 8).
      expect(CompareBarsHint.barHeight(0, 20), 8);
      // Eng katta — to‘liq balandlik.
      expect(CompareBarsHint.barHeight(20, 20), 52);
    });

    test('ustun kengligi cheklovlar ichida qoladi', () {
      expect(CompareBarsHint.barWidth(250, 4), 36); // keng ekranda maksimum
      expect(CompareBarsHint.barWidth(120, 4), 22); // tor ekranda minimum
    });
  });

  group('tenFrame', () {
    testWidgets('barcha yig‘indilar 1..20 budjetga sig‘adi (qo‘shish)',
        (tester) async {
      for (var sum = 2; sum <= 20; sum++) {
        final a = (sum / 2).ceil();
        await _pumpHint(
          tester,
          VisualHint(kind: VisualKind.tenFrame, groups: [a, sum - a]),
        );
        final size = tester.getSize(find.byType(VisualHintRow));
        expect(size.width, lessThanOrEqualTo(_cardWidth), reason: 'sum=$sum');
        expect(
          size.height,
          lessThanOrEqualTo(_heightBudget),
          reason: 'sum=$sum',
        );
      }
    });

    testWidgets('ayirish: oxirgi b katak xira', (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(kind: VisualKind.tenFrame, groups: [15], faded: 4),
      );
      final opacities = tester.widgetList<Opacity>(find.byType(Opacity));
      expect(opacities, hasLength(4));
      for (final o in opacities) {
        expect(o.opacity, .25);
      }
      final size = tester.getSize(find.byType(VisualHintRow));
      expect(size.height, lessThanOrEqualTo(_heightBudget));
    });

    testWidgets('yetishmayotgan operand: target oralig‘i sariq halqa',
        (tester) async {
      // 7 + ? = 11 → 7 to‘la, 8..11 sariq halqa (4 ta).
      await _pumpHint(
        tester,
        const VisualHint(kind: VisualKind.tenFrame, groups: [7], target: 11),
      );
      final rings = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
        final d = c.decoration;
        return d is BoxDecoration &&
            d.border is Border &&
            (d.border! as Border).top.color == FarmColors.yellow;
      });
      expect(rings, hasLength(4), reason: '8, 9, 10, 11 — yana 4 ta kerak');
    });

    testWidgets('10 gacha bitta ramka, 10 dan oshsa ikkita', (tester) async {
      expect(TenFrameHint.framesFor(9), 1);
      expect(TenFrameHint.framesFor(10), 1);
      expect(TenFrameHint.framesFor(11), 2);
      // target 10 dan oshsa ham ikkinchi ramka kerak (3 + ? = 12).
      await _pumpHint(
        tester,
        const VisualHint(kind: VisualKind.tenFrame, groups: [3], target: 12),
      );
      expect(tester.getSize(find.byType(VisualHintRow)).width,
          lessThanOrEqualTo(_cardWidth));
    });

    test('katak o‘lchami cheklovlar ichida', () {
      expect(TenFrameHint.cellSize(250, 2), closeTo(19.4, 0.1));
      expect(TenFrameHint.cellSize(250, 1), 26); // keng — maksimum
      expect(TenFrameHint.cellSize(120, 2), 14); // tor — minimum
    });
  });

  group('groupRows', () {
    // Kontentda a ∈ {2, 3} (generator `a <= 3` guardi bilan kafolatlanadi):
    // 3 qator 96px budjetga aynan sig‘adi. a = 4 uchun quyida alohida test.
    testWidgets('barcha a≤3, b≤10, a·b≤20 kombinatsiyasi budjetga sig‘adi',
        (tester) async {
      var checked = 0;
      for (var a = 2; a <= 3; a++) {
        for (var b = 1; b <= 10; b++) {
          if (a * b > 20) continue;
          await _pumpHint(
            tester,
            VisualHint(
              kind: VisualKind.groupRows,
              animal: HintAnimal.chick,
              groups: List<int>.filled(a, b),
            ),
          );
          final size = tester.getSize(find.byType(VisualHintRow));
          expect(
            size.width,
            lessThanOrEqualTo(_cardWidth),
            reason: '$a × $b kenglikka sig‘maydi',
          );
          expect(
            size.height,
            lessThanOrEqualTo(_heightBudget),
            reason: '$a × $b balandlik budjetidan oshdi',
          );
          expect(find.byType(ChickWidget), findsNWidgets(a * b));
          checked++;
        }
      }
      expect(checked, greaterThan(12), reason: 'sweep haqiqatan ishlagani');
    });

    testWidgets('a=4 budjetdan oshadi, lekin mavjud eng yomon holatdan yaxshi',
        (tester) async {
      // 4 qatorda o‘qiladigan jo‘ja o‘lchami (min 18px) 96px ga sig‘maydi.
      // Kontentda bunday holat YO‘Q (generator `a <= 3` bilan cheklaydi), lekin
      // agar paydo bo‘lsa — 121px, ya‘ni 12 cho‘chqali mavjud holatdan (139px)
      // baribir yaxshi va `SingleChildScrollView` overflow bermaydi.
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.groupRows,
          animal: HintAnimal.chick,
          groups: [5, 5, 5, 5],
        ),
      );
      final height = tester.getSize(find.byType(VisualHintRow)).height;
      expect(height, greaterThan(_heightBudget));
      expect(height, lessThan(139), reason: 'mavjud baseline’dan yaxshi qolsin');
    });

    testWidgets('guruhlar alohida qutilarda, hech biri bo‘linmaydi',
        (tester) async {
      await _pumpHint(
        tester,
        const VisualHint(
          kind: VisualKind.groupRows,
          animal: HintAnimal.chick,
          groups: [2, 2, 2],
        ),
      );
      // Har guruh — bitta yumshoq yashil quti.
      final boxes = tester.widgetList<Container>(find.byType(Container)).where(
            (c) =>
                c.decoration is BoxDecoration &&
                (c.decoration! as BoxDecoration).color ==
                    FarmColors.tagGreenBg,
          );
      expect(boxes, hasLength(3), reason: '3 guruh = 3 quti');
      // Wrap ISHLATILMAYDI — guruh ikki qatorga bo‘linmasligi kafolati.
      expect(find.byType(Wrap), findsNothing);
    });

    test('jo‘ja o‘lchami budjetdan hisoblanadi', () {
      // 3 qator — balandlik cheklovi hal qiladi.
      expect(GroupRowsHint.chickSize(250, 3, 6), closeTo(20, 0.5));
      // 2 qator, 9 ustun — kenglik cheklovi hal qiladi.
      expect(GroupRowsHint.chickSize(250, 2, 9), closeTo(22.7, 0.5));
      // 2×2 — maksimumga yetadi.
      expect(GroupRowsHint.chickSize(250, 2, 2), _maxChickSize);
    });
  });

  group('animatsiya tirikligi', () {
    const visual = VisualHint(
      kind: VisualKind.count,
      animal: HintAnimal.chick,
      count: 3,
    );

    testWidgets('pop: t=0 da shkala .6, oxirida aynan 1', (tester) async {
      await _pumpHint(tester, visual);
      expect(
        _scaleOf(tester, 0),
        closeTo(0.6, 0.001),
        reason: 'pop-in .6 dan boshlanadi (DESIGN_SPEC)',
      );
      // Pop davomiyligi: 60*(n-1) + 180 = 300ms.
      await tester.pump(const Duration(milliseconds: 320));
      expect(_scaleOf(tester, 0), closeTo(1, 0.001));
    });

    testWidgets('stagger: 2-element 1-elementdan keyin ko‘tariladi',
        (tester) async {
      await _pumpHint(tester, visual);
      // 60ms — 1-element pop o‘rtasida, 3-element hali boshlanmagan.
      await tester.pump(const Duration(milliseconds: 60));
      expect(_scaleOf(tester, 0), greaterThan(_scaleOf(tester, 2)));
    });

    testWidgets('pulseTick oshirilsa hayvonlar pulsatsiya qiladi',
        (tester) async {
      await tester.pumpWidget(const _TickHarness(visual: visual));
      await tester.pump(const Duration(milliseconds: 320)); // pop tugadi
      expect(_scaleOf(tester, 0), closeTo(1, 0.001));

      tester.state<_TickHarnessState>(find.byType(_TickHarness)).bump();
      await tester.pump();
      // Birinchi element o‘z 250ms oynasining o‘rtasida 1.15 ga chiqadi.
      await tester.pump(const Duration(milliseconds: 125));
      expect(
        _scaleOf(tester, 0),
        greaterThan(1.05),
        reason: '«kel, birga sanaymiz» pulsi o‘lib qolmasligi kerak',
      );
    });
  });
}
