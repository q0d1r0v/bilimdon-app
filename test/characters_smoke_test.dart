import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/characters/animal.dart';

Future<void> pumpAnimal(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: child)),
    ),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('every species renders at base and 2x size', (tester) async {
    for (final kind in FarmAnimal.values) {
      await pumpAnimal(tester, buildAnimal(kind, size: kind.baseWidth));
      await pumpAnimal(tester, buildAnimal(kind, size: kind.baseWidth * 2));
    }
  });

  testWidgets('cow renders all four expressions', (tester) async {
    for (final expression in AnimalExpression.values) {
      await pumpAnimal(
        tester,
        buildAnimal(FarmAnimal.cow, size: 100, expression: expression),
      );
    }
  });

  testWidgets('faded and mirrored variants render', (tester) async {
    await pumpAnimal(tester, buildAnimal(FarmAnimal.sheep, faded: true));
    await pumpAnimal(tester, buildAnimal(FarmAnimal.chick, mirrored: true));
    await pumpAnimal(
      tester,
      buildAnimal(FarmAnimal.pig, faded: true, mirrored: true),
    );
  });

  testWidgets('accessories render on their species', (tester) async {
    await pumpAnimal(
      tester,
      buildAnimal(FarmAnimal.cow, accessory: AnimalAccessory.cowHat),
    );
    await pumpAnimal(
      tester,
      buildAnimal(FarmAnimal.pig, accessory: AnimalAccessory.pigGlasses),
    );
    await pumpAnimal(
      tester,
      buildAnimal(FarmAnimal.sheep, accessory: AnimalAccessory.sheepScarf),
    );
    await pumpAnimal(
      tester,
      buildAnimal(FarmAnimal.chick, accessory: AnimalAccessory.chickBow),
    );
  });

  test('geometry extension matches the design spec', () {
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
    expect(FarmAnimal.cow.aspect, closeTo(92 / 100, 1e-9));
    expect(FarmAnimal.chick.aspect, closeTo(44 / 40, 1e-9));
  });
}
