import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Daraja natijasi yozuvi.
typedef LevelStat = ({int stars, int attempts});

/// Ko'nikma statistikasi yozuvi (QuizController.skillCounts bilan mos shakl,
/// kalit — QuestionType.name).
typedef SkillStat = ({int answered, int correctFirstTry});

/// O'yinchi profili — SharedPreferences dagi bitta JSON hujjat
/// (`profile_v1`) ustidan ChangeNotifier.
///
/// Buzilgan yoki yo'q ma'lumot hech qachon crash bermaydi — toza
/// defaultlar bilan ochiladi. Sana mantiqiga testlar uchun
/// [load] orqali `nowProvider` berish mumkin.
class ProgressStore extends ChangeNotifier {
  ProgressStore._(this._prefs, this._now);

  static const _storageKey = 'profile_v1';
  static const _schemaVersion = 1;

  /// FarmRules.levelsPerChapter bilan bir xil (bu qatlam theme'ga
  /// bog'lanmasligi uchun takrorlangan).
  static const levelsPerChapter = 6;

  /// Do'kon slotlari: 4 hayvon aksessuari + 4 dekor o'rni.
  static const shopSlots = [
    'cow',
    'chick',
    'pig',
    'sheep',
    'decor1',
    'decor2',
    'decor3',
    'decor4',
  ];

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  String _playerName = 'Aziza';
  String _avatar = 'cow';
  int? _age;
  bool _onboarded = false;
  int _coins = 0;
  int _streakCurrent = 0;
  int _streakBest = 0;
  String? _lastActiveDate;
  final Map<String, LevelStat> _levels = {};
  final Map<String, SkillStat> _skills = {};
  int _questionsAnswered = 0;
  int _levelsCompleted = 0;
  bool _soundOn = true;
  bool _musicOn = true;
  bool _timerAllowed = true;
  String? _localeOverride;
  final Set<String> _owned = {};
  final Map<String, String> _equipped = {};

  /// Power-up (sarflanadigan) zaxiralari: id → soni.
  final Map<String, int> _powerups = {};

  /// Profilni diskdan yuklaydi (yo'q/buzilgan bo'lsa — defaultlar).
  static Future<ProgressStore> load({DateTime Function()? nowProvider}) async {
    final prefs = await SharedPreferences.getInstance();
    final store = ProgressStore._(prefs, nowProvider ?? DateTime.now);
    store._restore();
    return store;
  }

  String get playerName => _playerName;
  String get avatar => _avatar;

  /// Bola yoshi (onboarding'da tanlanadi, 4–8); `null` — kiritilmagan.
  int? get age => _age;

  /// Birinchi ochilish sozlamasi tugallanganmi (til/ism/yosh/avatar).
  bool get onboarded => _onboarded;

  int get coins => _coins;
  int get streakCurrent => _streakCurrent;
  int get streakBest => _streakBest;

  /// Oxirgi faollik sanasi, `yyyy-MM-dd` (mahalliy vaqt).
  String? get lastActiveDate => _lastActiveDate;

  /// Daraja natijalari, kalit — levelId (masalan `1-3`).
  Map<String, LevelStat> get levels => Map.unmodifiable(_levels);

  /// Ko'nikma statistikasi, kalit — QuestionType.name.
  Map<String, SkillStat> get skills => Map.unmodifiable(_skills);

  /// Umumiy hisoblagichlar.
  ({int questionsAnswered, int levelsCompleted}) get totals =>
      (questionsAnswered: _questionsAnswered, levelsCompleted: _levelsCompleted);

  bool get soundOn => _soundOn;
  bool get musicOn => _musicOn;
  bool get timerAllowed => _timerAllowed;

  /// Til majburlash (`null` — tizim tili).
  String? get localeOverride => _localeOverride;

  /// Sotib olingan buyum idlari.
  Set<String> get ownedItems => Set.unmodifiable(_owned);

  /// Kiyilgan buyumlar: slot → itemId.
  Map<String, String> get equipped => Map.unmodifiable(_equipped);

  /// Slotdagi kiyilgan buyum (yo'q bo'lsa `null`).
  String? equippedFor(String slot) => _equipped[slot];

  /// Darajaning eng yaxshi yulduzlari (o'ynalmagan bo'lsa 0).
  int starsFor(String levelId) => _levels[levelId]?.stars ?? 0;

  /// Barcha darajalar yulduzlari yig'indisi.
  int get totalStars =>
      _levels.values.fold(0, (sum, stat) => sum + stat.stars);

  /// Profildagi «N-daraja» ko'rsatkichi.
  int get displayLevel => 1 + totalStars ~/ 6;

  /// Daraja ochiqmi. `1-1` doim ochiq; bobdagi N-daraja — N−1 da
  /// kamida 1 yulduz bo'lsa; C-bobning 1-darajasi — C−1 bobning barcha
  /// 6 darajasida kamida 1 yulduz bo'lsa.
  bool isLevelUnlocked(String levelId) {
    final parts = levelId.split('-');
    if (parts.length != 2) return false;
    final chapter = int.tryParse(parts[0]);
    final level = int.tryParse(parts[1]);
    if (chapter == null || level == null || chapter < 1 || level < 1) {
      return false;
    }
    if (level > levelsPerChapter) return false;
    if (chapter == 1 && level == 1) return true;
    if (level > 1) return starsFor('$chapter-${level - 1}') >= 1;
    for (var l = 1; l <= levelsPerChapter; l++) {
      if (starsFor('${chapter - 1}-$l') < 1) return false;
    }
    return true;
  }

  /// Daraja natijasini yozadi: yulduz — eski/yangi maksimumi, urinish +1,
  /// tangalar va statistikalar qo'shiladi, streak yangilanadi.
  Future<void> commitLevelResult({
    required String levelId,
    required int stars,
    required int coinsEarned,
    required Map<String, SkillStat> skills,
  }) async {
    final prev = _levels[levelId];
    final wasCompleted = (prev?.stars ?? 0) > 0;
    _levels[levelId] = (
      stars: math.max(prev?.stars ?? 0, stars),
      attempts: (prev?.attempts ?? 0) + 1,
    );
    _coins += coinsEarned;
    skills.forEach((key, stat) {
      final p = _skills[key] ?? (answered: 0, correctFirstTry: 0);
      _skills[key] = (
        answered: p.answered + stat.answered,
        correctFirstTry: p.correctFirstTry + stat.correctFirstTry,
      );
      _questionsAnswered += stat.answered;
    });
    if (!wasCompleted && stars > 0) _levelsCompleted += 1;
    _markActiveToday();
    await _persist();
    notifyListeners();
  }

  /// Buyum sotib olish. Tanga yetmasa yoki allaqachon olingan bo'lsa no-op.
  Future<void> buyItem(String itemId, int price) async {
    if (price < 0 || _coins < price || _owned.contains(itemId)) return;
    _coins -= price;
    _owned.add(itemId);
    await _persist();
    notifyListeners();
  }

  /// Power-up (sarflanadigan) zaxira soni.
  int powerupCount(String id) => _powerups[id] ?? 0;

  /// Power-up sotib olish — TAKRORLANADIGAN (`buyItem`dan farqli, egalik
  /// gard'i yo'q). Tanga yetmasa no-op.
  Future<void> buyConsumable(String id, int price) async {
    if (price < 0 || _coins < price) return;
    _coins -= price;
    _powerups[id] = (_powerups[id] ?? 0) + 1;
    await _persist();
    notifyListeners();
  }

  /// Power-up sarflash — bo'lsa bittani kamaytiradi va `true` qaytaradi.
  bool consumePowerup(String id) {
    final n = _powerups[id] ?? 0;
    if (n <= 0) return false;
    if (n == 1) {
      _powerups.remove(id);
    } else {
      _powerups[id] = n - 1;
    }
    unawaited(_persist());
    notifyListeners();
    return true;
  }

  /// Slotga buyum kiyish (`null` — yechish). Slot noto'g'ri yoki buyum
  /// sotib olinmagan bo'lsa no-op.
  Future<void> setEquipped(String slot, String? itemId) async {
    if (!shopSlots.contains(slot)) return;
    if (itemId == null) {
      if (_equipped.remove(slot) == null) return;
    } else {
      if (!_owned.contains(itemId)) return;
      if (_equipped[slot] == itemId) return;
      _equipped[slot] = itemId;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> setPlayerName(String name) async {
    if (name.isEmpty || name == _playerName) return;
    _playerName = name;
    await _persist();
    notifyListeners();
  }

  Future<void> setAvatar(String avatar) async {
    if (avatar.isEmpty || avatar == _avatar) return;
    _avatar = avatar;
    await _persist();
    notifyListeners();
  }

  Future<void> setAge(int? age) async {
    if (age == _age) return;
    _age = age;
    await _persist();
    notifyListeners();
  }

  /// Onboarding tugagach `true` — ilova endi RootShell'ni ko'rsatadi.
  Future<void> setOnboarded(bool value) async {
    if (value == _onboarded) return;
    _onboarded = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setSoundOn(bool value) async {
    if (value == _soundOn) return;
    _soundOn = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setMusicOn(bool value) async {
    if (value == _musicOn) return;
    _musicOn = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setTimerAllowed(bool value) async {
    if (value == _timerAllowed) return;
    _timerAllowed = value;
    await _persist();
    notifyListeners();
  }

  Future<void> setLocaleOverride(String? locale) async {
    if (locale == _localeOverride) return;
    _localeOverride = locale;
    await _persist();
    notifyListeners();
  }

  /// Streak: shu kun — noop; kecha — +1; eskiroq — 1 ga qaytadi;
  /// birinchi marta — 1. Rekord ham yangilanadi.
  void _markActiveToday() {
    final now = _now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _formatDate(today);
    if (_lastActiveDate == todayKey) return;
    final last =
        _lastActiveDate == null ? null : DateTime.tryParse(_lastActiveDate!);
    if (last == null) {
      _streakCurrent = 1;
    } else {
      // Kun farqi UTC nuqtalarda hisoblanadi: mahalliy yarim tunlar orasi
      // DST kunida 23 soat bo'lib, inDays == 0 chiqarib yuborardi.
      final lastDay = DateTime.utc(last.year, last.month, last.day);
      final todayUtc = DateTime.utc(today.year, today.month, today.day);
      final diff = todayUtc.difference(lastDay).inDays;
      if (diff <= 0) return; // soat orqaga surilgan — o'zgartirmaymiz
      _streakCurrent = diff == 1 ? _streakCurrent + 1 : 1;
    }
    _streakBest = math.max(_streakBest, _streakCurrent);
    _lastActiveDate = todayKey;
  }

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<void> _persist() async {
    await _prefs.setString(_storageKey, jsonEncode(_toJson()));
  }

  Map<String, Object?> _toJson() => {
        'schemaVersion': _schemaVersion,
        'playerName': _playerName,
        'avatar': _avatar,
        'age': _age,
        'onboarded': _onboarded,
        'coins': _coins,
        'streakCurrent': _streakCurrent,
        'streakBest': _streakBest,
        'lastActiveDate': _lastActiveDate,
        'levels': {
          for (final e in _levels.entries)
            e.key: {'stars': e.value.stars, 'attempts': e.value.attempts},
        },
        'skills': {
          for (final e in _skills.entries)
            e.key: {
              'answered': e.value.answered,
              'correctFirstTry': e.value.correctFirstTry,
            },
        },
        'totals': {
          'questionsAnswered': _questionsAnswered,
          'levelsCompleted': _levelsCompleted,
        },
        'settings': {
          'soundOn': _soundOn,
          'musicOn': _musicOn,
          'timerAllowed': _timerAllowed,
          'localeOverride': _localeOverride,
        },
        'shop': {
          'owned': _owned.toList(),
          'equipped': Map<String, String>.from(_equipped),
        },
        'powerups': Map<String, int>.from(_powerups),
      };

  /// Diskdan o'qish — har maydon himoyalangan, buzilgan qiymatlar
  /// defaultligicha qoladi.
  void _restore() {
    final raw = _prefs.getString(_storageKey);
    if (raw == null) return;
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return; // buzilgan JSON — toza defaultlar
    }
    if (decoded is! Map) return;
    final doc = decoded;

    _playerName = _asString(doc['playerName'], _playerName);
    _avatar = _asString(doc['avatar'], _avatar);
    final ageVal = doc['age'];
    _age = ageVal is num ? ageVal.toInt() : null;
    _onboarded = _asBool(doc['onboarded'], false);
    _coins = _asInt(doc['coins'], _coins);
    _streakCurrent = _asInt(doc['streakCurrent'], _streakCurrent);
    _streakBest = _asInt(doc['streakBest'], _streakBest);
    final lastActive = doc['lastActiveDate'];
    _lastActiveDate = lastActive is String ? lastActive : null;

    final levels = doc['levels'];
    if (levels is Map) {
      levels.forEach((key, value) {
        if (key is String && value is Map) {
          _levels[key] = (
            stars: _asInt(value['stars'], 0),
            attempts: _asInt(value['attempts'], 0),
          );
        }
      });
    }

    final skills = doc['skills'];
    if (skills is Map) {
      skills.forEach((key, value) {
        if (key is String && value is Map) {
          _skills[key] = (
            answered: _asInt(value['answered'], 0),
            correctFirstTry: _asInt(value['correctFirstTry'], 0),
          );
        }
      });
    }

    final totals = doc['totals'];
    if (totals is Map) {
      _questionsAnswered = _asInt(totals['questionsAnswered'], 0);
      _levelsCompleted = _asInt(totals['levelsCompleted'], 0);
    }

    final settings = doc['settings'];
    if (settings is Map) {
      _soundOn = _asBool(settings['soundOn'], true);
      _musicOn = _asBool(settings['musicOn'], true);
      _timerAllowed = _asBool(settings['timerAllowed'], true);
      final locale = settings['localeOverride'];
      _localeOverride = locale is String ? locale : null;
    }

    final shop = doc['shop'];
    if (shop is Map) {
      final owned = shop['owned'];
      if (owned is List) {
        _owned.addAll(owned.whereType<String>());
      }
      final equipped = shop['equipped'];
      if (equipped is Map) {
        equipped.forEach((slot, itemId) {
          if (slot is String &&
              itemId is String &&
              shopSlots.contains(slot)) {
            _equipped[slot] = itemId;
          }
        });
      }
    }

    final powerups = doc['powerups'];
    if (powerups is Map) {
      powerups.forEach((id, count) {
        if (id is String && count is int && count > 0) {
          _powerups[id] = count;
        }
      });
    }
  }

  static int _asInt(Object? v, int fallback) =>
      switch (v) { int value => value, num value => value.toInt(), _ => fallback };

  static bool _asBool(Object? v, bool fallback) =>
      v is bool ? v : fallback;

  static String _asString(Object? v, String fallback) =>
      v is String ? v : fallback;
}
