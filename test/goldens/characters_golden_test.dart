import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/characters/animal.dart';
import 'package:math_farm/scene/barn.dart';
import 'package:math_farm/scene/decorations.dart';
import 'package:math_farm/widgets/chunky_button.dart';
import 'package:math_farm/widgets/icons.dart';

/// «Design buzilmasin» avtomat nazorati: personajlar va asosiy
/// dizayn-atomlar golden rasmlarga qotirilgan. Radius/rang/burilishdagi
/// har qanday tasodifiy siljish bu testni yiqitadi.
///
/// DIQQAT: goldenlar shu Linux muhitida yaratilgan — boshqa OS'da
/// piksel farqi bo'lishi mumkin; yangilash: flutter test --update-goldens.
void main() {
  Widget host(Widget child, {Color bg = const Color(0xFF8FD0F8)}) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: bg,
        body: Center(child: RepaintBoundary(child: child)),
      ),
    );
  }

  testWidgets('sigir — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.cow, size: 200)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/cow_idle.png'),
    );
  });

  testWidgets('sigir — happy + shlyapa', (tester) async {
    await tester.pumpWidget(
      host(
        buildAnimal(
          FarmAnimal.cow,
          size: 200,
          expression: AnimalExpression.happy,
          accessory: AnimalAccessory.cowHat,
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/cow_happy_hat.png'),
    );
  });

  testWidgets('cho‘chqa — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.pig, size: 180)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/pig_idle.png'),
    );
  });

  testWidgets('qo‘y — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.sheep, size: 160)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/sheep_idle.png'),
    );
  });

  testWidgets('tovuq — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.chicken, size: 160)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/chicken_idle.png'),
    );
  });

  testWidgets('jo‘ja — idle va faded', (tester) async {
    await tester.pumpWidget(
      host(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            buildAnimal(FarmAnimal.chick, size: 120),
            const SizedBox(width: 16),
            buildAnimal(FarmAnimal.chick, size: 120, faded: true),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/chick_pair.png'),
    );
  });

  testWidgets('o‘rdak — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.duck, size: 180)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/duck_idle.png'),
    );
  });

  testWidgets('quyon — idle', (tester) async {
    await tester.pumpWidget(host(buildAnimal(FarmAnimal.rabbit, size: 160)));
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/rabbit_idle.png'),
    );
  });

  testWidgets('chunky tugmalar — 4 rang', (tester) async {
    await tester.pumpWidget(
      host(
        SizedBox(
          width: 340,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (bg, dark) in [
                (const Color(0xFFE8433F), const Color(0xFFC22F2C)),
                (const Color(0xFF58B94A), const Color(0xFF3F8F33)),
                (const Color(0xFF3D9BE9), const Color(0xFF2C79BD)),
                (const Color(0xFFFFC23C), const Color(0xFFDB9A14)),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ChunkyButton(
                    color: bg,
                    darkColor: dark,
                    minHeight: 78,
                    child: const Text(
                      '5',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        bg: const Color(0xFFFDF6E3),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/chunky_buttons.png'),
    );
  });

  testWidgets('ikonkalar va dekorlar', (tester) async {
    await tester.pumpWidget(
      host(
        const Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            CoinIcon(size: 28),
            SizedBox(width: 12),
            StreakFlameIcon(size: 26),
            SizedBox(width: 12),
            HeartIcon(size: 28),
            SizedBox(width: 12),
            StarIcon(size: 28),
            SizedBox(width: 16),
            BarnIcon(width: 60, height: 54),
            SizedBox(width: 16),
            AppleTree(size: 80),
            SizedBox(width: 12),
            HayStack(size: 64),
          ],
        ),
        bg: const Color(0xFFFDF6E3),
      ),
    );
    await expectLater(
      find.byType(RepaintBoundary).last,
      matchesGoldenFile('goldens/atoms.png'),
    );
  });
}
