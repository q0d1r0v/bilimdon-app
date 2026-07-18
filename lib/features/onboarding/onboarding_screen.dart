import 'package:flutter/material.dart';

import '../../characters/animal.dart';
import '../../core/audio/audio_service.dart';
import '../../core/persistence/progress_store.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/app_localizations.dart';
import '../../scene/sky.dart';
import '../../widgets/chunky_button.dart';

/// Birinchi ochilish sozlamasi (2 qadam):
///  1) TIL — uz/ru/en (tanlangach butun ilova shu tilga o'tadi);
///  2) ISM (klaviaturadan, majburiy) + YOSH (4–8) + AVATAR (default sigir).
/// Tugagach `store.setOnboarded(true)` — `app.dart` avtomatik RootShell'ga o'tadi.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.store});

  final ProgressStore store;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  late final TextEditingController _nameCtrl = TextEditingController(
    // 'Aziza' — default nom; foydalanuvchi o'zinikini yozsin (bo'sh boshlanadi).
    text: widget.store.playerName == 'Aziza' ? '' : widget.store.playerName,
  );
  final FocusNode _nameFocus = FocusNode();
  int? _age;
  late String _avatar = widget.store.avatar; // default 'cow'

  ProgressStore get store => widget.store;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _pickLanguage(String code) {
    AudioService.instance.play(Sfx.tap);
    store.setLocaleOverride(code); // butun ilova darhol shu tilga o'tadi
    setState(() => _step = 1);
  }

  bool get _canFinish => _nameCtrl.text.trim().isNotEmpty && _age != null;

  Future<void> _finish() async {
    if (!_canFinish) return;
    FocusScope.of(context).unfocus();
    AudioService.instance.play(Sfx.win);
    await store.setPlayerName(_nameCtrl.text.trim());
    await store.setAvatar(_avatar);
    await store.setAge(_age);
    await store.setOnboarded(true); // -> app.dart RootShell'ga o'tadi
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _step == 1) setState(() => _step = 0);
      },
      child: Scaffold(
        body: Container(
          decoration: farmSkyGradient(),
          child: SafeArea(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: _step == 0 ? _languageStep(l10n) : _profileStep(l10n),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 1-qadam: til ───────────────────────────────────────────────────────────
  Widget _languageStep(AppLocalizations l10n) {
    return _Card(
      children: [
        const Text('🌍', style: TextStyle(fontSize: 44)),
        const SizedBox(height: 10),
        Text(l10n.onbLangTitle, textAlign: TextAlign.center, style: _titleStyle),
        const SizedBox(height: 18),
        // Til nomlari HAR DOIM o'z tilida (to'g'ri i18n amaliyoti).
        _bigButton('O’zbekcha', () => _pickLanguage('uz')),
        const SizedBox(height: 10),
        _bigButton('Русский', () => _pickLanguage('ru')),
        const SizedBox(height: 10),
        _bigButton('English', () => _pickLanguage('en')),
      ],
    );
  }

  // ── 2-qadam: ism + yosh + avatar ────────────────────────────────────────────
  Widget _profileStep(AppLocalizations l10n) {
    return _Card(
      children: [
        Text(l10n.onbAboutTitle, textAlign: TextAlign.center, style: _titleStyle),
        const SizedBox(height: 16),
        // Avatar tanlash — tanlangan sigir default belgilangan.
        _label(l10n.onbAvatarLabel),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          children: [
            for (final animal in FarmAnimal.values) _avatarChoice(animal),
          ],
        ),
        const SizedBox(height: 16),
        _label(l10n.onbNameLabel),
        const SizedBox(height: 6),
        TextField(
          controller: _nameCtrl,
          focusNode: _nameFocus,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          maxLength: 16,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => FocusScope.of(context).unfocus(),
          decoration: InputDecoration(
            hintText: l10n.onbNameHint,
            counterText: '',
            filled: true,
            fillColor: FarmColors.cream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: FarmColors.cardBorder, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: FarmColors.green, width: 3),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: FarmColors.inkDark,
          ),
        ),
        const SizedBox(height: 12),
        _label(l10n.onbAgeLabel),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final age in [4, 5, 6, 7, 8]) _ageChoice(age),
          ],
        ),
        const SizedBox(height: 20),
        _bigButton(
          l10n.onbStart,
          _canFinish ? _finish : null,
          green: true,
        ),
      ],
    );
  }

  // ── Kichik qismlar ──────────────────────────────────────────────────────────
  Widget _avatarChoice(FarmAnimal animal) {
    final selected = _avatar == animal.name;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AudioService.instance.play(Sfx.tap);
        setState(() => _avatar = animal.name);
      },
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: FarmColors.creamAvatar,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? FarmColors.red : FarmColors.cardBorder,
            width: selected ? 3 : 2,
          ),
        ),
        child: ClipOval(child: Center(child: buildAnimal(animal, size: 38))),
      ),
    );
  }

  Widget _ageChoice(int age) {
    final selected = _age == age;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AudioService.instance.play(Sfx.tap);
          setState(() => _age = age);
        },
        child: Container(
          width: 46,
          height: 46,
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
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : FarmColors.inkDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _bigButton(String label, VoidCallback? onPressed, {bool green = false}) {
    final enabled = onPressed != null;
    return SizedBox(
      width: double.infinity,
      child: ChunkyButton(
        color: !enabled
            ? FarmColors.lockedBeige
            : (green ? FarmColors.green : Colors.white),
        darkColor: !enabled
            ? FarmColors.lockedDark
            : (green ? FarmColors.greenDark : FarmColors.cardBorder),
        borderRadius: 16,
        minHeight: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: onPressed ?? () {},
        child: Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: !enabled
                ? FarmColors.inkFaded
                : (green ? Colors.white : FarmColors.inkDark),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: FarmColors.inkOlive,
          ),
        ),
      );

  static const _titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: FarmColors.inkDark,
  );
}

/// Markazlashgan oq karta (onboarding qadamlari uchun).
class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: FarmColors.cardBorder, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(30, 60, 20, .18),
              offset: Offset(0, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
