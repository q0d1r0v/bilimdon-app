import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/core/theme/tokens.dart';
import 'package:math_farm/scene/barn.dart';
import 'package:math_farm/scene/bush.dart';
import 'package:math_farm/scene/cloud.dart';
import 'package:math_farm/scene/decorations.dart';
import 'package:math_farm/scene/fence.dart';
import 'package:math_farm/scene/flowers.dart';
import 'package:math_farm/scene/hill.dart';
import 'package:math_farm/scene/lock_icon.dart';
import 'package:math_farm/scene/sky.dart';
import 'package:math_farm/scene/sun.dart';

Future<void> pumpScene(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: child))),
  );
  expect(tester.takeException(), isNull);
}

void main() {
  testWidgets('sky gradients render', (tester) async {
    await pumpScene(
      tester,
      Column(
        children: [
          Container(width: 100, height: 100, decoration: farmSkyGradient()),
          Container(
            width: 100,
            height: 100,
            decoration: farmSkyGradient(game: true),
          ),
          Container(
            width: 100,
            height: 200,
            decoration: farmGameSkyGradient(200),
          ),
        ],
      ),
    );
  });

  testWidgets('sun renders', (tester) async {
    await pumpScene(tester, const Sun());
    await pumpScene(tester, const Sun(size: 60));
  });

  testWidgets('clouds render', (tester) async {
    await pumpScene(tester, const Cloud.big());
    await pumpScene(tester, const Cloud.small());
  });

  testWidgets('hill renders', (tester) async {
    await pumpScene(
      tester,
      const Hill(width: 300, height: 200, color: FarmColors.grassLight),
    );
  });

  testWidgets('fence renders in both variants', (tester) async {
    await pumpScene(
      tester,
      const SizedBox(width: 360, child: FenceStrip()),
    );
    await pumpScene(
      tester,
      const SizedBox(width: 360, child: FenceStrip(game: true, height: 40)),
    );
  });

  testWidgets('bush clusters render', (tester) async {
    await pumpScene(tester, const BushCluster.left());
    await pumpScene(tester, const BushCluster.right());
  });

  testWidgets('flower clusters render', (tester) async {
    await pumpScene(tester, FlowerCluster.mapCluster1);
    await pumpScene(tester, FlowerCluster.mapCluster2);
    await pumpScene(tester, FlowerCluster.gamePanelCluster);
    await pumpScene(
      tester,
      const FlowerCluster(
        dotSize: 5,
        color: FarmColors.red,
        clones: [(dx: 10, dy: 4, color: Colors.white)],
      ),
    );
  });

  testWidgets('barn icon renders', (tester) async {
    await pumpScene(tester, const BarnIcon());
    await pumpScene(tester, const BarnIcon(width: 80, height: 72));
  });

  testWidgets('lock icon renders', (tester) async {
    await pumpScene(tester, const LockIcon());
    await pumpScene(tester, const LockIcon(color: FarmColors.inkGray));
  });

  testWidgets('shop decorations render', (tester) async {
    await pumpScene(tester, const AppleTree());
    await pumpScene(tester, const HayStack());
    await pumpScene(tester, const Pond());
    await pumpScene(tester, const FlowerBed());
    await pumpScene(tester, const AppleTree(size: 120));
    await pumpScene(tester, const HayStack(size: 40));
    await pumpScene(tester, const Pond(size: 100));
    await pumpScene(tester, const FlowerBed(size: 100));
  });
}
