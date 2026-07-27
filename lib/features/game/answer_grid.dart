import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../content/models.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/css_shapes.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/chunky_button.dart';
import 'quiz_controller.dart';

/// Javoblar to‘ri (DESIGN_SPEC «Ekran 2»): 2×2, gap 12, gorizontal margin 16.
/// Tugmalar tartibi: qizil/yashil/ko‘k/sariq. Holatlar controller’dan
/// keladi: noto‘g‘ri tanlov — loy rang + shakeX; to‘g‘risi — yashil + pop;
/// xiralatilganlar — opacity .25; feedback payti qolganlari — .55.
class AnswerGrid extends StatefulWidget {
  const AnswerGrid({
    super.key,
    required this.answers,
    required this.correctIndex,
    required this.selectedIndex,
    required this.phase,
    required this.disabledIndexes,
    required this.fadedIndexes,
    required this.onSelect,
    required this.buttonKeys,
  });

  final List<AnswerCell> answers;
  final int correctIndex;
  final int? selectedIndex;
  final QuizPhase phase;
  final Set<int> disabledIndexes;
  final Set<int> fadedIndexes;
  final ValueChanged<int> onSelect;

  /// Effektlar (konfetti/tanga) pozitsiyasi uchun tashqaridan berilgan
  /// kalitlar — har tugmaga bittadan.
  final List<GlobalKey> buttonKeys;

  @override
  State<AnswerGrid> createState() => _AnswerGridState();
}

class _AnswerGridState extends State<AnswerGrid>
    with TickerProviderStateMixin {
  /// Tugma ranglari tartibi (prototip): qizil/yashil/ko‘k/sariq.
  static const _colors = [
    (FarmColors.red, FarmColors.redDark),
    (FarmColors.green, FarmColors.greenDark),
    (FarmColors.blue, FarmColors.blueDark),
    (FarmColors.yellow, FarmColors.yellowDark),
  ];

  /// To‘g‘ri javob popi (feedbackCorrect): 1→1.15→1.
  static final _popSelected = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 50),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0), weight: 50),
  ]);

  /// Reveal popIn (prototip keyframe): .4→1.12 (70%) →1.
  static final _popReveal = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.12), weight: 70),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0), weight: 30),
  ]);

  late final AnimationController _shakeCtrl;
  late final AnimationController _popCtrl;

  @override
  void initState() {
    super.initState();
    // Kontrollerlar shu yerda darhol yaratiladi (visual_hint_row.dart bilan
    // bir xil uslub). Lazy `late` bo'lsa, hech ishlatilmagan controller
    // birinchi marta dispose() ichida yaratilib, deaktiv elementda
    // TickerMode qidiruvi («Looking up a deactivated widget's ancestor»)
    // xatosini berardi — masalan, bola javob bermay ✕ bilan chiqsa.
    _shakeCtrl = AnimationController(vsync: this, duration: FarmAnim.shakeX);
    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void didUpdateWidget(AnswerGrid old) {
    super.didUpdateWidget(old);
    if (widget.phase == old.phase) return;
    switch (widget.phase) {
      case QuizPhase.feedbackWrong:
        _shakeCtrl.forward(from: 0);
      case QuizPhase.feedbackCorrect || QuizPhase.feedbackReveal:
        _popCtrl.forward(from: 0);
      case QuizPhase.question || QuizPhase.finished || QuizPhase.failed:
        break;
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _popCtrl.dispose();
    super.dispose();
  }

  bool get _inFeedback =>
      widget.phase == QuizPhase.feedbackCorrect ||
      widget.phase == QuizPhase.feedbackWrong ||
      widget.phase == QuizPhase.feedbackReveal;

  /// [fg] — tugma foniga mos matn/shakl rangi
  /// ([FarmColors.answerForeground]): sariq/yashil/ko'k tugmada oq raqam
  /// WCAG minimumidan past bo'lardi.
  Widget _cellContent(AnswerCell cell, Color fg) {
    if (cell.number != null) {
      return Text(
        '${cell.number}',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      );
    }
    // Shakllar (prototip o'lchamlari): uchburchak 48×40, doira 42,
    // kvadrat 40 r8, romb 34 rotate 45° r7.
    return switch (cell.shape!) {
      ShapeKind.triangle => TriangleWidget(
          width: 48,
          height: 40,
          color: fg,
          direction: TriangleDirection.up,
        ),
      ShapeKind.circle => Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: fg,
            shape: BoxShape.circle,
          ),
        ),
      ShapeKind.square => Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: fg,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ShapeKind.diamond => SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Transform.rotate(
              angle: math.pi / 4,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: fg,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ),
    };
  }

  Widget _button(int i) {
    if (i >= widget.answers.length) return const SizedBox.shrink();
    final phase = widget.phase;
    final isFaded = widget.fadedIndexes.contains(i);
    final isDisabled = widget.disabledIndexes.contains(i);
    final isSelectedWrong =
        i == widget.selectedIndex && phase == QuizPhase.feedbackWrong;
    final isCorrectShown = i == widget.correctIndex &&
        (phase == QuizPhase.feedbackCorrect ||
            phase == QuizPhase.feedbackReveal);

    var (color, dark) = _colors[i % _colors.length];
    if (isCorrectShown) {
      (color, dark) = (FarmColors.green, FarmColors.greenDark);
    } else if (isDisabled && !isFaded) {
      // Avval noto‘g‘ri bosilgan — loy rangda qoladi.
      (color, dark) = (FarmColors.mud, FarmColors.mudDark);
    }

    final dimmed = _inFeedback &&
        i != widget.selectedIndex &&
        !isCorrectShown &&
        !isFaded;

    final cell = widget.answers[i];
    final l10n = AppLocalizations.of(context);
    // Chizilgan shakl javoblari screen reader'da umuman o'qilmasdi.
    final semanticLabel = cell.number != null
        ? '${cell.number}'
        : l10n.shapeName(cell.shape!.name);

    Widget button = ChunkyButton(
      key: widget.buttonKeys[i],
      semanticLabel: semanticLabel,
      color: color,
      darkColor: dark,
      borderRadius: FarmRadius.answerButton,
      ledge: 5,
      minHeight: 78,
      enabled: phase == QuizPhase.question && !isDisabled,
      dimmed: dimmed,
      onPressed: () => widget.onSelect(i),
      child: _cellContent(cell, FarmColors.answerForeground(color)),
    );

    if (isSelectedWrong) {
      button = AnimatedBuilder(
        animation: _shakeCtrl,
        builder: (context, child) => Transform.translate(
          // CSS shakeX: 0/−7/+7/−7/+7/0 — ikki to‘liq sinus sikli.
          offset: Offset(
            -math.sin(_shakeCtrl.value * math.pi * 4) * 7,
            0,
          ),
          child: child,
        ),
        child: button,
      );
    } else if (isCorrectShown) {
      final seq =
          phase == QuizPhase.feedbackCorrect ? _popSelected : _popReveal;
      button = AnimatedBuilder(
        animation: _popCtrl,
        builder: (context, child) => Transform.scale(
          scale: seq.transform(_popCtrl.value),
          child: child,
        ),
        child: button,
      );
    }

    if (isFaded) {
      button = AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: .25,
        child: button,
      );
    }
    return button;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _button(0)),
              const SizedBox(width: 12),
              Expanded(child: _button(1)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _button(2)),
              const SizedBox(width: 12),
              Expanded(child: _button(3)),
            ],
          ),
        ],
      ),
    );
  }
}
