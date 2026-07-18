import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';

/// Haqiqiy JSON aktivlarni diskdan o'qib, models.fromJson orqali tekshiradi
/// (rootBundle emas — yo'l loyiha ildizidan, Directory.current orqali).
ChapterDef _loadChapter(String name) {
  final file = File('${Directory.current.path}/assets/content/$name.json');
  final root = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  if (root['schemaVersion'] != 1) {
    throw FormatException('$name.json: schemaVersion 1 kutilgan edi');
  }
  return ChapterDef.fromJson(
    Map<String, Object?>.from(root['chapter'] as Map),
  );
}

List<AnswerCell> _numbers(List<int> values) => [
      for (final value in values) AnswerCell.number(value),
    ];

void main() {
  late List<ChapterDef> chapters;

  setUpAll(() {
    chapters = [
      for (final name in ['ch1', 'ch2', 'ch3', 'ch4', 'ch5', 'ch6'])
        _loadChapter(name),
    ];
  });

  test('6 bob, jami 36 daraja, har darajada 5 savol', () {
    expect(chapters, hasLength(6));
    final levels = [for (final chapter in chapters) ...chapter.levels];
    expect(levels, hasLength(36));
    for (final level in levels) {
      expect(level.questions, hasLength(5), reason: level.id);
    }
  });

  test('daraja metama’lumotlari izchil', () {
    for (final chapter in chapters) {
      for (final (i, level) in chapter.levels.indexed) {
        expect(level.chapter, chapter.id, reason: level.id);
        expect(level.index, i + 1, reason: level.id);
        expect(level.id, '${chapter.id}-${i + 1}');
        expect(
          level.timerEnabled,
          level.timerSeconds > 0,
          reason: level.id,
        );
        // Faqat 1-3 (prototip) aralashtirilmaydi — qolganlari true.
        expect(
          level.shuffleAnswers,
          level.id != '1-3',
          reason: level.id,
        );
      }
    }
  });

  test('har bir savol tekshiruv qoidalariga mos', () {
    for (final chapter in chapters) {
      for (final level in chapter.levels) {
        for (final question in level.questions) {
          // Aynan 4 ta har xil javob, correctIndex 0..3.
          expect(question.answers, hasLength(4), reason: question.id);
          expect(
            question.answers.toSet(),
            hasLength(4),
            reason: question.id,
          );
          expect(
            question.correctIndex,
            inInclusiveRange(0, 3),
            reason: question.id,
          );
          for (final cell in question.answers) {
            // Katakchada aynan bitta qiymat; raqamlar 0..20, manfiy emas.
            expect(
              (cell.number == null) != (cell.shape == null),
              isTrue,
              reason: question.id,
            );
            final number = cell.number;
            if (number != null) {
              expect(number, inInclusiveRange(0, 20), reason: question.id);
            }
          }
          // To'g'ri javob > 5 bo'lsa, distraktor 2 barobaridan oshmaydi.
          final correct = question.correctAnswer.number;
          if (correct != null && correct > 5) {
            for (final cell in question.answers) {
              final number = cell.number;
              if (number != null) {
                expect(
                  number,
                  lessThanOrEqualTo(correct * 2),
                  reason: question.id,
                );
              }
            }
          }
          // Arifmetika: a/b butun son, missing 'none'|'b'; missing 'b'
          // bo'lsa natija c majburiy va a/b ga mos (3 + ? = 7).
          if (question.type == QuestionType.addition ||
              question.type == QuestionType.subtraction) {
            final a = question.data['a']! as int;
            final b = question.data['b']! as int;
            final missing = question.data['missing'];
            expect(missing, anyOf('none', 'b'), reason: question.id);
            if (question.type == QuestionType.subtraction) {
              // Ayirish natijasi kamida 1.
              expect(a - b, greaterThanOrEqualTo(1), reason: question.id);
            }
            if (missing == 'b') {
              final expected =
                  question.type == QuestionType.addition ? a + b : a - b;
              expect(question.data['c'], expected, reason: question.id);
            }
          }
          // Vizual soni 0..12; faded vizualda 1 <= faded < count.
          final count = question.visual?.count;
          if (count != null) {
            expect(count, inInclusiveRange(0, 12), reason: question.id);
          }
          if (question.visual?.kind == VisualKind.faded) {
            final faded = question.visual!.faded;
            expect(faded, isNotNull, reason: question.id);
            expect(count, isNotNull, reason: question.id);
            expect(faded, inInclusiveRange(1, count! - 1),
                reason: question.id);
          }
        }
      }
    }
  });

  test('1-3 birinchi savoli — prototip jo’ja sanash [3,4,5,6], to’g’ri 1', () {
    final level = chapters[0].levels.firstWhere((l) => l.id == '1-3');
    final question = level.questions.first;
    expect(question.type, QuestionType.counting);
    expect(question.data['animal'], 'chick');
    expect(question.visual?.kind, VisualKind.count);
    expect(question.visual?.animal, HintAnimal.chick);
    expect(question.visual?.count, 4);
    expect(question.answers, _numbers([3, 4, 5, 6]));
    expect(question.correctIndex, 1);
  });

  test('1-3 darajasi — aynan 5 ta prototip savol, tartibi bilan', () {
    final level = chapters[0].levels.firstWhere((l) => l.id == '1-3');
    expect(level.timerEnabled, isFalse);
    expect(level.questions, hasLength(5));

    final [q1, q2, q3, q4, q5] = level.questions;

    // 1. SANASH: 4 jo'ja — [3,4,5,6], to'g'ri: 4.
    expect(q1.type, QuestionType.counting);
    expect(q1.answers, _numbers([3, 4, 5, 6]));
    expect(q1.correctIndex, 1);

    // 2. QO'SHISH: 3 + 2 (cho'chqalar grouped) — [4,5,6,3], to'g'ri: 5.
    expect(q2.type, QuestionType.addition);
    expect(q2.data['a'], 3);
    expect(q2.data['b'], 2);
    expect(q2.data['missing'], 'none');
    expect(q2.visual?.kind, VisualKind.grouped);
    expect(q2.visual?.animal, HintAnimal.pig);
    expect(q2.visual?.groups, [3, 2]);
    expect(q2.answers, _numbers([4, 5, 6, 3]));
    expect(q2.correctIndex, 1);

    // 3. SHAKLLAR: uchburchakni top — [tri, cir, sq, dia], to'g'ri: 0.
    expect(q3.type, QuestionType.shapes);
    expect(q3.data['target'], 'triangle');
    expect(q3.answers, [
      const AnswerCell.shape(ShapeKind.triangle),
      const AnswerCell.shape(ShapeKind.circle),
      const AnswerCell.shape(ShapeKind.square),
      const AnswerCell.shape(ShapeKind.diamond),
    ]);
    expect(q3.correctIndex, 0);

    // 4. AYIRISH: 5 − 2 (qo'ylar faded) — [2,3,4,6], to'g'ri: 3.
    expect(q4.type, QuestionType.subtraction);
    expect(q4.data['a'], 5);
    expect(q4.data['b'], 2);
    expect(q4.visual?.kind, VisualKind.faded);
    expect(q4.visual?.animal, HintAnimal.sheep);
    expect(q4.visual?.count, 5);
    expect(q4.visual?.faded, 2);
    expect(q4.answers, _numbers([2, 3, 4, 6]));
    expect(q4.correctIndex, 1);

    // 5. MANTIQ: 2, 4, 6, ... — [7,8,10,9], to'g'ri: 8.
    expect(q5.type, QuestionType.sequence);
    expect(q5.data['terms'], [2, 4, 6]);
    expect(q5.answers, _numbers([7, 8, 10, 9]));
    expect(q5.correctIndex, 1);
  });

  group('fromJson xato yo’llari', () {
    Map<String, Object?> question({
      String type = 'addition',
      Map<String, Object?> data = const {'a': 3, 'b': 4, 'missing': 'none'},
      Map<String, Object?>? visual,
      List<Object?>? answers,
      int correctIndex = 0,
    }) =>
        {
          'id': 'test-q1',
          'type': type,
          'data': data,
          'visual': ?visual,
          'answers': answers ??
              [
                {'number': 7},
                {'number': 6},
                {'number': 8},
                {'number': 5},
              ],
          'correctIndex': correctIndex,
        };

    final throwsFormat = throwsA(isA<FormatException>());

    test('missing "b" bo’lsa data.c majburiy va a/b ga mos', () {
      // c yo'q — rad etiladi (aks holda UI «3 + ? = null» chizadi).
      expect(
        () => Question.fromJson(
          question(data: const {'a': 3, 'b': 4, 'missing': 'b'}),
        ),
        throwsFormat,
      );
      // c mos emas — rad etiladi.
      expect(
        () => Question.fromJson(
          question(data: const {'a': 3, 'b': 4, 'missing': 'b', 'c': 8}),
        ),
        throwsFormat,
      );
      // Ayirishda ham: c != a - b — rad.
      expect(
        () => Question.fromJson(
          question(
            type: 'subtraction',
            data: const {'a': 9, 'b': 4, 'missing': 'b', 'c': 6},
          ),
        ),
        throwsFormat,
      );
      // Mos c — qabul qilinadi.
      final ok = Question.fromJson(
        question(data: const {'a': 3, 'b': 4, 'missing': 'b', 'c': 7}),
      );
      expect(ok.data['c'], 7);
      final okSub = Question.fromJson(
        question(
          type: 'subtraction',
          data: const {'a': 9, 'b': 4, 'missing': 'b', 'c': 5},
        ),
      );
      expect(okSub.data['c'], 5);
    });

    test('missing qiymati faqat "none" yoki "b"', () {
      expect(
        () => Question.fromJson(
          question(data: const {'a': 3, 'b': 4, 'missing': 'a'}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(question(data: const {'a': 3, 'b': 4})),
        throwsFormat,
      );
    });

    test('addition operandlari ham butun son bo’lishi shart', () {
      expect(
        () => Question.fromJson(
          question(data: const {'a': 'banana', 'b': 4, 'missing': 'none'}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          question(data: const {'a': 3, 'missing': 'none'}),
        ),
        throwsFormat,
      );
    });

    test('faded vizual: count/faded majburiy, 1 <= faded < count', () {
      Map<String, Object?> faded(Map<String, Object?> visual) => question(
            type: 'subtraction',
            data: const {'a': 5, 'b': 2, 'missing': 'none'},
            visual: visual,
          );
      expect(
        () => Question.fromJson(
          faded({'kind': 'faded', 'animal': 'sheep', 'count': 5, 'faded': 9}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          faded({'kind': 'faded', 'animal': 'sheep', 'count': 5, 'faded': 5}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          faded({'kind': 'faded', 'animal': 'sheep', 'count': 5, 'faded': 0}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          faded({'kind': 'faded', 'animal': 'sheep', 'faded': 2}),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          faded({'kind': 'faded', 'animal': 'sheep', 'count': 5}),
        ),
        throwsFormat,
      );
      final ok = Question.fromJson(
        faded({'kind': 'faded', 'animal': 'sheep', 'count': 5, 'faded': 2}),
      );
      expect(ok.visual?.faded, 2);
    });

    test('vizual soni manfiy bo’lmasin', () {
      expect(
        () => Question.fromJson(
          question(
            type: 'counting',
            data: const {'animal': 'chick'},
            visual: const {'kind': 'count', 'animal': 'chick', 'count': -3},
          ),
        ),
        throwsFormat,
      );
    });

    test('aynan 4 ta javob — 3 yoki 5 talik rad etiladi', () {
      expect(
        () => Question.fromJson(
          question(answers: [for (var i = 0; i < 5; i++) {'number': i}]),
        ),
        throwsFormat,
      );
      expect(
        () => Question.fromJson(
          question(answers: [for (var i = 0; i < 3; i++) {'number': i}]),
        ),
        throwsFormat,
      );
    });

    test('sequence: terms bo’sh bo’lmagan butun sonlar ro’yxati', () {
      Map<String, Object?> seq(Object? terms) => question(
            type: 'sequence',
            data: {'terms': terms},
          );
      expect(() => Question.fromJson(seq(null)), throwsFormat);
      expect(() => Question.fromJson(seq(const <Object?>[])), throwsFormat);
      expect(
        () => Question.fromJson(seq(const [2, 'x', 6])),
        throwsFormat,
      );
      final ok = Question.fromJson(seq(const [2, 4, 6]));
      expect(ok.data['terms'], [2, 4, 6]);
    });

    test('comparison: mode faqat "biggest" yoki "smallest"', () {
      Map<String, Object?> cmp(Object? mode) => question(
            type: 'comparison',
            data: {'mode': mode},
          );
      expect(() => Question.fromJson(cmp('medium')), throwsFormat);
      expect(() => Question.fromJson(cmp(null)), throwsFormat);
      expect(
        Question.fromJson(cmp('smallest')).data['mode'],
        'smallest',
      );
    });

    test('LevelDef.shuffleAnswers: default true, false o’qiladi, '
        'noto’g’ri tur rad etiladi', () {
      Map<String, Object?> level({Object? shuffleAnswers = 'absent'}) => {
            'id': '9-1',
            'chapter': 9,
            'index': 1,
            'timerEnabled': false,
            'timerSeconds': 0,
            if (shuffleAnswers != 'absent') 'shuffleAnswers': shuffleAnswers,
            'questions': const <Object?>[],
          };
      expect(LevelDef.fromJson(level()).shuffleAnswers, isTrue);
      expect(
        LevelDef.fromJson(level(shuffleAnswers: false)).shuffleAnswers,
        isFalse,
      );
      expect(
        LevelDef.fromJson(level(shuffleAnswers: true)).shuffleAnswers,
        isTrue,
      );
      expect(
        () => LevelDef.fromJson(level(shuffleAnswers: 'yo’q')),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
