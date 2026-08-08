import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:jadwal/services/distractor_service.dart';

/// Precomputed bigram-twin distractors from [assets/quran_distractors.json].
class QuranDistractorsIndex {
  QuranDistractorsIndex._(this._words, this._after);

  final Map<String, List<String>> _words;
  final Map<String, List<String>> _after;

  static QuranDistractorsIndex? _instance;
  static Future<QuranDistractorsIndex>? _loading;

  static const assetPath = 'assets/quran_distractors.json';

  static Future<QuranDistractorsIndex> load() {
    if (_instance != null) return Future.value(_instance);
    return _loading ??= _load();
  }

  static Future<QuranDistractorsIndex> _load() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final json = jsonDecode(raw) as Map<String, dynamic>;

      final words = <String, List<String>>{};
      final wordsRaw = json['words'] as Map<String, dynamic>? ?? {};
      for (final e in wordsRaw.entries) {
        final data = e.value;
        if (data is Map && data['distractors'] is List) {
          words[e.key] = (data['distractors'] as List)
              .map((x) => x.toString())
              .toList();
        }
      }

      final after = <String, List<String>>{};
      final afterRaw = json['after'] as Map<String, dynamic>? ?? {};
      for (final e in afterRaw.entries) {
        if (e.value is List) {
          after[e.key] =
              (e.value as List).map((x) => x.toString()).toList();
        }
      }

      _instance = QuranDistractorsIndex._(words, after);
    } catch (_) {
      _instance = QuranDistractorsIndex._({}, {});
    }
    return _instance!;
  }

  /// Twins that share a previous-word context with [correctWord].
  List<String> twinsFor(String correctWord, {String? previousWord}) {
    final correctNorm = DistractorService.normalize(correctWord);
    final out = <String>[];
    final seen = <String>{correctNorm};

    // Prefer context-aware: other words that follow the same previous word
    if (previousWord != null && previousWord.trim().isNotEmpty) {
      final prevNorm = DistractorService.normalize(previousWord);
      final nexts = _after[prevNorm] ?? const [];
      for (final w in nexts) {
        final n = DistractorService.normalize(w);
        if (!seen.add(n)) continue;
        out.add(w);
      }
    }

    // Fall back / pad with global twins for this word
    final global = _words[correctNorm] ?? const [];
    for (final w in global) {
      final n = DistractorService.normalize(w);
      if (!seen.add(n)) continue;
      out.add(w);
    }

    return out;
  }
}
