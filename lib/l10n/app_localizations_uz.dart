// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Bilimdon';

  @override
  String get tabMap => 'Xarita';

  @override
  String get tabShop => 'Do’kon';

  @override
  String get tabRating => 'Reyting';

  @override
  String get tabProfile => 'Profil';

  @override
  String levelBadge(int n) {
    return '$n-daraja';
  }

  @override
  String chapterTitle(int n, String name) {
    return '$n-BOB · $name';
  }

  @override
  String get chapter1Name => 'MOLXONA';

  @override
  String get chapter1Sub => 'Sanash va qo’shish';

  @override
  String get chapter2Name => 'TOVUQXONA';

  @override
  String get chapter2Sub => 'Ayirish';

  @override
  String get chapter3Name => 'YAYLOV';

  @override
  String get chapter3Sub => 'Shakllar va mantiq';

  @override
  String get startButton => 'BOSHLA!';

  @override
  String get retryButton => 'Qayta urinish';

  @override
  String get comingSoon => 'Tez kunda!';

  @override
  String get bubblePigHi => 'Xryu! Salom!';

  @override
  String get bubbleChickenHi => 'Qo-qo-qo!';

  @override
  String get bubbleSheepHi => 'Bee-e!';

  @override
  String get bubbleCowPlay => 'Muu! O’ynaymizmi?';

  @override
  String get bubbleDuckHi => 'Vaq-vaq!';

  @override
  String get bubbleRabbitHi => 'Sakrab o’ynaymiz!';

  @override
  String get tagCounting => 'SANASH';

  @override
  String get tagAddition => 'QO’SHISH';

  @override
  String get tagSubtraction => 'AYIRISH';

  @override
  String get tagShapes => 'SHAKLLAR';

  @override
  String get tagSequence => 'MANTIQ';

  @override
  String get tagComparison => 'TAQQOSLASH';

  @override
  String promptCount(String animal) {
    String _temp0 = intl.Intl.selectLogic(animal, {
      'chick': 'Nechta jo’jacha?',
      'pig': 'Nechta cho’chqacha?',
      'sheep': 'Nechta qo’zichoq?',
      'other': 'Nechta?',
    });
    return '$_temp0';
  }

  @override
  String promptFindShape(String shape) {
    String _temp0 = intl.Intl.selectLogic(shape, {
      'triangle': 'Uchburchakni top!',
      'circle': 'Doirani top!',
      'square': 'Kvadratni top!',
      'diamond': 'Rombni top!',
      'other': 'Shaklni top!',
    });
    return '$_temp0';
  }

  @override
  String get promptBiggest => 'Qaysi son eng katta?';

  @override
  String get promptSmallest => 'Qaysi son eng kichik?';

  @override
  String questionOf(int n, int total) {
    return 'Savol $n / $total';
  }

  @override
  String get bubbleNeutral => 'Qani, o’ylab ko’r-chi...';

  @override
  String bubbleCorrect1(int coins) {
    return 'Muu! Zo’r! +$coins tanga';
  }

  @override
  String get bubbleCorrect2 => 'Muu! Juda to’g’ri! Sen zo’rsan!';

  @override
  String get bubbleCorrect3 => 'Muu! Barakalla!';

  @override
  String get bubbleWrong1 => 'Hechqisi yo’q, yana urin!';

  @override
  String get bubbleWrong2 => 'Muu! Yana bir bor o’ylab ko’r!';

  @override
  String get bubbleHint1 => 'Kel, birga sanaymiz: bir, ikki, uch...';

  @override
  String get bubbleHint2 => 'Rasmga qara — u senga yordam beradi!';

  @override
  String get bubbleReveal => 'Javob mana bu edi! Keyingisini birga topamiz!';

  @override
  String get bubbleTimeUp => 'Vaqt tugadi, hechqisi yo’q — davom etamiz!';

  @override
  String get finishTitle => 'Muu! Barakalla!';

  @override
  String finishSubtitle(String level) {
    return '$level-daraja tugadi';
  }

  @override
  String plusCoins(int n) {
    return '+$n tanga';
  }

  @override
  String get playAgain => 'Qaytadan o’ynash';

  @override
  String get continueButton => 'Davom etish';

  @override
  String get shopTitle => 'Do’kon';

  @override
  String get shopKeeperHi => 'Bee-e! Xush kelibsiz!';

  @override
  String get shopCatDecor => 'Ferma bezaklari';

  @override
  String get shopCatAccessory => 'Aksessuarlar';

  @override
  String get shopBuy => 'Sotib olish';

  @override
  String get shopEquip => 'Kiyish';

  @override
  String get shopUnequip => 'Yechish';

  @override
  String get shopPlace => 'Qo’yish';

  @override
  String get shopRemove => 'Olib qo’yish';

  @override
  String get shopOwned => 'Sizniki';

  @override
  String get shopNotEnough => 'Tanga yetmaydi!';

  @override
  String get itemFlowerBed => 'Gul to’plami';

  @override
  String get itemTree => 'Olma daraxti';

  @override
  String get itemHay => 'Pichan g’arami';

  @override
  String get itemPond => 'Ko’lcha';

  @override
  String get itemCowHat => 'Sigir shlyapasi';

  @override
  String get itemChickBow => 'Jo’ja bantigi';

  @override
  String get itemPigGlasses => 'Cho’chqa ko’zoynagi';

  @override
  String get itemSheepScarf => 'Qo’y sharfi';

  @override
  String get ratingSoonBubble => 'Xryu! Reyting tez kunda!';

  @override
  String get shopSoonBubble => 'Bee-e! Do’kon tez kunda ochiladi!';

  @override
  String get profileTitle => 'Profil';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingSound => 'Ovoz';

  @override
  String get settingMusic => 'Musiqa';

  @override
  String get settingLanguage => 'Til';

  @override
  String get settingTimer => 'Tezkor rejim (taymer)';

  @override
  String get statsTitle => 'Natijalar (ota-onalar uchun)';

  @override
  String get statQuestions => 'Javob berilgan savollar';

  @override
  String get statCorrectFirstTry => 'Birinchi urinishda to’g’ri';

  @override
  String get statStars => 'Yig’ilgan yulduzlar';

  @override
  String get statLevels => 'Tugatilgan darajalar';

  @override
  String get statStreak => 'O’ynagan kunlar';

  @override
  String get statCoins => 'Tangalar';

  @override
  String get parentGateTitle => 'Ota-onalar uchun';

  @override
  String parentGatePrompt(int a, int b) {
    return 'Davom etish uchun javob bering: $a × $b = ?';
  }

  @override
  String get parentGateWrong => 'Noto’g’ri, yana urinib ko’ring';

  @override
  String get playerDefaultName => 'Aziza';

  @override
  String dailyGoal(int n, int total) {
    return 'Bugungi maqsad: $n/$total savol';
  }

  @override
  String speedBonus(int n) {
    return 'Tezlik bonusi +$n';
  }

  @override
  String get onbLangTitle => 'Tilni tanlang';

  @override
  String get onbAboutTitle => 'O’zingiz haqingizda';

  @override
  String get onbNameLabel => 'Isming';

  @override
  String get onbNameHint => 'Ismingni yoz';

  @override
  String get onbAgeLabel => 'Yoshing';

  @override
  String get onbAvatarLabel => 'Yoqqan hayvoningni tanla';

  @override
  String get onbNext => 'Davom etish';

  @override
  String get onbStart => 'Boshlash!';

  @override
  String get profileInfoTitle => 'Ma’lumotlarim';

  @override
  String get tabContents => 'Mundarija';

  @override
  String get contentsTitle => 'Mundarija';

  @override
  String get contentsSubtitle => 'Nimalar o’rganamiz';

  @override
  String levelOfChapter(int n, int total) {
    return '$n/$total-daraja';
  }

  @override
  String starsProgress(int done, int total) {
    return '$done/$total';
  }

  @override
  String get topic_1_1 => 'Sanash 1–5';

  @override
  String get topic_1_2 => 'Sanash 1–10';

  @override
  String get topic_1_3 => 'Aralash mashq';

  @override
  String get topic_1_4 => 'Qo’shish 5 gacha';

  @override
  String get topic_1_5 => 'Qo’shish 10 gacha';

  @override
  String get topic_1_6 => '1-bob sinovi';

  @override
  String get topic_2_1 => 'Ayirish 5 gacha';

  @override
  String get topic_2_2 => 'Ayirish 10 gacha';

  @override
  String get topic_2_3 => 'Qo’shish va ayirish';

  @override
  String get topic_2_4 => 'Ketma-ketlik';

  @override
  String get topic_2_5 => 'Aralash mashq';

  @override
  String get topic_2_6 => '2-bob sinovi';

  @override
  String get topic_3_1 => 'Shakllar';

  @override
  String get topic_3_2 => 'Shakllar 2';

  @override
  String get topic_3_3 => 'Mantiqiy ketma-ketlik';

  @override
  String get topic_3_4 => 'Qo’shish va ayirish';

  @override
  String get topic_3_5 => 'Taqqoslash';

  @override
  String get topic_3_6 => 'Katta sinov';

  @override
  String get chapter4Name => 'KO’LMAK';

  @override
  String get chapter4Sub => 'Sonlar 20 gacha';

  @override
  String get chapter5Name => 'DALA';

  @override
  String get chapter5Sub => 'Qo’shish-ayirish 20 gacha';

  @override
  String get chapter6Name => 'BOG’';

  @override
  String get chapter6Sub => 'Ko’paytirish';

  @override
  String get tagMultiplication => 'KO’PAYTIRISH';

  @override
  String get topic_4_1 => 'Ketma-ketlik 20 gacha';

  @override
  String get topic_4_2 => 'Taqqoslash';

  @override
  String get topic_4_3 => 'Aralash mashq';

  @override
  String get topic_4_4 => 'Qo’shish 15 gacha';

  @override
  String get topic_4_5 => 'Aralash mashq';

  @override
  String get topic_4_6 => '4-bob sinovi';

  @override
  String get topic_5_1 => 'Qo’shish 15 gacha';

  @override
  String get topic_5_2 => 'Qo’shish 20 gacha';

  @override
  String get topic_5_3 => 'Ayirish 15 gacha';

  @override
  String get topic_5_4 => 'Ayirish 20 gacha';

  @override
  String get topic_5_5 => 'Tezkor mashq';

  @override
  String get topic_5_6 => '5-bob sinovi';

  @override
  String get topic_6_1 => 'Ko’paytirish 2×';

  @override
  String get topic_6_2 => 'Ko’paytirish 3×';

  @override
  String get topic_6_3 => 'Guruhlar';

  @override
  String get topic_6_4 => 'Aralash amallar';

  @override
  String get topic_6_5 => 'Taqqoslash';

  @override
  String get topic_6_6 => 'Yakuniy sinov';

  @override
  String get shopCatPowerup => 'Yordamchilar';

  @override
  String shopOwnedCount(int n) {
    return 'Sizda: $n';
  }

  @override
  String get itemPowerHeart => 'Qo’shimcha yurak';

  @override
  String get itemPowerHint => 'Yordam';

  @override
  String get itemPowerSkip => 'O’tkazish';

  @override
  String get itemPowerCoinX2 => 'Tanga ×2';

  @override
  String get failTitle => 'Yana urinamiz!';

  @override
  String get failRetry => 'Qaytadan';

  @override
  String get failExit => 'Chiqish';
}
