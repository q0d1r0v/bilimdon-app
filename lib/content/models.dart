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
///
/// Hayvonli: [count], [grouped], [faded], [groupRows].
/// Hayvonsiz: [tenFrame], [numberLine], [bars].
enum VisualKind {
  /// n ta hayvon (sanash).
  count,

  /// a ta hayvon + «+» + b ta hayvon (aynan 2 guruh).
  grouped,

  /// n ta hayvon, oxirgi f tasi xira (ayirish).
  faded,

  /// a qator × b hayvon (ko'paytirish: 3 × 2 → 3 guruh, har birida 2 ta).
  groupRows,

  /// 2×5 katakli o'nlik ramka — 20 gacha sonlar (12 dan katta qo'shish/ayirish).
  tenFrame,

  /// Son chizig'i: hadlar + qadam strelkalari (ketma-ketlik).
  numberLine,

  /// Balandligi songa proporsional ustunlar (taqqoslash).
  bars,

  /// Vizualsiz.
  none,
}

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

/// Butun sonlar ro'yxati (`null` — maydon yo'q). Har element tekshiriladi.
List<int>? _intListFromJson(
  Object? raw, {
  required String field,
  required String context,
}) =>
    switch (raw) {
      null => null,
      final List<Object?> list => List<int>.unmodifiable([
          for (var i = 0; i < list.length; i++)
            _intFromJson(list[i], field: '$field[$i]', context: context),
        ]),
      _ => throw FormatException('$context: "$field" ro’yxat bo’lishi kerak'),
    };

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
/// Turi bo'yicha maydonlar:
///
/// | kind | maydonlar |
/// |---|---|
/// | `count` | [animal] + [count] (0..12) |
/// | `grouped` | [animal] + [groups] (aynan 2 ta, yig'indi ≤ 12) |
/// | `faded` | [animal] + [count] + [faded] (oxirgi [faded] tasi xira, .25) |
/// | `groupRows` | [animal] + [groups] (2..4 guruh, har biri 1..10, yig'indi ≤ 20) |
/// | `tenFrame` | [groups] (1..2 bo'lak, yig'indi 1..20) + ixtiyoriy [faded]/[target] |
/// | `numberLine` | [terms] (2..4 had, 0..20) + [step] (≠ 0) |
/// | `bars` | [values] (aynan 4 son, 0..20, kamida 2 xil) |
/// | `none` | — |
///
/// [groups] ATAYLAB uchta turda qayta ishlatiladi (yangi `parts` maydoni
/// kiritilmaydi) — JSON diffini kichik saqlaydi. Turlar orasidagi ma'no
/// farqi [fromJson] dagi `switch` bilan majburlanadi.
class VisualHint {
  const VisualHint({
    required this.kind,
    this.animal,
    this.count,
    this.groups,
    this.faded,
    this.target,
    this.terms,
    this.step,
    this.values,
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
    final groups = _intListFromJson(
      json['groups'],
      field: 'groups',
      context: context,
    );
    final faded = json['faded'] == null
        ? null
        : _intFromJson(json['faded'], field: 'faded', context: context);
    final target = json['target'] == null
        ? null
        : _intFromJson(json['target'], field: 'target', context: context);
    final terms = _intListFromJson(
      json['terms'],
      field: 'terms',
      context: context,
    );
    final step = json['step'] == null
        ? null
        : _intFromJson(json['step'], field: 'step', context: context);
    final values = _intListFromJson(
      json['values'],
      field: 'values',
      context: context,
    );

    // Tur bo'yicha majburiy maydonlar. Bu switch ikki mavjud yashirin
    // nuqsonni ham yopadi: animalsiz `count` va bitta guruhli `grouped` —
    // ular avval renderda JIMGINA bo'sh joy berardi.
    void need(bool ok, String what) {
      if (!ok) throw FormatException('$context: ${kind.name} vizualda $what');
    }

    switch (kind) {
      case VisualKind.count:
        need(animal != null, '"animal" bo’lishi kerak');
        need(count != null, '"count" bo’lishi kerak');
      case VisualKind.grouped:
        need(animal != null, '"animal" bo’lishi kerak');
        need(groups != null && groups.length == 2, '"groups" aynan 2 ta bo’lsin');
        need(
          groups!.every((g) => g >= 1) && groups.reduce((a, b) => a + b) <= 12,
          '"groups" har biri ≥ 1 va yig’indisi ≤ 12 bo’lsin',
        );
      case VisualKind.faded:
        if (count == null || faded == null) {
          throw FormatException(
            '$context: faded vizualda "count" va "faded" bo’lishi kerak',
          );
        }
        need(animal != null, '"animal" bo’lishi kerak');
        if (faded < 1 || faded >= count) {
          throw FormatException(
            '$context: "faded" kamida 1 va count dan kichik bo’lishi kerak: '
            '$faded (count: $count)',
          );
        }
      case VisualKind.groupRows:
        need(animal != null, '"animal" bo’lishi kerak');
        need(
          groups != null && groups.length >= 2 && groups.length <= 4,
          '"groups" 2..4 ta bo’lsin',
        );
        need(
          groups!.every((g) => g >= 1 && g <= 10) &&
              groups.reduce((a, b) => a + b) <= 20,
          '"groups" har biri 1..10 va yig’indisi ≤ 20 bo’lsin',
        );
      case VisualKind.tenFrame:
        need(
          groups != null && groups.isNotEmpty && groups.length <= 2,
          '"groups" 1..2 bo’lak bo’lsin',
        );
        final sum = groups!.reduce((a, b) => a + b);
        need(
          groups.every((g) => g >= 1) && sum >= 1 && sum <= 20,
          '"groups" har biri ≥ 1 va yig’indisi 1..20 bo’lsin',
        );
        if (faded != null) {
          need(faded >= 1 && faded <= sum, '"faded" 1..$sum bo’lsin');
        }
        if (target != null) {
          need(
            target > sum && target <= 20,
            '"target" yig’indidan katta va ≤ 20 bo’lsin',
          );
        }
      case VisualKind.numberLine:
        need(
          terms != null && terms.length >= 2 && terms.length <= 4,
          '"terms" 2..4 had bo’lsin',
        );
        need(
          terms!.every((t) => t >= 0 && t <= 20),
          '"terms" har biri 0..20 bo’lsin',
        );
        need(step != null && step != 0, '"step" nolga teng bo’lmasin');
        for (var i = 1; i < terms.length; i++) {
          need(
            terms[i] - terms[i - 1] == step,
            'hadlar qadamga mos bo’lsin (strelka yolg’on ko’rsatmasligi kerak): '
            '${terms.join(",")} step $step',
          );
        }
      case VisualKind.bars:
        need(values != null && values.length == 4, '"values" aynan 4 ta bo’lsin');
        need(
          values!.every((v) => v >= 0 && v <= 20),
          '"values" har biri 0..20 bo’lsin',
        );
        need(values.toSet().length >= 2, '"values" kamida 2 xil bo’lsin');
      case VisualKind.none:
        break;
    }

    return VisualHint(
      kind: kind,
      animal: animal,
      count: count,
      groups: groups,
      faded: faded,
      target: target,
      terms: terms,
      step: step,
      values: values,
    );
  }

  final VisualKind kind;
  final HintAnimal? animal;
  final int? count;
  final List<int>? groups;
  final int? faded;

  /// `tenFrame`: yetishmayotgan operand savolida maqsad (`a + ? = target`) —
  /// a dan keyingi kataklar sariq halqa bilan belgilanadi.
  final int? target;

  /// `numberLine`: ko'rsatiladigan hadlar.
  final List<int>? terms;

  /// `numberLine`: hadlar orasidagi qadam (manfiy bo'lishi mumkin).
  final int? step;

  /// `bars`: to'rtta taqqoslanadigan son.
  final List<int>? values;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        if (animal != null) 'animal': animal!.name,
        if (count != null) 'count': count,
        if (groups != null) 'groups': groups,
        if (faded != null) 'faded': faded,
        if (target != null) 'target': target,
        if (terms != null) 'terms': terms,
        if (step != null) 'step': step,
        if (values != null) 'values': values,
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
/// Vizual savolning o'ziga mos kelishini tekshiradi.
///
/// FAQAT yangi turlar uchun ishlaydi (`groupRows`, `tenFrame`, `numberLine`,
/// `bars`). Eski `count`/`grouped`/`faded` ataylab tekshirilmaydi — ular
/// prototipdan kelgan va mavjud kontent/testlarda vizual `data` dan biroz
/// erkin (masalan `faded` soni `data.b` ga teng bo'lishi shart emas).
void _validateVisualAgainstData(
  QuestionType type,
  Map<String, Object?> data,
  VisualHint visual,
  List<AnswerCell> answers,
  String context,
) {
  void need(bool ok, String what) {
    if (!ok) {
      throw FormatException('$context: ${visual.kind.name} vizuali — $what');
    }
  }

  switch (visual.kind) {
    case VisualKind.groupRows:
      need(type == QuestionType.multiplication, 'faqat ko’paytirishda');
      final a = data['a'] as int;
      final b = data['b'] as int;
      final groups = visual.groups!;
      need(groups.length == a, '"groups" uzunligi data.a ($a) ga teng bo’lsin');
      need(groups.every((g) => g == b), '"groups" har biri data.b ($b) bo’lsin');
    case VisualKind.tenFrame:
      need(
        type == QuestionType.addition || type == QuestionType.subtraction,
        'faqat qo’shish/ayirishda',
      );
      final a = data['a'] as int;
      final b = data['b'] as int;
      final groups = visual.groups!;
      if (data['missing'] == 'b') {
        // Yetishmayotgan operand IKKI amalda ham «qo'shib to'ldirish» sifatida
        // ko'rsatiladi (standart strategiya):
        //   a + ? = c  → ramkada a ta to'la, halqa c gacha (javob = c − a);
        //   a − ? = c  → ramkada c ta to'la, halqa a gacha (javob = a − c).
        // Shu tufayli `target` HAR IKKI holda yig'indidan katta bo'ladi.
        final c = data['c'] as int;
        final filled = type == QuestionType.addition ? a : c;
        final goal = type == QuestionType.addition ? c : a;
        need(
          groups.length == 1 && groups[0] == filled,
          '"groups" [$filled] bo’lsin',
        );
        need(visual.target == goal, '"target" $goal ga teng bo’lsin');
      } else if (type == QuestionType.addition) {
        need(
          groups.length == 2 && groups[0] == a && groups[1] == b,
          '"groups" [$a, $b] bo’lsin',
        );
      } else {
        need(groups.length == 1 && groups[0] == a, '"groups" [$a] bo’lsin');
        need(visual.faded == b, '"faded" data.b ($b) ga teng bo’lsin');
      }
    case VisualKind.numberLine:
      need(type == QuestionType.sequence, 'faqat ketma-ketlikda');
      final terms = (data['terms'] as List).cast<int>();
      need(
        visual.terms!.length == terms.length &&
            List.generate(terms.length, (i) => visual.terms![i] == terms[i])
                .every((ok) => ok),
        '"terms" data.terms bilan bir xil bo’lsin',
      );
    case VisualKind.bars:
      need(type == QuestionType.comparison, 'faqat taqqoslashda');
      // Ustunlarda yozilgan sonlar javob tugmalaridagi sonlarning
      // PERMUTATSIYASI bo'lishi shart — aks holda bola ustunda ko'rgan
      // sonni hech bir tugmada topmaydi.
      final fromAnswers = answers.map((c) => c.number).whereType<int>().toList()
        ..sort();
      final fromVisual = [...visual.values!]..sort();
      need(
        fromAnswers.length == fromVisual.length &&
            List.generate(
              fromVisual.length,
              (i) => fromAnswers[i] == fromVisual[i],
            ).every((ok) => ok),
        '"values" javoblardagi sonlarning permutatsiyasi bo’lsin '
        '(javoblar: $fromAnswers, vizual: $fromVisual)',
      );
    case VisualKind.count:
    case VisualKind.grouped:
    case VisualKind.faded:
    case VisualKind.none:
      break;
  }
}

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
    if (visual != null) {
      _validateVisualAgainstData(type, data, visual, answers, context);
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
