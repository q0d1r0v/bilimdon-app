import '../../content/models.dart';
import '../../l10n/app_localizations.dart';

/// Savol matnini quradi — matnli savollar l10n orqali, arifmetika esa
/// raqamli ifoda sifatida (ayirishda U+2212 minus, prototipdagidek «5 − 2»).
String promptFor(Question q, AppLocalizations l10n) {
  switch (q.type) {
    case QuestionType.counting:
      return l10n.promptCount(q.data['animal'] as String? ?? '');
    case QuestionType.addition:
      final a = q.data['a'];
      final b = q.data['b'];
      if (q.data['missing'] == 'b') {
        // Natija «c» kalitida (models.dart: 3 + ? = 7).
        return '$a + ? = ${q.data['c']}';
      }
      return '$a + $b = ?';
    case QuestionType.subtraction:
      final a = q.data['a'];
      final b = q.data['b'];
      if (q.data['missing'] == 'b') {
        return '$a − ? = ${q.data['c']}';
      }
      return '$a − $b = ?';
    case QuestionType.sequence:
      final terms = q.data['terms'];
      final joined = terms is List ? terms.join(', ') : '';
      return '$joined, ... ?';
    case QuestionType.shapes:
      return l10n.promptFindShape(q.data['target'] as String? ?? '');
    case QuestionType.comparison:
      return q.data['mode'] == 'biggest'
          ? l10n.promptBiggest
          : l10n.promptSmallest;
    case QuestionType.multiplication:
      return '${q.data['a']} × ${q.data['b']} = ?';
  }
}
