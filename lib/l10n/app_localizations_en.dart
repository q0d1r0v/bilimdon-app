// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Bilimdon';

  @override
  String get tabMap => 'Map';

  @override
  String get tabShop => 'Shop';

  @override
  String get tabRating => 'Ranking';

  @override
  String get tabProfile => 'Profile';

  @override
  String levelBadge(int n) {
    return 'Level $n';
  }

  @override
  String chapterTitle(int n, String name) {
    return 'CHAPTER $n · $name';
  }

  @override
  String get chapter1Name => 'BARN';

  @override
  String get chapter1Sub => 'Counting and addition';

  @override
  String get chapter2Name => 'HEN HOUSE';

  @override
  String get chapter2Sub => 'Subtraction';

  @override
  String get chapter3Name => 'MEADOW';

  @override
  String get chapter3Sub => 'Shapes and logic';

  @override
  String get startButton => 'START!';

  @override
  String get retryButton => 'Try again';

  @override
  String get comingSoon => 'Coming soon!';

  @override
  String get bubblePigHi => 'Oink! Hello!';

  @override
  String get bubbleChickenHi => 'Cluck-cluck!';

  @override
  String get bubbleSheepHi => 'Baa!';

  @override
  String get bubbleCowPlay => 'Moo! Shall we play?';

  @override
  String get bubbleDuckHi => 'Quack-quack!';

  @override
  String get bubbleRabbitHi => 'Let’s hop and play!';

  @override
  String get tagCounting => 'COUNTING';

  @override
  String get tagAddition => 'ADDITION';

  @override
  String get tagSubtraction => 'SUBTRACTION';

  @override
  String get tagShapes => 'SHAPES';

  @override
  String get tagSequence => 'LOGIC';

  @override
  String get tagComparison => 'COMPARE';

  @override
  String promptCount(String animal) {
    String _temp0 = intl.Intl.selectLogic(animal, {
      'chick': 'How many chicks?',
      'pig': 'How many piglets?',
      'sheep': 'How many lambs?',
      'other': 'How many?',
    });
    return '$_temp0';
  }

  @override
  String promptFindShape(String shape) {
    String _temp0 = intl.Intl.selectLogic(shape, {
      'triangle': 'Find the triangle!',
      'circle': 'Find the circle!',
      'square': 'Find the square!',
      'diamond': 'Find the diamond!',
      'other': 'Find the shape!',
    });
    return '$_temp0';
  }

  @override
  String get promptBiggest => 'Which number is the biggest?';

  @override
  String get promptSmallest => 'Which number is the smallest?';

  @override
  String questionOf(int n, int total) {
    return 'Question $n / $total';
  }

  @override
  String get bubbleNeutral => 'Hmm, think about it...';

  @override
  String bubbleCorrect1(int coins) {
    return 'Moo! Great! +$coins coins';
  }

  @override
  String get bubbleCorrect2 => 'Moo! That’s right! You rock!';

  @override
  String get bubbleCorrect3 => 'Moo! Well done!';

  @override
  String get bubbleWrong1 => 'No worries, try again!';

  @override
  String get bubbleWrong2 => 'Moo! Think once more!';

  @override
  String get bubbleHint1 => 'Let’s count together: one, two, three...';

  @override
  String get bubbleHint2 => 'Look at the picture — it will help!';

  @override
  String get bubbleReveal =>
      'Here is the answer! Let’s find the next one together!';

  @override
  String get bubbleTimeUp => 'Time’s up, no worries — let’s go on!';

  @override
  String get finishTitle => 'Moo! Well done!';

  @override
  String finishSubtitle(String level) {
    return 'Level $level complete';
  }

  @override
  String plusCoins(int n) {
    return '+$n coins';
  }

  @override
  String get playAgain => 'Play again';

  @override
  String get continueButton => 'Continue';

  @override
  String get shopTitle => 'Shop';

  @override
  String get shopKeeperHi => 'Baa! Welcome!';

  @override
  String get shopCatDecor => 'Farm decorations';

  @override
  String get shopCatAccessory => 'Accessories';

  @override
  String get shopBuy => 'Buy';

  @override
  String get shopEquip => 'Wear';

  @override
  String get shopUnequip => 'Take off';

  @override
  String get shopPlace => 'Place';

  @override
  String get shopRemove => 'Remove';

  @override
  String get shopOwned => 'Owned';

  @override
  String get shopNotEnough => 'Not enough coins!';

  @override
  String get itemFlowerBed => 'Flower bed';

  @override
  String get itemTree => 'Apple tree';

  @override
  String get itemHay => 'Hay stack';

  @override
  String get itemPond => 'Little pond';

  @override
  String get itemCowHat => 'Cow’s hat';

  @override
  String get itemChickBow => 'Chick’s bow';

  @override
  String get itemPigGlasses => 'Pig’s glasses';

  @override
  String get itemSheepScarf => 'Sheep’s scarf';

  @override
  String get ratingSoonBubble => 'Oink! Ranking coming soon!';

  @override
  String get shopSoonBubble => 'Baa! The shop opens soon!';

  @override
  String get profileTitle => 'Profile';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingSound => 'Sound';

  @override
  String get settingMusic => 'Music';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingTimer => 'Speed mode (timer)';

  @override
  String get statsTitle => 'Results (for parents)';

  @override
  String get statQuestions => 'Questions answered';

  @override
  String get statCorrectFirstTry => 'Correct on first try';

  @override
  String get statStars => 'Stars collected';

  @override
  String get statLevels => 'Levels completed';

  @override
  String get statStreak => 'Days played';

  @override
  String get statCoins => 'Coins';

  @override
  String get parentGateTitle => 'For parents';

  @override
  String parentGatePrompt(int a, int b) {
    return 'To continue, answer: $a × $b = ?';
  }

  @override
  String get parentGateWrong => 'Not quite, try again';

  @override
  String get playerDefaultName => 'Aziza';

  @override
  String dailyGoal(int n, int total) {
    return 'Today’s goal: $n/$total questions';
  }

  @override
  String speedBonus(int n) {
    return 'Speed bonus +$n';
  }

  @override
  String get onbLangTitle => 'Choose language';

  @override
  String get onbAboutTitle => 'About you';

  @override
  String get onbNameLabel => 'Name';

  @override
  String get onbNameHint => 'Type your name';

  @override
  String get onbAgeLabel => 'Age';

  @override
  String get onbAvatarLabel => 'Pick your favorite animal';

  @override
  String get onbNext => 'Next';

  @override
  String get onbStart => 'Start!';

  @override
  String get profileInfoTitle => 'My info';

  @override
  String get tabContents => 'Contents';

  @override
  String get contentsTitle => 'Contents';

  @override
  String get contentsSubtitle => 'What we learn';

  @override
  String levelOfChapter(int n, int total) {
    return 'Level $n/$total';
  }

  @override
  String starsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get topic_1_1 => 'Count 1–5';

  @override
  String get topic_1_2 => 'Count 1–10';

  @override
  String get topic_1_3 => 'Mixed practice';

  @override
  String get topic_1_4 => 'Add up to 5';

  @override
  String get topic_1_5 => 'Add up to 10';

  @override
  String get topic_1_6 => 'Chapter 1 test';

  @override
  String get topic_2_1 => 'Subtract up to 5';

  @override
  String get topic_2_2 => 'Subtract up to 10';

  @override
  String get topic_2_3 => 'Add and subtract';

  @override
  String get topic_2_4 => 'Sequences';

  @override
  String get topic_2_5 => 'Mixed practice';

  @override
  String get topic_2_6 => 'Chapter 2 test';

  @override
  String get topic_3_1 => 'Shapes';

  @override
  String get topic_3_2 => 'Shapes 2';

  @override
  String get topic_3_3 => 'Logic sequences';

  @override
  String get topic_3_4 => 'Add and subtract';

  @override
  String get topic_3_5 => 'Compare';

  @override
  String get topic_3_6 => 'Big test';

  @override
  String get chapter4Name => 'POND';

  @override
  String get chapter4Sub => 'Numbers to 20';

  @override
  String get chapter5Name => 'FIELD';

  @override
  String get chapter5Sub => 'Add & subtract to 20';

  @override
  String get chapter6Name => 'GARDEN';

  @override
  String get chapter6Sub => 'Multiplication';

  @override
  String get tagMultiplication => 'MULTIPLY';

  @override
  String get topic_4_1 => 'Sequences to 20';

  @override
  String get topic_4_2 => 'Compare';

  @override
  String get topic_4_3 => 'Mixed practice';

  @override
  String get topic_4_4 => 'Add up to 15';

  @override
  String get topic_4_5 => 'Mixed practice';

  @override
  String get topic_4_6 => 'Chapter 4 test';

  @override
  String get topic_5_1 => 'Add up to 15';

  @override
  String get topic_5_2 => 'Add up to 20';

  @override
  String get topic_5_3 => 'Subtract up to 15';

  @override
  String get topic_5_4 => 'Subtract up to 20';

  @override
  String get topic_5_5 => 'Speed round';

  @override
  String get topic_5_6 => 'Chapter 5 test';

  @override
  String get topic_6_1 => 'Multiply by 2';

  @override
  String get topic_6_2 => 'Multiply by 3';

  @override
  String get topic_6_3 => 'Groups';

  @override
  String get topic_6_4 => 'Mixed operations';

  @override
  String get topic_6_5 => 'Compare';

  @override
  String get topic_6_6 => 'Final test';

  @override
  String get shopCatPowerup => 'Boosters';

  @override
  String shopOwnedCount(int n) {
    return 'You have: $n';
  }

  @override
  String get itemPowerHeart => 'Extra heart';

  @override
  String get itemPowerHint => 'Hint';

  @override
  String get itemPowerSkip => 'Skip';

  @override
  String get itemPowerCoinX2 => 'Coins ×2';

  @override
  String get failTitle => 'Let’s try again!';

  @override
  String get failRetry => 'Retry';

  @override
  String get failExit => 'Exit';
}
