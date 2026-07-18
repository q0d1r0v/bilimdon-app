import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/features/game/quiz_controller.dart';

/// QuizController bo'shliq (gap) holatlari: taymer x fazalar matritsasi,
/// haqiqiy 4-javobli savolda reveal yo'li, takror-taqdimot invariantlari,
/// progress monotonligi va bubbleKind o'tishlar matritsasi.
/// (quiz_controller_test.dart dagi asosiy oqimlar takrorlanmaydi.)
Question makeQ(int n, {QuestionType type = QuestionType.counting}) {
  return Question(
    id: 'q$n',
    type: type,
    data: const {},
    answers: [for (var i = 0; i < 4; i++) AnswerCell.number(n * 10 + i)],
    correctIndex: 0,
  );
}

/// Ishlab chiqarish sxemasidagi HAQIQIY savol — fromJson barcha himoyaviy
/// tekshiruvlardan o'tadi (4 javob, addition uchun a/b/missing, vizual).
Question realAdditionQuestion() {
  return Question.fromJson({
    'id': 'gap-add-1',
    'type': 'addition',
    'data': {'a': 3, 'b': 2, 'missing': 'none'},
    'visual': {
      'kind': 'grouped',
      'animal': 'chick',
      'groups': [3, 2],
    },
    'answers': [
      {'number': 4},
      {'number': 5},
      {'number': 6},
      {'number': 7},
    ],
    'correctIndex': 1,
  });
}

QuizController makeController({
  List<Question>? questions,
  bool timerEnabled = false,
  bool shuffleAnswers = true,
  int seed = 42,
}) {
  return QuizController(
    baseQuestions: questions ?? [for (var n = 1; n <= 5; n++) makeQ(n)],
    timerEnabled: timerEnabled,
    shuffleAnswers: shuffleAnswers,
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
  group('timer expiry x phase matrix', () {
    test('expiry during feedbackCorrect is a no-op and keeps earned bonus',
        () {
      final c = makeController(timerEnabled: true);
      c.selectAnswer(c.current.correctIndex); // tez javob — bonus olindi
      expect(c.phase, QuizPhase.feedbackCorrect);
      expect(c.speedBonus, 5);

      var notifications = 0;
      c.addListener(() => notifications++);
      c.onTimerExpired(); // feedback bosqichida — no-op
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(c.speedBonus, 5, reason: 'berilgan bonus qaytarib olinmaydi');
      expect(notifications, 0);

      c.completeFeedback();
      expect(c.timerExpiredThisQuestion, isFalse);
      answerCorrect(c); // keyingi savol tez — yana bonus
      expect(c.speedBonus, 10);
    });

    test('expiry during feedbackWrong is a no-op; flag stays clear on retry',
        () {
      final c = makeController(timerEnabled: true);
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackWrong);

      var notifications = 0;
      c.addListener(() => notifications++);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(notifications, 0);

      c.completeFeedback();
      expect(c.phase, QuizPhase.question);
      // Bayroq hech qachon o'rnatilmagan — qayta urinishdagi to'g'ri
      // javob hali ham tezlik bonusini oladi.
      c.selectAnswer(c.current.correctIndex);
      expect(c.speedBonus, 5);
    });

    test('expiry during feedbackReveal and finished is a no-op', () {
      final c = makeController(timerEnabled: true, questions: [makeQ(1)]);
      answerWrongOnce(c);
      answerWrongOnce(c);
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);

      var notifications = 0;
      c.addListener(() => notifications++);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(notifications, 0);

      c.completeFeedback(); // takror taqdimot
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(notifications, 3, reason: 'faqat javob/feedback notifylari');
    });

    test('double expiry on the same question notifies only once', () {
      final c = makeController(timerEnabled: true);
      var notifications = 0;
      c.addListener(() => notifications++);
      c.onTimerExpired();
      expect(c.timerExpiredThisQuestion, isTrue);
      expect(notifications, 1);
      c.onTimerExpired(); // ikkinchi chaqiruv — no-op
      expect(notifications, 1);
    });

    test('onTimerExpired with timer disabled is a no-op in every phase', () {
      final c = makeController(questions: [makeQ(1), makeQ(2)]);
      var notifications = 0;
      c.addListener(() => notifications++);

      c.onTimerExpired(); // question
      expect(c.timerExpiredThisQuestion, isFalse);
      c.selectAnswer(c.current.correctIndex);
      c.onTimerExpired(); // feedbackCorrect
      expect(c.timerExpiredThisQuestion, isFalse);
      c.completeFeedback();
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
      c.onTimerExpired(); // finished
      expect(c.timerExpiredThisQuestion, isFalse);
      expect(c.speedBonus, 0, reason: 'taymer o’chiq — bonus umuman yo’q');
      expect(notifications, 4);
    });

    test('speed bonus skipped after expiry, granted on later fast questions',
        () {
      final c = makeController(timerEnabled: true);
      // q1: sekin (taymer tugadi) — bonus yo'q
      c.onTimerExpired();
      answerCorrect(c);
      expect(c.speedBonus, 0);
      // q2: tez — +5
      answerCorrect(c);
      expect(c.speedBonus, 5);
      // q3: yana sekin — bonus o'zgarmaydi
      c.onTimerExpired();
      answerCorrect(c);
      expect(c.speedBonus, 5);
      // q4: tez — +5
      answerCorrect(c);
      expect(c.speedBonus, 10);
      // q5: yakuniy savolda ham sekin javob bonus olmaydi
      c.onTimerExpired();
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
      expect(c.speedBonus, 10);
      expect(c.sessionCoins, 50);
      expect(c.totalReward, 50 + 10 + 50);
    });
  });

  group('reveal path on a real 4-answer question', () {
    test('scripted order (shuffle off): wrong, hint-fade, faded tap, reveal',
        () {
      final base = realAdditionQuestion(); // correctIndex 1
      final c = makeController(questions: [base], shuffleAnswers: false);

      // 1-xato: yurak ketadi (yagona marta).
      c.selectAnswer(0);
      expect(c.phase, QuizPhase.feedbackWrong);
      expect(c.bubbleKind, BubbleKind.wrong);
      expect(c.hearts, 2);
      c.completeFeedback();

      // 2-xato: hint + fade (eng kichik mos indeks = 3), yurak ketmaydi.
      c.selectAnswer(2);
      expect(c.phase, QuizPhase.feedbackWrong);
      expect(c.bubbleKind, BubbleKind.hint);
      expect(c.hearts, 2);
      expect(c.fadedIndexes, {3});
      // Xiralashgan javob BOSILADIGAN bo'lib qoladi — disabled emas.
      expect(c.disabledIndexes, {0, 2});
      expect(c.disabledIndexes, isNot(contains(3)));
      c.completeFeedback();

      // 3-xato aynan xiralashgan indeksda — reveal bosqichi.
      c.selectAnswer(3);
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(c.bubbleKind, BubbleKind.reveal);
      expect(c.hearts, 2, reason: 'birinchi xatodan keyin yurak ketmaydi');
      expect(c.sessionCoins, 0);
      expect(c.totalQuestions, 2, reason: 'takror BIR marta navbatga tushdi');

      // Takror taqdimotda tartib saqlangan (shuffle off) va yakunlanadi.
      c.completeFeedback();
      expect(c.isRepeatPass, isTrue);
      expect(c.current.id, base.id);
      expect(c.current.correctIndex, base.correctIndex);
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
      expect(c.totalQuestions, 2, reason: 'reveal takrori qayta qo’shilmadi');
    });

    test('shuffled real question keeps the same invariants', () {
      final c = makeController(
        questions: [realAdditionQuestion()],
        shuffleAnswers: true,
        seed: 7,
      );
      expect(c.current.correctAnswer, const AnswerCell.number(5));

      c.selectAnswer(firstWrongIndex(c));
      expect(c.hearts, 2);
      c.completeFeedback();
      c.selectAnswer(firstWrongIndex(c));
      expect(c.hearts, 2);
      final faded = c.fadedIndexes.single;
      expect(c.disabledIndexes, isNot(contains(faded)));
      c.completeFeedback();

      c.selectAnswer(faded);
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(c.hearts, 2);
      expect(c.totalQuestions, 2);

      c.completeFeedback();
      expect(c.isRepeatPass, isTrue);
      // Takror nusxada ham correctIndex to'g'ri qiymatni ko'rsatadi.
      expect(c.current.correctAnswer, const AnswerCell.number(5));
      answerCorrect(c);
      expect(c.phase, QuizPhase.finished);
    });
  });

  group('repeat pass invariants', () {
    test('full reveal on repeat: no heart loss, no re-enqueue, no recount',
        () {
      final qs = [
        makeQ(1, type: QuestionType.counting),
        makeQ(2, type: QuestionType.addition),
      ];
      final c = makeController(questions: qs);
      answerWrongOnce(c); // q1 — yurak 2 ga tushadi
      answerCorrect(c); // q1 navbatga tushdi
      answerCorrect(c); // q2
      expect(c.isRepeatPass, isTrue);
      expect(c.hearts, 2);
      expect(c.totalQuestions, 3);
      final skillsBefore = Map.of(c.skillCounts);

      // Takrorda 3 xato — reveal, lekin yurak/navbat/statistika o'zgarmas.
      c.selectAnswer(firstWrongIndex(c));
      expect(c.hearts, 2);
      c.completeFeedback();
      c.selectAnswer(firstWrongIndex(c));
      expect(c.hearts, 2);
      c.completeFeedback();
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);
      expect(c.hearts, 2);
      expect(c.totalQuestions, 3);
      expect(c.skillCounts, skillsBefore);

      c.completeFeedback();
      expect(c.phase, QuizPhase.finished);
    });

    test('wrong-then-correct on repeat neither recounts skills nor enqueues',
        () {
      final qs = [
        makeQ(1, type: QuestionType.counting),
        makeQ(2, type: QuestionType.addition),
      ];
      final c = makeController(questions: qs);
      answerWrongOnce(c);
      answerCorrect(c);
      answerCorrect(c);
      expect(c.isRepeatPass, isTrue);
      expect(
        c.skillCounts[QuestionType.counting],
        (answered: 1, correctFirstTry: 0),
      );

      answerWrongOnce(c); // takrorda xato
      expect(c.hearts, 2);
      answerCorrect(c); // attempt>0 dagi to'g'ri — lekin takror taqdimot
      expect(c.phase, QuizPhase.finished);
      expect(c.totalQuestions, 3, reason: 'takror qayta navbatga tushmadi');
      expect(
        c.skillCounts[QuestionType.counting],
        (answered: 1, correctFirstTry: 0),
        reason: 'takror yechimi statistikaga qo’shilmaydi',
      );
      expect(
        c.skillCounts[QuestionType.addition],
        (answered: 1, correctFirstTry: 1),
      );
    });
  });

  group('shuffleAnswers=false identity', () {
    test('base and reveal-repeat copies are the very same question objects',
        () {
      final base = realAdditionQuestion();
      final c = makeController(questions: [base], shuffleAnswers: false);
      expect(identical(c.current, base), isTrue);

      answerWrongOnce(c);
      answerWrongOnce(c);
      c.selectAnswer(firstWrongIndex(c));
      expect(c.phase, QuizPhase.feedbackReveal);
      c.completeFeedback();

      expect(c.isRepeatPass, isTrue);
      expect(identical(c.current, base), isTrue,
          reason: 'shuffle o’chiq — takror nusxa ham aynan shu obyekt');
      expect(c.current.answers, base.answers);
      expect(c.current.correctIndex, base.correctIndex);
    });
  });

  group('progress monotonic guard', () {
    test('mid-run enqueue never lowers progress; exact values', () {
      final c = makeController(); // 5 baza savol
      expect(c.progress, 0.0);

      answerCorrect(c); // q1
      expect(c.progress, closeTo(1 / 5, 1e-9));

      // q2: xato, keyin to'g'ri — to'g'ri javob paytida navbat 6 ga o'sadi,
      // raw 1/6 < 1/5 bo'lib qoladi, lekin progress ORQAGA tushmaydi.
      c.selectAnswer(firstWrongIndex(c));
      c.completeFeedback();
      c.selectAnswer(c.current.correctIndex);
      expect(c.totalQuestions, 6);
      expect(c.progress, closeTo(1 / 5, 1e-9),
          reason: 'monoton qo’riqchi: 1/6 ga tushmasligi kerak');

      c.completeFeedback();
      expect(c.progress, closeTo(2 / 6, 1e-9));

      var last = c.progress;
      while (c.phase != QuizPhase.finished) {
        answerCorrect(c);
        expect(c.progress, greaterThanOrEqualTo(last));
        last = c.progress;
      }
      expect(c.progress, 1.0);
    });
  });

  group('selectAnswer disabled-index guard', () {
    test('tap on disabled index changes nothing and does not notify', () {
      final c = makeController();
      final wrong = firstWrongIndex(c);
      c.selectAnswer(wrong);
      c.completeFeedback();
      expect(c.phase, QuizPhase.question);
      expect(c.selectedIndex, isNull);

      var notifications = 0;
      c.addListener(() => notifications++);
      c.selectAnswer(wrong); // o'chirilgan indeks — to'liq no-op
      expect(notifications, 0);
      expect(c.attempt, 1);
      expect(c.selectedIndex, isNull);
      expect(c.phase, QuizPhase.question);
      expect(c.hearts, 2);
      expect(c.bubbleKind, BubbleKind.neutral);
    });
  });

  group('bubbleKind transition matrix', () {
    test('neutral -> correct/wrong/hint/reveal -> neutral across a run', () {
      final qs = [makeQ(1), makeQ(2), makeQ(3)];
      final c = makeController(questions: qs, shuffleAnswers: false);
      expect(c.bubbleKind, BubbleKind.neutral);

      // q1: to'g'ri — correct, keyin neutral.
      c.selectAnswer(c.current.correctIndex);
      expect(c.bubbleKind, BubbleKind.correct);
      c.completeFeedback();
      expect(c.bubbleKind, BubbleKind.neutral);

      // q2: 1-xato wrong, 2-xato hint, 3-xato reveal, keyin neutral.
      c.selectAnswer(firstWrongIndex(c));
      expect(c.bubbleKind, BubbleKind.wrong);
      c.completeFeedback();
      expect(c.bubbleKind, BubbleKind.neutral);
      c.selectAnswer(firstWrongIndex(c));
      expect(c.bubbleKind, BubbleKind.hint);
      c.completeFeedback();
      expect(c.bubbleKind, BubbleKind.neutral);
      c.selectAnswer(c.fadedIndexes.single);
      expect(c.bubbleKind, BubbleKind.reveal);
      c.completeFeedback();
      expect(c.bubbleKind, BubbleKind.neutral,
          reason: 'reveal dan keyingi savol neutral pufak bilan ochiladi');

      // q3 va q2 takrori — correct/neutral aylanishi davom etadi.
      c.selectAnswer(c.current.correctIndex);
      expect(c.bubbleKind, BubbleKind.correct);
      c.completeFeedback();
      expect(c.bubbleKind, BubbleKind.neutral);
      expect(c.isRepeatPass, isTrue);
    });

    test('finish keeps the last bubble kind (correct and reveal variants)',
        () {
      // Yakunda pufak qayta o'rnatilmaydi — UI finish overlay ko'rsatadi,
      // shuning uchun oxirgi qiymat saqlanib qolishi hujjatlangan xulq.
      final c1 = makeController(questions: [makeQ(1)]);
      answerCorrect(c1);
      expect(c1.phase, QuizPhase.finished);
      expect(c1.bubbleKind, BubbleKind.correct);

      final c2 = makeController(questions: [makeQ(1)]);
      // Baza savolda reveal, takrorda ham reveal — yakun reveal bilan.
      for (var pass = 0; pass < 2; pass++) {
        answerWrongOnce(c2);
        answerWrongOnce(c2);
        c2.selectAnswer(firstWrongIndex(c2));
        expect(c2.phase, QuizPhase.feedbackReveal);
        c2.completeFeedback();
      }
      expect(c2.phase, QuizPhase.finished);
      expect(c2.bubbleKind, BubbleKind.reveal);
    });
  });
}
