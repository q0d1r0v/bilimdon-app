import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../content/models.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../effects/animal_life.dart';
import '../../effects/effects_layer.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/fence.dart';
import '../../scene/flowers.dart';
import '../../scene/sky.dart';
import '../../widgets/icons.dart';
import '../../widgets/pill.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/speech_bubble.dart';
import 'answer_grid.dart';
import 'fail_overlay.dart';
import 'finish_overlay.dart';
import 'question_card.dart';
import 'quiz_controller.dart';

/// O‘yin ekrani (DESIGN_SPEC «Ekran 2») — mahsulot yuragi.
/// Holat mashinasi [QuizController]da; bu widget dwell taymerlarini,
/// taymer barini, effektlarni va yakuniy commitni boshqaradi.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.store, required this.level});

  final ProgressStore store;
  final LevelDef level;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late QuizController _controller;
  late final AnimationController _timerCtrl;
  late final EffectsGame _effects;
  final _rng = math.Random();

  final _rootStackKey = GlobalKey();
  final _coinsPillKey = GlobalKey();
  final _answerKeys = List.generate(4, (_) => GlobalKey());

  Timer? _dwellTimer;
  QuizPhase _lastPhase = QuizPhase.question;
  (int, int)? _lastTimerKey;
  bool _timerBarHidden = false;
  bool _committed = false;

  /// Ayni damda tirik GameScreen'lar soni. Pop tranzitsiyasi paytida bola
  /// keyingi darajani ochsa, yangi ekran initState'i eski ekran dispose'idan
  /// OLDIN ishlaydi — map musiqasi faqat oxirgi ekran yopilganda qaytadi.
  static int _activeGameScreens = 0;

  /// Fonga o'tganda (qo'ng'iroq, home tugmasi) savol taymerini muzlatadi —
  /// bola yo'q paytda tezlik bonusi kuyib ketmasin.
  late final AppLifecycleListener _lifecycle;

  /// Sessiya boshidagi tanga zaxirasi — commitdan keyin ikki marta
  /// hisoblanmasligi uchun alohida saqlanadi.
  late int _baseCoins;

  /// Pufak matn variantlari («bir xil ikki marta emas» rotatsiyasi).
  int _correctVariant = 1;
  int _wrongVariant = 1;
  int _hintVariant = 1;

  /// Har oshirilganda hint-qatordagi «birga sanaymiz» pulsi ishlaydi.
  int _hintPulseTick = 0;

  /// Daraja boshida sarflangan power-uplar (qalqon + tanga×2). _restart ham
  /// shu qiymatlarni ishlatadi (qayta sarflamaydi).
  int _shield = 0;
  int _coinMult = 1;

  @override
  void initState() {
    super.initState();
    _activeGameScreens++;
    _effects = EffectsGame();
    _baseCoins = widget.store.coins;
    // Power-uplarni daraja boshida bir marta sarflaymiz (bo'lsa).
    _shield = widget.store.consumePowerup('powerHeart') ? 1 : 0;
    _coinMult = widget.store.consumePowerup('powerCoinX2') ? 2 : 1;
    _controller = _createController()..addListener(_onControllerChanged);
    _timerCtrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: math.max(1, widget.level.timerSeconds)),
    )..addStatusListener(_onTimerStatus);
    // onInactive butun inactive→hidden→paused kaskadini qamraydi (iOS
    // qo'ng'iroq banneri kabi frame'lar davom etadigan holatlar bilan).
    _lifecycle = AppLifecycleListener(
      onInactive: _pauseQuestionTimer,
      onResume: _resumeQuestionTimer,
    );
    if (_controller.timerEnabled) {
      _lastTimerKey = _controller.timerKey;
      _timerCtrl.forward(from: 0);
    }
    AudioService.instance.startMusic(Bgm.game, fadeIn: true);
  }

  @override
  void dispose() {
    _dwellTimer?.cancel();
    // Himoya: yakun bosqichida yopilgan bo'lsa, mukofot yo'qolmasin
    // (_commitOnce idempotent — ikki marta yozilmaydi).
    if (_controller.phase == QuizPhase.finished) _commitOnce();
    _lifecycle.dispose();
    _timerCtrl.dispose();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    _activeGameScreens--;
    if (_activeGameScreens == 0) {
      // Faqat oxirgi o'yin ekrani yopilganda — aks holda pop paytida
      // ochilgan yangi darajaning game-musiqasini bosib qo'yardi.
      AudioService.instance.startMusic(Bgm.map, fadeIn: true);
    }
    super.dispose();
  }

  QuizController _createController() => QuizController(
        baseQuestions: widget.level.questions,
        timerEnabled: widget.level.timerEnabled && widget.store.timerAllowed,
        timerSeconds: widget.level.timerSeconds,
        shuffleAnswers: widget.level.shuffleAnswers,
        shieldCharges: _shield,
        coinMultiplier: _coinMult,
      );

  // ── Holat oqimi ────────────────────────────────────────────────────────

  void _onControllerChanged() {
    if (!mounted) return;
    final phase = _controller.phase;
    if (phase != _lastPhase) {
      _lastPhase = phase;
      _dwellTimer?.cancel();
      switch (phase) {
        case QuizPhase.feedbackCorrect:
          _correctVariant = _pickVariant(3, _correctVariant);
          AudioService.instance.play(Sfx.correct);
          _fireCorrectEffects();
          _dwellTimer = Timer(
            FarmAnim.feedbackDwellCorrect,
            _controller.completeFeedback,
          );
          // Oxirgi taqdimot: natija shu yerda uzil-kesil hal bo'ldi —
          // dwell/pop poygasida mukofot yo'qolmasligi uchun darhol commit.
          if (_controller.index + 1 >= _controller.totalQuestions) {
            _commitOnce();
          }
        case QuizPhase.feedbackWrong:
          if (_controller.bubbleKind == BubbleKind.hint) {
            _hintVariant = _pickVariant(2, _hintVariant);
            _hintPulseTick++;
          } else {
            _wrongVariant = _pickVariant(2, _wrongVariant);
          }
          AudioService.instance.play(Sfx.wrong);
          _dwellTimer = Timer(
            FarmAnim.feedbackDwellWrong,
            _controller.completeFeedback,
          );
        case QuizPhase.feedbackReveal:
          AudioService.instance.play(Sfx.unlock);
          _dwellTimer = Timer(
            FarmAnim.revealDwell,
            _controller.completeFeedback,
          );
          if (_controller.index + 1 >= _controller.totalQuestions) {
            _commitOnce();
          }
        case QuizPhase.finished:
          _commitOnce();
        case QuizPhase.failed:
          // 3 yurak tugadi — commit YO'Q (jarimasiz). Muloyim fail oynasi.
          AudioService.instance.play(Sfx.wrong);
        case QuizPhase.question:
          break;
      }
    }
    // Taymer bar: yangi savol/urinishda qayta ishga tushadi, feedback
    // paytida pauza qilinadi.
    if (_controller.timerEnabled) {
      if (phase == QuizPhase.question) {
        if (_controller.timerKey != _lastTimerKey) {
          _lastTimerKey = _controller.timerKey;
          _timerBarHidden = false;
          _timerCtrl.forward(from: 0);
        }
      } else if (_timerCtrl.isAnimating) {
        _timerCtrl.stop();
      }
    }
    setState(() {});
  }

  void _onTimerStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) return;
    // Jazo yo‘q, signal yo‘q — bar shunchaki yumshoq so‘nadi.
    _controller.onTimerExpired();
    setState(() => _timerBarHidden = true);
  }

  /// Fon/qo'ng'iroq: bar joyida to'xtaydi (stop() qiymatni saqlaydi).
  void _pauseQuestionTimer() {
    if (_timerCtrl.isAnimating) _timerCtrl.stop();
  }

  /// Qaytganda faqat savol bosqichidagi, tugamagan bar davom etadi.
  /// isAnimating sharti: fon paytida dwell o'tib yangi savol boshlangan
  /// bo'lsa, forward(from: 0) allaqachon ishlagan — qayta boshlamaymiz.
  void _resumeQuestionTimer() {
    if (_controller.timerEnabled &&
        _controller.phase == QuizPhase.question &&
        !_timerBarHidden &&
        !_timerCtrl.isAnimating &&
        !_timerCtrl.isCompleted) {
      _timerCtrl.forward();
    }
  }

  /// Avvalgisidan farqli tasodifiy variant (1..[count]).
  int _pickVariant(int count, int last) {
    if (count <= 1) return 1;
    var v = _rng.nextInt(count) + 1;
    while (v == last) {
      v = _rng.nextInt(count) + 1;
    }
    return v;
  }

  void _commitOnce() {
    if (_committed) return;
    _committed = true;
    unawaited(
      widget.store.commitLevelResult(
        levelId: widget.level.id,
        stars: _controller.earnedStars,
        coinsEarned: _controller.totalReward,
        skills: {
          for (final e in _controller.skillCounts.entries)
            e.key.name: (
              answered: e.value.answered,
              correctFirstTry: e.value.correctFirstTry,
            ),
        },
      ),
    );
  }

  void _restart() {
    AudioService.instance.play(Sfx.tap);
    _dwellTimer?.cancel();
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    setState(() {
      _baseCoins = widget.store.coins;
      _controller = _createController()..addListener(_onControllerChanged);
      _committed = false;
      _lastPhase = QuizPhase.question;
      _lastTimerKey = null;
      _timerBarHidden = false;
      _hintPulseTick = 0;
      if (_controller.timerEnabled) {
        _lastTimerKey = _controller.timerKey;
        _timerCtrl.forward(from: 0);
      }
    });
  }

  // ── Effektlar ──────────────────────────────────────────────────────────

  /// [key] widgetining markazini overlay (ildiz Stack) koordinatasida beradi.
  Offset? _centerOf(GlobalKey key) {
    final box = key.currentContext?.findRenderObject();
    final root = _rootStackKey.currentContext?.findRenderObject();
    if (box is! RenderBox || root is! RenderBox) return null;
    if (!box.attached || !root.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero), ancestor: root);
  }

  void _fireCorrectEffects() {
    final center = _centerOf(_answerKeys[_controller.current.correctIndex]);
    if (center == null) return;
    _effects
      ..confettiBurst(center)
      ..starSparkle(center);
    final coins = _centerOf(_coinsPillKey);
    if (coins != null) {
      _effects.coinFly(
        center,
        coins,
        onArrive: () => AudioService.instance.play(Sfx.coin),
      );
    }
  }

  void _sparkleAtGlobal(Offset globalCenter) {
    final root = _rootStackKey.currentContext?.findRenderObject();
    if (root is! RenderBox || !root.attached) return;
    _effects.starSparkle(root.globalToLocal(globalCenter));
  }

  void _selectAnswer(int i) {
    AudioService.instance.play(Sfx.tap);
    _controller.selectAnswer(i);
  }

  // ── UI ─────────────────────────────────────────────────────────────────

  static AnimalAccessory _accessoryFromItem(String? itemId) =>
      switch (itemId) {
        'cowHat' => AnimalAccessory.cowHat,
        'chickBow' => AnimalAccessory.chickBow,
        'pigGlasses' => AnimalAccessory.pigGlasses,
        'sheepScarf' => AnimalAccessory.sheepScarf,
        _ => AnimalAccessory.none,
      };

  AnimalExpression get _cowExpression => switch (_controller.phase) {
        QuizPhase.feedbackCorrect => AnimalExpression.happy,
        QuizPhase.feedbackWrong ||
        QuizPhase.feedbackReveal =>
          AnimalExpression.sad,
        _ => AnimalExpression.idle,
      };

  String _bubbleText(AppLocalizations l10n) => switch (_controller.bubbleKind) {
        BubbleKind.neutral => l10n.bubbleNeutral,
        BubbleKind.correct => switch (_correctVariant) {
            2 => l10n.bubbleCorrect2,
            3 => l10n.bubbleCorrect3,
            _ => l10n.bubbleCorrect1(FarmRules.coinsPerCorrect),
          },
        BubbleKind.wrong =>
          _wrongVariant == 2 ? l10n.bubbleWrong2 : l10n.bubbleWrong1,
        BubbleKind.hint =>
          _hintVariant == 2 ? l10n.bubbleHint2 : l10n.bubbleHint1,
        BubbleKind.reveal => l10n.bubbleReveal,
      };

  Color get _bubbleBackground => switch (_controller.bubbleKind) {
        BubbleKind.correct => FarmColors.correctBg,
        BubbleKind.wrong || BubbleKind.hint => FarmColors.wrongBg,
        _ => Colors.white,
      };

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          // ✕ yopish: vizual 32×32, samarali teginish maydoni 48×48.
          GestureDetector(
            key: const ValueKey('game-close'),
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Dwell taymeri pop tranzitsiyasi o'rtasida otilib,
              // FinishOverlay/Sfx.win chiqib ketmasin.
              _dwellTimer?.cancel();
              Navigator.of(context).maybePop();
            },
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(30, 60, 20, .15),
                        offset: Offset(0, 2),
                        blurRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(child: _CloseX()),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: GameProgressBar(fraction: _controller.progress)),
          const SizedBox(width: 12),
          StatPill(
            gap: 2,
            children: [
              for (var i = 0; i < FarmRules.maxHearts; i++)
                HeartIcon(size: 14, filled: i < _controller.hearts),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _timerBarHidden ? 0 : 1,
        child: TimerBar(animation: ReverseAnimation(_timerCtrl)),
      ),
    );
  }

  /// Power-up tugmalari qatori (yordam/o'tkazish) — faqat savol bosqichida va
  /// zaxira bo'lsa ko'rinadi.
  Widget _powerupRow(AppLocalizations l10n) {
    if (_controller.phase != QuizPhase.question) {
      return const SizedBox.shrink();
    }
    final hints = widget.store.powerupCount('powerHint');
    final skips = widget.store.powerupCount('powerSkip');
    if (hints == 0 && skips == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      // Wrap — tor ekranda ikki tugma sig'masa ikkinchi qatorga tushadi
      // (RenderFlex overflow o'rniga).
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          if (hints > 0)
            _powerupButton(
              icon: Icons.lightbulb,
              color: FarmColors.yellow,
              label: l10n.itemPowerHint,
              count: hints,
              onTap: () {
                if (_controller.useHint()) {
                  widget.store.consumePowerup('powerHint');
                  AudioService.instance.play(Sfx.unlock);
                }
              },
            ),
          if (skips > 0)
            _powerupButton(
              icon: Icons.fast_forward_rounded,
              color: FarmColors.blue,
              label: l10n.itemPowerSkip,
              count: skips,
              onTap: () {
                if (_controller.skipQuestion()) {
                  widget.store.consumePowerup('powerSkip');
                  AudioService.instance.play(Sfx.whoosh);
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _powerupButton({
    required IconData icon,
    required Color color,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(FarmRadius.pill),
          border: Border.all(color: FarmColors.cardBorder, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              '$label ($count)',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: FarmColors.inkDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _groundPanel(AppLocalizations l10n, double bottomInset) {
    final shownCoins =
        _baseCoins + _controller.sessionCoins + _controller.speedBonus;
    return Container(
      height: 132 + bottomInset,
      decoration: const BoxDecoration(
        color: FarmColors.grass,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Pufak eni panel enidan hisoblanadi: tor ekranlarda (360px)
          // o'ngdagi tanga pill ustiga chiqib ketmasin. Pill eni raqamlar
          // sonidan deterministik baholanadi: 20 padding + 15 tanga ikonkasi
          // + 5 oraliq + ~8.5px/raqam (M3 letterSpacing zaxirasi bilan).
          final coinPillWidth = 40 + 8.5 * shownCoins.toString().length;
          final bubbleMaxWidth = math.min(
            180.0,
            math.max(
              60.0,
              constraints.maxWidth - 126 - 14 - coinPillWidth - 6,
            ),
          );
          return Stack(
            clipBehavior: Clip.none,
            children: [
              const Positioned(
                left: 150,
                top: 18,
                child: FlowerCluster.gamePanelCluster,
              ),
              Positioned(
                left: 16,
                bottom: 12 + bottomInset,
                // Tirik sigir: nafas oladi, pirpiraydi; har to'g'ri javobda
                // quvnoq sakraydi (sessionCoins o'zgarishi trigger bo'ladi).
                child: LivingAnimal(
                  kind: FarmAnimal.cow,
                  size: 100,
                  expression: _cowExpression,
                  accessory:
                      _accessoryFromItem(widget.store.equippedFor('cow')),
                  jumpTrigger: _controller.sessionCoins,
                ),
              ),
              Positioned(
                left: 126,
                bottom: 64 + bottomInset,
                child: SpeechBubble(
                  text: _bubbleText(l10n),
                  background: _bubbleBackground,
                  fontSize: 13,
                  maxWidth: bubbleMaxWidth,
                  tail: BubbleTail.leftBottom,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                ),
              ),
              Positioned(
                right: 14,
                bottom: 28 + bottomInset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatPill(
                      key: _coinsPillKey,
                      children: [
                        const CoinIcon(size: 15),
                        TweenAnimationBuilder<int>(
                          tween: IntTween(begin: shownCoins, end: shownCoins),
                          duration: const Duration(milliseconds: 400),
                          builder: (context, value, _) => Text(
                            '$value',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: FarmColors.coinText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    StatPill(
                      children: [
                        Text(
                          l10n.questionOf(
                            _controller.questionNumber,
                            _controller.totalQuestions,
                          ),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: FarmColors.inkOlive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: Stack(
        key: _rootStackKey,
        children: [
          Positioned.fill(
            child: Container(decoration: farmGameSkyGradient(size.height)),
          ),
          Positioned(
            left: 12,
            right: 12,
            top: padding.top + 124,
            child: const FenceStrip(game: true),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _topBar(),
                if (_controller.timerEnabled) _timerRow(),
                // O'rta qism: baland ekranlarda avvalgidek tepaga taqalgan
                // (skroll sezilmaydi), qisqa ekranlarda (640px va past)
                // kesilish o'rniga skroll bo'ladi — pastdagi maysa paneli
                // hech qachon siqilmaydi.
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QuestionCard(
                          // Savol almashganda hint-qator pop-in qayta
                          // boshlanadi.
                          key: ValueKey('question-${_controller.index}'),
                          question: _controller.current,
                          hintPulseTick: _hintPulseTick,
                        ),
                        AnswerGrid(
                          answers: _controller.current.answers,
                          correctIndex: _controller.current.correctIndex,
                          selectedIndex: _controller.selectedIndex,
                          phase: _controller.phase,
                          disabledIndexes: _controller.disabledIndexes,
                          fadedIndexes: _controller.fadedIndexes,
                          onSelect: _selectAnswer,
                          buttonKeys: _answerKeys,
                        ),
                        _powerupRow(l10n),
                      ],
                    ),
                  ),
                ),
                _groundPanel(l10n, padding.bottom),
              ],
            ),
          ),
          if (_controller.phase == QuizPhase.finished)
            FinishOverlay(
              stars: _controller.earnedStars,
              totalReward: _controller.totalReward,
              levelNumber: widget.level.index,
              onPlayAgain: _restart,
              onContinue: () => Navigator.of(context).maybePop(),
              onStarSparkle: _sparkleAtGlobal,
            ),
          if (_controller.phase == QuizPhase.failed)
            FailOverlay(
              onRetry: _restart,
              onExit: () => Navigator.of(context).maybePop(),
            ),
          // Effektlar Stack'ning ENG OXIRIDA: yulduz uchqunlari
          // FinishOverlay kartasi ustida ko'rinadi; IgnorePointer tugma
          // bosishlariga xalaqit bermaydi.
          EffectsOverlay(game: _effects),
        ],
      ),
    );
  }
}

/// Chizilgan ✕ belgisi (shrift glifiga tayanmaymiz) — 2 ta 45° tayoqcha.
class _CloseX extends StatelessWidget {
  const _CloseX();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 14,
      height: 14,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final angle in const [45.0, -45.0])
            Transform.rotate(
              angle: angle * math.pi / 180,
              child: Container(
                width: 14,
                height: 2.6,
                decoration: BoxDecoration(
                  color: FarmColors.inkGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
