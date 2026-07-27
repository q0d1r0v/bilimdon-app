// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Bilimdon';

  @override
  String get tabMap => 'Карта';

  @override
  String get tabShop => 'Магазин';

  @override
  String get tabRating => 'Рейтинг';

  @override
  String get tabProfile => 'Профиль';

  @override
  String levelBadge(int n) {
    return 'Уровень $n';
  }

  @override
  String chapterTitle(int n, String name) {
    return 'ГЛАВА $n · $name';
  }

  @override
  String get chapter1Name => 'КОРОВНИК';

  @override
  String get chapter1Sub => 'Счёт и сложение';

  @override
  String get chapter2Name => 'КУРЯТНИК';

  @override
  String get chapter2Sub => 'Вычитание';

  @override
  String get chapter3Name => 'ЛУЖАЙКА';

  @override
  String get chapter3Sub => 'Фигуры и логика';

  @override
  String get startButton => 'НАЧАТЬ!';

  @override
  String get retryButton => 'Повторить';

  @override
  String get comingSoon => 'Скоро!';

  @override
  String get bubblePigHi => 'Хрю! Привет!';

  @override
  String get bubbleChickenHi => 'Ко-ко-ко!';

  @override
  String get bubbleSheepHi => 'Бе-е!';

  @override
  String get bubbleCowPlay => 'Му-у! Поиграем?';

  @override
  String get bubbleDuckHi => 'Кря-кря!';

  @override
  String get bubbleRabbitHi => 'Попрыгаем вместе!';

  @override
  String get tagCounting => 'СЧЁТ';

  @override
  String get tagAddition => 'СЛОЖЕНИЕ';

  @override
  String get tagSubtraction => 'ВЫЧИТАНИЕ';

  @override
  String get tagShapes => 'ФИГУРЫ';

  @override
  String get tagSequence => 'ЛОГИКА';

  @override
  String get tagComparison => 'СРАВНЕНИЕ';

  @override
  String promptCount(String animal) {
    String _temp0 = intl.Intl.selectLogic(animal, {
      'chick': 'Сколько цыплят?',
      'pig': 'Сколько поросят?',
      'sheep': 'Сколько ягнят?',
      'other': 'Сколько?',
    });
    return '$_temp0';
  }

  @override
  String shapeName(String shape) {
    String _temp0 = intl.Intl.selectLogic(shape, {
      'triangle': 'Треугольник',
      'circle': 'Круг',
      'square': 'Квадрат',
      'diamond': 'Ромб',
      'other': 'Фигура',
    });
    return '$_temp0';
  }

  @override
  String promptFindShape(String shape) {
    String _temp0 = intl.Intl.selectLogic(shape, {
      'triangle': 'Найди треугольник!',
      'circle': 'Найди круг!',
      'square': 'Найди квадрат!',
      'diamond': 'Найди ромб!',
      'other': 'Найди фигуру!',
    });
    return '$_temp0';
  }

  @override
  String get promptBiggest => 'Какое число самое большое?';

  @override
  String get promptSmallest => 'Какое число самое маленькое?';

  @override
  String questionOf(int n, int total) {
    return 'Вопрос $n / $total';
  }

  @override
  String get bubbleNeutral => 'Ну-ка, подумай...';

  @override
  String bubbleCorrect1(int coins) {
    return 'Му-у! Класс! +$coins монет';
  }

  @override
  String get bubbleCorrect2 => 'Му-у! Верно! Ты молодец!';

  @override
  String get bubbleCorrect3 => 'Му-у! Умница!';

  @override
  String get bubbleWrong1 => 'Ничего страшного, попробуй ещё!';

  @override
  String get bubbleWrong2 => 'Му-у! Подумай ещё разок!';

  @override
  String get bubbleHint1 => 'Давай посчитаем вместе: один, два, три...';

  @override
  String get bubbleHint2 => 'Посмотри на картинку — она поможет!';

  @override
  String get bubbleHintLook => 'Посмотри внимательно на ответы!';

  @override
  String get bubbleReveal => 'Вот правильный ответ! Следующий найдём вместе!';

  @override
  String get bubbleTimeUp => 'Время вышло, ничего — продолжаем!';

  @override
  String get finishTitle => 'Му-у! Умница!';

  @override
  String finishSubtitle(String level) {
    return 'Уровень $level пройден';
  }

  @override
  String plusCoins(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n монет',
      many: '$n монет',
      few: '$n монеты',
      one: '$n монета',
    );
    return '+$_temp0';
  }

  @override
  String get playAgain => 'Играть снова';

  @override
  String get continueButton => 'Дальше';

  @override
  String get shopTitle => 'Магазин';

  @override
  String get shopKeeperHi => 'Бе-е! Добро пожаловать!';

  @override
  String get shopCatDecor => 'Украшения фермы';

  @override
  String get shopCatAccessory => 'Аксессуары';

  @override
  String get shopBuy => 'Купить';

  @override
  String get shopEquip => 'Надеть';

  @override
  String get shopUnequip => 'Снять';

  @override
  String get shopPlace => 'Поставить';

  @override
  String get shopRemove => 'Убрать';

  @override
  String get shopOwned => 'Куплено';

  @override
  String get shopNotEnough => 'Не хватает монет!';

  @override
  String get itemFlowerBed => 'Клумба';

  @override
  String get itemTree => 'Яблоня';

  @override
  String get itemHay => 'Стог сена';

  @override
  String get itemPond => 'Прудик';

  @override
  String get itemCowHat => 'Шляпа коровы';

  @override
  String get itemChickBow => 'Бантик цыплёнка';

  @override
  String get itemPigGlasses => 'Очки поросёнка';

  @override
  String get itemSheepScarf => 'Шарф овечки';

  @override
  String get ratingSoonBubble => 'Хрю! Рейтинг скоро!';

  @override
  String get shopSoonBubble => 'Бе-е! Магазин скоро откроется!';

  @override
  String get profileTitle => 'Профиль';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingSound => 'Звук';

  @override
  String get settingMusic => 'Музыка';

  @override
  String get settingLanguage => 'Язык';

  @override
  String get settingTimer => 'Быстрый режим (таймер)';

  @override
  String get statsTitle => 'Результаты (для родителей)';

  @override
  String get statQuestions => 'Отвеченные вопросы';

  @override
  String get statCorrectFirstTry => 'Верно с первой попытки';

  @override
  String get statStars => 'Собранные звёзды';

  @override
  String get statLevels => 'Пройденные уровни';

  @override
  String get statStreak => 'Дней в игре';

  @override
  String get statCoins => 'Монеты';

  @override
  String get parentGateTitle => 'Для родителей';

  @override
  String parentGatePrompt(int a, int b) {
    return 'Чтобы продолжить, ответьте: $a × $b = ?';
  }

  @override
  String get parentGateWrong => 'Неверно, попробуйте ещё раз';

  @override
  String get playerDefaultName => 'Азиза';

  @override
  String dailyGoal(int n, int total) {
    return 'Цель на сегодня: $n/$total вопросов';
  }

  @override
  String speedBonus(int n) {
    return 'Бонус за скорость +$n';
  }

  @override
  String get onbLangTitle => 'Выберите язык';

  @override
  String get onbAboutTitle => 'О себе';

  @override
  String get onbNameLabel => 'Имя';

  @override
  String get onbNameHint => 'Напиши своё имя';

  @override
  String get onbAgeLabel => 'Возраст';

  @override
  String get onbAvatarLabel => 'Выбери любимого зверька';

  @override
  String get onbNext => 'Далее';

  @override
  String get onbStart => 'Начать!';

  @override
  String get profileInfoTitle => 'Мои данные';

  @override
  String get tabContents => 'Содержание';

  @override
  String get contentsTitle => 'Содержание';

  @override
  String get contentsSubtitle => 'Что мы учим';

  @override
  String levelOfChapter(int n, int total) {
    return 'Уровень $n/$total';
  }

  @override
  String starsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get topic_1_1 => 'Счёт 1–5';

  @override
  String get topic_1_2 => 'Счёт 1–10';

  @override
  String get topic_1_3 => 'Смешанное';

  @override
  String get topic_1_4 => 'Сложение до 5';

  @override
  String get topic_1_5 => 'Сложение до 10';

  @override
  String get topic_1_6 => 'Тест главы 1';

  @override
  String get topic_2_1 => 'Вычитание до 5';

  @override
  String get topic_2_2 => 'Вычитание до 10';

  @override
  String get topic_2_3 => 'Сложение и вычитание';

  @override
  String get topic_2_4 => 'Последовательности';

  @override
  String get topic_2_5 => 'Смешанное';

  @override
  String get topic_2_6 => 'Тест главы 2';

  @override
  String get topic_3_1 => 'Фигуры';

  @override
  String get topic_3_2 => 'Фигуры 2';

  @override
  String get topic_3_3 => 'Логика';

  @override
  String get topic_3_4 => 'Сложение и вычитание';

  @override
  String get topic_3_5 => 'Сравнение';

  @override
  String get topic_3_6 => 'Большой тест';

  @override
  String get chapter4Name => 'ПРУД';

  @override
  String get chapter4Sub => 'Числа до 20';

  @override
  String get chapter5Name => 'ПОЛЕ';

  @override
  String get chapter5Sub => 'Сложение-вычитание до 20';

  @override
  String get chapter6Name => 'САД';

  @override
  String get chapter6Sub => 'Умножение';

  @override
  String get tagMultiplication => 'УМНОЖЕНИЕ';

  @override
  String get topic_4_1 => 'Последовательности до 20';

  @override
  String get topic_4_2 => 'Сравнение';

  @override
  String get topic_4_3 => 'Смешанное';

  @override
  String get topic_4_4 => 'Сложение до 15';

  @override
  String get topic_4_5 => 'Смешанное';

  @override
  String get topic_4_6 => 'Тест главы 4';

  @override
  String get topic_5_1 => 'Сложение до 15';

  @override
  String get topic_5_2 => 'Сложение до 20';

  @override
  String get topic_5_3 => 'Вычитание до 15';

  @override
  String get topic_5_4 => 'Вычитание до 20';

  @override
  String get topic_5_5 => 'Быстрый раунд';

  @override
  String get topic_5_6 => 'Тест главы 5';

  @override
  String get topic_6_1 => 'Умножение 2×';

  @override
  String get topic_6_2 => 'Умножение 3×';

  @override
  String get topic_6_3 => 'Группы';

  @override
  String get topic_6_4 => 'Смешанные действия';

  @override
  String get topic_6_5 => 'Сравнение';

  @override
  String get topic_6_6 => 'Финальный тест';

  @override
  String get shopCatPowerup => 'Помощники';

  @override
  String shopOwnedCount(int n) {
    return 'У вас: $n';
  }

  @override
  String get itemPowerHeart => 'Доп. сердце';

  @override
  String get itemPowerHint => 'Подсказка';

  @override
  String get itemPowerSkip => 'Пропуск';

  @override
  String get itemPowerCoinX2 => 'Монеты ×2';

  @override
  String get failTitle => 'Попробуем ещё!';

  @override
  String get failRetry => 'Заново';

  @override
  String get failExit => 'Выход';
}
