import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import 'prompt_text.dart';
import 'visual_hint_row.dart';

/// Savol kartasi (DESIGN_SPEC «Ekran 2»): oq, 3px #F0DDB4 jant, radius 24,
/// padding 18/16/16, yumshoq soya. Ichida: teg-pill, 36px savol matni va
/// (bo‘lsa) vizual hint-qator. [key] savol almashganda yangilanishi kerak —
/// shunda hint-qator pop-in animatsiyasi qayta boshlanadi.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    this.hintPulseTick = 0,
  });

  final Question question;

  /// 2-urinish hintida oshiriladi — hayvonlar «birga sanaymiz» pulsi.
  final int hintPulseTick;

  static String _tagFor(QuestionType type, AppLocalizations l10n) =>
      switch (type) {
        QuestionType.counting => l10n.tagCounting,
        QuestionType.addition => l10n.tagAddition,
        QuestionType.subtraction => l10n.tagSubtraction,
        QuestionType.shapes => l10n.tagShapes,
        QuestionType.sequence => l10n.tagSequence,
        QuestionType.comparison => l10n.tagComparison,
        QuestionType.multiplication => l10n.tagMultiplication,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final visual = question.visual;
    final hasVisual = visual != null && visual.kind != VisualKind.none;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 58, 16, 12),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: FarmColors.cardBorder, width: 3),
        borderRadius: BorderRadius.circular(FarmRadius.card),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(90, 80, 40, .12),
            offset: Offset(0, 4),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: FarmColors.tagGreenBg,
              borderRadius: BorderRadius.circular(FarmRadius.pill),
            ),
            child: Text(
              _tagFor(question.type, l10n),
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: FarmColors.tagGreenText,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            promptFor(question, l10n),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkDark,
              height: 1.1,
            ),
          ),
          if (hasVisual) ...[
            const SizedBox(height: 12),
            VisualHintRow(visual: visual, pulseTick: hintPulseTick),
          ],
        ],
      ),
    );
  }
}
