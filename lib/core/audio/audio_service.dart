import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';

/// Barcha ovoz effektlari — enum orqali, fayl nomi bilan 1:1.
enum Sfx {
  tap('tap'),
  cardSlide('card_slide'),
  whoosh('whoosh'),
  thunk('thunk'),
  correct('correct'),
  wrong('wrong'),
  coin('coin'),
  star('star'),
  win('win'),
  unlock('unlock'),
  tick('tick'),
  cowMoo('cow_moo'),
  chickenCluck('chicken_cluck'),
  pigOink('pig_oink'),
  sheepBaa('sheep_baa'),
  chickCheep('chick_cheep'),
  duckQuack('duck_quack'),
  rabbitSqueak('rabbit_squeak');

  const Sfx(this.file);
  final String file;

  String get assetPath => 'audio/sfx/$file.wav';
}

enum Bgm {
  // Menyu (map) — tinch, past ovoz; o'yin (game) — jonliroq, balandroq.
  map('audio/music/music_map.wav', 0.30),
  game('audio/music/music_game.wav', 0.42);

  const Bgm(this.assetPath, this.volume);
  final String assetPath;

  /// Shu trek uchun maqsad-ovoz (0..1).
  final double volume;
}

/// Singleton audio servis: SFX pool + BGM loop, mute, lifecycle pauza.
/// Ovoz fayli yo'q/buzuq bo'lsa hech qachon crash qilmaydi.
class AudioService with WidgetsBindingObserver {
  AudioService._();

  static final AudioService instance = AudioService._();

  final AudioPlayer _music = AudioPlayer(playerId: 'bgm');
  final List<AudioPlayer> _sfxPool = List.generate(
    4,
    (i) => AudioPlayer(playerId: 'sfx$i'),
  );
  int _next = 0;

  bool soundOn = true;
  bool musicOn = true;
  Bgm? _currentBgm;
  bool _initialized = false;

  /// Fade-in/out ramp timeri (yangi start/stop'da bekor qilinadi).
  Timer? _fadeTimer;

  /// SFX (hayvon ovozi / tugma) fon musiqasini TO'XTATMASLIGI uchun audio
  /// kontekst — audioplayers'ning default `audioFocus: gain` har SFX'da
  /// musiqadan fokusni tortib olardi (musiqa pauza bo'lardi). `none` bilan
  /// hech bir pleyer fokus so'ramaydi → musiqa + SFX media oqimida aralashadi.
  static final AudioContext _mixContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.none,
    ),
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: const {AVAudioSessionOptions.mixWithOthers},
    ),
  );

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    WidgetsBinding.instance.addObserver(this);
    try {
      // Global + har pleyer uchun: fokus tortilmasin (musiqa uzilmasin).
      await AudioPlayer.global.setAudioContext(_mixContext);
      await _music.setAudioContext(_mixContext);
      await _music.setReleaseMode(ReleaseMode.loop);
      // Boshlang'ich ovoz — startMusic har trek uchun o'zi belgilaydi.
      for (final p in _sfxPool) {
        await p.setAudioContext(_mixContext);
        await p.setReleaseMode(ReleaseMode.stop);
        await p.setPlayerMode(PlayerMode.lowLatency);
      }
    } catch (e) {
      debugPrint('Audio init xatosi (davom etamiz): $e');
    }
  }

  Future<void> play(Sfx sfx) async {
    if (!soundOn) return;
    final player = _sfxPool[_next];
    _next = (_next + 1) % _sfxPool.length;
    try {
      await player.stop();
      await player.play(AssetSource(sfx.assetPath));
    } catch (e) {
      debugPrint('SFX xatosi ${sfx.file}: $e');
    }
  }

  /// [fadeIn] — musiqa keskin yonmasin, ovoz 0'dan maqsadga asta ko'tariladi
  /// (menyuda «ochilib qolgan» keskinlikni yumshatadi).
  Future<void> startMusic(Bgm bgm, {bool fadeIn = false}) async {
    _currentBgm = bgm;
    if (!musicOn) return;
    _fadeTimer?.cancel();
    try {
      await _music.stop();
      await _music.setVolume(fadeIn ? 0.0 : bgm.volume);
      await _music.play(AssetSource(bgm.assetPath));
      if (fadeIn) _fadeTo(bgm.volume);
    } catch (e) {
      debugPrint('BGM xatosi: $e');
    }
  }

  Future<void> stopMusic() async {
    _currentBgm = null;
    _fadeTimer?.cancel();
    try {
      await _music.stop();
    } catch (_) {}
  }

  /// Ovozni joriy qiymatdan [target]'gacha ~800ms davomida asta ko'taradi.
  /// Timer'ga bog'liq — «hech qachon crash qilmaydi» shartnomasi uchun har
  /// setVolume .catchError bilan himoyalangan.
  void _fadeTo(double target) {
    _fadeTimer?.cancel();
    const step = Duration(milliseconds: 40);
    const totalMs = 800;
    final steps = totalMs ~/ step.inMilliseconds;
    var i = 0;
    _fadeTimer = Timer.periodic(step, (t) {
      i++;
      final v = (target * i / steps).clamp(0.0, target);
      _music.setVolume(v).catchError((Object e) {
        debugPrint('BGM fade xatosi: $e');
      });
      if (i >= steps) t.cancel();
    });
  }

  Future<void> setSound({required bool on}) async {
    soundOn = on;
  }

  Future<void> setMusic({required bool on}) async {
    musicOn = on;
    if (!on) {
      _fadeTimer?.cancel();
      try {
        await _music.pause();
      } catch (_) {}
    } else if (_currentBgm != null) {
      // Qayta yoqilganda 0'dan EMAS, pauza qilingan JOYIDAN davom etadi
      // (fade-in bilan). Trek yuklanmagan bo'lsa (hech boshlanmagan) —
      // noldan boshlaymiz.
      _fadeTimer?.cancel();
      try {
        await _music.setVolume(0.0);
        await _music.resume();
        _fadeTo(_currentBgm!.volume);
      } catch (_) {
        await startMusic(_currentBgm!, fadeIn: true);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Telefon qo'ng'irog'i/fon — musiqa pauza, qaytganda davom.
    // Fire-and-forget Future'lar .catchError bilan himoyalanadi: player
    // xato holatda bo'lsa (masalan, webda autoplay taqiqlari) rad etilgan
    // Future zonaning tutilmagan xatosiga aylanib ketmasin — bu servis
    // «hech qachon crash qilmaydi» shartnomasiga ega.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _music.pause().catchError((Object e) {
        debugPrint('BGM pauza xatosi: $e');
      });
    } else if (state == AppLifecycleState.resumed &&
        musicOn &&
        _currentBgm != null) {
      _music.resume().catchError((Object e) {
        debugPrint('BGM resume xatosi: $e');
      });
    }
  }
}
