import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/core/theme/tokens.dart';
import 'package:math_farm/widgets/chunky_button.dart';
import 'package:math_farm/widgets/icons.dart';
import 'package:math_farm/widgets/pill.dart';
import 'package:math_farm/widgets/progress_bar.dart';
import 'package:math_farm/widgets/speech_bubble.dart';

/// Dizayn-tizim vidjetlari testlari. pumpAndSettle ishlatilmaydi —
/// barcha pump’lar aniq davomiylik bilan chegaralangan.
Widget wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

/// ChunkyButton ichidagi jant-Padding (AnimatedOpacity ostidagi birinchi
/// Padding) — bosilganda top/bottom qiymatlari almashadi.
EdgeInsets ledgePadding(WidgetTester tester) {
  final padding = tester.widget<Padding>(
    find
        .descendant(of: find.byType(ChunkyButton), matching: find.byType(Padding))
        .first,
  );
  return padding.padding as EdgeInsets;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChunkyButton', () {
    testWidgets('tap fires onPressed and sends lightImpact haptic',
        (tester) async {
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      var pressed = 0;
      await tester.pumpWidget(wrap(ChunkyButton(
        color: FarmColors.green,
        onPressed: () => pressed++,
        child: const Text('OK'),
      )));

      platformCalls.clear();
      await tester.tap(find.byType(ChunkyButton));
      await tester.pump();

      expect(pressed, 1);
      expect(
        platformCalls.where((c) =>
            c.method == 'HapticFeedback.vibrate' &&
            c.arguments.toString().contains('lightImpact')),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('enabled=false: tap does not fire and no haptic is sent',
        (tester) async {
      final platformCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          platformCalls.add(call);
          return null;
        },
      );
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));

      var pressed = 0;
      await tester.pumpWidget(wrap(ChunkyButton(
        color: FarmColors.green,
        enabled: false,
        onPressed: () => pressed++,
        child: const Text('OK'),
      )));

      platformCalls.clear();
      await tester.tap(find.byType(ChunkyButton));
      await tester.pump();

      expect(pressed, 0);
      expect(
        platformCalls.where((c) => c.method == 'HapticFeedback.vibrate'),
        isEmpty,
      );
      // Bosilgan vizual holat ham yoqilmagan: jant joyida qoladi.
      expect(ledgePadding(tester), const EdgeInsets.only(bottom: 5));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dimmed=true: subtree fades to opacity .55 and stays tappable',
        (tester) async {
      var pressed = 0;
      Widget build({required bool dimmed}) => wrap(ChunkyButton(
            color: FarmColors.yellow,
            dimmed: dimmed,
            onPressed: () => pressed++,
            child: const Text('7'),
          ));

      await tester.pumpWidget(build(dimmed: false));
      final fadeFinder = find.descendant(
        of: find.byType(ChunkyButton),
        matching: find.byType(AnimatedOpacity),
      );
      expect(tester.widget<AnimatedOpacity>(fadeFinder).opacity, 1.0);

      // dimmed=true — nishon .55, 200ms ichida silliq o’tadi.
      await tester.pumpWidget(build(dimmed: true));
      expect(tester.widget<AnimatedOpacity>(fadeFinder).opacity, 0.55);
      await tester.pump(const Duration(milliseconds: 250));
      final fade = tester.widget<FadeTransition>(
        find.descendant(
          of: find.byType(ChunkyButton),
          matching: find.byType(FadeTransition),
        ),
      );
      expect(fade.opacity.value, moreOrLessEquals(0.55, epsilon: 0.001));

      // Xiralashgan javob BOSILADIGAN bo’lib qoladi (2-urinish xatti-harakati).
      await tester.tap(find.byType(ChunkyButton));
      await tester.pump();
      expect(pressed, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'press translate: down shifts body by ledge, layout height is stable',
        (tester) async {
      await tester.pumpWidget(wrap(ChunkyButton(
        color: FarmColors.blue,
        onPressed: () {},
        child: const Text('OK'),
      )));

      Container body() => tester.widget<Container>(
            find.descendant(
              of: find.byType(ChunkyButton),
              matching: find.byType(Container),
            ),
          );

      // Boshlang’ich: tana yuqorida, jant (soya) pastda 5px.
      expect(ledgePadding(tester), const EdgeInsets.only(bottom: 5));
      expect(
        (body().decoration! as BoxDecoration).boxShadow!.single.offset,
        const Offset(0, 5),
      );
      final sizeBefore = tester.getSize(find.byType(ChunkyButton));

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(ChunkyButton)));
      await tester.pump();

      // Bosilgan: tana pastga tushdi, jant yig’ildi — umumiy o’lcham o’zgarmas.
      expect(ledgePadding(tester), const EdgeInsets.only(top: 5));
      expect(
        (body().decoration! as BoxDecoration).boxShadow!.single.offset,
        Offset.zero,
      );
      expect(tester.getSize(find.byType(ChunkyButton)), sizeBefore);

      await gesture.up();
      await tester.pump();
      expect(ledgePadding(tester), const EdgeInsets.only(bottom: 5));
      expect(tester.getSize(find.byType(ChunkyButton)), sizeBefore);
      expect(tester.takeException(), isNull);
    });
  });

  group('StatPill', () {
    testWidgets('renders children with gap and padding', (tester) async {
      await tester.pumpWidget(wrap(const StatPill(
        gap: 7,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [Text('A'), Text('B'), Text('C')],
      )));

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);

      // Har bir qo’shni juftlik orasida aynan gap=7 masofa.
      final a = tester.getRect(find.text('A'));
      final b = tester.getRect(find.text('B'));
      final c = tester.getRect(find.text('C'));
      expect(b.left - a.right, 7);
      expect(c.left - b.right, 7);

      final container = tester.widget<Container>(
        find.descendant(of: find.byType(StatPill), matching: find.byType(Container)),
      );
      expect(container.padding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6));
      final deco = container.decoration! as BoxDecoration;
      expect(deco.color, Colors.white);
      expect(deco.borderRadius, BorderRadius.circular(999));
      expect(tester.takeException(), isNull);
    });
  });

  group('SpeechBubble', () {
    testWidgets('bottomLeft tail: below the bubble, 16px from the left',
        (tester) async {
      await tester.pumpWidget(wrap(const SpeechBubble(text: 'Salom!')));

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(SpeechBubble),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.left, 16);
      expect(positioned.bottom, -5);
      expect(find.text('Salom!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('leftBottom tail: on the left side, 8px from the bottom',
        (tester) async {
      await tester.pumpWidget(wrap(const SpeechBubble(
        text: 'Nechta jo’ja?',
        tail: BubbleTail.leftBottom,
      )));

      final positioned = tester.widget<Positioned>(
        find.descendant(
          of: find.byType(SpeechBubble),
          matching: find.byType(Positioned),
        ),
      );
      expect(positioned.left, -4);
      expect(positioned.bottom, 8);
      expect(tester.takeException(), isNull);
    });

    testWidgets('background color animates over 300ms', (tester) async {
      Widget bubble(Color bg) =>
          wrap(SpeechBubble(text: 'Hi', background: bg));

      Color bubbleColor() {
        final decorations = tester
            .widgetList<DecoratedBox>(find.descendant(
              of: find.byType(SpeechBubble),
              matching: find.byType(DecoratedBox),
            ))
            .map((b) => b.decoration)
            .whereType<BoxDecoration>();
        // Pufak tanasi soyali; dum soyasiz — shu bilan ajratamiz.
        return decorations.firstWhere((d) => d.boxShadow != null).color!;
      }

      await tester.pumpWidget(bubble(Colors.white));
      expect(bubbleColor(), Colors.white);

      await tester.pumpWidget(bubble(FarmColors.correctBg));
      await tester.pump(const Duration(milliseconds: 150));
      final mid = bubbleColor();
      expect(mid, isNot(Colors.white));
      expect(mid, isNot(FarmColors.correctBg));

      await tester.pump(const Duration(milliseconds: 200));
      expect(bubbleColor(), FarmColors.correctBg);
      expect(tester.takeException(), isNull);
    });
  });

  group('Icons', () {
    testWidgets('CoinIcon: coin circle with proportional border',
        (tester) async {
      await tester.pumpWidget(wrap(const CoinIcon(size: 28)));

      expect(tester.getSize(find.byType(CoinIcon)), const Size(28, 28));
      final container = tester.widget<Container>(
        find.descendant(of: find.byType(CoinIcon), matching: find.byType(Container)),
      );
      final deco = container.decoration! as BoxDecoration;
      expect(deco.shape, BoxShape.circle);
      expect(deco.color, FarmColors.coin);
      final border = deco.border! as Border;
      expect(border.top.color, FarmColors.coinBorder);
      expect(border.top.width, 28 * 3 / 14);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StreakFlameIcon: orange drop with coin core', (tester) async {
      await tester.pumpWidget(wrap(const StreakFlameIcon(size: 26)));

      expect(tester.getSize(find.byType(StreakFlameIcon)), const Size(26, 26));
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(StreakFlameIcon),
          matching: find.byType(Container),
        ),
      );
      expect(
        containers.where((c) =>
            (c.decoration as BoxDecoration?)?.color == FarmColors.streakOrange),
        hasLength(1),
      );
      expect(
        containers.where(
            (c) => (c.decoration as BoxDecoration?)?.color == FarmColors.coin),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('HeartIcon: filled and outline paint differently',
        (tester) async {
      await tester.pumpWidget(wrap(Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          HeartIcon(size: 20),
          HeartIcon(size: 20, filled: false),
          HeartIcon(size: 20),
        ],
      )));

      final paints = tester
          .widgetList<CustomPaint>(find.descendant(
            of: find.byType(HeartIcon),
            matching: find.byType(CustomPaint),
          ))
          .toList();
      expect(paints, hasLength(3));
      expect(paints[0].size, const Size(20, 20));

      // filled vs outline — painter qayta chizishni talab qiladi.
      expect(paints[0].painter!.shouldRepaint(paints[1].painter!), isTrue);
      // Bir xil konfiguratsiya — qayta chizish kerak emas.
      expect(paints[0].painter!.shouldRepaint(paints[2].painter!), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StarIcon: filled and dim paint differently', (tester) async {
      await tester.pumpWidget(wrap(Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          StarIcon(size: 16),
          StarIcon(size: 16, filled: false),
          StarIcon(size: 16),
        ],
      )));

      final paints = tester
          .widgetList<CustomPaint>(find.descendant(
            of: find.byType(StarIcon),
            matching: find.byType(CustomPaint),
          ))
          .toList();
      expect(paints, hasLength(3));
      expect(paints[0].size, const Size(16, 16));
      expect(paints[0].painter!.shouldRepaint(paints[1].painter!), isTrue);
      expect(paints[0].painter!.shouldRepaint(paints[2].painter!), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StarRatingPill: always 3 stars, filled count = stars',
        (tester) async {
      for (var stars = 0; stars <= 3; stars++) {
        await tester.pumpWidget(wrap(StarRatingPill(stars: stars)));

        final icons = tester.widgetList<StarIcon>(find.byType(StarIcon)).toList();
        expect(icons, hasLength(3), reason: 'stars=$stars');
        expect(
          icons.where((i) => i.filled).length,
          stars,
          reason: 'stars=$stars',
        );
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('GameProgressBar', () {
    /// Yashil gradientli to’ldirish konteynerining joriy kengligi.
    double fillWidth(WidgetTester tester) {
      final fill = find.descendant(
        of: find.byType(GameProgressBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).gradient != null,
          description: 'gradient fill container',
        ),
      );
      return tester.getSize(fill).width;
    }

    Widget bar(double fraction) =>
        wrap(SizedBox(width: 200, child: GameProgressBar(fraction: fraction)));

    testWidgets('fraction clamps below 0 and above 1', (tester) async {
      await tester.pumpWidget(bar(-0.5));
      final boxFinder = find.byType(AnimatedFractionallySizedBox);
      expect(
        tester.widget<AnimatedFractionallySizedBox>(boxFinder).widthFactor,
        0.0,
      );
      expect(fillWidth(tester), 0.0);

      await tester.pumpWidget(bar(1.5));
      expect(
        tester.widget<AnimatedFractionallySizedBox>(boxFinder).widthFactor,
        1.0,
      );
      // Animatsiya (400ms) tugagach to’liq kenglik — 200dan oshmaydi.
      await tester.pump(const Duration(milliseconds: 500));
      expect(fillWidth(tester), moreOrLessEquals(200, epsilon: 0.01));
      expect(tester.takeException(), isNull);
    });

    testWidgets('fill width animates towards the new fraction',
        (tester) async {
      await tester.pumpWidget(bar(0));
      expect(fillWidth(tester), 0.0);

      await tester.pumpWidget(bar(1));
      // 400ms easeOut o’tishning o’rtasi: 0 va 200 orasida qatiy oraliq.
      await tester.pump(const Duration(milliseconds: 200));
      final mid = fillWidth(tester);
      expect(mid, greaterThan(0.0));
      expect(mid, lessThan(200.0));

      await tester.pump(const Duration(milliseconds: 300));
      expect(fillWidth(tester), moreOrLessEquals(200, epsilon: 0.01));
      expect(tester.takeException(), isNull);
    });
  });

  group('TimerBar', () {
    testWidgets('fill scaleX follows the controller: 1.0 then 0.5 then 0.0',
        (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(seconds: 1),
        value: 1,
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        wrap(SizedBox(width: 220, child: TimerBar(animation: controller))),
      );

      double scaleX() {
        final transforms = tester.widgetList<Transform>(
          find.descendant(of: find.byType(TimerBar), matching: find.byType(Transform)),
        );
        // To’ldirish transformi centerLeft langarli; soat mili — translate.
        final fill =
            transforms.firstWhere((t) => t.alignment == Alignment.centerLeft);
        return fill.transform.storage[0];
      }

      final fillFinder = find.descendant(
        of: find.byType(TimerBar),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).gradient != null,
          description: 'gradient fill container',
        ),
      );
      // 220 - 18 (soat) - 8 (oraliq) = 194 — trekning to’liq kengligi.
      final fullWidth = tester.getSize(fillFinder).width;
      expect(fullWidth, 194.0);
      expect(scaleX(), 1.0);

      controller.reverse();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(scaleX(), moreOrLessEquals(0.5, epsilon: 0.01));

      await tester.pump(const Duration(milliseconds: 500));
      expect(scaleX(), moreOrLessEquals(0.0, epsilon: 0.001));
      // Paint-only transform: layout kengligi o’zgarmaydi (CSS scaleX kabi).
      expect(tester.getSize(fillFinder).width, fullWidth);

      // Simulyatsiya isDone qatiy «>» bilan tekshiradi — kontroller aynan
      // duration chegarasida hali «animating» holatida. Bitta qoshimcha kadr
      // bilan tugatamiz, aks holda dispose paytida ticker ochiq qoladi.
      await tester.pump(const Duration(milliseconds: 20));
      expect(scaleX(), 0.0);
      expect(tester.takeException(), isNull);
    });
  });
}
