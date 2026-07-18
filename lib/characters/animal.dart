import 'package:flutter/material.dart';

import 'chick.dart';
import 'chicken.dart';
import 'cow.dart';
import 'duck.dart';
import 'pig.dart';
import 'rabbit.dart';
import 'sheep.dart';

/// Ferma hayvonlari (DESIGN_SPEC "Personajlar" + yangi turlar: o‘rdak, quyon).
enum FarmAnimal { cow, pig, sheep, chicken, chick, duck, rabbit }

/// Yuz ifodasi — [AnimalEye] ko‘z holatini shu bo‘yicha chizadi.
enum AnimalExpression { idle, blink, happy, sad }

/// Aksessuarlar — har biri o‘z turiga mos, boshqa turda e‘tiborsiz qoladi.
enum AnimalAccessory { none, cowHat, chickBow, pigGlasses, sheepScarf }

/// Prototipdagi baza o‘lchamlar (px): sigir 100×92, cho‘chqa 90×82,
/// qo‘y 46×42, tovuq 72×84, jo‘ja 40×44.
extension FarmAnimalGeometry on FarmAnimal {
  /// Baza kenglik (px).
  double get baseWidth => switch (this) {
    FarmAnimal.cow => 100,
    FarmAnimal.pig => 90,
    FarmAnimal.sheep => 46,
    FarmAnimal.chicken => 72,
    FarmAnimal.chick => 40,
    FarmAnimal.duck => 60,
    FarmAnimal.rabbit => 48,
  };

  /// Baza balandlik (px).
  double get baseHeight => switch (this) {
    FarmAnimal.cow => 92,
    FarmAnimal.pig => 82,
    FarmAnimal.sheep => 42,
    FarmAnimal.chicken => 84,
    FarmAnimal.chick => 44,
    FarmAnimal.duck => 54,
    FarmAnimal.rabbit => 56,
  };

  /// Balandlik / kenglik nisbati (h/w).
  double get aspect => baseHeight / baseWidth;
}

/// Tur bo‘yicha personaj widgetini quradi. [size] — kenglik px (balandlik
/// tur nisbatidan chiqadi). [faded] — ayirish hintida xira ko‘rsatish
/// (Opacity .25); [mirrored] — gorizontal aks (Transform.flip).
Widget buildAnimal(
  FarmAnimal kind, {
  double size = 60,
  AnimalExpression expression = AnimalExpression.idle,
  AnimalAccessory accessory = AnimalAccessory.none,
  bool faded = false,
  bool mirrored = false,
}) {
  Widget animal = switch (kind) {
    FarmAnimal.cow => CowWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.pig => PigWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.sheep => SheepWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.chicken => ChickenWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.chick => ChickWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.duck => DuckWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
    FarmAnimal.rabbit => RabbitWidget(
      size: size,
      expression: expression,
      accessory: accessory,
    ),
  };
  if (mirrored) {
    animal = Transform.flip(flipX: true, child: animal);
  }
  if (faded) {
    animal = Opacity(opacity: .25, child: animal);
  }
  return animal;
}
