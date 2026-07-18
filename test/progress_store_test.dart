import 'package:flutter_test/flutter_test.dart';
import 'package:math_farm/core/persistence/progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProgressStore> loadStore({DateTime Function()? nowProvider}) =>
      ProgressStore.load(
        nowProvider: nowProvider ?? () => DateTime(2026, 7, 16, 12),
      );

  /// Darajaga 1 yulduz yozish uchun qisqartma.
  Future<void> star(ProgressStore store, String levelId,
      {int stars = 1, int coins = 0}) {
    return store.commitLevelResult(
      levelId: levelId,
      stars: stars,
      coinsEarned: coins,
      skills: const {},
    );
  }

  group('defaults', () {
    test('fresh profile has spec defaults', () async {
      final store = await loadStore();
      expect(store.playerName, 'Aziza');
      expect(store.avatar, 'cow');
      expect(store.coins, 0);
      expect(store.age, isNull);
      expect(store.onboarded, isFalse);
      expect(store.streakCurrent, 0);
      expect(store.streakBest, 0);
      expect(store.lastActiveDate, isNull);
      expect(store.levels, isEmpty);
      expect(store.skills, isEmpty);
      expect(store.totals, (questionsAnswered: 0, levelsCompleted: 0));
      expect(store.soundOn, isTrue);
      expect(store.musicOn, isTrue);
      expect(store.timerAllowed, isTrue);
      expect(store.localeOverride, isNull);
      expect(store.ownedItems, isEmpty);
      expect(store.equipped, isEmpty);
      expect(store.totalStars, 0);
      expect(store.displayLevel, 1);
    });
  });

  group('stars and levels', () {
    test('keeps max stars, counts attempts and coins', () async {
      final store = await loadStore();
      await store.commitLevelResult(
        levelId: '1-1',
        stars: 2,
        coinsEarned: 80,
        skills: const {},
      );
      expect(store.starsFor('1-1'), 2);
      expect(store.totals.levelsCompleted, 1);

      await store.commitLevelResult(
        levelId: '1-1',
        stars: 1,
        coinsEarned: 40,
        skills: const {},
      );
      expect(store.starsFor('1-1'), 2, reason: 'yomonroq natija yozilmaydi');
      expect(store.levels['1-1'], (stars: 2, attempts: 2));
      expect(store.coins, 120);
      expect(store.totals.levelsCompleted, 1, reason: 'qayta o‘yin sanalmaydi');

      await store.commitLevelResult(
        levelId: '1-1',
        stars: 3,
        coinsEarned: 100,
        skills: const {},
      );
      expect(store.starsFor('1-1'), 3);
      expect(store.levels['1-1'], (stars: 3, attempts: 3));
    });

    test('displayLevel = 1 + totalStars ~/ 6', () async {
      final store = await loadStore();
      await star(store, '1-1', stars: 3);
      await star(store, '1-2', stars: 2);
      expect(store.totalStars, 5);
      expect(store.displayLevel, 1);
      await star(store, '1-3', stars: 1);
      expect(store.totalStars, 6);
      expect(store.displayLevel, 2);
    });

    test('unlock chain within chapter and across chapter boundary', () async {
      final store = await loadStore();
      expect(store.isLevelUnlocked('1-1'), isTrue);
      expect(store.isLevelUnlocked('1-2'), isFalse);

      await star(store, '1-1');
      expect(store.isLevelUnlocked('1-2'), isTrue);
      expect(store.isLevelUnlocked('1-3'), isFalse);
      expect(store.isLevelUnlocked('2-1'), isFalse);

      for (final id in ['1-2', '1-3', '1-4', '1-5']) {
        await star(store, id);
      }
      expect(store.isLevelUnlocked('1-6'), isTrue);
      expect(store.isLevelUnlocked('2-1'), isFalse,
          reason: '6 tadan 5 tasi yetarli emas');

      await star(store, '1-6');
      expect(store.isLevelUnlocked('2-1'), isTrue);
      expect(store.isLevelUnlocked('2-2'), isFalse);

      await star(store, '2-1');
      expect(store.isLevelUnlocked('2-2'), isTrue);
      expect(store.isLevelUnlocked('3-1'), isFalse);
    });

    test('malformed level ids are locked', () async {
      final store = await loadStore();
      expect(store.isLevelUnlocked(''), isFalse);
      expect(store.isLevelUnlocked('1'), isFalse);
      expect(store.isLevelUnlocked('a-b'), isFalse);
      expect(store.isLevelUnlocked('0-1'), isFalse);
      expect(store.isLevelUnlocked('1-7'), isFalse);
    });
  });

  group('streak', () {
    test('same day noop, next day +1, gap resets, best kept', () async {
      var now = DateTime(2026, 7, 16, 10);
      final store = await ProgressStore.load(nowProvider: () => now);

      await star(store, '1-1'); // birinchi faollik
      expect(store.streakCurrent, 1);
      expect(store.streakBest, 1);
      expect(store.lastActiveDate, '2026-07-16');

      now = DateTime(2026, 7, 16, 22);
      await star(store, '1-1'); // shu kunning o'zi — noop
      expect(store.streakCurrent, 1);

      now = DateTime(2026, 7, 17, 6);
      await star(store, '1-2'); // ertasi kun — +1
      expect(store.streakCurrent, 2);
      expect(store.streakBest, 2);

      now = DateTime(2026, 7, 18, 23);
      await star(store, '1-3');
      expect(store.streakCurrent, 3);
      expect(store.streakBest, 3);

      now = DateTime(2026, 7, 25, 9);
      await star(store, '1-4'); // uzilish — 1 ga qaytadi
      expect(store.streakCurrent, 1);
      expect(store.streakBest, 3);
      expect(store.lastActiveDate, '2026-07-25');
    });

    test('DST (23 soatlik kun) streakni yutib yubormaydi', () async {
      // AQShda 2026-03-08 — spring-forward: mahalliy yarim tunlar orasi
      // 23 soat, eski wall-clock hisobda inDays == 0 bo'lib qolardi.
      // Test DST bo'lmagan zonada ham o'tadi (UTC arifmetikasi bir xil),
      // regressiya esa TZ=America/New_York bilan ishga tushirilganda
      // ushlanadi.
      var now = DateTime(2026, 3, 7, 20);
      final store = await ProgressStore.load(nowProvider: () => now);

      await star(store, '1-1');
      expect(store.streakCurrent, 1);
      expect(store.lastActiveDate, '2026-03-07');

      now = DateTime(2026, 3, 8, 10); // spring-forward kuni
      await star(store, '1-2');
      expect(store.streakCurrent, 2);

      now = DateTime(2026, 3, 9, 10); // DST kunidan keyingi kun
      await star(store, '1-3');
      expect(store.streakCurrent, 3);
      expect(store.streakBest, 3);
      expect(store.lastActiveDate, '2026-03-09');
    });

    test('soat orqaga surilsa streak va sana o’zgarmaydi', () async {
      var now = DateTime(2026, 7, 16, 12);
      final store = await ProgressStore.load(nowProvider: () => now);
      await star(store, '1-1');
      expect(store.streakCurrent, 1);

      now = DateTime(2026, 7, 14, 12); // soat orqaga surilgan
      await star(store, '1-2');
      expect(store.streakCurrent, 1);
      expect(store.lastActiveDate, '2026-07-16');
    });
  });

  group('shop', () {
    test('buyItem guards price and double purchase', () async {
      final store = await loadStore();
      await star(store, '1-1', coins: 500);
      expect(store.coins, 500);

      await store.buyItem('chickBow', 200);
      expect(store.ownedItems, {'chickBow'});
      expect(store.coins, 300);

      await store.buyItem('chickBow', 200); // allaqachon olingan
      expect(store.coins, 300);

      await store.buyItem('pond', 500); // tanga yetmaydi
      expect(store.ownedItems, {'chickBow'});
      expect(store.coins, 300);
    });

    test('setEquipped guards slot validity and ownership', () async {
      final store = await loadStore();
      await star(store, '1-1', coins: 500);
      await store.buyItem('chickBow', 200);

      await store.setEquipped('chick', 'chickBow');
      expect(store.equippedFor('chick'), 'chickBow');

      await store.setEquipped('chick', 'pigGlasses'); // sotib olinmagan
      expect(store.equippedFor('chick'), 'chickBow');

      await store.setEquipped('nosuch', 'chickBow'); // noto'g'ri slot
      expect(store.equipped.containsKey('nosuch'), isFalse);

      await store.setEquipped('chick', null); // yechish
      expect(store.equippedFor('chick'), isNull);
      expect(store.ownedItems, {'chickBow'});
    });
  });

  group('power-uplar (sarflanadigan)', () {
    test('buyConsumable takrorlanadi, tangani sarflaydi, yetmasa no-op',
        () async {
      final store = await loadStore();
      await star(store, '1-1', coins: 100);
      expect(store.powerupCount('powerHint'), 0);

      await store.buyConsumable('powerHint', 20);
      expect(store.powerupCount('powerHint'), 1);
      expect(store.coins, 80);

      // Xuddi shu power-up qayta olinadi (buyItem'dan farqli — gard yo'q).
      await store.buyConsumable('powerHint', 20);
      expect(store.powerupCount('powerHint'), 2);
      expect(store.coins, 60);

      // Tanga yetmasa — o'zgarmaydi.
      await store.buyConsumable('powerHint', 100);
      expect(store.powerupCount('powerHint'), 2);
      expect(store.coins, 60);
    });

    test('consumePowerup bo\'lsa kamaytiradi va true qaytaradi', () async {
      final store = await loadStore();
      await star(store, '1-1', coins: 100);
      await store.buyConsumable('powerSkip', 30);
      await store.buyConsumable('powerSkip', 30);
      expect(store.powerupCount('powerSkip'), 2);

      expect(store.consumePowerup('powerSkip'), isTrue);
      expect(store.powerupCount('powerSkip'), 1);
      expect(store.consumePowerup('powerSkip'), isTrue);
      expect(store.powerupCount('powerSkip'), 0);
      // Bo'sh — false, o'zgarmaydi.
      expect(store.consumePowerup('powerSkip'), isFalse);
      expect(store.powerupCount('powerSkip'), 0);
    });

    test('power-uplar diskка saqlanadi va qayta yuklanadi', () async {
      final store = await loadStore();
      await star(store, '1-1', coins: 200);
      await store.buyConsumable('powerHeart', 40);
      await store.buyConsumable('powerCoinX2', 50);
      await store.buyConsumable('powerCoinX2', 50);

      final reloaded = await loadStore();
      expect(reloaded.powerupCount('powerHeart'), 1);
      expect(reloaded.powerupCount('powerCoinX2'), 2);
      expect(reloaded.powerupCount('powerHint'), 0);
    });
  });

  group('persistence', () {
    test('corrupt JSON falls back to fresh defaults', () async {
      SharedPreferences.setMockInitialValues({'profile_v1': '{broken json!!'});
      final store = await loadStore();
      expect(store.playerName, 'Aziza');
      expect(store.coins, 0);
      expect(store.levels, isEmpty);
      expect(store.isLevelUnlocked('1-1'), isTrue);
    });

    test('wrong-shaped JSON values fall back per field', () async {
      SharedPreferences.setMockInitialValues({
        'profile_v1': '{"coins":"ko‘p","levels":5,"settings":{"soundOn":"ha"},'
            '"shop":{"owned":"tree","equipped":{"cow":7,"bogus":"x"}},'
            '"playerName":"Botir","streakBest":4}',
      });
      final store = await loadStore();
      expect(store.playerName, 'Botir');
      expect(store.streakBest, 4);
      expect(store.coins, 0);
      expect(store.levels, isEmpty);
      expect(store.soundOn, isTrue);
      expect(store.ownedItems, isEmpty);
      expect(store.equipped, isEmpty);
    });

    test('non-map JSON document falls back to defaults', () async {
      SharedPreferences.setMockInitialValues({'profile_v1': '[1,2,3]'});
      final store = await loadStore();
      expect(store.playerName, 'Aziza');
      expect(store.coins, 0);
    });

    test('roundtrip: reload restores the full state', () async {
      DateTime now() => DateTime(2026, 7, 16, 12);
      final store = await ProgressStore.load(nowProvider: now);
      await store.commitLevelResult(
        levelId: '1-1',
        stars: 2,
        coinsEarned: 300,
        skills: const {
          'counting': (answered: 3, correctFirstTry: 2),
          'addition': (answered: 2, correctFirstTry: 2),
        },
      );
      await store.buyItem('chickBow', 200);
      await store.setEquipped('chick', 'chickBow');
      await store.setSoundOn(false);
      await store.setMusicOn(false);
      await store.setTimerAllowed(false);
      await store.setLocaleOverride('ru');
      await store.setPlayerName('Malika');
      await store.setAvatar('sheep');

      final reloaded = await ProgressStore.load(nowProvider: now);
      expect(reloaded.playerName, 'Malika');
      expect(reloaded.avatar, 'sheep');
      expect(reloaded.coins, 100);
      expect(reloaded.streakCurrent, 1);
      expect(reloaded.streakBest, 1);
      expect(reloaded.lastActiveDate, '2026-07-16');
      expect(reloaded.levels['1-1'], (stars: 2, attempts: 1));
      expect(
        reloaded.skills['counting'],
        (answered: 3, correctFirstTry: 2),
      );
      expect(
        reloaded.skills['addition'],
        (answered: 2, correctFirstTry: 2),
      );
      expect(reloaded.totals, (questionsAnswered: 5, levelsCompleted: 1));
      expect(reloaded.soundOn, isFalse);
      expect(reloaded.musicOn, isFalse);
      expect(reloaded.timerAllowed, isFalse);
      expect(reloaded.localeOverride, 'ru');
      expect(reloaded.ownedItems, {'chickBow'});
      expect(reloaded.equippedFor('chick'), 'chickBow');
      expect(reloaded.isLevelUnlocked('1-2'), isTrue);
    });

    test('skills accumulate across commits', () async {
      final store = await loadStore();
      await store.commitLevelResult(
        levelId: '1-1',
        stars: 3,
        coinsEarned: 50,
        skills: const {'counting': (answered: 5, correctFirstTry: 4)},
      );
      await store.commitLevelResult(
        levelId: '1-2',
        stars: 3,
        coinsEarned: 50,
        skills: const {'counting': (answered: 2, correctFirstTry: 2)},
      );
      expect(
        store.skills['counting'],
        (answered: 7, correctFirstTry: 6),
      );
      expect(store.totals.questionsAnswered, 7);
      expect(store.totals.levelsCompleted, 2);
    });
  });
}
