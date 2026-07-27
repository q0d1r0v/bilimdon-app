import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uz, this message translates to:
  /// **'Bilimdon'**
  String get appTitle;

  /// No description provided for @tabMap.
  ///
  /// In uz, this message translates to:
  /// **'Xarita'**
  String get tabMap;

  /// No description provided for @tabShop.
  ///
  /// In uz, this message translates to:
  /// **'Do’kon'**
  String get tabShop;

  /// No description provided for @tabRating.
  ///
  /// In uz, this message translates to:
  /// **'Reyting'**
  String get tabRating;

  /// No description provided for @tabProfile.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @levelBadge.
  ///
  /// In uz, this message translates to:
  /// **'{n}-daraja'**
  String levelBadge(int n);

  /// No description provided for @chapterTitle.
  ///
  /// In uz, this message translates to:
  /// **'{n}-BOB · {name}'**
  String chapterTitle(int n, String name);

  /// No description provided for @chapter1Name.
  ///
  /// In uz, this message translates to:
  /// **'MOLXONA'**
  String get chapter1Name;

  /// No description provided for @chapter1Sub.
  ///
  /// In uz, this message translates to:
  /// **'Sanash va qo’shish'**
  String get chapter1Sub;

  /// No description provided for @chapter2Name.
  ///
  /// In uz, this message translates to:
  /// **'TOVUQXONA'**
  String get chapter2Name;

  /// No description provided for @chapter2Sub.
  ///
  /// In uz, this message translates to:
  /// **'Ayirish'**
  String get chapter2Sub;

  /// No description provided for @chapter3Name.
  ///
  /// In uz, this message translates to:
  /// **'YAYLOV'**
  String get chapter3Name;

  /// No description provided for @chapter3Sub.
  ///
  /// In uz, this message translates to:
  /// **'Shakllar va mantiq'**
  String get chapter3Sub;

  /// No description provided for @startButton.
  ///
  /// In uz, this message translates to:
  /// **'BOSHLA!'**
  String get startButton;

  /// No description provided for @retryButton.
  ///
  /// In uz, this message translates to:
  /// **'Qayta urinish'**
  String get retryButton;

  /// No description provided for @comingSoon.
  ///
  /// In uz, this message translates to:
  /// **'Tez kunda!'**
  String get comingSoon;

  /// No description provided for @bubblePigHi.
  ///
  /// In uz, this message translates to:
  /// **'Xryu! Salom!'**
  String get bubblePigHi;

  /// No description provided for @bubbleChickenHi.
  ///
  /// In uz, this message translates to:
  /// **'Qo-qo-qo!'**
  String get bubbleChickenHi;

  /// No description provided for @bubbleSheepHi.
  ///
  /// In uz, this message translates to:
  /// **'Bee-e!'**
  String get bubbleSheepHi;

  /// No description provided for @bubbleCowPlay.
  ///
  /// In uz, this message translates to:
  /// **'Muu! O’ynaymizmi?'**
  String get bubbleCowPlay;

  /// No description provided for @bubbleDuckHi.
  ///
  /// In uz, this message translates to:
  /// **'Vaq-vaq!'**
  String get bubbleDuckHi;

  /// No description provided for @bubbleRabbitHi.
  ///
  /// In uz, this message translates to:
  /// **'Sakrab o’ynaymiz!'**
  String get bubbleRabbitHi;

  /// No description provided for @tagCounting.
  ///
  /// In uz, this message translates to:
  /// **'SANASH'**
  String get tagCounting;

  /// No description provided for @tagAddition.
  ///
  /// In uz, this message translates to:
  /// **'QO’SHISH'**
  String get tagAddition;

  /// No description provided for @tagSubtraction.
  ///
  /// In uz, this message translates to:
  /// **'AYIRISH'**
  String get tagSubtraction;

  /// No description provided for @tagShapes.
  ///
  /// In uz, this message translates to:
  /// **'SHAKLLAR'**
  String get tagShapes;

  /// No description provided for @tagSequence.
  ///
  /// In uz, this message translates to:
  /// **'MANTIQ'**
  String get tagSequence;

  /// No description provided for @tagComparison.
  ///
  /// In uz, this message translates to:
  /// **'TAQQOSLASH'**
  String get tagComparison;

  /// No description provided for @promptCount.
  ///
  /// In uz, this message translates to:
  /// **'{animal, select, chick{Nechta jo’jacha?} pig{Nechta cho’chqacha?} sheep{Nechta qo’zichoq?} other{Nechta?}}'**
  String promptCount(String animal);

  /// No description provided for @shapeName.
  ///
  /// In uz, this message translates to:
  /// **'{shape, select, triangle{Uchburchak} circle{Doira} square{Kvadrat} diamond{Romb} other{Shakl}}'**
  String shapeName(String shape);

  /// No description provided for @promptFindShape.
  ///
  /// In uz, this message translates to:
  /// **'{shape, select, triangle{Uchburchakni top!} circle{Doirani top!} square{Kvadratni top!} diamond{Rombni top!} other{Shaklni top!}}'**
  String promptFindShape(String shape);

  /// No description provided for @promptBiggest.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi son eng katta?'**
  String get promptBiggest;

  /// No description provided for @promptSmallest.
  ///
  /// In uz, this message translates to:
  /// **'Qaysi son eng kichik?'**
  String get promptSmallest;

  /// No description provided for @questionOf.
  ///
  /// In uz, this message translates to:
  /// **'Savol {n} / {total}'**
  String questionOf(int n, int total);

  /// No description provided for @bubbleNeutral.
  ///
  /// In uz, this message translates to:
  /// **'Qani, o’ylab ko’r-chi...'**
  String get bubbleNeutral;

  /// No description provided for @bubbleCorrect1.
  ///
  /// In uz, this message translates to:
  /// **'Muu! Zo’r! +{coins} tanga'**
  String bubbleCorrect1(int coins);

  /// No description provided for @bubbleCorrect2.
  ///
  /// In uz, this message translates to:
  /// **'Muu! Juda to’g’ri! Sen zo’rsan!'**
  String get bubbleCorrect2;

  /// No description provided for @bubbleCorrect3.
  ///
  /// In uz, this message translates to:
  /// **'Muu! Barakalla!'**
  String get bubbleCorrect3;

  /// No description provided for @bubbleWrong1.
  ///
  /// In uz, this message translates to:
  /// **'Hechqisi yo’q, yana urin!'**
  String get bubbleWrong1;

  /// No description provided for @bubbleWrong2.
  ///
  /// In uz, this message translates to:
  /// **'Muu! Yana bir bor o’ylab ko’r!'**
  String get bubbleWrong2;

  /// No description provided for @bubbleHint1.
  ///
  /// In uz, this message translates to:
  /// **'Kel, birga sanaymiz: bir, ikki, uch...'**
  String get bubbleHint1;

  /// No description provided for @bubbleHint2.
  ///
  /// In uz, this message translates to:
  /// **'Rasmga qara — u senga yordam beradi!'**
  String get bubbleHint2;

  /// No description provided for @bubbleHintLook.
  ///
  /// In uz, this message translates to:
  /// **'Javoblarga diqqat bilan qara!'**
  String get bubbleHintLook;

  /// No description provided for @bubbleReveal.
  ///
  /// In uz, this message translates to:
  /// **'Javob mana bu edi! Keyingisini birga topamiz!'**
  String get bubbleReveal;

  /// No description provided for @bubbleTimeUp.
  ///
  /// In uz, this message translates to:
  /// **'Vaqt tugadi, hechqisi yo’q — davom etamiz!'**
  String get bubbleTimeUp;

  /// No description provided for @finishTitle.
  ///
  /// In uz, this message translates to:
  /// **'Muu! Barakalla!'**
  String get finishTitle;

  /// No description provided for @finishSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'{level}-daraja tugadi'**
  String finishSubtitle(String level);

  /// No description provided for @plusCoins.
  ///
  /// In uz, this message translates to:
  /// **'+{n, plural, other{{n} tanga}}'**
  String plusCoins(int n);

  /// No description provided for @playAgain.
  ///
  /// In uz, this message translates to:
  /// **'Qaytadan o’ynash'**
  String get playAgain;

  /// No description provided for @continueButton.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get continueButton;

  /// No description provided for @shopTitle.
  ///
  /// In uz, this message translates to:
  /// **'Do’kon'**
  String get shopTitle;

  /// No description provided for @shopKeeperHi.
  ///
  /// In uz, this message translates to:
  /// **'Bee-e! Xush kelibsiz!'**
  String get shopKeeperHi;

  /// No description provided for @shopCatDecor.
  ///
  /// In uz, this message translates to:
  /// **'Ferma bezaklari'**
  String get shopCatDecor;

  /// No description provided for @shopCatAccessory.
  ///
  /// In uz, this message translates to:
  /// **'Aksessuarlar'**
  String get shopCatAccessory;

  /// No description provided for @shopBuy.
  ///
  /// In uz, this message translates to:
  /// **'Sotib olish'**
  String get shopBuy;

  /// No description provided for @shopEquip.
  ///
  /// In uz, this message translates to:
  /// **'Kiyish'**
  String get shopEquip;

  /// No description provided for @shopUnequip.
  ///
  /// In uz, this message translates to:
  /// **'Yechish'**
  String get shopUnequip;

  /// No description provided for @shopPlace.
  ///
  /// In uz, this message translates to:
  /// **'Qo’yish'**
  String get shopPlace;

  /// No description provided for @shopRemove.
  ///
  /// In uz, this message translates to:
  /// **'Olib qo’yish'**
  String get shopRemove;

  /// No description provided for @shopOwned.
  ///
  /// In uz, this message translates to:
  /// **'Sizniki'**
  String get shopOwned;

  /// No description provided for @shopNotEnough.
  ///
  /// In uz, this message translates to:
  /// **'Tanga yetmaydi!'**
  String get shopNotEnough;

  /// No description provided for @itemFlowerBed.
  ///
  /// In uz, this message translates to:
  /// **'Gul to’plami'**
  String get itemFlowerBed;

  /// No description provided for @itemTree.
  ///
  /// In uz, this message translates to:
  /// **'Olma daraxti'**
  String get itemTree;

  /// No description provided for @itemHay.
  ///
  /// In uz, this message translates to:
  /// **'Pichan g’arami'**
  String get itemHay;

  /// No description provided for @itemPond.
  ///
  /// In uz, this message translates to:
  /// **'Ko’lcha'**
  String get itemPond;

  /// No description provided for @itemCowHat.
  ///
  /// In uz, this message translates to:
  /// **'Sigir shlyapasi'**
  String get itemCowHat;

  /// No description provided for @itemChickBow.
  ///
  /// In uz, this message translates to:
  /// **'Jo’ja bantigi'**
  String get itemChickBow;

  /// No description provided for @itemPigGlasses.
  ///
  /// In uz, this message translates to:
  /// **'Cho’chqa ko’zoynagi'**
  String get itemPigGlasses;

  /// No description provided for @itemSheepScarf.
  ///
  /// In uz, this message translates to:
  /// **'Qo’y sharfi'**
  String get itemSheepScarf;

  /// No description provided for @ratingSoonBubble.
  ///
  /// In uz, this message translates to:
  /// **'Xryu! Reyting tez kunda!'**
  String get ratingSoonBubble;

  /// No description provided for @shopSoonBubble.
  ///
  /// In uz, this message translates to:
  /// **'Bee-e! Do’kon tez kunda ochiladi!'**
  String get shopSoonBubble;

  /// No description provided for @profileTitle.
  ///
  /// In uz, this message translates to:
  /// **'Profil'**
  String get profileTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Sozlamalar'**
  String get settingsTitle;

  /// No description provided for @settingSound.
  ///
  /// In uz, this message translates to:
  /// **'Ovoz'**
  String get settingSound;

  /// No description provided for @settingMusic.
  ///
  /// In uz, this message translates to:
  /// **'Musiqa'**
  String get settingMusic;

  /// No description provided for @settingLanguage.
  ///
  /// In uz, this message translates to:
  /// **'Til'**
  String get settingLanguage;

  /// No description provided for @settingTimer.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor rejim (taymer)'**
  String get settingTimer;

  /// No description provided for @statsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Natijalar (ota-onalar uchun)'**
  String get statsTitle;

  /// No description provided for @statQuestions.
  ///
  /// In uz, this message translates to:
  /// **'Javob berilgan savollar'**
  String get statQuestions;

  /// No description provided for @statCorrectFirstTry.
  ///
  /// In uz, this message translates to:
  /// **'Birinchi urinishda to’g’ri'**
  String get statCorrectFirstTry;

  /// No description provided for @statStars.
  ///
  /// In uz, this message translates to:
  /// **'Yig’ilgan yulduzlar'**
  String get statStars;

  /// No description provided for @statLevels.
  ///
  /// In uz, this message translates to:
  /// **'Tugatilgan darajalar'**
  String get statLevels;

  /// No description provided for @statStreak.
  ///
  /// In uz, this message translates to:
  /// **'O’ynagan kunlar'**
  String get statStreak;

  /// No description provided for @statCoins.
  ///
  /// In uz, this message translates to:
  /// **'Tangalar'**
  String get statCoins;

  /// No description provided for @parentGateTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ota-onalar uchun'**
  String get parentGateTitle;

  /// No description provided for @parentGatePrompt.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish uchun javob bering: {a} × {b} = ?'**
  String parentGatePrompt(int a, int b);

  /// No description provided for @parentGateWrong.
  ///
  /// In uz, this message translates to:
  /// **'Noto’g’ri, yana urinib ko’ring'**
  String get parentGateWrong;

  /// No description provided for @playerDefaultName.
  ///
  /// In uz, this message translates to:
  /// **'Aziza'**
  String get playerDefaultName;

  /// No description provided for @dailyGoal.
  ///
  /// In uz, this message translates to:
  /// **'Bugungi maqsad: {n}/{total} savol'**
  String dailyGoal(int n, int total);

  /// No description provided for @speedBonus.
  ///
  /// In uz, this message translates to:
  /// **'Tezlik bonusi +{n}'**
  String speedBonus(int n);

  /// No description provided for @onbLangTitle.
  ///
  /// In uz, this message translates to:
  /// **'Tilni tanlang'**
  String get onbLangTitle;

  /// No description provided for @onbAboutTitle.
  ///
  /// In uz, this message translates to:
  /// **'O’zingiz haqingizda'**
  String get onbAboutTitle;

  /// No description provided for @onbNameLabel.
  ///
  /// In uz, this message translates to:
  /// **'Isming'**
  String get onbNameLabel;

  /// No description provided for @onbNameHint.
  ///
  /// In uz, this message translates to:
  /// **'Ismingni yoz'**
  String get onbNameHint;

  /// No description provided for @onbAgeLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yoshing'**
  String get onbAgeLabel;

  /// No description provided for @onbAvatarLabel.
  ///
  /// In uz, this message translates to:
  /// **'Yoqqan hayvoningni tanla'**
  String get onbAvatarLabel;

  /// No description provided for @onbNext.
  ///
  /// In uz, this message translates to:
  /// **'Davom etish'**
  String get onbNext;

  /// No description provided for @onbStart.
  ///
  /// In uz, this message translates to:
  /// **'Boshlash!'**
  String get onbStart;

  /// No description provided for @profileInfoTitle.
  ///
  /// In uz, this message translates to:
  /// **'Ma’lumotlarim'**
  String get profileInfoTitle;

  /// No description provided for @tabContents.
  ///
  /// In uz, this message translates to:
  /// **'Mundarija'**
  String get tabContents;

  /// No description provided for @contentsTitle.
  ///
  /// In uz, this message translates to:
  /// **'Mundarija'**
  String get contentsTitle;

  /// No description provided for @contentsSubtitle.
  ///
  /// In uz, this message translates to:
  /// **'Nimalar o’rganamiz'**
  String get contentsSubtitle;

  /// No description provided for @levelOfChapter.
  ///
  /// In uz, this message translates to:
  /// **'{n}/{total}-daraja'**
  String levelOfChapter(int n, int total);

  /// No description provided for @starsProgress.
  ///
  /// In uz, this message translates to:
  /// **'{done}/{total}'**
  String starsProgress(int done, int total);

  /// No description provided for @topic_1_1.
  ///
  /// In uz, this message translates to:
  /// **'Sanash 1–5'**
  String get topic_1_1;

  /// No description provided for @topic_1_2.
  ///
  /// In uz, this message translates to:
  /// **'Sanash 1–10'**
  String get topic_1_2;

  /// No description provided for @topic_1_3.
  ///
  /// In uz, this message translates to:
  /// **'Aralash mashq'**
  String get topic_1_3;

  /// No description provided for @topic_1_4.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish 5 gacha'**
  String get topic_1_4;

  /// No description provided for @topic_1_5.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish 10 gacha'**
  String get topic_1_5;

  /// No description provided for @topic_1_6.
  ///
  /// In uz, this message translates to:
  /// **'1-bob sinovi'**
  String get topic_1_6;

  /// No description provided for @topic_2_1.
  ///
  /// In uz, this message translates to:
  /// **'Ayirish 5 gacha'**
  String get topic_2_1;

  /// No description provided for @topic_2_2.
  ///
  /// In uz, this message translates to:
  /// **'Ayirish 10 gacha'**
  String get topic_2_2;

  /// No description provided for @topic_2_3.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish va ayirish'**
  String get topic_2_3;

  /// No description provided for @topic_2_4.
  ///
  /// In uz, this message translates to:
  /// **'Ketma-ketlik'**
  String get topic_2_4;

  /// No description provided for @topic_2_5.
  ///
  /// In uz, this message translates to:
  /// **'Aralash mashq'**
  String get topic_2_5;

  /// No description provided for @topic_2_6.
  ///
  /// In uz, this message translates to:
  /// **'2-bob sinovi'**
  String get topic_2_6;

  /// No description provided for @topic_3_1.
  ///
  /// In uz, this message translates to:
  /// **'Shakllar'**
  String get topic_3_1;

  /// No description provided for @topic_3_2.
  ///
  /// In uz, this message translates to:
  /// **'Shakllar 2'**
  String get topic_3_2;

  /// No description provided for @topic_3_3.
  ///
  /// In uz, this message translates to:
  /// **'Mantiqiy ketma-ketlik'**
  String get topic_3_3;

  /// No description provided for @topic_3_4.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish va ayirish'**
  String get topic_3_4;

  /// No description provided for @topic_3_5.
  ///
  /// In uz, this message translates to:
  /// **'Taqqoslash'**
  String get topic_3_5;

  /// No description provided for @topic_3_6.
  ///
  /// In uz, this message translates to:
  /// **'Katta sinov'**
  String get topic_3_6;

  /// No description provided for @chapter4Name.
  ///
  /// In uz, this message translates to:
  /// **'KO’LMAK'**
  String get chapter4Name;

  /// No description provided for @chapter4Sub.
  ///
  /// In uz, this message translates to:
  /// **'Sonlar 20 gacha'**
  String get chapter4Sub;

  /// No description provided for @chapter5Name.
  ///
  /// In uz, this message translates to:
  /// **'DALA'**
  String get chapter5Name;

  /// No description provided for @chapter5Sub.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish-ayirish 20 gacha'**
  String get chapter5Sub;

  /// No description provided for @chapter6Name.
  ///
  /// In uz, this message translates to:
  /// **'BOG’'**
  String get chapter6Name;

  /// No description provided for @chapter6Sub.
  ///
  /// In uz, this message translates to:
  /// **'Ko’paytirish'**
  String get chapter6Sub;

  /// No description provided for @tagMultiplication.
  ///
  /// In uz, this message translates to:
  /// **'KO’PAYTIRISH'**
  String get tagMultiplication;

  /// No description provided for @topic_4_1.
  ///
  /// In uz, this message translates to:
  /// **'Ketma-ketlik 20 gacha'**
  String get topic_4_1;

  /// No description provided for @topic_4_2.
  ///
  /// In uz, this message translates to:
  /// **'Taqqoslash'**
  String get topic_4_2;

  /// No description provided for @topic_4_3.
  ///
  /// In uz, this message translates to:
  /// **'Aralash mashq'**
  String get topic_4_3;

  /// No description provided for @topic_4_4.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish 15 gacha'**
  String get topic_4_4;

  /// No description provided for @topic_4_5.
  ///
  /// In uz, this message translates to:
  /// **'Aralash mashq'**
  String get topic_4_5;

  /// No description provided for @topic_4_6.
  ///
  /// In uz, this message translates to:
  /// **'4-bob sinovi'**
  String get topic_4_6;

  /// No description provided for @topic_5_1.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish 15 gacha'**
  String get topic_5_1;

  /// No description provided for @topic_5_2.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shish 20 gacha'**
  String get topic_5_2;

  /// No description provided for @topic_5_3.
  ///
  /// In uz, this message translates to:
  /// **'Ayirish 15 gacha'**
  String get topic_5_3;

  /// No description provided for @topic_5_4.
  ///
  /// In uz, this message translates to:
  /// **'Ayirish 20 gacha'**
  String get topic_5_4;

  /// No description provided for @topic_5_5.
  ///
  /// In uz, this message translates to:
  /// **'Tezkor mashq'**
  String get topic_5_5;

  /// No description provided for @topic_5_6.
  ///
  /// In uz, this message translates to:
  /// **'5-bob sinovi'**
  String get topic_5_6;

  /// No description provided for @topic_6_1.
  ///
  /// In uz, this message translates to:
  /// **'Ko’paytirish 2×'**
  String get topic_6_1;

  /// No description provided for @topic_6_2.
  ///
  /// In uz, this message translates to:
  /// **'Ko’paytirish 3×'**
  String get topic_6_2;

  /// No description provided for @topic_6_3.
  ///
  /// In uz, this message translates to:
  /// **'Guruhlar'**
  String get topic_6_3;

  /// No description provided for @topic_6_4.
  ///
  /// In uz, this message translates to:
  /// **'Aralash amallar'**
  String get topic_6_4;

  /// No description provided for @topic_6_5.
  ///
  /// In uz, this message translates to:
  /// **'Taqqoslash'**
  String get topic_6_5;

  /// No description provided for @topic_6_6.
  ///
  /// In uz, this message translates to:
  /// **'Yakuniy sinov'**
  String get topic_6_6;

  /// No description provided for @shopCatPowerup.
  ///
  /// In uz, this message translates to:
  /// **'Yordamchilar'**
  String get shopCatPowerup;

  /// No description provided for @shopOwnedCount.
  ///
  /// In uz, this message translates to:
  /// **'Sizda: {n}'**
  String shopOwnedCount(int n);

  /// No description provided for @itemPowerHeart.
  ///
  /// In uz, this message translates to:
  /// **'Qo’shimcha yurak'**
  String get itemPowerHeart;

  /// No description provided for @itemPowerHint.
  ///
  /// In uz, this message translates to:
  /// **'Yordam'**
  String get itemPowerHint;

  /// No description provided for @itemPowerSkip.
  ///
  /// In uz, this message translates to:
  /// **'O’tkazish'**
  String get itemPowerSkip;

  /// No description provided for @itemPowerCoinX2.
  ///
  /// In uz, this message translates to:
  /// **'Tanga ×2'**
  String get itemPowerCoinX2;

  /// No description provided for @failTitle.
  ///
  /// In uz, this message translates to:
  /// **'Yana urinamiz!'**
  String get failTitle;

  /// No description provided for @failRetry.
  ///
  /// In uz, this message translates to:
  /// **'Qaytadan'**
  String get failRetry;

  /// No description provided for @failExit.
  ///
  /// In uz, this message translates to:
  /// **'Chiqish'**
  String get failExit;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
