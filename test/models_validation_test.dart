import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';

/// Model validatsiyasi: har bir fromJson xato yo'li [FormatException]
/// tashlaydi va xabarda savol/daraja id bo'ladi (diagnostika uchun).
/// ChapterDef roundtrip esa haqiqiy aktivda toJson/fromJson izchilligini
/// tekshiradi.
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

/// FormatException tashlanadi va xabari [id] ni o'z ichiga oladi.
Matcher _throwsFormatWithId(String id) => throwsA(
      isA<FormatException>()
          .having((e) => e.message, 'message', contains(id)),
    );

const String _qId = 'val-q1';

Map<String, Object?> _question({
  String type = 'addition',
  Map<String, Object?> data = const {'a': 3, 'b': 4, 'missing': 'none'},
  Map<String, Object?>? visual,
  List<Object?>? answers,
  Object? correctIndex = 0,
}) =>
    {
      'id': _qId,
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

Map<String, Object?> _level({
  Object? id = '9-1',
  Object? timerSeconds = 0,
  Object? shuffleAnswers = 'absent',
}) =>
    {
      'id': id,
      'chapter': 9,
      'index': 1,
      'timerEnabled': false,
      'timerSeconds': timerSeconds,
      if (shuffleAnswers != 'absent') 'shuffleAnswers': shuffleAnswers,
      'questions': const <Object?>[],
    };

void main() {
  group('Question.fromJson xato yo’llari — id xabarda ko’rinadi', () {
    test('4 ta emas javob rad etiladi (3 va 5 talik)', () {
      expect(
        () => Question.fromJson(
          _question(answers: [
            for (var i = 0; i < 3; i++) {'number': i},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
      expect(
        () => Question.fromJson(
          _question(answers: [
            for (var i = 0; i < 5; i++) {'number': i},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
    });

    test('takrorlangan javoblar rad etiladi', () {
      expect(
        () => Question.fromJson(
          _question(answers: [
            {'number': 7},
            {'number': 7},
            {'number': 8},
            {'number': 5},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
      // Takrorlangan shakllar ham.
      expect(
        () => Question.fromJson(
          _question(
            type: 'shapes',
            data: const {'target': 'circle'},
            answers: [
              {'shape': 'circle'},
              {'shape': 'circle'},
              {'shape': 'square'},
              {'shape': 'diamond'},
            ],
          ),
        ),
        _throwsFormatWithId(_qId),
      );
    });

    test('correctIndex 0..3 dan tashqarida rad etiladi', () {
      expect(
        () => Question.fromJson(_question(correctIndex: -1)),
        _throwsFormatWithId(_qId),
      );
      expect(
        () => Question.fromJson(_question(correctIndex: 4)),
        _throwsFormatWithId(_qId),
      );
      // Chegara qiymatlari qabul qilinadi.
      expect(Question.fromJson(_question(correctIndex: 0)).correctIndex, 0);
      expect(Question.fromJson(_question(correctIndex: 3)).correctIndex, 3);
    });

    test('ayirish natijasi kamida 1 — a-b<1 rad etiladi', () {
      Map<String, Object?> sub(int a, int b) => _question(
            type: 'subtraction',
            data: {'a': a, 'b': b, 'missing': 'none'},
          );
      expect(
        () => Question.fromJson(sub(3, 3)),
        _throwsFormatWithId(_qId),
      );
      expect(
        () => Question.fromJson(sub(2, 5)),
        _throwsFormatWithId(_qId),
      );
      // a-b == 1 — eng kichik ruxsat etilgan natija.
      expect(Question.fromJson(sub(4, 3)).data['b'], 3);
    });

    test('vizual soni 12 dan oshmasin', () {
      Map<String, Object?> counting(int count) => _question(
            type: 'counting',
            data: const {'animal': 'chick'},
            visual: {'kind': 'count', 'animal': 'chick', 'count': count},
          );
      expect(
        () => Question.fromJson(counting(13)),
        _throwsFormatWithId(_qId),
      );
      // 12 — chegara, qabul qilinadi.
      expect(Question.fromJson(counting(12)).visual?.count, 12);
    });

    test('faded >= count rad etiladi', () {
      Map<String, Object?> faded(int count, int fadedCount) => _question(
            type: 'subtraction',
            data: const {'a': 5, 'b': 2, 'missing': 'none'},
            visual: {
              'kind': 'faded',
              'animal': 'sheep',
              'count': count,
              'faded': fadedCount,
            },
          );
      expect(
        () => Question.fromJson(faded(5, 5)),
        _throwsFormatWithId(_qId),
      );
      expect(
        () => Question.fromJson(faded(5, 6)),
        _throwsFormatWithId(_qId),
      );
      expect(Question.fromJson(faded(5, 4)).visual?.faded, 4);
    });

    test('missing "b" bo’lsa "data.c" siz rad etiladi', () {
      expect(
        () => Question.fromJson(
          _question(data: const {'a': 3, 'b': 4, 'missing': 'b'}),
        ),
        _throwsFormatWithId(_qId),
      );
      expect(
        () => Question.fromJson(
          _question(
            type: 'subtraction',
            data: const {'a': 9, 'b': 4, 'missing': 'b'},
          ),
        ),
        _throwsFormatWithId(_qId),
      );
    });

    test('noma’lum enum satrlari rad etiladi (type/shape/animal/kind)', () {
      // type (mavjud bo'lmagan tur).
      expect(
        () => Question.fromJson(_question(type: 'division')),
        _throwsFormatWithId(_qId),
      );
      // javob shakli.
      expect(
        () => Question.fromJson(
          _question(
            type: 'shapes',
            data: const {'target': 'triangle'},
            answers: [
              {'shape': 'star'},
              {'shape': 'circle'},
              {'shape': 'square'},
              {'shape': 'diamond'},
            ],
          ),
        ),
        _throwsFormatWithId(_qId),
      );
      // vizual hayvoni (cow hint-qatorda yo'q).
      expect(
        () => Question.fromJson(
          _question(
            type: 'counting',
            data: const {'animal': 'chick'},
            visual: const {'kind': 'count', 'animal': 'cow', 'count': 4},
          ),
        ),
        _throwsFormatWithId(_qId),
      );
      // vizual turi.
      expect(
        () => Question.fromJson(
          _question(
            type: 'counting',
            data: const {'animal': 'chick'},
            visual: const {'kind': 'sparkle', 'animal': 'chick', 'count': 4},
          ),
        ),
        _throwsFormatWithId(_qId),
      );
    });

    test('butun son kutilgan joyda boshqa tur rad etiladi', () {
      // correctIndex satr sifatida.
      expect(
        () => Question.fromJson(_question(correctIndex: '0')),
        _throwsFormatWithId(_qId),
      );
      // data.a kasr son sifatida (jsonDecode 4.5 → double).
      expect(
        () => Question.fromJson(
          _question(data: const {'a': 4.5, 'b': 2, 'missing': 'none'}),
        ),
        _throwsFormatWithId(_qId),
      );
      // vizual soni satr sifatida.
      expect(
        () => Question.fromJson(
          _question(
            type: 'counting',
            data: const {'animal': 'chick'},
            visual: const {'kind': 'count', 'animal': 'chick', 'count': '4'},
          ),
        ),
        _throwsFormatWithId(_qId),
      );
      // javob raqami satr sifatida.
      expect(
        () => Question.fromJson(
          _question(answers: [
            {'number': '7'},
            {'number': 6},
            {'number': 8},
            {'number': 5},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
    });

    test('javob katakchasida aynan bitta qiymat (number XOR shape)', () {
      // Bo'sh katakcha.
      expect(
        () => Question.fromJson(
          _question(answers: [
            <String, Object?>{},
            {'number': 6},
            {'number': 8},
            {'number': 5},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
      // Ikkalasi ham berilgan.
      expect(
        () => Question.fromJson(
          _question(answers: [
            {'number': 7, 'shape': 'circle'},
            {'number': 6},
            {'number': 8},
            {'number': 5},
          ]),
        ),
        _throwsFormatWithId(_qId),
      );
    });
  });

  group('LevelDef.fromJson', () {
    test('id: bo’sh yoki satr bo’lmagan qiymat rad etiladi; '
        'naqsh (masalan "1-3") majburiy EMAS — generator kafolatlaydi', () {
      expect(
        () => LevelDef.fromJson(_level(id: '')),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => LevelDef.fromJson(_level(id: 13)),
        throwsA(isA<FormatException>()),
      );
      // Naqsh tekshirilmaydi: ixtiyoriy bo'sh bo'lmagan satr qabul qilinadi.
      expect(LevelDef.fromJson(_level(id: 'g’alati-id')).id, 'g’alati-id');
    });

    test('butun son kutilgan maydonda satr — daraja id xabarda', () {
      expect(
        () => LevelDef.fromJson(_level(timerSeconds: '30')),
        _throwsFormatWithId('9-1'),
      );
    });

    test('shuffleAnswers: JSONda yo’q → true, false hurmat qilinadi', () {
      expect(LevelDef.fromJson(_level()).shuffleAnswers, isTrue);
      expect(
        LevelDef.fromJson(_level(shuffleAnswers: false)).shuffleAnswers,
        isFalse,
      );
      expect(
        LevelDef.fromJson(_level(shuffleAnswers: true)).shuffleAnswers,
        isTrue,
      );
      expect(
        () => LevelDef.fromJson(_level(shuffleAnswers: 1)),
        _throwsFormatWithId('9-1'),
      );
    });

    test('savolda xato bo’lsa savol id xabarga chiqadi', () {
      final level = _level();
      level['questions'] = [
        _question(correctIndex: 9),
      ];
      expect(
        () => LevelDef.fromJson(level),
        _throwsFormatWithId(_qId),
      );
    });
  });

  group('ChapterDef roundtrip (haqiqiy aktiv)', () {
    test('ch1: toJson → fromJson → toJson aynan teng', () {
      final chapter = _loadChapter('ch1');
      final roundtrip = ChapterDef.fromJson(chapter.toJson());

      expect(roundtrip.id, chapter.id);
      expect(roundtrip.levels, hasLength(chapter.levels.length));
      for (final (i, level) in chapter.levels.indexed) {
        final other = roundtrip.levels[i];
        expect(other.id, level.id);
        expect(other.shuffleAnswers, level.shuffleAnswers, reason: level.id);
        expect(other.timerEnabled, level.timerEnabled, reason: level.id);
        expect(other.timerSeconds, level.timerSeconds, reason: level.id);
        for (final (j, question) in level.questions.indexed) {
          final otherQ = other.questions[j];
          expect(otherQ.id, question.id);
          expect(otherQ.type, question.type, reason: question.id);
          // AnswerCell == chuqur taqqoslaydi.
          expect(otherQ.answers, question.answers, reason: question.id);
          expect(
            otherQ.correctIndex,
            question.correctIndex,
            reason: question.id,
          );
        }
      }
      // Chuqur map/list tengligi va JSONga qayta kodlanish barqarorligi.
      expect(roundtrip.toJson(), equals(chapter.toJson()));
      expect(
        jsonEncode(roundtrip.toJson()),
        jsonEncode(chapter.toJson()),
      );
    });

    test('ch2 va ch3 ham roundtripda o’zgarmaydi', () {
      for (final name in ['ch2', 'ch3']) {
        final chapter = _loadChapter(name);
        final roundtrip = ChapterDef.fromJson(chapter.toJson());
        expect(roundtrip.toJson(), equals(chapter.toJson()), reason: name);
      }
    });
  });
}
