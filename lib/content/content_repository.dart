import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

/// `assets/content/ch1.json..ch3.json` fayllarini yuklaydi, tekshiradi va
/// xotirada keshlaydi. [loadAll] bir marta o'qiydi — keyingi chaqiriqlar
/// keshdan qaytadi; [levelById] yuklangandan so'ng sinxron ishlaydi.
class ContentRepository {
  ContentRepository();

  /// Qo'llab-quvvatlanadigan JSON sxema versiyasi.
  static const int schemaVersion = 1;

  static const List<String> _chapterAssets = [
    'assets/content/ch1.json',
    'assets/content/ch2.json',
    'assets/content/ch3.json',
    'assets/content/ch4.json',
    'assets/content/ch5.json',
    'assets/content/ch6.json',
  ];

  Future<List<ChapterDef>>? _loading;
  List<ChapterDef>? _cachedChapters;
  final Map<String, LevelDef> _levelsById = {};

  /// Yuklab bo'lingan boblar (sinxron). Hali yuklanmagan bo'lsa — null.
  /// FutureBuilder `initialData` uchun: isitilgan repo'da bo'sh kadr bo'lmaydi.
  List<ChapterDef>? get cachedChapters => _cachedChapters;

  /// Barcha boblarni yuklaydi (birinchi chaqiriqda — keyin kesh).
  Future<List<ChapterDef>> loadAll() {
    return _loading ??= _loadChapters().onError((Object error, StackTrace st) {
      _loading = null; // xato keshlanmasin — keyingi urinish qayta o'qiydi
      Error.throwWithStackTrace(error, st);
    });
  }

  /// Yuklangan darajani id bo'yicha qaytaradi (masalan "1-3").
  /// Hali yuklanmagan yoki topilmagan bo'lsa — null.
  LevelDef? levelById(String id) => _levelsById[id];

  Future<List<ChapterDef>> _loadChapters() async {
    final chapters = <ChapterDef>[];
    for (final asset in _chapterAssets) {
      final raw = await rootBundle.loadString(asset);
      chapters.add(_parseChapterFile(asset, raw));
    }
    for (final chapter in chapters) {
      for (final level in chapter.levels) {
        _levelsById[level.id] = level;
      }
    }
    return _cachedChapters = List.unmodifiable(chapters);
  }

  ChapterDef _parseChapterFile(String asset, String raw) {
    final root = jsonDecode(raw);
    if (root is! Map) {
      throw FormatException('$asset: ildiz obyekt bo’lishi kerak');
    }
    final version = root['schemaVersion'];
    if (version != schemaVersion) {
      throw FormatException(
        '$asset: schemaVersion $schemaVersion kutilgan edi, topildi: $version',
      );
    }
    final chapter = root['chapter'];
    if (chapter is! Map) {
      throw FormatException('$asset: "chapter" obyekt bo’lishi kerak');
    }
    return ChapterDef.fromJson(Map<String, Object?>.from(chapter));
  }
}
