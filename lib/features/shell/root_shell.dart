import 'package:flutter/material.dart';

import '../../content/content_repository.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../core/utils/css_shapes.dart';
import '../../l10n/app_localizations.dart';
import '../contents/contents_screen.dart';
import '../map/map_screen.dart';
import '../profile/profile_screen.dart';
import '../shop/shop_screen.dart';

/// Ildiz qobiq: IndexedStack + 4 tabli pastki nav (prototip dizayni).
class RootShell extends StatefulWidget {
  const RootShell({super.key, required this.store, this.repo});

  final ProgressStore store;

  /// Oldindan isitilgan kontent repo (main.dart) — xaritaga uzatiladi.
  final ContentRepository? repo;

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _tab = 0;

  /// Profil tabidan HAR chiqishda oshadi — ProfileScreen yangi kalit
  /// bilan qayta quriladi va holati (jumladan ota-onalar darvozasi
  /// qulfi, `_statsUnlocked`) qayta yopiladi. IndexedStack state'ni
  /// hech qachon dispose qilmaydi, shuning uchun kalit orqali tiklanadi.
  int _profileEpoch = 0;

  @override
  void initState() {
    super.initState();
    AudioService.instance
      ..soundOn = widget.store.soundOn
      ..musicOn = widget.store.musicOn
      // Menyu musiqasi asta ko'tariladi — ochilishda keskin «yonmasin».
      ..startMusic(Bgm.map, fadeIn: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final screens = <Widget>[
      MapScreen(store: widget.store, repo: widget.repo),
      ShopScreen(store: widget.store),
      ContentsScreen(store: widget.store),
      ProfileScreen(key: ValueKey(_profileEpoch), store: widget.store),
    ];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: [
                // TickerMode: ko’rinmayotgan tab animatsiya tikerlarini
                // to’xtatadi (IndexedStack buni o’zi qilmaydi) — nafas,
                // bulut va puls kontrollerlarining bekor CPU sarfi yo’q.
                for (var i = 0; i < screens.length; i++)
                  TickerMode(enabled: i == _tab, child: screens[i]),
              ],
            ),
          ),
          _BottomNav(
            current: _tab,
            labels: [l10n.tabMap, l10n.tabShop, l10n.tabContents, l10n.tabProfile],
            onTap: (i) {
              if (i == _tab) return;
              AudioService.instance.play(Sfx.tap);
              setState(() {
                if (_tab == 3) _profileEpoch++; // profildan chiqildi
                _tab = i;
              });
            },
          ),
        ],
      ),
    );
  }
}

/// Pastki nav — prototip: #FFFDF6 fon, 4px #7ED957 tepa chiziq,
/// CSS-chizilgan ikonkalar (bayroq/do'kon/kubok/profil).
class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.current,
    required this.labels,
    required this.onTap,
  });

  final int current;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: FarmColors.cream,
        border: Border(
          top: BorderSide(color: FarmColors.navGrass, width: 4),
        ),
      ),
      padding: EdgeInsets.only(
        // 4 + 48dp tap zonasi ichidagi markazlash (6) = ikonka avvalgidek
        // 10dp dan boshlanadi; tap maydoni esa 36 → 48dp ga o'sdi.
        top: 4,
        left: 8,
        right: 8,
        bottom: bottomInset > 0 ? bottomInset : 12,
      ),
      child: Row(
        children: [
          for (var i = 0; i < 4; i++)
            Expanded(
              child: Semantics(
                button: true,
                selected: current == i,
                label: labels[i],
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  // Android minimal bosish maydoni 48dp. Ikonka+matn faqat
                  // 36dp beradi, shuning uchun cheklov TAP ZONASI ICHIDA
                  // bo'lishi kerak — tashqi `padding` hisoblanmaydi.
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ExcludeSemantics(
                          child: SizedBox(
                            width: 22,
                            height: 18,
                            child: _NavIcon(index: i, active: current == i),
                          ),
                        ),
                        const SizedBox(height: 4),
                        ExcludeSemantics(
                          child: Text(
                            labels[i],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: current == i
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: current == i
                                  ? FarmColors.red
                                  : FarmColors.navInactive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({required this.index, required this.active});

  final int index;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return switch (index) {
      0 => _flag(),
      1 => _shop(),
      2 => _book(),
      _ => _person(),
    };
  }

  /// Mundarija: 3 gorizontal chiziq (ro'yxat/mundarija belgisi).
  Widget _book() {
    final bar = active ? FarmColors.red : FarmColors.navInactive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.6),
            child: Container(
              width: 18,
              height: 2.6,
              decoration: BoxDecoration(
                color: bar,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }

  /// Xarita: yog'och tayoq + qizil bayroq (faol holatda qizil).
  Widget _flag() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 4,
          child: Container(
            width: 4,
            height: 14,
            decoration: BoxDecoration(
              color: active ? FarmColors.brown : FarmColors.navInactiveLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            width: 20,
            height: 9,
            decoration: BoxDecoration(
              color: active ? FarmColors.red : FarmColors.navInactive,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2),
                topRight: Radius.circular(5),
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Do'kon: uchburchak tom + tana + eshik.
  Widget _shop() {
    final roof = active ? FarmColors.red : FarmColors.navInactive;
    final wall = active ? FarmColors.redGradTop : FarmColors.navInactiveLight;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        TriangleWidget(width: 22, height: 8, color: roof,
            direction: TriangleDirection.up),
        Positioned(
          top: 8,
          child: Container(
            width: 18,
            height: 10,
            decoration: BoxDecoration(
              color: wall,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(3),
                bottomRight: Radius.circular(3),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 6,
            height: 7,
            decoration: const BoxDecoration(
              color: FarmColors.cream,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(3),
                topRight: Radius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }


  /// Profil: bosh doira + kichik pastga uchburchak.
  Widget _person() {
    final head = active ? FarmColors.red : FarmColors.navInactiveLight;
    final chin = active ? FarmColors.redDark : FarmColors.navInactive;
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Positioned(
          top: 1,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(color: head, shape: BoxShape.circle),
          ),
        ),
        Positioned(
          top: 8,
          child: TriangleWidget(
            width: 6,
            height: 5,
            color: chin,
            direction: TriangleDirection.down,
          ),
        ),
      ],
    );
  }
}
