import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/characters/animal.dart';
import 'package:math_farm/characters/chick.dart';
import 'package:math_farm/characters/chicken.dart';
import 'package:math_farm/characters/cow.dart';
import 'package:math_farm/characters/duck.dart';
import 'package:math_farm/characters/parts.dart';
import 'package:math_farm/characters/pig.dart';
import 'package:math_farm/characters/rabbit.dart';
import 'package:math_farm/characters/sheep.dart';
import 'package:math_farm/core/utils/css_shapes.dart';

/// Har tur uchun konkret widget klassi.
const speciesType = <FarmAnimal, Type>{
  FarmAnimal.cow: CowWidget,
  FarmAnimal.pig: PigWidget,
  FarmAnimal.sheep: SheepWidget,
  FarmAnimal.chicken: ChickenWidget,
  FarmAnimal.chick: ChickWidget,
  FarmAnimal.duck: DuckWidget,
  FarmAnimal.rabbit: RabbitWidget,
};

/// Ko‘z soni: o‘rdak yon profilda — 1 ko‘z; qolganlari old ko‘rinishda 2 ko‘z.
int expectedEyes(FarmAnimal kind) => kind == FarmAnimal.duck ? 1 : 2;

Future<void> pumpAnimal(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
  expect(tester.takeException(), isNull);
}

/// Birinchi AnimalEye ichki daraxtining imzosi: (Transform soni,
/// CustomPaint soni, DecoratedBox soni). Har ifoda o'ziga xos imzo
/// beradi — subtree haqiqatan FARQLI ekanini isbotlaydi.
({int transforms, int paints, int boxes}) eyeSignature(WidgetTester tester) {
  final eye = find.byType(AnimalEye).first;
  int count(Finder inner) =>
      tester.widgetList(find.descendant(of: eye, matching: inner)).length;
  return (
    transforms: count(find.byType(Transform)),
    paints: count(find.byType(CustomPaint)),
    boxes: count(find.byType(DecoratedBox)),
  );
}

/// Birinchi ko'z ichida scaleY = [sy] bo'lgan sof masshtab Transform
/// bormi (scaleX = 1 — Transform.scale(scaleY: ...) imzosi).
bool eyeHasScaleY(WidgetTester tester, double sy) {
  final eye = find.byType(AnimalEye).first;
  return tester
      .widgetList<Transform>(
        find.descendant(of: eye, matching: find.byType(Transform)),
      )
      .any(
        (t) =>
            (t.transform.storage[5] - sy).abs() < 1e-9 &&
            (t.transform.storage[0] - 1).abs() < 1e-9,
      );
}

/// Tur ildizi ichidagi (DecoratedBox, TriangleWidget) soni — aksessuar
/// delta-hisobi uchun.
(int, int) partCounts(WidgetTester tester, FarmAnimal kind) {
  final root = find.byType(speciesType[kind]!);
  int count(Finder inner) =>
      tester.widgetList(find.descendant(of: root, matching: inner)).length;
  return (count(find.byType(DecoratedBox)), count(find.byType(TriangleWidget)));
}

void main() {
  group('AnimalExpression subtree', () {
    // Kutilgan imzolar: idle — transformsiz ochiq ellips; blink — scaleY .1
    // masshtab; happy — faqat CustomPaint yoy; sad — scaleY .8 + qoshcha.
    const expected = <AnimalExpression, (int, int, int)>{
      AnimalExpression.idle: (0, 0, 2),
      AnimalExpression.blink: (1, 0, 2),
      AnimalExpression.happy: (0, 1, 0),
      AnimalExpression.sad: (2, 0, 3),
    };

    for (final kind in FarmAnimal.values) {
      testWidgets('$kind renders each expression with a distinct eye subtree',
          (tester) async {
        final signatures = <(int, int, int)>{};
        for (final expression in AnimalExpression.values) {
          await pumpAnimal(
            tester,
            buildAnimal(kind, size: kind.baseWidth, expression: expression),
          );

          // Ifoda ikkala ko'zga ham yetib boradi.
          final eyes =
              tester.widgetList<AnimalEye>(find.byType(AnimalEye)).toList();
          expect(eyes.length, expectedEyes(kind),
              reason: '$kind $expression: ${expectedEyes(kind)} ta ko’z kerak');
          for (final eye in eyes) {
            expect(eye.expression, expression);
          }

          final sig = eyeSignature(tester);
          final tuple = (sig.transforms, sig.paints, sig.boxes);
          expect(
            tuple,
            expected[expression],
            reason: '$kind $expression eye signature',
          );
          signatures.add(tuple);

          // Parametr darajasidagi qo'shimcha tekshiruvlar.
          switch (expression) {
            case AnimalExpression.blink:
              expect(eyeHasScaleY(tester, .1), isTrue,
                  reason: '$kind blink: scaleY .1 Transform kerak');
            case AnimalExpression.sad:
              expect(eyeHasScaleY(tester, .8), isTrue,
                  reason: '$kind sad: scaleY .8 Transform kerak');
            case AnimalExpression.idle || AnimalExpression.happy:
              break;
          }
        }
        // 4 ifoda — 4 xil imzo.
        expect(signatures.length, AnimalExpression.values.length);
      });
    }
  });

  group('AnimalAccessory', () {
    // Egasi va kutilgan delta: (+DecoratedBox, +TriangleWidget).
    const owner = <AnimalAccessory, FarmAnimal>{
      AnimalAccessory.cowHat: FarmAnimal.cow,
      AnimalAccessory.chickBow: FarmAnimal.chick,
      AnimalAccessory.pigGlasses: FarmAnimal.pig,
      AnimalAccessory.sheepScarf: FarmAnimal.sheep,
    };
    const delta = <AnimalAccessory, (int, int)>{
      AnimalAccessory.cowHat: (2, 0),
      AnimalAccessory.chickBow: (3, 2),
      AnimalAccessory.pigGlasses: (3, 0),
      AnimalAccessory.sheepScarf: (1, 0),
    };

    for (final kind in FarmAnimal.values) {
      testWidgets(
          '$kind: own accessory adds parts, foreign ones are ignored',
          (tester) async {
        await pumpAnimal(
          tester,
          buildAnimal(kind, size: kind.baseWidth),
        );
        final (baseBoxes, baseTris) = partCounts(tester, kind);

        for (final accessory in AnimalAccessory.values) {
          if (accessory == AnimalAccessory.none) continue;
          await pumpAnimal(
            tester,
            buildAnimal(kind, size: kind.baseWidth, accessory: accessory),
          );
          final (boxes, tris) = partCounts(tester, kind);
          final (dBoxes, dTris) =
              owner[accessory] == kind ? delta[accessory]! : (0, 0);
          expect(
            (boxes - baseBoxes, tris - baseTris),
            (dBoxes, dTris),
            reason: '$kind + $accessory delta',
          );
        }
      });
    }
  });

  group('buildAnimal', () {
    test('maps every FarmAnimal to its widget and forwards params', () {
      expect(buildAnimal(FarmAnimal.cow), isA<CowWidget>());
      expect(buildAnimal(FarmAnimal.pig), isA<PigWidget>());
      expect(buildAnimal(FarmAnimal.sheep), isA<SheepWidget>());
      expect(buildAnimal(FarmAnimal.chicken), isA<ChickenWidget>());
      expect(buildAnimal(FarmAnimal.chick), isA<ChickWidget>());

      final cow = buildAnimal(
        FarmAnimal.cow,
        size: 123,
        expression: AnimalExpression.happy,
        accessory: AnimalAccessory.cowHat,
      ) as CowWidget;
      expect(cow.size, 123);
      expect(cow.expression, AnimalExpression.happy);
      expect(cow.accessory, AnimalAccessory.cowHat);

      // Standart kenglik 60 px.
      expect((buildAnimal(FarmAnimal.pig) as PigWidget).size, 60);
    });

    test('faded wraps the animal in Opacity .25', () {
      final w = buildAnimal(FarmAnimal.sheep, faded: true);
      expect(w, isA<Opacity>());
      final opacity = w as Opacity;
      expect(opacity.opacity, .25);
      expect(opacity.child, isA<SheepWidget>());
    });

    test('mirrored wraps the animal in a horizontal Transform.flip', () {
      final w = buildAnimal(FarmAnimal.chick, mirrored: true);
      expect(w, isA<Transform>());
      final flip = w as Transform;
      expect(flip.transform.storage[0], -1); // flipX
      expect(flip.transform.storage[5], 1); // Y tegmagan
      expect(flip.child, isA<ChickWidget>());
    });

    test('faded + mirrored: Opacity outside, flip inside', () {
      final w = buildAnimal(FarmAnimal.pig, faded: true, mirrored: true);
      final opacity = w as Opacity;
      expect(opacity.opacity, .25);
      final flip = opacity.child as Transform;
      expect(flip.transform.storage[0], -1);
      expect(flip.child, isA<PigWidget>());
    });

    testWidgets('faded and mirrored variants render without exceptions',
        (tester) async {
      for (final kind in FarmAnimal.values) {
        await pumpAnimal(tester, buildAnimal(kind, faded: true));
        await pumpAnimal(tester, buildAnimal(kind, mirrored: true));
        await pumpAnimal(
          tester,
          buildAnimal(kind, faded: true, mirrored: true),
        );
      }
    });
  });

  group('FarmAnimalGeometry', () {
    test('base sizes match the prototype spec', () {
      expect(FarmAnimal.cow.baseWidth, 100);
      expect(FarmAnimal.cow.baseHeight, 92);
      expect(FarmAnimal.pig.baseWidth, 90);
      expect(FarmAnimal.pig.baseHeight, 82);
      expect(FarmAnimal.sheep.baseWidth, 46);
      expect(FarmAnimal.sheep.baseHeight, 42);
      expect(FarmAnimal.chicken.baseWidth, 72);
      expect(FarmAnimal.chicken.baseHeight, 84);
      expect(FarmAnimal.chick.baseWidth, 40);
      expect(FarmAnimal.chick.baseHeight, 44);
      for (final kind in FarmAnimal.values) {
        expect(kind.aspect, closeTo(kind.baseHeight / kind.baseWidth, 1e-9));
      }
    });

    testWidgets('rendered widget size = size x aspect for every species',
        (tester) async {
      for (final kind in FarmAnimal.values) {
        // Baza kenglikda: aynan spec o'lchami.
        await pumpAnimal(tester, buildAnimal(kind, size: kind.baseWidth));
        var box = tester.getSize(find.byType(speciesType[kind]!));
        expect(box.width, moreOrLessEquals(kind.baseWidth, epsilon: 1e-6));
        expect(box.height, moreOrLessEquals(kind.baseHeight, epsilon: 1e-6));

        // 2x kenglikda nisbat saqlanadi.
        await pumpAnimal(tester, buildAnimal(kind, size: kind.baseWidth * 2));
        box = tester.getSize(find.byType(speciesType[kind]!));
        expect(box.width, moreOrLessEquals(kind.baseWidth * 2, epsilon: 1e-6));
        expect(
          box.height,
          moreOrLessEquals(kind.baseHeight * 2, epsilon: 1e-6),
        );
      }
    });
  });
}
