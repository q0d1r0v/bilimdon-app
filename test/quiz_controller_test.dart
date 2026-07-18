import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/features/game/quiz_controller.dart';

/// Test savoli: 4 ta javob `n*10 + i` raqamlari (ishlab chiqarish
/// invarianti — fromJson aynan 4 talikni talab qiladi), to'g'risi doim
/// `n*10` (aralashtirishdan oldin index 0).
Question makeQ(int n, {QuestionType type = QuestionType.counting}) {
  return Question(
    id: 'q$n',
    type: type,
    data: const {},
    answers: [for (var i = 0; i < 4; i++) AnswerCell.number(n * 10 + i)],
    correctIndex: 0,
  );
}

List<Question> fiveQuestions() => [
      makeQ(1, type: QuestionType.counting),
      makeQ(2, type: QuestionType.addition),
      makeQ(3, type: QuestionType.shapes),
      makeQ(4, type: QuestionType.subtraction),
      makeQ(5, type: QuestionType.sequence),
    ];

QuizController makeController({
  List<Question>? questions,
  bool timerEnabled = false,
  bool shuffleAnswers = true,
  int shieldCharges = 0,
  int coinMultiplier = 1,
  int seed = 42,
}) {
  return QuizController(
    baseQuestions: questions ?? fiveQuestions(),
    timerEnabled: timerEnabled,
    shuffleAnswers: shuffleAnswers,
    shieldCharges: shieldCharges,
    coinMultiplier: coinMultiplier,
    rng: Random(seed),
  );
}

/// Bosib bo'ladigan birinchi noto'g'ri javob indeksi.
int firstWrongIndex(QuizController c) {
  for (var i = 0; i < c.current.answers.length; i++) {
    if (i != c.current.correctIndex && !c.disabledIndexes.contains(i)) {
      return i;
    }
  }
  fail('no selectable wrong answer left');
}

/// To'g'ri javob berib feedbackni yakunlaydi.
void answerCorrect(QuizController c) {
  c.selectAnswer(c.current.correctIndex);
  expect(c.phase, QuizPhase.feedbackCorrect);
  c.completeFeedback();
}

/// Bitta noto'g'ri javob berib savolga qaytadi.
void answerWrongOnce(QuizController c) {
  c.selectAnswer(firstWrongIndex(c));
  expect(c.phase, QuizPhase.feedbackWrong);
  c.completeFeedback();
  expect(c.phase, QuizPhase.question);
}

void main() {
  group('answer shuffle', () {
    test('keeps correctIndex pointing at the correct value', () {
      final c = makeController();
      var anyMoved = false;
      for (var i = 0; i < 5; i++) {
        final n = i + 1;
        expect(c.current.id, 'q$n');
        expect(c.current.correctAnswer, AnswerCell.number(n * 10));
        if (c.current.correctIndex != 0) anyMoved = true;
        answerCorrect(c);
      }
      expect(anyMoved, isTrue, reason: 'seeded rng should move some answers');
    });

    test('shuffleAnswers=false keeps base order, including repeat enqueue',
        () {
      final base = fiveQuestions();
      final c = makeController(questions: base, shuffleAnswers: false);
      for (var i = 0; i < 5; i++) {
        expect(c.current.answers, base[i].answers, reason: 'q${i + 1}');
        expect(c.current.correctIndex, base[i].correctIndex);
        if (i == 0) answerWrongOnce(c); // q1 takror navbatga tushadi
        answerCorrect(c);
      }
      // Takror taqdimot ham aralashtirilmaydi.
      expect(c.isRepeatPass, isTrue);
      expect(c.current.id, 'q1');
      expect(c.current.answers, base[0].answers);
      expect(c.current.correctIndex, base[0].correctIndex);
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
    });
  });

  group('perfect run', () {
    test('5/5 correct: finished, 3 hearts/stars, 50 coins, 50 bonus', () {
      final c = makeController();
      expect(c.phase, QuizPhase.question);
      for (var i = 0; i < 5; i++) {
        expect(c.questionNumber, i + 1);
        expect(c.isRepeatPass, isFalse);
        answerCorrect(c);
      }
      expect(c.phase, QuizPhase.finished);
      expect(c.totalQuestions, 5);
      expect(c.hearts, 3);
      expect(c.earnedStars, 3);
      expect(c.sessionCoins, 50);
      expect(c.speedBonus, 0);
      expect(c.finishBonus, 50);
      expect(c.totalReward, 100);
      expect(c.progress, 1.0);
    });
  });

  group('wrong answers and repeats', () {
    test('one wrong then correct: -1 heart, repeated once at end', () {
      final c = makeController();
      answerWrongOnce(c);
      expect(c.hearts, 2);
      expect(c.attempt, 1);
      answerCorrect(c); // xato bo'lgan savol navbatga qo'shiladi
      expect(c.totalQuestions, 6);
      for (var i = 0; i < 4; i++) {
        answerCorrect(c);
      }
      // Takror taqdimot
      expect(c.phase, QuizPhase.question);
      expect(c.isRepeatPass, isTrue);
      expect(c.questionNumber, 6);
      expect(c.current.id, 'q1');
      final coinsBefore = c.sessionCoins;
      answerCorrect(c);
      expect(c.sessionCoins, coinsBefore + 10);
      expect(c.phase, QuizPhase.finished);
      expect(c.hearts, 2);
      expect(c.earnedStars, 2);
      expect(c.sessionCoins, 60);
    });

    test('wrong on repeat pass does not decrement hearts or re-enqueue', () {
      final c = makeController();
      answerWrongOnce(c);
      answerCorrect(c);
      for (var i = 0; i < 4; i++) {
        answerCorrect(c);
      }
      expect(c.isRepeatPass, isTrue);
      expect(c.hearts, 2);
      answerWrongOnce(c); // takrorda xato — yurak ketmaydi
      expect(c.hearts, 2);
      answerCorrect(c);
      expect(c.totalQuestions, 6); // qayta navbatga qo'shilmadi
      expect(c.phase, QuizPhase.finished);
      expect(c.hearts, 2);
    });

    test('three wrongs: reveal phase, only first attempt costs a heart, '
        'question repeats', () {
      final qs = [
        makeQ(1),
        makeQ(2, type: QuestionType.addition),
      ];
      final c = makeController(questions: qs);

      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackWrong);
      expect(c.bubbleKind, BubbleKind.wrong);
      expect(c.hearts, 2);
      c.completeFeedback();

      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackWrong);
      expect(c.bubbleKind, BubbleKind.hint);
      expect(c.hearts, 2); // faqat birinchi xato yurak oladi
      c.completeFeedback();

      // 3-xato: 4 javobli savolda faqat xiralashgan javob qoladi —
      // u bosiladigan bo'lishi shart, aks holda reveal'ga yetib bo'lmaydi.
      final faded = c.fadedIndexes.single;
      expect(c.disabledIndexes, isNot(contains(faded)));
      expect(firstWrongIndex(c), faded);
      final coinsBefore = c.sessionCoins;
      c.selectAnswer(faded);
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(c.bubbleKind, BubbleKind.reveal);
      expect(c.hearts, 2);
      expect(c.sessionCoins, coinsBefore, reason: 'reveal mukofot bermaydi');
      expect(c.totalQuestions, 3); // takror navbatga qo'shildi

      c.completeFeedback();
      expect(c.current.id, 'q2');
      answerCorrect(c);

      expect(c.isRepeatPass, isTrue);
      expect(c.current.id, 'q1');
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
    });

    test('reveal on repeat pass does not re-enqueue', () {
      final qs = [makeQ(1)];
      final c = makeController(questions: qs);
      // 3 xato → reveal → takror
      for (var i = 0; i < 2; i++) {
        answerWrongOnce(c);
      }
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);
      c.completeFeedback();
      expect(c.totalQuestions, 2);
      expect(c.isRepeatPass, isTrue);
      // Takrorda ham 3 xato → reveal, lekin navbat o'smaydi
      for (var i = 0; i < 2; i++) {
        answerWrongOnce(c);
      }
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(c.totalQuestions, 2);
      c.completeFeedback();
      expect(c.phase, QuizPhase.finished);
    });
  });

  group('attempt 2 hint fade', () {
    test('fades exactly one wrong answer which stays tappable', () {
      final c = makeController(questions: [makeQ(1)]);
      answerWrongOnce(c);
      expect(c.disabledIndexes.length, 1);
      expect(c.fadedIndexes, isEmpty);
      answerWrongOnce(c);
      expect(c.fadedIndexes.length, 1);
      // Faqat 2 ta bosilgan xato o'chadi; xiralashgan javob bosiladi.
      expect(c.disabledIndexes.length, 2);
      final faded = c.fadedIndexes.single;
      expect(c.disabledIndexes, isNot(contains(faded)));
      expect(faded, isNot(c.current.correctIndex));
      final live = [
        for (var i = 0; i < c.current.answers.length; i++)
          if (!c.disabledIndexes.contains(i)) i,
      ];
      expect(live.length, 2); // to'g'ri javob + xiralashgan xato
      expect(live, containsAll([c.current.correctIndex, faded]));
      // Xiralashgan javob bosilsa — 3-xato, reveal bosqichi.
      c.selectAnswer(faded);
      expect(c.phase, QuizPhase.feedbackReveal);
    });
  });

  group('yuraklar tugashi', () {
    test('uch birinchi-urinish xato yuraklarni tugatib failed ga o‘tadi', () {
      final c = makeController();
      // q1: birinchi urinishda xato → yurak 3→2, so'ng to'g'ri (keyingi savol).
      answerWrongOnce(c);
      answerCorrect(c);
      expect(c.hearts, 2);
      // q2: yurak 2→1.
      answerWrongOnce(c);
      answerCorrect(c);
      expect(c.hearts, 1);
      // q3: yurak 1→0 → silkinish, so'ng completeFeedback fail'ga o'tadi.
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackWrong);
      c.completeFeedback();
      expect(c.hearts, 0);
      expect(c.phase, QuizPhase.failed);
      expect(c.earnedStars, 0);
    });

    test('failed bosqichida completeFeedback no-op', () {
      final c = makeController();
      answerWrongOnce(c);
      answerCorrect(c);
      answerWrongOnce(c);
      answerCorrect(c);
      c.selectAnswer(firstWrongIndex(c));
      c.completeFeedback();
      expect(c.phase, QuizPhase.failed);
      var notified = false;
      c.addListener(() => notified = true);
      c.completeFeedback(); // failed'da hech narsa qilmaydi
      expect(c.phase, QuizPhase.failed);
      expect(notified, isFalse);
    });

    test('qalqon yurak o‘rniga ketadi — yulduzlar saqlanadi', () {
      final c = makeController(shieldCharges: 1);
      expect(c.shieldCharges, 1);
      // Birinchi xato qalqonni yeydi, yurak 3 da qoladi.
      answerWrongOnce(c);
      expect(c.shieldCharges, 0);
      expect(c.hearts, 3);
      answerCorrect(c);
      // Qalqon tugagach keyingi xato yurakdan ketadi.
      answerWrongOnce(c);
      expect(c.hearts, 2);
    });

    test('tanga ko‘paytirgich mukofotni ikkilantiradi', () {
      final c = makeController(coinMultiplier: 2);
      for (var i = 0; i < 5; i++) {
        answerCorrect(c);
      }
      expect(c.phase, QuizPhase.finished);
      // 5 to'g'ri × 10 + yakun bonusi (20 + 3×10 = 50) = 100; ×2 = 200.
      expect(c.totalReward, (50 + 50) * 2);
    });

    test('skipQuestion yuraksiz keyingi savolga o‘tadi', () {
      final c = makeController();
      expect(c.skipQuestion(), isTrue);
      expect(c.hearts, 3);
      expect(c.index, 1);
      expect(c.phase, QuizPhase.question);
    });

    test('useHint bitta xatoni xiralashtiradi', () {
      final c = makeController();
      expect(c.fadedIndexes, isEmpty);
      expect(c.useHint(), isTrue);
      expect(c.fadedIndexes.length, 1);
      expect(c.fadedIndexes.single, isNot(c.current.correctIndex));
    });
  });

  group('selectAnswer guards', () {
    test('no-op during feedback phases', () {
      final c = makeController();
      var notifications = 0;
      c.addListener(() => notifications++);
      c.selectAnswer(c.current.correctIndex);
      expect(notifications, 1);
      expect(c.phase, QuizPhase.feedbackCorrect);
      final coins = c.sessionCoins;
      c.selectAnswer(c.current.correctIndex); // feedbackda no-op
      c.selectAnswer(firstWrongIndex(c));
      expect(c.sessionCoins, coins);
      expect(c.phase, QuizPhase.feedbackCorrect);
      expect(notifications, 1); // no-op notify qilmaydi
    });

    test('no-op on disabled and out-of-range indexes', () {
      final c = makeController();
      final wrong = firstWrongIndex(c);
      c.selectAnswer(wrong);
      c.completeFeedback();
      expect(c.phase, QuizPhase.question);
      c.selectAnswer(wrong); // o'chirilgan indeks
      expect(c.attempt, 1);
      expect(c.phase, QuizPhase.question);
      c.selectAnswer(-1);
      c.selectAnswer(c.current.answers.length);
      expect(c.attempt, 1);
      expect(c.phase, QuizPhase.question);
    });

    test('completeFeedback is a no-op in question and finished phases', () {
      final c = makeController(questions: [makeQ(1)]);
      c.completeFeedback();
      expect(c.phase, QuizPhase.question);
      expect(c.index, 0);
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
      c.completeFeedback();
      expect(c.phase, QuizPhase.finished);
    });
  });

  group('timer', () {
    test('expiry has no penalty but forfeits speed bonus for that question',
        () {
      final c = makeController(timerEnabled: true);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isTrue);
      answerCorrect(c); // sekin javob — bonus yo'q
      expect(c.sessionCoins, 10);
      expect(c.speedBonus, 0);
      expect(c.hearts, 3);
      // Keyingi savolda flag tozalanadi, tez javob bonus oladi
      expect(c.timerExpiredThisQuestion, isFalse);
      answerCorrect(c);
      expect(c.speedBonus, 5);
    });

    test('onTimerExpired is a no-op when timer is disabled', () {
      final c = makeController(timerEnabled: false);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(notifications, 0);
      for (var i = 0; i < 5; i++) {
        answerCorrect(c);
      }
      expect(c.speedBonus, 0);
    });

    test('timerKey changes per question and per attempt', () {
      final c = makeController(timerEnabled: true);
      expect(c.timerKey, (0, 0));
      c.selectAnswer(firstWrongIndex(c));
      c.completeFeedback();
      expect(c.timerKey, (0, 1));
      c.selectAnswer(c.current.correctIndex);
      c.completeFeedback();
      expect(c.timerKey, (1, 0));
    });
  });

  group('rewards', () {
    test('totalReward = sessionCoins + speedBonus + finishBonus', () {
      final c = makeController(timerEnabled: true);
      // q1 sekin (taymer tugadi), qolganlari tez
      c.onTimerExpired();
      answerCorrect(c);
      for (var i = 0; i < 4; i++) {
        answerCorrect(c);
      }
      expect(c.phase, QuizPhase.finished);
      expect(c.sessionCoins, 50);
      expect(c.speedBonus, 20); // 4 ta tez javob
      expect(c.finishBonus, 50); // 20 + 3×10
      expect(c.totalReward, 120);
    });
  });

  group('progress', () {
    test('is monotonic even when repeats grow the queue, ends at 1.0', () {
      final c = makeController();
      var last = c.progress;
      void check() {
        expect(c.progress, greaterThanOrEqualTo(last));
        last = c.progress;
      }

      expect(c.progress, 0.0);
      answerCorrect(c);
      check();
      // q2: xato (navbat o'sadi) keyin to'g'ri
      c.selectAnswer(firstWrongIndex(c));
      check();
      c.completeFeedback();
      check();
      c.selectAnswer(c.current.correctIndex);
      check();
      c.completeFeedback();
      check();
      while (c.phase != QuizPhase.finished) {
        c.selectAnswer(c.current.correctIndex);
        check();
        c.completeFeedback();
        check();
      }
      expect(c.progress, 1.0);
    });
  });

  group('skillCounts', () {
    test('counts first-pass resolutions only, correctFirstTry on clean solve',
        () {
      final qs = [
        makeQ(1, type: QuestionType.counting),
        makeQ(2, type: QuestionType.addition),
        makeQ(3, type: QuestionType.addition),
      ];
      final c = makeController(questions: qs);
      // q1: xato → to'g'ri (firstTry emas)
      answerWrongOnce(c);
      answerCorrect(c);
      // q2, q3: darhol to'g'ri
      answerCorrect(c);
      answerCorrect(c);
      // q1 takrori — statistikaga qo'shilmaydi
      expect(c.isRepeatPass, isTrue);
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);

      expect(
        c.skillCounts[QuestionType.counting],
        (answered: 1, correctFirstTry: 0),
      );
      expect(
        c.skillCounts[QuestionType.addition],
        (answered: 2, correctFirstTry: 2),
      );
    });

    test('reveal counts as answered without correctFirstTry', () {
      final qs = [makeQ(1, type: QuestionType.shapes)];
      final c = makeController(questions: qs);
      answerWrongOnce(c);
      answerWrongOnce(c);
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(
        c.skillCounts[QuestionType.shapes],
        (answered: 1, correctFirstTry: 0),
      );
      c.completeFeedback();
      answerCorrect(c); // takror — hisob o'zgarmaydi
      expect(
        c.skillCounts[QuestionType.shapes],
        (answered: 1, correctFirstTry: 0),
      );
    });
  });
}
