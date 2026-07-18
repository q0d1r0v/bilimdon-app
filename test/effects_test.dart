import 'dart:ui' as ui;

import 'package:flame/components.dart' show ParticleSystemComponent;
import 'package:flame/game.dart' show GameWidget;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/characters/animal.dart';
import 'package:math_farm/characters/parts.dart';
import 'package:math_farm/effects/animal_life.dart';
import 'package:math_farm/effects/effects_layer.dart';

/// EffectsGame'ni GameWidget orqali mount qiladi (load + mount hayot
/// sikli), lekin dvigatel pauzada qoladi — vaqtni testlar game.update(dt)
/// bilan QO'LDA, deterministik yuritadi.
Future<EffectsGame> mountGame(WidgetTester tester) async {
  final game = EffectsGame();
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: GameWidget(game: game))),
  );
  for (var i = 0; i < 5 && !game.isMounted; i++) {
    await tester.pump();
  }
  expect(game.isMounted, isTrue);
  expect(tester.takeException(), isNull);
  return game;
}

int particleCount(EffectsGame game) =>
    game.children.whereType<ParticleSystemComponent>().length;

/// Bir kadr chizish — coinFly onArrive faqat renderer ichida chaqiriladi.
void renderFrame(EffectsGame game) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  game.render(canvas);
  recorder.endRecording().dispose();
}

/// Blink holatidagi ko'zni topadi (LivingAnimal pirpirash kadri).
final blinkEye = find.byWidgetPredicate(
  (w) => w is AnimalEye && w.expression == AnimalExpression.blink,
);

/// LivingAnimal'ni yopadi va uchayotgan blink Future.delayed
/// taymerlarini oqizadi — testlar osilib qolgan taymersiz tugaydi.
Future<void> disposeAndFlush(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(tester.takeException(), isNull);
}

/// LivingAnimal daraxtidagi birinchi Transform (preorder) — tashqi
/// Transform.translate (sakrash dy shu yerda).
Transform outerTranslate(WidgetTester tester) => tester.firstWidget<Transform>(
      find.descendant(
        of: find.byType(LivingAnimal),
        matching: find.byType(Transform),
      ),
    );

void main() {
  group('EffectsGame', () {
    test('engine starts paused right from the constructor', () {
      expect(EffectsGame().paused, isTrue);
    });

    testWidgets('confettiBurst wakes engine, adds a burst, then auto-pauses',
        (tester) async {
      final game = await mountGame(tester);
      expect(game.paused, isTrue);

      game.confettiBurst(const Offset(100, 100));
      expect(game.paused, isFalse, reason: 'effekt dvigatelni uyg’otadi');

      game.update(0); // lifecycle: komponent daraxtga o’tadi
      expect(particleCount(game), 1);

      // lifespan 0.85s — 1.2s dan keyin partikl yo’q va dvigatel pauzada.
      for (var i = 0; i < 12; i++) {
        game.update(0.1);
      }
      expect(particleCount(game), 0);
      expect(game.paused, isTrue, reason: 'partikllar tugagach auto-pauza');
      expect(tester.takeException(), isNull);
    });

    testWidgets('starSparkle adds three staggered sparkles and auto-pauses',
        (tester) async {
      final game = await mountGame(tester);

      game.starSparkle(const Offset(50, 60));
      expect(game.paused, isFalse);
      game.update(0);
      expect(particleCount(game), 3);

      // Maksimal lifespan 0.45 + 2*0.09 = 0.63s.
      for (var i = 0; i < 16; i++) {
        game.update(0.05);
      }
      expect(particleCount(game), 0);
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coinFly calls onArrive once per coin and auto-pauses',
        (tester) async {
      final game = await mountGame(tester);

      var arrivals = 0;
      game.coinFly(
        const Offset(50, 300),
        const Offset(300, 40),
        count: 3,
        onArrive: () => arrivals++,
      );
      expect(game.paused, isFalse);
      game.update(0);
      expect(particleCount(game), 3);

      // Maksimal lifespan 0.55 + 2*0.06 = 0.67s. onArrive renderer ichida
      // chaqiriladi — shuning uchun update va render almashib yuritiladi.
      for (var i = 0; i < 16; i++) {
        game.update(0.05);
        renderFrame(game);
      }
      expect(arrivals, 3, reason: 'har tanga bir marta yetib keladi');
      expect(particleCount(game), 0);
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('coinFly default count is 5 coins', (tester) async {
      final game = await mountGame(tester);
      game.coinFly(const Offset(10, 200), const Offset(200, 30));
      game.update(0);
      expect(particleCount(game), 5);

      // Maksimal lifespan 0.55 + 4*0.06 = 0.79s.
      for (var i = 0; i < 20; i++) {
        game.update(0.05);
      }
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('overlapping effects keep the engine awake until the last one',
        (tester) async {
      final game = await mountGame(tester);

      game.confettiBurst(const Offset(80, 80));
      for (var i = 0; i < 10; i++) {
        game.update(0.05); // t = 0.5
      }
      game.starSparkle(const Offset(120, 40)); // uchqunlar 0.5 da qo’shildi

      for (var i = 0; i < 8; i++) {
        game.update(0.05); // t = 0.9: konfetti (0.85) tugadi
      }
      expect(game.paused, isFalse,
          reason: 'uchqunlar hali tirik — pauza bo’lmasin');
      expect(particleCount(game), greaterThan(0));

      for (var i = 0; i < 8; i++) {
        game.update(0.05); // t = 1.3 > 0.5 + 0.63
      }
      expect(particleCount(game), 0);
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('EffectsOverlay: GameWidget under IgnorePointer, fills stack',
        (tester) async {
      final game = EffectsGame();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(children: [EffectsOverlay(game: game)]),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.byType(GameWidget<EffectsGame>), findsOneWidget);
      expect(
        find.ancestor(
          of: find.byType(GameWidget<EffectsGame>),
          matching: find.byType(IgnorePointer),
        ),
        findsWidgets,
        reason: 'overlay bosishlarni yutmasligi kerak',
      );
      // Effekt chaqirilmagan — dvigatel pauzada qolaveradi.
      expect(game.paused, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('LivingAnimal', () {
    testWidgets('blinks within the 2-6s window and opens eyes again',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(child: LivingAnimal(kind: FarmAnimal.cow, size: 100)),
          ),
        ),
      );

      // 80ms qadam < 160ms blink davomiyligi — blink kadri o’tkazib
      // yuborilmaydi. Maksimal birinchi blink 5999ms + 160ms < 8s.
      var found = false;
      for (var elapsed = 0; elapsed < 8000; elapsed += 80) {
        await tester.pump(const Duration(milliseconds: 80));
        if (tester.any(blinkEye)) {
          found = true;
          break;
        }
      }
      expect(found, isTrue, reason: '8s ichida kamida bitta blink kadri');
      expect(tester.widgetList(blinkEye).length, 2,
          reason: 'ikkala ko’z birga pirpiraydi');

      // 240ms dan keyin blink tugagan (160ms) va qo’sh-blink boshlanmagan
      // (birinchisidan keyin 250ms pauza bor) — ko’zlar yana idle.
      await tester.pump(const Duration(milliseconds: 240));
      expect(tester.any(blinkEye), isFalse);
      expect(
        tester
            .widgetList<AnimalEye>(find.byType(AnimalEye))
            .every((e) => e.expression == AnimalExpression.idle),
        isTrue,
      );
      expect(tester.takeException(), isNull);

      await disposeAndFlush(tester);
    });

    testWidgets('external happy expression always overrides blinking',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivingAnimal(
                kind: FarmAnimal.chick,
                size: 60,
                expression: AnimalExpression.happy,
              ),
            ),
          ),
        ),
      );

      // 6.4s — blink oynasi kafolatlangan; ko’zlar hech qachon blink emas.
      for (var elapsed = 0; elapsed < 6400; elapsed += 100) {
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.any(blinkEye), isFalse);
        expect(
          tester
              .widgetList<AnimalEye>(find.byType(AnimalEye))
              .every((e) => e.expression == AnimalExpression.happy),
          isTrue,
        );
      }
      expect(tester.takeException(), isNull);

      await disposeAndFlush(tester);
    });

    testWidgets('jumpTrigger change starts a jump inside the 630ms window',
        (tester) async {
      Widget host(int trigger) => MaterialApp(
            home: Scaffold(
              body: Center(
                child: LivingAnimal(
                  kind: FarmAnimal.pig,
                  size: 90,
                  jumpTrigger: trigger,
                ),
              ),
            ),
          );

      await tester.pumpWidget(host(0));
      await tester.pump(); // ticker t0
      expect(outerTranslate(tester).transform.storage[13], 0,
          reason: 'sakrashsiz dy = 0');

      await tester.pumpWidget(host(1)); // trigger o’zgardi -> sakrash
      await tester.pump(); // sakrash tickeri t0
      await tester.pump(const Duration(milliseconds: 250)); // t ~ 0.4
      final midJumpDy = outerTranslate(tester).transform.storage[13];
      expect(midJumpDy, lessThan(-5),
          reason: 'parvoz fazasida personaj yuqorida (dy < 0)');

      await tester.pump(const Duration(milliseconds: 500)); // > 630ms
      expect(outerTranslate(tester).transform.storage[13], 0,
          reason: 'qo’nishdan keyin dy yana 0');
      expect(tester.takeException(), isNull);

      await disposeAndFlush(tester);
    });

    testWidgets('disableAnimations freezes the breath transform',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
          home: const Scaffold(
            body: Center(child: LivingAnimal(kind: FarmAnimal.sheep, size: 46)),
          ),
        ),
      );
      await tester.pump();

      List<double> scaleMatrix() => tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(LivingAnimal),
              matching: find.byType(Transform),
            ),
          )
          .toList()[1]
          .transform
          .storage
          .toList();

      final before = scaleMatrix();
      await tester.pump(const Duration(milliseconds: 300));
      expect(scaleMatrix(), before, reason: 'nafas to’xtagan — matritsa qotgan');
      await tester.pump(const Duration(milliseconds: 300));
      expect(scaleMatrix(), before);
      expect(tester.takeException(), isNull);

      await disposeAndFlush(tester);
    });

    testWidgets('dispose mid-blink is safe', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: LivingAnimal(kind: FarmAnimal.chicken, size: 72),
            ),
          ),
        ),
      );

      // Blink kadrini kutamiz va AYNAN shu payt widgetni yo’q qilamiz.
      var found = false;
      for (var elapsed = 0; elapsed < 8000; elapsed += 80) {
        await tester.pump(const Duration(milliseconds: 80));
        if (tester.any(blinkEye)) {
          found = true;
          break;
        }
      }
      expect(found, isTrue);

      await disposeAndFlush(tester); // blink o’rtasida dispose — istisnosiz
    });

    testWidgets('every species lives briefly without exceptions',
        (tester) async {
      for (final kind in FarmAnimal.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: LivingAnimal(
                  key: ValueKey(kind),
                  kind: kind,
                  size: kind.baseWidth,
                ),
              ),
            ),
          ),
        );
        // 1s < 2s minimal blink oynasi — ichki taymer boshlanmaydi.
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(tester.takeException(), isNull, reason: '$kind tirik render');
      }
      await disposeAndFlush(tester);
    });
  });

  group('DriftingCloud', () {
    Widget cloudHost({double phase = 0, bool disableAnimations = false}) {
      final cloud = DriftingCloud(
        travelWidth: 300,
        period: const Duration(seconds: 10),
        initialPhase: phase,
        child: const SizedBox(width: 60, height: 30),
      );
      return MaterialApp(
        builder: disableAnimations
            ? (context, child) => MediaQuery(
                  data:
                      MediaQuery.of(context).copyWith(disableAnimations: true),
                  child: child!,
                )
            : null,
        home: Scaffold(body: Stack(children: [cloud])),
      );
    }

    double cloudX(WidgetTester tester) => tester
        .firstWidget<Transform>(
          find.descendant(
            of: find.byType(DriftingCloud),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .storage[12];

    testWidgets('translates left-to-right over pumps and wraps around',
        (tester) async {
      await tester.pumpWidget(cloudHost());
      await tester.pump(); // ticker t0

      // x = value * 300 - 60.
      expect(cloudX(tester), moreOrLessEquals(-60, epsilon: .1));

      await tester.pump(const Duration(milliseconds: 2500)); // value .25
      expect(cloudX(tester), moreOrLessEquals(15, epsilon: .1));

      await tester.pump(const Duration(milliseconds: 2500)); // value .5
      expect(cloudX(tester), moreOrLessEquals(90, epsilon: .1));

      // Yana 6s: value 1.1 % 1 = 0.1 — chapga qaytdi (wrap-around).
      await tester.pump(const Duration(milliseconds: 6000));
      expect(cloudX(tester), moreOrLessEquals(-30, epsilon: .1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('initialPhase offsets the starting position', (tester) async {
      await tester.pumpWidget(cloudHost(phase: .5));
      await tester.pump();
      expect(cloudX(tester), moreOrLessEquals(.5 * 300 - 60, epsilon: .1));
    });

    testWidgets('disableAnimations keeps the cloud parked', (tester) async {
      await tester.pumpWidget(cloudHost(phase: .5, disableAnimations: true));
      await tester.pump();
      expect(cloudX(tester), moreOrLessEquals(90, epsilon: .1));
      await tester.pump(const Duration(seconds: 3));
      expect(cloudX(tester), moreOrLessEquals(90, epsilon: .1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dispose mid-flight is safe', (tester) async {
      await tester.pumpWidget(cloudHost());
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    });
  });
}
