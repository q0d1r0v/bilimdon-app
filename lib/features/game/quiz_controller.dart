import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../content/models.dart';

/// O'yin bosqichi. Vaqt (dwell/animatsiya) UI tomonida boshqariladi —
/// controller faqat holat mashinasini yuritadi.
enum QuizPhase {
  /// Savol ko'rsatilmoqda, javob kutilmoqda.
  question,

  /// To'g'ri javob feedbacki (popIn, yashil pufak).
  feedbackCorrect,

  /// Noto'g'ri javob feedbacki (shakeX) — savol qayta urinishga qoladi.
  feedbackWrong,

  /// 3 xatodan keyin to'g'ri javob ochib ko'rsatiladi.
  feedbackReveal,

  /// Barcha savollar (takrorlar bilan) tugadi.
  finished,

  /// 3 yurak tugadi — daraja muvaffaqiyatsiz (muloyim qayta boshlash).
  failed,
}

/// Sigir pufagining ko'rinishi (matnlar l10n da hal qilinadi).
enum BubbleKind { neutral, correct, wrong, hint, reveal }

/// Ko'nikma statistikasi yozuvi (ProgressStore.skills bilan mos shakl).
typedef SkillCount = ({int answered, int correctFirstTry});

/// Viktorina holat mashinasi — sof mantiq, hech qanday Timer/Future yo'q.
///
/// [shuffleAnswers] yoqilganda javoblar tartibi konstruksiyada (va takror
/// navbatga qo'shishda) [rng] bilan aralashtiriladi (correctIndex qayta
/// hisoblanadi); o'chirilganda (prototip darajalar) tartib aynan saqlanadi.
/// Noto'g'ri yechilgan savollar taqdimot ro'yxati oxiriga bir marta
/// takrorlash uchun qo'shiladi.
class QuizController extends ChangeNotifier {
  QuizController({
    required List<Question> baseQuestions,
    required this.timerEnabled,
    this.timerSeconds = 10,
    this.shuffleAnswers = true,
    int shieldCharges = 0,
    this.coinMultiplier = 1,
    Random? rng,
  })  : assert(baseQuestions.isNotEmpty, 'baseQuestions bo’sh bo’lmasin'),
        _rng = rng ?? Random(),
        _shieldCharges = shieldCharges,
        _baseCount = baseQuestions.length {
    _questions = [
      for (final q in baseQuestions) shuffleAnswers ? _shuffleAnswers(q) : q,
    ];
  }

  // FarmRules (tokens.dart) bilan bir xil qiymatlar — bu fayl faqat
  // foundation + dart:math + models import qilgani uchun takrorlangan.
  static const _maxHearts = 3;
  static const _coinsPerCorrect = 10;
  static const _speedBonusCoins = 5;
  static const _finishBonusBase = 20;
  static const _finishBonusPerHeart = 10;

  /// Taymer yoqilganmi. Taymer faqat bonus uchun — tugasa jazo YO'Q.
  final bool timerEnabled;

  /// Bir savolga ajratilgan soniyalar (UI taymer bar davomiyligi).
  final int timerSeconds;

  /// Javoblar tartibi aralashtiriladimi (LevelDef.shuffleAnswers dan
  /// keladi; prototip darajalarda false — DESIGN_SPEC tartibi saqlanadi).
  final bool shuffleAnswers;

  /// Tanga ko'paytirgich (power-up: ×2). Mukofotga qo'llanadi.
  final int coinMultiplier;

  /// Qalqon zaryadlari (power-up): yurak tushishi kerak bo'lganda qalqon
  /// bo'lsa yurak o'rniga qalqon ketadi (yulduz ≤3 buzilmaydi).
  int _shieldCharges;

  /// 3 yurak tugab, joriy noto'g'ri feedback'dan keyin fail'ga o'tish belgisi.
  bool _pendingFail = false;

  final Random _rng;
  final int _baseCount;
  late final List<Question> _questions;

  QuizPhase _phase = QuizPhase.question;
  int _index = 0;
  int _hearts = _maxHearts;
  int _sessionCoins = 0;
  int _speedBonus = 0;
  int _attempt = 0;
  int? _selectedIndex;
  final Set<int> _disabledIndexes = {};
  final Set<int> _fadedIndexes = {};
  bool _timerExpiredThisQuestion = false;
  BubbleKind _bubbleKind = BubbleKind.neutral;
  int _answered = 0;
  double _progress = 0;
  final Set<int> _enqueuedIndexes = {};
  final Map<QuestionType, SkillCount> _skillCounts = {};

  /// Joriy bosqich.
  QuizPhase get phase => _phase;

  /// Joriy taqdimot indeksi (0 dan boshlab).
  int get index => _index;

  /// Joriy savol (javoblari aralashtirilgan nusxa).
  Question get current => _questions[_index];

  /// 1 dan boshlanadigan savol raqami («Savol N / M» uchun).
  int get questionNumber => _index + 1;

  /// Baza savollar + hozirgacha qo'shilgan takrorlar soni.
  int get totalQuestions => _questions.length;

  /// Yuraklar (3 dan boshlanadi). 0 ga tushsa — daraja fail (qayta boshlash).
  int get hearts => _hearts;

  /// Qolgan qalqon zaryadlari (UI ko'rsatishi mumkin).
  int get shieldCharges => _shieldCharges;

  /// Bu sessiyada to'g'ri javoblardan yig'ilgan tangalar.
  int get sessionCoins => _sessionCoins;

  /// Taymer tugamasidan oldin berilgan javoblar bonusi.
  int get speedBonus => _speedBonus;

  /// Joriy savoldagi noto'g'ri urinishlar soni (0 dan boshlab).
  int get attempt => _attempt;

  /// Oxirgi tanlangan javob indeksi (feedback bosqichida UI uchun).
  int? get selectedIndex => _selectedIndex;

  /// Bu savolda noto'g'ri bosilgan (endi bosib bo'lmaydigan) indekslar.
  Set<int> get disabledIndexes => Set.unmodifiable(_disabledIndexes);

  /// 2-urinishda avtomatik xiralashtirilgan indekslar. Xiralashgan javob
  /// bosiladigan bo'lib qoladi (faqat vizual ishora) — 3-xato shu orqali
  /// reveal bosqichiga yetadi.
  Set<int> get fadedIndexes => Set.unmodifiable(_fadedIndexes);

  /// Joriy savol takror taqdimotmi.
  bool get isRepeatPass => _index >= _baseCount;

  /// O'zgarganda UI taymer barni qayta ishga tushiradi.
  (int, int) get timerKey => (_index, _attempt);

  /// Bu savolda taymer tugaganmi (tezlik bonusi yo'qoladi, jazo yo'q).
  bool get timerExpiredThisQuestion => _timerExpiredThisQuestion;

  /// Progress bar qiymati — monoton o'sadi, yakunda 1.0.
  double get progress => _phase == QuizPhase.finished ? 1.0 : _progress;

  /// Sigir pufagining joriy ko'rinishi.
  BubbleKind get bubbleKind => _bubbleKind;

  /// Yakunda beriladigan yulduzlar = qolgan yuraklar.
  int get earnedStars => _hearts;

  /// Yakun bonusi: 20 + yurak×10.
  int get finishBonus => _finishBonusBase + _hearts * _finishBonusPerHeart;

  /// Sessiyaning umumiy mukofoti (tanga ko'paytirgich bilan).
  int get totalReward =>
      (_sessionCoins + _speedBonus + finishBonus) * coinMultiplier;

  /// Ko'nikma statistikasi: har baza savol birinchi yechimida `answered`,
  /// birinchi taqdimotda xatosiz yechilsa `correctFirstTry` ortadi.
  Map<QuestionType, SkillCount> get skillCounts =>
      Map<QuestionType, SkillCount>.unmodifiable(_skillCounts);

  /// Javob tanlash. Faqat [QuizPhase.question] bosqichida va faol
  /// (o'chirilmagan) indekslarda ishlaydi, aks holda no-op.
  void selectAnswer(int i) {
    if (_phase != QuizPhase.question) return;
    if (i < 0 || i >= current.answers.length) return;
    if (_disabledIndexes.contains(i)) return;

    _selectedIndex = i;
    if (i == current.correctIndex) {
      _sessionCoins += _coinsPerCorrect;
      if (timerEnabled && !_timerExpiredThisQuestion) {
        _speedBonus += _speedBonusCoins;
      }
      _recordResolution(firstTry: _attempt == 0);
      if (_attempt > 0) _enqueueRepeat();
      _phase = QuizPhase.feedbackCorrect;
      _bubbleKind = BubbleKind.correct;
    } else {
      _attempt += 1;
      _disabledIndexes.add(i);
      if (_attempt == 1 && !isRepeatPass) {
        // Yurak faqat birinchi xatoda ketadi; takror taqdimotda ketmaydi.
        // Qalqon bo'lsa yurak o'rniga qalqon ketadi.
        if (_shieldCharges > 0) {
          _shieldCharges -= 1;
        } else {
          _hearts -= 1;
        }
      }
      if (_hearts <= 0 && !isRepeatPass) {
        // 3 yurak tugadi — noto'g'ri feedback (silkinish) ko'rsatiladi,
        // so'ng completeFeedback fail'ga o'tadi.
        _pendingFail = true;
        _bubbleKind = BubbleKind.wrong;
        _phase = QuizPhase.feedbackWrong;
      } else if (_attempt >= 3) {
        _recordResolution(firstTry: false);
        _enqueueRepeat();
        _phase = QuizPhase.feedbackReveal;
        _bubbleKind = BubbleKind.reveal;
      } else {
        if (_attempt == 2) {
          _fadeOneWrongAnswer();
          _bubbleKind = BubbleKind.hint;
        } else {
          _bubbleKind = BubbleKind.wrong;
        }
        _phase = QuizPhase.feedbackWrong;
      }
    }
    notifyListeners();
  }

  /// UI taymeri tugaganda chaqiriladi. Jazo yo'q — faqat shu savol uchun
  /// tezlik bonusi bekor bo'ladi.
  void onTimerExpired() {
    if (!timerEnabled ||
        _phase != QuizPhase.question ||
        _timerExpiredThisQuestion) {
      return;
    }
    _timerExpiredThisQuestion = true;
    notifyListeners();
  }

  /// Feedback dwelli tugagach UI chaqiradi: to'g'ri/reveal → keyingi savol
  /// yoki yakun; noto'g'ri → shu savolga qayta urinish.
  void completeFeedback() {
    switch (_phase) {
      case QuizPhase.feedbackWrong:
        if (_pendingFail) {
          _phase = QuizPhase.failed;
        } else {
          _phase = QuizPhase.question;
          _selectedIndex = null;
          _bubbleKind = BubbleKind.neutral;
        }
        notifyListeners();
      case QuizPhase.feedbackCorrect || QuizPhase.feedbackReveal:
        _answered += 1;
        _bumpProgress();
        if (_index + 1 >= _questions.length) {
          _phase = QuizPhase.finished;
        } else {
          _index += 1;
          _attempt = 0;
          _selectedIndex = null;
          _disabledIndexes.clear();
          _fadedIndexes.clear();
          _timerExpiredThisQuestion = false;
          _bubbleKind = BubbleKind.neutral;
          _phase = QuizPhase.question;
        }
        notifyListeners();
      case QuizPhase.question || QuizPhase.finished || QuizPhase.failed:
        break; // no-op
    }
  }

  /// Power-up: yordam — bitta noto'g'ri javobni xiralashtiradi. Faqat savol
  /// bosqichida ishlaydi. Xiralashtirilsa `true` qaytadi (o'shanda chaqiruvchi
  /// store'dan power-up sarflaydi).
  bool useHint() {
    if (_phase != QuizPhase.question) return false;
    final before = _fadedIndexes.length;
    _fadeOneWrongAnswer();
    if (_fadedIndexes.length == before) return false;
    _bubbleKind = BubbleKind.hint;
    notifyListeners();
    return true;
  }

  /// Power-up: savolni o'tkazib yuborish — yuraksiz keyingi savolga o'tadi
  /// (tanga/ko'nikma yozilmaydi). Faqat savol bosqichida.
  bool skipQuestion() {
    if (_phase != QuizPhase.question) return false;
    _answered += 1;
    _bumpProgress();
    if (_index + 1 >= _questions.length) {
      _phase = QuizPhase.finished;
    } else {
      _index += 1;
      _attempt = 0;
      _selectedIndex = null;
      _disabledIndexes.clear();
      _fadedIndexes.clear();
      _timerExpiredThisQuestion = false;
      _bubbleKind = BubbleKind.neutral;
      _phase = QuizPhase.question;
    }
    notifyListeners();
    return true;
  }

  /// Javoblar tartibini aralashtirib, correctIndex ni qayta hisoblaydi.
  Question _shuffleAnswers(Question q) {
    final order = List<int>.generate(q.answers.length, (i) => i)
      ..shuffle(_rng);
    return Question(
      id: q.id,
      type: q.type,
      data: q.data,
      visual: q.visual,
      answers: List<AnswerCell>.unmodifiable(
        [for (final i in order) q.answers[i]],
      ),
      correctIndex: order.indexOf(q.correctIndex),
    );
  }

  /// Joriy savolni ro'yxat oxiriga BIR marta takrorlash uchun qo'shadi.
  /// Takror taqdimotlar qayta navbatga qo'shilmaydi.
  void _enqueueRepeat() {
    if (isRepeatPass || _enqueuedIndexes.contains(_index)) return;
    _enqueuedIndexes.add(_index);
    _questions.add(shuffleAnswers ? _shuffleAnswers(current) : current);
    _bumpProgress();
  }

  /// 2-urinishda bitta qo'shimcha noto'g'ri javobni xiralashtiradi
  /// (deterministik: eng kichik mos indeks). Xiralashgan javob ATAYIN
  /// o'chirilmaydi — 4 javobli savolda 3-xato imkoni qolishi kerak,
  /// aks holda feedbackReveal bosqichiga yetib bo'lmaydi.
  void _fadeOneWrongAnswer() {
    for (var i = 0; i < current.answers.length; i++) {
      if (i == current.correctIndex || _disabledIndexes.contains(i)) continue;
      _fadedIndexes.add(i);
      return;
    }
  }

  /// Baza savolning birinchi yechimida ko'nikma statistikasini yozadi.
  void _recordResolution({required bool firstTry}) {
    if (isRepeatPass) return;
    final prev =
        _skillCounts[current.type] ?? (answered: 0, correctFirstTry: 0);
    _skillCounts[current.type] = (
      answered: prev.answered + 1,
      correctFirstTry: prev.correctFirstTry + (firstTry ? 1 : 0),
    );
  }

  /// Progressni faqat oshiradi (takror qo'shilganda orqaga qaytmaydi).
  void _bumpProgress() {
    final raw = _answered / _questions.length;
    if (raw > _progress) _progress = raw;
  }
}
