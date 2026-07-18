import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../characters/animal.dart';
import '../../content/content_repository.dart';
import '../../content/models.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/dotted_path_painter.dart';
import '../../effects/ambient_life.dart';
import '../../effects/animal_life.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/bush.dart';
import '../../scene/cloud.dart';
import '../../scene/decorations.dart';
import '../../scene/fence.dart';
import '../../scene/flowers.dart';
import '../../scene/hill.dart';
import '../../scene/sky.dart';
import '../../scene/sun.dart';
import '../../widgets/chunky_button.dart';
import '../../widgets/speech_bubble.dart';
import '../game/game_screen.dart';
import 'chapter_banner.dart';
import 'level_node.dart';
import 'map_header.dart';

/// Sahna dizayn-fazosi (DottedPathPainter bilan bir xil): 390×500 (bir bob).
const double _designW = 390;
const double _designH = 500;

/// Tugun markazlari 390×500 fazoda — nuqta-yo’l langarlariga mos (bir bob).
const List<Offset> _nodeAnchors = [
  Offset(73, 441),
  Offset(191, 381),
  Offset(98, 253),
  Offset(242, 212),
  Offset(122, 121),
  Offset(262, 41),
];

/// Ekran 1 — Duolingo uslubidagi ferma xaritasi. Endi BARCHA boblar bitta
/// uzun scroll-yo'lda ustma-ust turadi (pastda 1-bob, tepada oxirgi bob);
/// ochilganda joriy darajaga avto-scroll qilinadi.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.store, this.repo});

  final ProgressStore store;

  /// Tashqaridan (main.dart) oldindan isitilgan repo — splash paytida
  /// kontent yuklanib bo'ladi, xarita bo'sh kadr ko'rsatmaydi. Berilmasa
  /// (testlar) o'z nusxasini yaratadi.
  final ContentRepository? repo;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Bitta repository nusxasi — muvaffaqiyatsiz yuklashdan keyin qayta
  /// urinish uning ichki kesh-tozalashidan (loadAll onError) foydalanadi.
  late final ContentRepository _repo = widget.repo ?? ContentRepository();

  /// `final` emas: xatodan keyin qayta urinishda qayta tayinlanadi.
  late Future<List<ChapterDef>> _chapters;

  final ScrollController _scroll = ScrollController();

  /// Joriy darajaga bir marta avto-scroll qilingach `true`.
  bool _autoScrolled = false;

  /// Har hayvon bosilganda sakrashi uchun trigger hisoblagichlari.
  final Map<FarmAnimal, int> _jumps = {};

  /// Ayni damda «quvnoq» ifodada turgan hayvonlar (teginishdan keyin ~0.75s).
  final Set<FarmAnimal> _happy = {};

  /// «Quvnoq» ifodani qaytaruvchi taymerlar — dispose'da bekor qilinadi.
  final List<Timer> _celebrateTimers = [];

  @override
  void initState() {
    super.initState();
    _chapters = _loadContent();
  }

  @override
  void dispose() {
    for (final t in _celebrateTimers) {
      t.cancel();
    }
    _scroll.dispose();
    super.dispose();
  }

  Future<List<ChapterDef>> _loadContent() {
    return _repo.loadAll().onError((Object error, StackTrace st) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: error,
        stack: st,
        library: 'math_farm',
        context: ErrorDescription('xarita kontentini yuklashda'),
      ));
      Error.throwWithStackTrace(error, st);
    });
  }

  void _retryLoad() {
    AudioService.instance.play(Sfx.tap);
    rootBundle.clear();
    setState(() {
      _chapters = _loadContent();
    });
  }

  /// Joriy (faol) daraja: birinchi qulfsiz + 0-yulduzli daraja (butun
  /// kurikulum bo'ylab). Qaytadi (bob, daraja, langar-indeks) yoki null
  /// (hammasi bajarilgan).
  (ChapterDef, LevelDef, int)? _activeLevel(List<ChapterDef> chapters) {
    for (final ch in chapters) {
      final n = ch.levels.length < _nodeAnchors.length
          ? ch.levels.length
          : _nodeAnchors.length;
      for (var i = 0; i < n; i++) {
        final lv = ch.levels[i];
        if (widget.store.starsFor(lv.id) == 0 &&
            widget.store.isLevelUnlocked(lv.id)) {
          return (ch, lv, i);
        }
      }
    }
    return null;
  }

  Future<void> _playLevel(LevelDef level) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(store: widget.store, level: level),
      ),
    );
    if (!mounted) return;
    // Yulduzlar/tangalar o’zgargan bo’lishi mumkin — xaritani yangilaymiz.
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: farmSkyGradient(),
      child: SafeArea(
        bottom: false,
        child: FutureBuilder<List<ChapterDef>>(
          future: _chapters,
          // Isitilgan repo'da darhol ma'lumot bo'ladi — bo'sh osmon kadri yo'q.
          initialData: _repo.cachedChapters,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildErrorState(context);
            }
            final chapters = snapshot.data;
            if (chapters == null || chapters.isEmpty) {
              return const SizedBox.expand();
            }
            return ListenableBuilder(
              listenable: widget.store,
              builder: (context, _) {
                final active = _activeLevel(chapters);
                final currentChapter = active?.$1 ?? chapters.last;
                final activeLevelId = active?.$2.id;
                return Column(
                  children: [
                    MapHeader(store: widget.store),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: ChapterBanner(
                        chapterNumber: currentChapter.id,
                        levelIndex: active?.$2.index,
                        levelTotal: currentChapter.levels.length,
                      ),
                    ),
                    Expanded(
                      child: ClipRect(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final scale = constraints.maxWidth / _designW;
                            final sectionH = _designH * scale;
                            _maybeAutoScroll(
                              chapters: chapters,
                              active: active,
                              scale: scale,
                              sectionH: sectionH,
                              viewportH: constraints.maxHeight,
                            );
                            // Tepada oxirgi bob, pastda 1-bob (progress yuqoriga).
                            final ordered = chapters.reversed.toList();
                            return SingleChildScrollView(
                              controller: _scroll,
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                children: [
                                  for (final chapter in ordered)
                                    SizedBox(
                                      width: constraints.maxWidth,
                                      height: sectionH,
                                      child: FittedBox(
                                        fit: BoxFit.fill,
                                        clipBehavior: Clip.none,
                                        child: SizedBox(
                                          width: _designW,
                                          height: _designH,
                                          child: _buildSection(
                                            context,
                                            chapter,
                                            activeLevelId,
                                            isTop: chapter == chapters.last,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Ochilganda faol darajani ekran markaziga bir marta scroll qiladi.
  /// Scroll o'lchamlari (maxScrollExtent) birinchi kadrda tayyor bo'lmasligi
  /// mumkin — shuning uchun tayyor bo'lguncha bir necha kadr qayta uriniladi.
  void _maybeAutoScroll({
    required List<ChapterDef> chapters,
    required (ChapterDef, LevelDef, int)? active,
    required double scale,
    required double sectionH,
    required double viewportH,
  }) {
    if (_autoScrolled || active == null) return;
    final reversedIndex = chapters.length - 1 - chapters.indexOf(active.$1);
    final anchorY = _nodeAnchors[active.$3].dy;
    final globalY = reversedIndex * sectionH + anchorY * scale;
    final target = globalY - viewportH * 0.5;

    void attempt(int triesLeft) {
      if (!mounted || _autoScrolled) return;
      if (_scroll.hasClients && _scroll.position.hasContentDimensions) {
        _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
        _autoScrolled = true;
      } else if (triesLeft > 0) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => attempt(triesLeft - 1));
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => attempt(6));
  }

  Widget _buildErrorState(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpeechBubble(text: l10n.bubbleWrong1),
          const SizedBox(height: 14),
          const LivingAnimal(kind: FarmAnimal.cow, size: 116),
          const SizedBox(height: 24),
          ChunkyButton(
            color: FarmColors.green,
            darkColor: FarmColors.greenDark,
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            onPressed: _retryLoad,
            child: Text(
              l10n.retryButton,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bitta bob seksiyasi (390×500): tepaliklar, yo'lak, tugunlar, bob yorlig'i
  /// va SHU BOBNING hayvonlari. [isTop] — eng tepadagi seksiya (osmon jonzotlari
  /// bir marta): quyosh, bulutlar, kapalaklar, gulchang.
  Widget _buildSection(
    BuildContext context,
    ChapterDef chapter,
    String? activeLevelId, {
    required bool isTop,
  }) {
    final l10n = AppLocalizations.of(context);
    final store = widget.store;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (isTop) ...[
          const Positioned(left: 16, top: 2, child: Sun()),
          const Positioned(
            left: 0,
            top: 10,
            child: DriftingCloud(
              travelWidth: _designW + 80,
              period: Duration(seconds: 55),
              initialPhase: .78,
              child: Cloud.big(),
            ),
          ),
          const Positioned(
            left: 0,
            top: 34,
            child: DriftingCloud(
              travelWidth: _designW + 80,
              period: Duration(seconds: 38),
              initialPhase: .42,
              child: Cloud.small(),
            ),
          ),
        ],
        // Tepaliklar (o'tloq).
        Positioned(
          left: -_designW * .24,
          top: 96,
          child: const Hill(
            width: _designW * 1.48,
            height: 520,
            color: FarmColors.grassLight,
          ),
        ),
        Positioned(
          left: -_designW * .20,
          top: 150,
          child: const Hill(
            width: _designW * 1.40,
            height: 560,
            color: FarmColors.grass,
          ),
        ),
        const Positioned(
          left: 14,
          right: 14,
          top: 104,
          child: FenceStrip(height: 40),
        ),
        const Positioned.fill(
          child: CustomPaint(painter: DottedPathPainter()),
        ),
        if (isTop) const Positioned.fill(child: DottedPathGlow()),
        const Positioned(left: -16, bottom: -20, child: BushCluster.left()),
        const Positioned(right: -20, bottom: -26, child: BushCluster.right()),
        const Positioned(left: 36, top: 186, child: FlowerCluster.mapCluster1),
        const Positioned(left: 70, top: 330, child: FlowerCluster.mapCluster2),
        if (isTop)
          const Positioned.fill(
            child: AmbientPollen(width: _designW, height: _designH),
          ),
        // Do'kondan qo'yilgan dekorlar — faqat 1-bobda (uy fermasi).
        if (chapter.id == 1) ..._decor(store),
        // Bob yorlig'i (qaysi bob ekanini bildiradi).
        Positioned(
          left: 0,
          right: 0,
          top: 8,
          child: Center(child: _chapterLabel(l10n, chapter.id)),
        ),
        // Shu bobning hayvonlari.
        ..._chapterAnimals(chapter, l10n),
        // Daraja tugunlari.
        ..._buildNodes(chapter, activeLevelId),
        if (isTop)
          const Positioned.fill(
            child: AmbientFliers(width: _designW, height: _designH),
          ),
      ],
    );
  }

  List<Widget> _decor(ProgressStore store) => [
        if (store.equippedFor('decor1') == 'flowerBed')
          const Positioned(left: 8, top: 150, child: FlowerBed(size: 56)),
        if (store.equippedFor('decor2') == 'tree')
          const Positioned(right: 60, top: 250, child: AppleTree(size: 70)),
        if (store.equippedFor('decor3') == 'hay')
          const Positioned(left: 210, top: 330, child: HayStack(size: 50)),
        if (store.equippedFor('decor4') == 'pond')
          const Positioned(right: 100, top: 430, child: Pond(size: 64)),
      ];

  Widget _chapterLabel(AppLocalizations l10n, int id) {
    final (name, _) = chapterNames(l10n, id);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .82),
        borderRadius: BorderRadius.circular(FarmRadius.pill),
        border: Border.all(color: FarmColors.cardBorder, width: 2),
      ),
      child: Text(
        l10n.chapterTitle(id, name),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: FarmColors.inkOlive,
          letterSpacing: .5,
        ),
      ),
    );
  }

  /// Hayvon ovozi (tur → SFX).
  Sfx _voiceOf(FarmAnimal kind) => switch (kind) {
        FarmAnimal.cow => Sfx.cowMoo,
        FarmAnimal.pig => Sfx.pigOink,
        FarmAnimal.sheep => Sfx.sheepBaa,
        FarmAnimal.chicken => Sfx.chickenCluck,
        FarmAnimal.chick => Sfx.chickCheep,
        FarmAnimal.duck => Sfx.duckQuack,
        FarmAnimal.rabbit => Sfx.rabbitSqueak,
      };

  /// Sahnaga qo'yilgan tirik hayvon (bosiladi).
  Widget _placedAnimal(
    FarmAnimal kind, {
    double? left,
    double? right,
    required double top,
    required double size,
    bool mirrored = false,
  }) {
    return Positioned(
      left: left,
      right: right,
      top: top,
      child: _animalTap(
        _voiceOf(kind),
        kind,
        LivingAnimal(
          kind: kind,
          size: size,
          mirrored: mirrored,
          accessory: _accessoryFor(kind.name),
          expression: _expr(kind),
          jumpTrigger: _jumps[kind],
        ),
      ),
    );
  }

  /// Ikkita jo'ja (ikkinchisi ko'zguда).
  Widget _chickPair({required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      child: _animalTap(
        Sfx.chickCheep,
        FarmAnimal.chick,
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LivingAnimal(
              kind: FarmAnimal.chick,
              size: 40,
              accessory: _accessoryFor('chick'),
              expression: _expr(FarmAnimal.chick),
              jumpTrigger: _jumps[FarmAnimal.chick],
            ),
            const SizedBox(width: 4),
            Transform.scale(
              scale: .86,
              alignment: Alignment.bottomCenter,
              child: LivingAnimal(
                kind: FarmAnimal.chick,
                size: 40,
                accessory: _accessoryFor('chick'),
                mirrored: true,
                expression: _expr(FarmAnimal.chick),
                jumpTrigger: _jumps[FarmAnimal.chick],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bubbleAt(double left, double top, String text) =>
      Positioned(left: left, top: top, child: SpeechBubble(text: text));

  /// Har bob o'z hayvonlari to'plamini ko'rsatadi (ferma to'la). Har bobda
  /// 4–6 hayvon; 4/5-KO'LMAK/DALA o'rdak, 3/6-YAYLOV/BOG' quyon bilan boyitilgan.
  List<Widget> _chapterAnimals(ChapterDef chapter, AppLocalizations l10n) {
    switch (chapter.id) {
      case 1: // MOLXONA — sigir, jo'jalar, tovuq, cho'chqa
        return [
          _placedAnimal(FarmAnimal.cow, left: 250, top: 356, size: 116),
          _bubbleAt(246, 318, l10n.bubbleCowPlay),
          _chickPair(left: 118, top: 452),
          _placedAnimal(FarmAnimal.chicken, left: 2, top: 214, size: 60),
          _placedAnimal(FarmAnimal.pig, right: 12, top: 150, size: 60),
        ];
      case 2: // TOVUQXONA — tovuq, jo'ja, cho'chqa, qo'y
        return [
          _placedAnimal(FarmAnimal.chicken, left: 250, top: 320, size: 80),
          _bubbleAt(244, 286, l10n.bubbleChickenHi),
          _placedAnimal(FarmAnimal.pig, right: 14, top: 150, size: 64),
          _placedAnimal(FarmAnimal.chick, left: 20, top: 420, size: 40),
          _placedAnimal(FarmAnimal.sheep, left: 8, top: 300, size: 60),
        ];
      case 3: // YAYLOV — qo'y, cho'chqa, sigir, quyon
        return [
          _placedAnimal(FarmAnimal.sheep, left: 6, top: 320, size: 46 * 1.7),
          _bubbleAt(8, 292, l10n.bubbleSheepHi),
          _placedAnimal(FarmAnimal.pig, right: 14, top: 320, size: 86),
          _bubbleAt(300, 288, l10n.bubblePigHi),
          _placedAnimal(FarmAnimal.cow, left: 150, top: 452, size: 72),
          _placedAnimal(FarmAnimal.rabbit, left: 250, top: 150, size: 50),
        ];
      case 4: // KO'LMAK — o'rdaklar, tovuq, jo'ja, qo'y
        return [
          _placedAnimal(FarmAnimal.chicken, left: 248, top: 356, size: 78),
          _bubbleAt(244, 322, l10n.bubbleChickenHi),
          _chickPair(left: 20, top: 300),
          _placedAnimal(FarmAnimal.sheep, right: 8, top: 150, size: 68),
          _placedAnimal(FarmAnimal.duck, left: 138, top: 448, size: 62),
          _bubbleAt(150, 414, l10n.bubbleDuckHi),
          _placedAnimal(FarmAnimal.duck, left: 206, top: 458, size: 46,
              mirrored: true),
        ];
      case 5: // DALA — sigir, qo'y, jo'ja, o'rdak
        return [
          _placedAnimal(FarmAnimal.cow, left: 246, top: 340, size: 110),
          _bubbleAt(242, 302, l10n.bubbleCowPlay),
          _placedAnimal(FarmAnimal.sheep, left: 6, top: 300, size: 46 * 1.6),
          _placedAnimal(FarmAnimal.chick, left: 150, top: 452, size: 40),
          _placedAnimal(FarmAnimal.duck, right: 10, top: 150, size: 56),
        ];
      default: // BOG' — cho'chqa, tovuq, jo'jalar, quyonlar
        return [
          _placedAnimal(FarmAnimal.pig, left: 250, top: 340, size: 90),
          _bubbleAt(246, 302, l10n.bubblePigHi),
          _placedAnimal(FarmAnimal.chicken, left: 6, top: 300, size: 72),
          _chickPair(left: 132, top: 452),
          _placedAnimal(FarmAnimal.rabbit, right: 18, top: 150, size: 56),
          _bubbleAt(286, 118, l10n.bubbleRabbitHi),
          _placedAnimal(FarmAnimal.rabbit, left: 20, top: 452, size: 46,
              mirrored: true),
        ];
    }
  }

  List<Widget> _buildNodes(ChapterDef chapter, String? activeLevelId) {
    final store = widget.store;
    final nodes = <Widget>[];
    final count = chapter.levels.length < _nodeAnchors.length
        ? chapter.levels.length
        : _nodeAnchors.length;
    for (var i = 0; i < count; i++) {
      final level = chapter.levels[i];
      final stars = store.starsFor(level.id);
      final LevelNodeState state;
      if (stars > 0) {
        state = LevelNodeState.completed;
      } else if (level.id == activeLevelId) {
        state = LevelNodeState.active;
      } else {
        state = LevelNodeState.locked;
      }
      final d = LevelNode.diameterFor(state);
      final size = LevelNode.sizeFor(state);
      final anchor = _nodeAnchors[i];
      final active = state == LevelNodeState.active;
      final ctaBelow = active && anchor.dy - d / 2 - LevelNode.ctaExtent < 0;
      nodes.add(
        Positioned(
          left: anchor.dx - size.width / 2,
          top: anchor.dy -
              d / 2 -
              (active && !ctaBelow ? LevelNode.ctaExtent : 0),
          child: LevelNode(
            number: level.index,
            state: state,
            stars: stars,
            ctaBelow: ctaBelow,
            onPlay:
                state == LevelNodeState.locked ? null : () => _playLevel(level),
          ),
        ),
      );
    }
    return nodes;
  }

  /// Slotdagi kiyilgan buyumni personaj aksessuariga o’giradi.
  AnimalAccessory _accessoryFor(String slot) {
    return switch (widget.store.equippedFor(slot)) {
      'cowHat' => AnimalAccessory.cowHat,
      'chickBow' => AnimalAccessory.chickBow,
      'pigGlasses' => AnimalAccessory.pigGlasses,
      'sheepScarf' => AnimalAccessory.sheepScarf,
      _ => AnimalAccessory.none,
    };
  }

  /// Hayvon bosilganda: ovoz + quvnoq yuz + sakrash.
  Widget _animalTap(Sfx sfx, FarmAnimal kind, Widget child) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _celebrate(sfx, kind),
      child: child,
    );
  }

  void _celebrate(Sfx sfx, FarmAnimal kind) {
    AudioService.instance.play(sfx);
    setState(() {
      _jumps[kind] = (_jumps[kind] ?? 0) + 1;
      _happy.add(kind);
    });
    final t = Timer(const Duration(milliseconds: 750), () {
      if (!mounted) return;
      setState(() => _happy.remove(kind));
    });
    _celebrateTimers.add(t);
  }

  /// Teginishdan keyin ~0.75s «quvnoq» ifoda (aks holda idle).
  AnimalExpression _expr(FarmAnimal kind) =>
      _happy.contains(kind) ? AnimalExpression.happy : AnimalExpression.idle;
}
