import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Apostrof siyosati: barcha foydalanuvchiga ko'rinadigan satrlarda
/// YAGONA kanonik kodepoint — U+2019 (').
/// Taqiqlangan: U+0027 ('), U+2018 (‘), U+02BB (ʻ) — Fredoka'da U+02BB
/// glifi YO'Q (tofu chiqadi), aralash apostroflar esa qidiruv/tartiblashni
/// buzadi.
void main() {
  test('ARB fayllarida faqat U+2019 apostrof ishlatiladi', () {
    final dir = Directory('lib/l10n');
    final offenders = <String>[];
    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.arb')) continue;
      final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      map.forEach((key, value) {
        if (key.startsWith('@') || value is! String) return;
        for (final (cp, name) in [
          (0x0027, 'U+0027 ASCII apostrof'),
          (0x2018, 'U+2018 chap qo‘shtirnoq'),
          (0x02BB, 'U+02BB okina'),
        ]) {
          if (value.runes.contains(cp)) {
            offenders.add('${file.path} → $key: $name ("$value")');
          }
        }
      });
    }
    expect(
      offenders,
      isEmpty,
      reason: 'Apostrofni U+2019 (’) ga almashtiring:\n${offenders.join('\n')}',
    );
  });
}
