import 'package:flutter/material.dart';

/// Barcha ranglar DESIGN_SPEC.md dan — prototipdan aynan.
/// Qoida: tokens.dart dan tashqarida xom hex ishlatilmaydi.
abstract final class FarmColors {
  // Osmon va tabiat
  static const skyTop = Color(0xFF57ADEE);
  static const skyMid = Color(0xFF8FD0F8);
  static const skyLow = Color(0xFFB8E6FF);
  static const grassLight = Color(0xFF8ED95E);
  static const grass = Color(0xFF6FC93F);
  static const bushDark = Color(0xFF4CA82E);
  static const navGrass = Color(0xFF7ED957);

  // Brend / harakatlar
  static const red = Color(0xFFE8433F);
  static const redDark = Color(0xFFC22F2C);
  static const redGradTop = Color(0xFFF26B5E);
  static const bannerGradTop = Color(0xFFF05A50);
  static const green = Color(0xFF58B94A);
  static const greenDark = Color(0xFF3F8F33);
  static const greenLight = Color(0xFF8EDD5F);
  static const blue = Color(0xFF3D9BE9);
  static const blueDark = Color(0xFF2C79BD);
  static const yellow = Color(0xFFFFC23C);
  static const yellowDark = Color(0xFFDB9A14);
  static const brown = Color(0xFFB5793B);
  static const brownDark = Color(0xFF8E5C2B);
  static const mud = Color(0xFFB0654A);
  static const mudDark = Color(0xFF8C4C36);

  // Tanga / streak / yulduz
  static const coin = Color(0xFFFFD43C);
  static const coinBorder = Color(0xFFE3A81E);
  static const coinText = Color(0xFFD69410);
  static const streakOrange = Color(0xFFFF8A3D);
  static const streakText = Color(0xFFF07A22);
  static const starGold = Color(0xFFFFB020);

  // Kontur va yuzalar
  static const outline = Color(0xFF4A3B28);
  static const cream = Color(0xFFFFFDF6);
  static const creamAvatar = Color(0xFFFFF6DE);
  static const fenceRail = Color(0xFFEFEDE6);
  static const fenceRailGame = Color(0xFFF7F5EE);
  static const fencePost = Color(0xFFF7F5EE);
  static const fencePostGame = Color(0xFFFFFDF6);
  static const gameBg = Color(0xFFFDF6E3);
  static const cardBorder = Color(0xFFF0DDB4);
  static const lockedBeige = Color(0xFFF2E9CE);
  static const lockedDark = Color(0xFFD8CBA4);
  static const lockIcon = Color(0xFFB3A67E);
  static const bonusPillBg = Color(0xFFFFF4D6);

  // Matn
  static const inkDark = Color(0xFF3A3520);
  static const inkOlive = Color(0xFF6E7F5A);
  static const inkGray = Color(0xFF8A8266);
  static const inkFaded = Color(0xFF9A9070);
  static const navInactive = Color(0xFFA8B894);
  static const navInactiveLight = Color(0xFFC4CFB4);
  static const headerSub = Color(0xFFE3F3FF);
  static const bannerSub = Color(0xFFFFD9CF);

  // Fikr-mulohaza yuzalari
  static const correctBg = Color(0xFFE3F7E9);
  static const wrongBg = Color(0xFFFFE8E6);
  static const tagGreenText = Color(0xFF3F8F33);
  static const tagGreenBg = Color(0xFFE7F6DF);

  // Yo'l
  static const pathDot = Color(0xFFF7E8B8);

  // Personajlar
  static const cowWhite = Color(0xFFFFFFFF);
  static const horn = Color(0xFFF2D8A0);
  static const cowPink = Color(0xFFF7B8C4);
  static const cowNostril = Color(0xFFC25E77);
  static const pigBody = Color(0xFFF9BCCB);
  static const pigEar = Color(0xFFF7A8B8);
  static const pigSnout = Color(0xFFF08CA4);
  static const pigNostril = Color(0xFFA8455C);
  static const pigBlush = Color(0xFFF585A0);
  static const sheepWool = Color(0xFFFFFDF6);
  static const sheepFace = Color(0xFFEFD9B8);
  static const chickBody = Color(0xFFFFD43C);
  static const chickWing = Color(0xFFF2B93C);
  static const chickBeak = Color(0xFFF07A22);
  static const chickenComb = Color(0xFFE8433F);
  static const chickenBody = Color(0xFFFFFDF6);
  // O'rdak — oq (Pekin) tana, to'q sariq tumshuq/oyoq, iliq soya qanot.
  static const duckBody = Color(0xFFFFFDF6);
  static const duckBill = Color(0xFFF6A21E);
  static const duckWing = Color(0xFFEDE4CE);
  // Quyon — iliq kulrang-oq tana, pushti quloq ichi/burun, oq dumaloq dum.
  static const rabbitBody = Color(0xFFEDE7DE);
  static const rabbitEar = Color(0xFFF3D0D6);
  static const rabbitNose = Color(0xFFEB9FAE);
  static const barnRoof = Color(0xFFE3B778);
  static const barnWall = Color(0xFFFFF6DE);
  static const barnDoor = Color(0xFFC22F2C);
}

abstract final class FarmSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

abstract final class FarmRadius {
  static const double pill = 999;
  static const double card = 24;
  static const double answerButton = 22;
  static const double banner = 18;
  static const double bubble = 12;
  static const double overlayCard = 28;
}

/// Prototipdagi keyframe qiymatlari — aynan.
abstract final class FarmAnim {
  static const pulseNode = Duration(milliseconds: 1600); // scale 1<->1.07
  static const shakeX = Duration(milliseconds: 400); // +-7px
  static const popIn = Duration(milliseconds: 400); // .4 -> 1.12 -> 1
  static const cardTransition = Duration(milliseconds: 280);
  static const progressFill = Duration(milliseconds: 400);
  static const feedbackDwellCorrect = Duration(milliseconds: 1000);
  static const feedbackDwellWrong = Duration(milliseconds: 800);
  static const revealDwell = Duration(milliseconds: 2500);
}

/// O'yin doimiylari.
abstract final class FarmRules {
  static const questionsPerLevel = 5;
  static const maxHearts = 3;
  static const coinsPerCorrect = 10;
  static const speedBonusCoins = 5;
  static const finishBonusBase = 20;
  static const finishBonusPerHeart = 10;
  static const levelsPerChapter = 6;
}
