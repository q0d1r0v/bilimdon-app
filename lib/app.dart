import 'package:flutter/material.dart';

import 'content/content_repository.dart';
import 'core/persistence/progress_store.dart';
import 'core/theme/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/root_shell.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';

/// Ildiz ilova. Locale BIR joyda hal qilinadi ([MathFarmApp.resolveLocale])
/// va natija ham satrlarga, ham temaga beriladi — ru tizim tilida shrift
/// Nunito bo'lishi shart (Fredoka'da kirill glifi yo'q, DESIGN_SPEC).
class MathFarmApp extends StatefulWidget {
  const MathFarmApp({super.key, required this.store, this.content});

  final ProgressStore store;

  /// Oldindan isitilgan kontent repo (main.dart) — RootShell/xaritaga uzatiladi
  /// (splash tugaganда xarita bo'sh osmon kadri ko'rsatmaydi). Testlarда null.
  final ContentRepository? content;

  /// Yagona locale-yechim: aniq override → qurilma tillari ro'yxatidan
  /// birinchi qo'llab-quvvatlanadigani → uz (standart).
  static Locale resolveLocale(
    String? override,
    List<Locale>? deviceLocales,
    Iterable<Locale> supported,
  ) {
    if (override != null) return Locale(override);
    for (final device in deviceLocales ?? const <Locale>[]) {
      for (final l in supported) {
        if (l.languageCode == device.languageCode) return l;
      }
    }
    return const Locale('uz');
  }

  @override
  State<MathFarmApp> createState() => _MathFarmAppState();
}

class _MathFarmAppState extends State<MathFarmApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Tizim tili o'zgarganda tema shrifti qayta hisoblanadi (satrlarni
  /// MaterialApp o'zi yangilaydi, tema esa build'da hisoblanadi).
  @override
  void didChangeLocales(List<Locale>? locales) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final override = widget.store.localeOverride;
        final resolved = MathFarmApp.resolveLocale(
          override,
          WidgetsBinding.instance.platformDispatcher.locales,
          AppLocalizations.supportedLocales,
        );
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          debugShowCheckedModeBanner: false,
          locale: override != null ? Locale(override) : null,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          localeListResolutionCallback: (device, supported) =>
              MathFarmApp.resolveLocale(override, device, supported),
          builder: (context, child) {
            // Matn — dizaynning bir qismi: tizim shrift masshtabi art'ni
            // buzmasligi uchun 1.0 ga qotiriladi (bolalar planshetlarida
            // masshtab har xil bo'ladi).
            return MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
          theme: buildFarmTheme(resolved),
          // Kirish splash sahnasi (~2.2s), so'ng: til/ism/yosh/avatar
          // sozlangunicha onboarding. `home` store `ListenableBuilder` ichida —
          // setOnboarded(true) avtomatik RootShell'ga almashtiradi.
          home: SplashGate(
            child: widget.store.onboarded
                ? RootShell(store: widget.store, repo: widget.content)
                : OnboardingScreen(store: widget.store),
          ),
        );
      },
    );
  }
}
