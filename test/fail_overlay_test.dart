import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/features/game/fail_overlay.dart';
import 'package:math_farm/l10n/app_localizations.dart';
import 'package:math_farm/l10n/app_localizations_uz.dart';

/// FailOverlay — 3 yurak tugaganda ko'rinadigan MULOYIM oyna. Qattiq
/// "yutqazding" yo'q: hamdard matn + "Qaytadan" + "Chiqish".
Widget wrap(Widget child) {
  return MaterialApp(
    locale: const Locale('uz'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: Stack(children: [child])),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final uz = AppLocalizationsUz();

  testWidgets('muloyim matn + ikkala tugmani ko\'rsatadi', (tester) async {
    await tester.pumpWidget(
      wrap(FailOverlay(onRetry: () {}, onExit: () {})),
    );
    await tester.pump();

    expect(find.text(uz.failTitle), findsOneWidget);
    expect(find.text(uz.failRetry), findsOneWidget);
    expect(find.text(uz.failExit), findsOneWidget);
  });

  testWidgets('Qaytadan tugmasi onRetry ni chaqiradi', (tester) async {
    var retried = 0;
    var exited = 0;
    await tester.pumpWidget(
      wrap(FailOverlay(onRetry: () => retried++, onExit: () => exited++)),
    );
    await tester.pump();

    await tester.tap(find.text(uz.failRetry));
    await tester.pump();
    expect(retried, 1);
    expect(exited, 0);
  });

  testWidgets('Chiqish tugmasi onExit ni chaqiradi', (tester) async {
    var retried = 0;
    var exited = 0;
    await tester.pumpWidget(
      wrap(FailOverlay(onRetry: () => retried++, onExit: () => exited++)),
    );
    await tester.pump();

    await tester.tap(find.text(uz.failExit));
    await tester.pump();
    expect(exited, 1);
    expect(retried, 0);
  });
}
