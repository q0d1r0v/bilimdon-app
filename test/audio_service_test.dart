import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:math_farm/core/audio/audio_service.dart';

/// Audio o'zgarishlari testi — PLAYBACK'siz.
///
/// Loyiha konvensiyasi: `AudioService` «fire-and-forget, hech qachon crash
/// qilmaydi» shartnomasiga ega va testlarda haqiqiy pleer chaqirilmaydi
/// (audioplayers'ning creation-completer'i mock ostida hech qachon tugamaydi
/// → await qotadi). Shuning uchun bu yerda enum shartnomasi va DISKDAGI
/// (regeneratsiya qilingan) asset fayllari tekshiriladi — fade/never-crash
/// xulqi qurilmada (device run) tasdiqlanadi.

void main() {
  group('Bgm — menyu va o\'yin ENDI farqli (bug fix)', () {
    test('menyu treki o\'yin trekidan tinchroq (past ijro ovozi)', () {
      expect(Bgm.map.volume, lessThan(Bgm.game.volume));
      expect(Bgm.map.volume, greaterThan(0));
      expect(Bgm.game.volume, lessThanOrEqualTo(1.0));
    });

    test('trek yo\'llari to\'g\'ri va alohida fayllar', () {
      expect(Bgm.map.assetPath, 'audio/music/music_map.wav');
      expect(Bgm.game.assetPath, 'audio/music/music_game.wav');
      expect(Bgm.map.assetPath, isNot(Bgm.game.assetPath));
    });
  });

  group('Sfx enum ↔ fayl shartnomasi', () {
    test('18 ta SFX, har biri audio/sfx/<file>.wav', () {
      expect(Sfx.values.length, 18);
      for (final s in Sfx.values) {
        expect(s.assetPath, 'audio/sfx/${s.file}.wav');
      }
    });

    test('7 ta hayvon ovozi mavjud (o‘rdak va quyon qo‘shildi)', () {
      final files = Sfx.values.map((s) => s.file).toSet();
      expect(files, containsAll(<String>[
        'cow_moo',
        'chicken_cluck',
        'pig_oink',
        'sheep_baa',
        'chick_cheep',
        'duck_quack',
        'rabbit_squeak',
      ]));
    });
  });

  group('Regeneratsiya qilingan asset fayllari (tools/gen_audio.py)', () {
    // Testlar paket ildizidan (math_farm) ishga tushadi.
    File sfx(String f) => File('assets/audio/sfx/$f.wav');
    File music(String f) => File('assets/audio/music/$f.wav');

    test('barcha 18 SFX fayli mavjud va bo\'sh emas', () {
      for (final s in Sfx.values) {
        final file = sfx(s.file);
        expect(file.existsSync(), isTrue, reason: '${s.file}.wav yo\'q');
        expect(file.lengthSync(), greaterThan(1000),
            reason: '${s.file}.wav juda kichik');
      }
    });

    test('2 musiqa fayli mavjud, katta va BIR-BIRIDAN FARQLI', () {
      final mapF = music('music_map');
      final gameF = music('music_game');
      expect(mapF.existsSync(), isTrue);
      expect(gameF.existsSync(), isTrue);
      // Har biri sezilarli loop (~1MB atrofida) — «soda bir-ikki tonli» emas.
      expect(mapF.lengthSync(), greaterThan(200 * 1024));
      expect(gameF.lengthSync(), greaterThan(200 * 1024));
      // Menyu ≠ o'yin: bir xil generic loop bug'i qaytmasin.
      expect(mapF.readAsBytesSync(), isNot(gameF.readAsBytesSync()));
    });
  });
}
