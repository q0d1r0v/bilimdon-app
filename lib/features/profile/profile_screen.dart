import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/lock_icon.dart';
import '../../scene/sky.dart';
import '../../widgets/chunky_button.dart';
import 'parent_gate.dart';

/// Profil ekrani: osmon fonli sarlavha (avatar + ism + daraja),
/// avatar tanlash qatori, sozlamalar kartasi va ota-onalar
/// darvozasi ortidagi statistika kartasi.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  /// Darvoza ochilgach statistika tabdan chiqilguncha ko‘rinib turadi.
  bool _statsUnlocked = false;

  /// Ism maydoni faqat tahrirlash paytida TextField bo'ladi.
  bool _editingName = false;

  late final TextEditingController _nameCtrl =
      TextEditingController(text: widget.store.playerName);

  ProgressStore get store => widget.store;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _saveName() {
    final t = _nameCtrl.text.trim();
    if (t.isNotEmpty) store.setPlayerName(t);
  }

  /// Ko'rish rejimida — matn + qalam; tahrir rejimida — TextField.
  Widget _nameField(AppLocalizations l10n) {
    if (!_editingName) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _nameCtrl.text = store.playerName;
          setState(() => _editingName = true);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: FarmColors.cream,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: FarmColors.cardBorder, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  store.playerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: FarmColors.inkDark,
                  ),
                ),
              ),
              const Icon(Icons.edit, size: 18, color: FarmColors.inkOlive),
            ],
          ),
        ),
      );
    }
    return TextField(
      controller: _nameCtrl,
      autofocus: true,
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      maxLength: 16,
      onSubmitted: (_) {
        _saveName();
        setState(() => _editingName = false);
      },
      onTapOutside: (_) {
        FocusManager.instance.primaryFocus?.unfocus();
        _saveName();
        setState(() => _editingName = false);
      },
      decoration: InputDecoration(
        hintText: l10n.onbNameHint,
        counterText: '',
        filled: true,
        fillColor: FarmColors.cream,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FarmColors.cardBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: FarmColors.green, width: 3),
        ),
      ),
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: FarmColors.inkDark,
      ),
    );
  }

  /// Saqlangan avatar nomini turga o‘girish (noma’lum bo‘lsa sigir).
  static FarmAnimal _avatarKind(String name) {
    for (final a in FarmAnimal.values) {
      if (a.name == name) return a;
    }
    return FarmAnimal.cow;
  }

  Future<void> _openGate() async {
    AudioService.instance.play(Sfx.tap);
    final ok = await showParentGate(context);
    if (ok == true && mounted) {
      AudioService.instance.play(Sfx.unlock);
      setState(() => _statsUnlocked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      color: FarmColors.gameBg,
      child: ListenableBuilder(
        listenable: store,
        builder: (context, _) => Column(
          children: [
            _header(l10n),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _profileCard(l10n),
                    const SizedBox(height: 12),
                    _settingsCard(l10n),
                    const SizedBox(height: 12),
                    _statsCard(l10n),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Osmon gradientli sarlavha: 72px avatar doirasi, ism, daraja va
  /// 5 ta avatar tanlash doirasi.
  Widget _header(AppLocalizations l10n) {
    return Container(
      decoration: farmSkyGradient(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: FarmColors.creamAvatar,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(30, 60, 20, .18),
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Center(
                        child: buildAnimal(_avatarKind(store.avatar), size: 56),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          store.playerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Color.fromRGBO(20, 60, 110, .35),
                                offset: Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.levelBadge(store.displayLevel),
                          style: const TextStyle(
                            fontSize: 12,
                            color: FarmColors.headerSub,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _avatarPicker(),
            ],
          ),
        ),
      ),
    );
  }

  /// Kichik doiralar — tanlangani qizil halqa bilan. 7 tur bir qatorga
  /// sig'masligi mumkin (o'rdak/quyon qo'shilgach) — Wrap bilan o'raladi.
  Widget _avatarPicker() {
    final current = _avatarKind(store.avatar);
    return Wrap(
      alignment: WrapAlignment.center,
      runSpacing: 4,
      children: [
        for (final animal in FarmAnimal.values)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              AudioService.instance.play(Sfx.tap);
              store.setAvatar(animal.name);
            },
            child: Padding(
              // Umumiy teginish maydoni 48×48 dan kam bo‘lmasin.
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: FarmColors.creamAvatar,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: animal == current ? FarmColors.red : Colors.white,
                    width: animal == current ? 3 : 2,
                  ),
                ),
                child: ClipOval(
                  child: Center(child: buildAnimal(animal, size: 34)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Profil ma'lumotlari: ism (tahrirlanadi) + yosh (4–8).
  Widget _profileCard(AppLocalizations l10n) {
    return _Card(
      title: l10n.profileInfoTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onbNameLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkOlive,
            ),
          ),
          const SizedBox(height: 6),
          // Ism faqat TAHRIRLAGANDA TextField bo'ladi; aks holda oddiy matn.
          // (Doimiy TextField IndexedStack'da fon-timerlar qoldirar edi.)
          _nameField(l10n),
          const SizedBox(height: 10),
          Text(
            l10n.onbAgeLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkOlive,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [for (final age in [4, 5, 6, 7, 8]) _ageChip(age)],
          ),
        ],
      ),
    );
  }

  Widget _ageChip(int age) {
    final selected = store.age == age;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.play(Sfx.tap);
          store.setAge(age);
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? FarmColors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? FarmColors.greenDark : FarmColors.cardBorder,
              width: 2,
            ),
          ),
          child: Text(
            '$age',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : FarmColors.inkDark,
            ),
          ),
        ),
      ),
    );
  }

  /// Sozlamalar kartasi: ovoz/musiqa/taymer va til chiplari.
  Widget _settingsCard(AppLocalizations l10n) {
    return _Card(
      title: l10n.settingsTitle,
      child: Column(
        children: [
          _switchRow(
            label: l10n.settingSound,
            value: store.soundOn,
            onChanged: (v) {
              store.setSoundOn(v);
              AudioService.instance.soundOn = v;
            },
          ),
          _switchRow(
            label: l10n.settingMusic,
            value: store.musicOn,
            onChanged: (v) {
              store.setMusicOn(v);
              AudioService.instance.setMusic(on: v);
            },
          ),
          _switchRow(
            label: l10n.settingTimer,
            value: store.timerAllowed,
            onChanged: store.setTimerAllowed,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.settingLanguage,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: FarmColors.inkDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Til nomlari o‘z tilida qoladi — bu to‘g‘ri i18n amaliyoti.
              _langChip('uz', 'O’zbekcha'),
              const SizedBox(width: 8),
              _langChip('ru', 'Русский'),
              const SizedBox(width: 8),
              _langChip('en', 'English'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _switchRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: FarmColors.inkDark,
            ),
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: FarmColors.green,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _langChip(String code, String label) {
    // Haqiqiy hal qilingan locale bilan solishtiramiz — override yo'q
    // (yangi o'rnatish, tizim tili ru/en) holatda ham to'g'ri chip yonadi.
    final selected = Localizations.localeOf(context).languageCode == code;
    return Expanded(
      child: ChunkyButton(
        color: selected ? FarmColors.green : Colors.white,
        darkColor: selected ? FarmColors.greenDark : FarmColors.cardBorder,
        borderRadius: 12,
        ledge: 3,
        minHeight: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        onPressed: () {
          AudioService.instance.play(Sfx.tap);
          store.setLocaleOverride(code);
        },
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : FarmColors.inkDark,
          ),
        ),
      ),
    );
  }

  /// Statistika kartasi — qulflangan holda darvozani ochadi.
  Widget _statsCard(AppLocalizations l10n) {
    if (!_statsUnlocked) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openGate,
        child: _Card(
          title: l10n.statsTitle,
          trailing: const LockIcon(),
          child: const SizedBox(height: 4),
        ),
      );
    }
    final correctFirstTry = store.skills.values
        .fold(0, (sum, s) => sum + s.correctFirstTry);
    return _Card(
      key: const ValueKey('statsCard'),
      title: l10n.statsTitle,
      child: Column(
        children: [
          _statRow(l10n.statQuestions, store.totals.questionsAnswered),
          _statRow(l10n.statCorrectFirstTry, correctFirstTry),
          _statRow(l10n.statStars, store.totalStars),
          _statRow(l10n.statLevels, store.totals.levelsCompleted),
          _statRow(l10n.statStreak, store.streakCurrent),
          _statRow(l10n.statCoins, store.coins),
        ],
      ),
    );
  }

  Widget _statRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: FarmColors.inkDark,
              ),
            ),
          ),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: FarmColors.inkOlive,
            ),
          ),
        ],
      ),
    );
  }
}

/// Oq karta: radius 20, 3px cardBorder, padding 16, inkOlive sarlavha.
class _Card extends StatelessWidget {
  const _Card({super.key, required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: FarmColors.cardBorder, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: FarmColors.inkOlive,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
