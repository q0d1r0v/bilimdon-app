import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/content/models.dart';
import 'package:math_farm/features/game/prompt_text.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_en.dart';
import 'package:math_farm/l10n/app_localizations_ru.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';

/// promptFor — har bir tur × 3 til (uz/ru/en) uchun ANIQ satrlar.
/// L10n obyektlari to'g'ridan-to'g'ri yaratiladi — vidjet kerak emas.
/// Muhim: uz satrlarida apostrof U+2019 (’), ayirishda minus U+2212 (−).
Question _q(QuestionType type, Map<String, Object?> data) => Question(
      id: 'pt-1',
      type: type,
      data: data,
      answers: const [
        AnswerCell.number(1),
        AnswerCell.number(2),
        AnswerCell.number(3),
        AnswerCell.number(4),
      ],
      correctIndex: 0,
    );

void main() {
  final locales = <String, AppLocalizations>{
    'uz': AppLocalizationsUz(),
    'ru': AppLocalizationsRu(),
    'en': AppLocalizationsEn(),
  };

  group('SANASH — uch hayvon, har tilda aniq satr', () {
    const expected = <String, Map<String, String>>{
      'uz': {
        'chick': 'Nechta jo’jacha?',
        'pig': 'Nechta cho’chqacha?',
        'sheep': 'Nechta qo’zichoq?',
      },
      'ru': {
        'chick': 'Сколько цыплят?',
        'pig': 'Сколько поросят?',
        'sheep': 'Сколько ягнят?',
      },
      'en': {
        'chick': 'How many chicks?',
        'pig': 'How many piglets?',
        'sheep': 'How many lambs?',
      },
    };

    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('counting [$code]', () {
        for (final animal in ['chick', 'pig', 'sheep']) {
          expect(
            promptFor(_q(QuestionType.counting, {'animal': animal}), l10n),
            expected[code]![animal],
            reason: '$code/$animal',
          );
        }
      });
    }

    test('noma’lum yoki yo’q hayvon — umumiy "other" tarmog’i', () {
      const fallback = {
        'uz': 'Nechta?',
        'ru': 'Сколько?',
        'en': 'How many?',
      };
      for (final MapEntry(key: code, value: l10n) in locales.entries) {
        expect(
          promptFor(_q(QuestionType.counting, const {'animal': 'cow'}), l10n),
          fallback[code],
          reason: '$code/cow',
        );
        // animal umuman yo'q — null → '' → other.
        expect(
          promptFor(_q(QuestionType.counting, const {}), l10n),
          fallback[code],
          reason: '$code/absent',
        );
      }
    });
  });

  group('QO’SHISH — tilga bog’liq emas, hamma tilda bir xil', () {
    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('addition oddiy va missing-b [$code]', () {
        expect(
          promptFor(
            _q(QuestionType.addition,
                const {'a': 3, 'b': 2, 'missing': 'none'}),
            l10n,
          ),
          '3 + 2 = ?',
        );
        expect(
          promptFor(
            _q(QuestionType.addition,
                const {'a': 3, 'b': 4, 'missing': 'b', 'c': 7}),
            l10n,
          ),
          '3 + ? = 7',
        );
      });
    }
  });

  group('AYIRISH — U+2212 minus (ASCII defis EMAS)', () {
    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('subtraction oddiy va missing-b [$code]', () {
        final normal = promptFor(
          _q(QuestionType.subtraction,
              const {'a': 5, 'b': 2, 'missing': 'none'}),
          l10n,
        );
        expect(normal, '5 − 2 = ?');
        expect(normal.runes, contains(0x2212), reason: 'U+2212 minus');
        expect(normal.contains('-'), isFalse, reason: 'ASCII defis yo’q');

        final missingB = promptFor(
          _q(QuestionType.subtraction,
              const {'a': 9, 'b': 4, 'missing': 'b', 'c': 5}),
          l10n,
        );
        expect(missingB, '9 − ? = 5');
        expect(missingB.runes, contains(0x2212), reason: 'U+2212 minus');
      });
    }
  });

  group('MANTIQ — hadlar vergul bilan qo’shiladi', () {
    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('sequence [$code]', () {
        expect(
          promptFor(
            _q(QuestionType.sequence, const {
              'terms': [2, 4, 6],
            }),
            l10n,
          ),
          '2, 4, 6, ... ?',
        );
        // Bitta had ham to'g'ri qo'shiladi.
        expect(
          promptFor(
            _q(QuestionType.sequence, const {
              'terms': [7],
            }),
            l10n,
          ),
          '7, ... ?',
        );
      });
    }
  });

  group('SHAKLLAR — to’rt nishon, har tilda aniq satr', () {
    const expected = <String, Map<String, String>>{
      'uz': {
        'triangle': 'Uchburchakni top!',
        'circle': 'Doirani top!',
        'square': 'Kvadratni top!',
        'diamond': 'Rombni top!',
      },
      'ru': {
        'triangle': 'Найди треугольник!',
        'circle': 'Найди круг!',
        'square': 'Найди квадрат!',
        'diamond': 'Найди ромб!',
      },
      'en': {
        'triangle': 'Find the triangle!',
        'circle': 'Find the circle!',
        'square': 'Find the square!',
        'diamond': 'Find the diamond!',
      },
    };

    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('shapes [$code]', () {
        for (final target in ['triangle', 'circle', 'square', 'diamond']) {
          expect(
            promptFor(_q(QuestionType.shapes, {'target': target}), l10n),
            expected[code]![target],
            reason: '$code/$target',
          );
        }
      });
    }
  });

  group('TAQQOSLASH — biggest/smallest, har tilda aniq satr', () {
    const biggest = {
      'uz': 'Qaysi son eng katta?',
      'ru': 'Какое число самое большое?',
      'en': 'Which number is the biggest?',
    };
    const smallest = {
      'uz': 'Qaysi son eng kichik?',
      'ru': 'Какое число самое маленькое?',
      'en': 'Which number is the smallest?',
    };

    for (final MapEntry(key: code, value: l10n) in locales.entries) {
      test('comparison [$code]', () {
        expect(
          promptFor(
            _q(QuestionType.comparison, const {'mode': 'biggest'}),
            l10n,
          ),
          biggest[code],
        );
        expect(
          promptFor(
            _q(QuestionType.comparison, const {'mode': 'smallest'}),
            l10n,
          ),
          smallest[code],
        );
      });
    }
  });
}
