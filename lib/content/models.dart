/// Kontent modellari — sof Dart (Flutter importlarisiz).
///
/// JSON sxemasi (schemaVersion 1) `tools/generate_questions.mjs` tomonidan
/// generatsiya qilinadi va `assets/content/chN.json` fayllarida saqlanadi.
/// Barcha `fromJson` fabrikalar himoyaviy tekshiruv qiladi va xato
/// ma'lumotda savol/daraja id bilan [FormatException] tashlaydi.
library;

/// Savol turi. Statistikada kalit sifatida [name] ishlatiladi.
enum QuestionType {
  /// SANASH — «Nechta jo'jacha?»
  counting,

  /// QO'SHISH — «3 + 2 = ?» (yoki «3 + ? = 7», `missing: 'b'`)
  addition,

  /// AYIRISH — «5 − 2 = ?»
  subtraction,

  /// SHAKLLAR — «Uchburchakni top!»
  shapes,

  /// MANTIQ — «2, 4, 6, ... ?»
  sequence,

  /// TAQQOSLASH — «Eng kattasini top!»
  comparison,

  /// KO'PAYTIRISH — «3 × 2 = ?» (mahsulot <= 20)
  multiplication,
}

/// Shakl-javob turlari (SHAKLLAR savollari uchun).
enum ShapeKind { triangle, circle, square, diamond }

/// Hint-qator vizual turi.
enum VisualKind { count, grouped, faded, none }

/// Hint-qatorda chiziladigan hayvon.
enum HintAnimal { chick, pig, sheep }

T _enumFromJson<T extends Enum>(
  List<T> values,
  Object? raw, {
  required String field,
  required String context,
}) {
  if (raw is String) {
    for (final value in values) {
      if (value.name == raw) return value;
    }
  }
  throw FormatException('$context: "$field" qiymati noma’lum: $raw');
}

int _intFromJson(
  Object? raw, {
  required String field,
  required String context,
}) {
  if (raw is int) return raw;
  throw FormatException('$context: "$field" butun son bo’lishi kerak: $raw');
}

bool _boolFromJson(
  Object? raw, {
  required String field,
  required String context,
}) {
  if (raw is bool) return raw;
  throw FormatException(
    '$context: "$field" mantiqiy qiymat bo’lishi kerak: $raw',
  );
}

String _stringFromJson(
  Object? raw, {
  required String field,
  required String context,
}) {
  if (raw is String && raw.isNotEmpty) return raw;
  throw FormatException(
    '$context: "$field" bo’sh bo’lmagan matn bo’lishi kerak: $raw',
  );
}

/// Savol ustidagi vizual ko'rsatma (hint-qator).
///
/// Turi bo'yicha maydonlar: `count` → [animal] + [count]; `grouped` →
/// [animal] + [groups] (masalan 3+2 → [3,2]); `faded` → [animal] +
/// [count] + [faded] (oxirgi [faded] tasi xira, opacity .25); `none` —
/// vizualsiz.
class VisualHint {
  const VisualHint({
    required this.kind,
    this.animal,
    this.count,
    this.groups,
    this.faded,
  });

  factory VisualHint.fromJson(
    Map<String, Object?> json, {
    String context = 'vizual',
  }) {
    final kind = _enumFromJson(
      VisualKind.values,
      json['kind'],
      field: 'kind',
      context: context,
    );
    final animal = json['animal'] == null
        ? null
        : _enumFromJson(
            HintAnimal.values,
            json['animal'],
            field: 'animal',
            context: context,
          );
    final count = json['count'] == null
        ? null
        : _intFromJson(json['count'], field: 'count', context: context);
    if (count != null && (count < 0 || count > 12)) {
      throw FormatException(
        '$context: vizual soni 0..12 oralig’ida bo’lishi kerak: $count',
      );
    }
    final groups = switch (json['groups']) {
      null => null,
      final List<Object?> list => List<int>.unmodifiable([
          for (var i = 0; i < list.length; i++)
            _intFromJson(list[i], field: 'groups[$i]', context: context),
        ]),
      _ => throw FormatException('$context: "groups" ro’yxat bo’lishi kerak'),
    };
    final faded = json['faded'] == null
        ? null
        : _intFromJson(json['faded'], field: 'faded', context: context);
    if (kind == VisualKind.faded) {
      if (count == null || faded == null) {
        throw FormatException(
          '$context: faded vizualda "count" va "faded" bo’lishi kerak',
        );
      }
      if (faded < 1 || faded >= count) {
        throw FormatException(
          '$context: "faded" kamida 1 va count dan kichik bo’lishi kerak: '
          '$faded (count: $count)',
        );
      }
    }
    return VisualHint(
      kind: kind,
      animal: animal,
      count: count,
      groups: groups,
      faded: faded,
    );
  }

  final VisualKind kind;
  final HintAnimal? animal;
  final int? count;
  final List<int>? groups;
  final int? faded;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (animal != null) 'animal': animal!.name,
        if (count != null) 'count': count,
        if (groups != null) 'groups': groups,
        if (faded != null) 'faded': faded,
      };
}

/// Bitta javob katakchasi: yo raqam, yo shakl — aynan bittasi null emas.
class AnswerCell {
  const AnswerCell.number(int this.number) : shape = null;

  const AnswerCell.shape(ShapeKind this.shape) : number = null;

  factory AnswerCell.fromJson(
    Map<String, Object?> json, {
    String context = 'javob',
  }) {
    final rawNumber = json['number'];
    final rawShape = json['shape'];
    if ((rawNumber == null) == (rawShape == null)) {
      throw FormatException(
        '$context: katakchada aynan bitta qiymat '
        '(number yoki shape) bo’lishi kerak',
      );
    }
    if (rawNumber != null) {
      return AnswerCell.number(
        _intFromJson(rawNumber, field: 'number', context: context),
      );
    }
    return AnswerCell.shape(
      _enumFromJson(
        ShapeKind.values,
        rawShape,
        field: 'shape',
        context: context,
      ),
    );
  }

  final int? number;
  final ShapeKind? shape;

  Map<String, Object?> toJson() =>
      number != null ? {'number': number} : {'shape': shape!.name};

  @override
  bool operator ==(Object other) =>
      other is AnswerCell && other.number == number && other.shape == shape;

  @override
  int get hashCode => Object.hash(number, shape);

  @override
  String toString() => 'AnswerCell(${number ?? shape!.name})';
}

/// Bitta viktorina savoli.
///
/// [data] tur bo'yicha: counting `{animal}` (soni vizualda); addition
/// `{a, b, missing: 'none'|'b'}` (missing 'b' bo'lsa natija `c` ham bor,
/// masalan 3 + ? = 7); subtraction — additiondagidek; shapes `{target}`;
/// sequence `{terms}`; comparison `{mode: 'biggest'|'smallest'}`.
class Question {
  const Question({
    required this.id,
    required this.type,
    required this.data,
    this.visual,
    required this.answers,
    required this.correctIndex,
  });

  factory Question.fromJson(Map<String, Object?> json) {
    final id = _stringFromJson(json['id'], field: 'id', context: 'savol');
    final context = 'savol $id';
    final type = _enumFromJson(
      QuestionType.values,
      json['type'],
      field: 'type',
      context: context,
    );
    final rawData = json['data'];
    if (rawData is! Map) {
      throw FormatException('$context: "data" obyekt bo’lishi kerak');
    }
    final data = Map<String, Object?>.unmodifiable(
      Map<String, Object?>.from(rawData),
    );
    final visual = switch (json['visual']) {
      null => null,
      final Map map => VisualHint.fromJson(
          Map<String, Object?>.from(map),
          context: context,
        ),
      _ => throw FormatException('$context: "visual" obyekt bo’lishi kerak'),
    };
    final rawAnswers = json['answers'];
    if (rawAnswers is! List) {
      throw FormatException('$context: "answers" ro’yxat bo’lishi kerak');
    }
    if (rawAnswers.length != 4) {
      throw FormatException(
        '$context: aynan 4 ta javob bo’lishi kerak, topildi: '
        '${rawAnswers.length}',
      );
    }
    final answers = List<AnswerCell>.unmodifiable([
      for (var i = 0; i < rawAnswers.length; i++)
        AnswerCell.fromJson(
          switch (rawAnswers[i]) {
            final Map map => Map<String, Object?>.from(map),
            _ => throw FormatException(
                '$context: javob $i obyekt bo’lishi kerak',
              ),
          },
          context: '$context, javob $i',
        ),
    ]);
    if (answers.toSet().length != answers.length) {
      throw FormatException('$context: javoblar takrorlanmasligi kerak');
    }
    final correctIndex = _intFromJson(
      json['correctIndex'],
      field: 'correctIndex',
      context: context,
    );
    if (correctIndex < 0 || correctIndex > 3) {
      throw FormatException(
        '$context: correctIndex 0..3 oralig’ida bo’lishi kerak: $correctIndex',
      );
    }
    if (type == QuestionType.addition || type == QuestionType.subtraction) {
      final a = _intFromJson(data['a'], field: 'data.a', context: context);
      final b = _intFromJson(data['b'], field: 'data.b', context: context);
      final missing = data['missing'];
      if (missing != 'none' && missing != 'b') {
        throw FormatException(
          '$context: "data.missing" qiymati "none" yoki "b" '
          'bo’lishi kerak: $missing',
        );
      }
      if (type == QuestionType.subtraction && a - b < 1) {
        throw FormatException(
          '$context: ayirish natijasi kamida 1 bo’lishi kerak: $a − $b',
        );
      }
      if (missing == 'b') {
        // 3 + ? = c ko'rinishida natija "c" majburiy va a/b ga mos bo'lsin,
        // aks holda UI «3 + ? = null» kabi matn ko'rsatib qo'yadi.
        final c = _intFromJson(data['c'], field: 'data.c', context: context);
        final expected =
            type == QuestionType.addition ? a + b : a - b;
        if (c != expected) {
          throw FormatException(
            '$context: "data.c" $expected bo’lishi kerak: $c',
          );
        }
      }
    }
    if (type == QuestionType.sequence) {
      final terms = data['terms'];
      if (terms is! List || terms.isEmpty) {
        throw FormatException(
          '$context: "data.terms" bo’sh bo’lmagan ro’yxat bo’lishi kerak',
        );
      }
      for (var i = 0; i < terms.length; i++) {
        _intFromJson(terms[i], field: 'data.terms[$i]', context: context);
      }
    }
    if (type == QuestionType.comparison) {
      final mode = data['mode'];
      if (mode != 'biggest' && mode != 'smallest') {
        throw FormatException(
          '$context: "data.mode" qiymati "biggest" yoki "smallest" '
          'bo’lishi kerak: $mode',
        );
      }
    }
    if (type == QuestionType.multiplication) {
      _intFromJson(data['a'], field: 'data.a', context: context);
      _intFromJson(data['b'], field: 'data.b', context: context);
    }
    return Question(
      id: id,
      type: type,
      data: data,
      visual: visual,
      answers: answers,
      correctIndex: correctIndex,
    );
  }

  final String id;
  final QuestionType type;
  final Map<String, Object?> data;
  final VisualHint? visual;
  final List<AnswerCell> answers;
  final int correctIndex;

  /// To'g'ri javob katakchasi.
  AnswerCell get correctAnswer => answers[correctIndex];

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'data': data,
        if (visual != null) 'visual': visual!.toJson(),
        'answers': [for (final cell in answers) cell.toJson()],
        'correctIndex': correctIndex,
      };
}

/// Bitta daraja (masalan "1-3" — 1-bob, 3-daraja).
class LevelDef {
  const LevelDef({
    required this.id,
    required this.chapter,
    required this.index,
    required this.timerEnabled,
    required this.timerSeconds,
    this.shuffleAnswers = true,
    required this.questions,
  });

  factory LevelDef.fromJson(Map<String, Object?> json) {
    final id = _stringFromJson(json['id'], field: 'id', context: 'daraja');
    final context = 'daraja $id';
    final rawQuestions = json['questions'];
    if (rawQuestions is! List) {
      throw FormatException('$context: "questions" ro’yxat bo’lishi kerak');
    }
    return LevelDef(
      id: id,
      chapter: _intFromJson(
        json['chapter'],
        field: 'chapter',
        context: context,
      ),
      index: _intFromJson(json['index'], field: 'index', context: context),
      timerEnabled: _boolFromJson(
        json['timerEnabled'],
        field: 'timerEnabled',
        context: context,
      ),
      timerSeconds: _intFromJson(
        json['timerSeconds'],
        field: 'timerSeconds',
        context: context,
      ),
      shuffleAnswers: json['shuffleAnswers'] == null
          ? true
          : _boolFromJson(
              json['shuffleAnswers'],
              field: 'shuffleAnswers',
              context: context,
            ),
      questions: List<Question>.unmodifiable([
        for (final rawQuestion in rawQuestions)
          Question.fromJson(
            switch (rawQuestion) {
              final Map map => Map<String, Object?>.from(map),
              _ => throw FormatException(
                  '$context: savol obyekt bo’lishi kerak',
                ),
            },
          ),
      ]),
    );
  }

  /// "1-3" ko'rinishidagi identifikator.
  final String id;
  final int chapter;
  final int index;
  final bool timerEnabled;
  final int timerSeconds;

  /// Javoblar taqdimotda aralashtiriladimi. Prototip darajalarda false —
  /// DESIGN_SPEC dagi javob tartibi aynan saqlanadi. JSONda yo'q bo'lsa
  /// true (eski sxema bilan moslik).
  final bool shuffleAnswers;

  final List<Question> questions;

  Map<String, Object?> toJson() => {
        'id': id,
        'chapter': chapter,
        'index': index,
        'timerEnabled': timerEnabled,
        'timerSeconds': timerSeconds,
        'shuffleAnswers': shuffleAnswers,
        'questions': [for (final question in questions) question.toJson()],
      };
}

/// Bitta bob (6 daraja).
class ChapterDef {
  const ChapterDef({required this.id, required this.levels});

  factory ChapterDef.fromJson(Map<String, Object?> json) {
    final id = _intFromJson(json['id'], field: 'id', context: 'bob');
    final context = 'bob $id';
    final rawLevels = json['levels'];
    if (rawLevels is! List) {
      throw FormatException('$context: "levels" ro’yxat bo’lishi kerak');
    }
    return ChapterDef(
      id: id,
      levels: List<LevelDef>.unmodifiable([
        for (final rawLevel in rawLevels)
          LevelDef.fromJson(
            switch (rawLevel) {
              final Map map => Map<String, Object?>.from(map),
              _ => throw FormatException(
                  '$context: daraja obyekt bo’lishi kerak',
                ),
            },
          ),
      ]),
    );
  }

  final int id;
  final List<LevelDef> levels;

  Map<String, Object?> toJson() => {
        'id': id,
        'levels': [for (final level in levels) level.toJson()],
      };
}
