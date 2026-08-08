import 'dart:math';

import 'package:jadwal/services/quran_distractors_index.dart';
import 'package:jadwal/utils/quran_text_utils.dart';

/// Builds Qur'anic distractors from real verse text (no invented words).
///
/// Pool = whole-Qur'an bigram twins (preferred) + neighbouring ayahs in the
/// quiz range, scored for confusion (length, ending, shared context).
class DistractorService {
  DistractorService({
    required this.splitVerse,
    Random? random,
    QuranDistractorsIndex? twinIndex,
  })  : _random = random ?? Random(),
        _twinIndex = twinIndex;

  /// Tokeniser shared with quiz generation (special pause marks, etc.).
  final List<String> Function(String verse) splitVerse;
  final Random _random;
  final QuranDistractorsIndex? _twinIndex;

  static const int defaultDistractorCount = 5;
  static const int neighbourWindow = 12;
  static const int targetCandidateCount = 24;

  /// Diacritics / Quranic marks stripped for comparison only.
  static String normalize(String input) {
    const remove = [
      '\u064B', '\u064C', '\u064D', '\u064E', '\u064F', '\u0650',
      '\u0651', '\u0652', '\u0653', '\u0654', '\u0655', '\u0656',
      '\u0657', '\u0658', '\u0670',
      '\u06D6', '\u06D7', '\u06D8', '\u06D9', '\u06DA', '\u06DB', '\u06DC',
      '\u06DF', '\u06E0', '\u06E1', '\u06E2', '\u06E3', '\u06E4',
      '\u06E5', '\u06E6', '\u06E7', '\u06E8', '\u06EA', '\u06EB', '\u06EC',
      '\u06ED',
      '\u0640',
      '\u06DE', // Rub el Hizb
      '\u06E9', // Sajda
    ];
    var s = input.trim();
    for (final c in remove) {
      s = s.replaceAll(c, '');
    }
    return s
        .replaceAll('آ', 'ا')
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('ٱ', 'ا');
  }

  static bool isUsableWord(String word) {
    if (QuranTextUtils.isNonSpokenToken(word)) return false;
    return RegExp(r'[\u0600-\u06FF]').hasMatch(word.trim());
  }

  /// Build a scored candidate pool of real words from nearby verses.
  List<String> buildCandidates({
    required String correctWord,
    required String currentVerse,
    required int verseIndex,
    required List<dynamic> versesList,
    int window = neighbourWindow,
  }) {
    final excludeNorm = <String>{normalize(correctWord)};
    for (final w in splitVerse(currentVerse)) {
      if (isUsableWord(w)) excludeNorm.add(normalize(w));
    }

    final contextWords = splitVerse(currentVerse)
        .where(isUsableWord)
        .map(normalize)
        .toSet();

    // normalized → (display, score)
    final best = <String, ({String display, double score})>{};

    final start = max(0, verseIndex - window);
    final end = min(versesList.length - 1, verseIndex + window);
    final correctNorm = normalize(correctWord);

    for (int vi = start; vi <= end; vi++) {
      if (vi == verseIndex) continue;
      final words =
          splitVerse(versesList[vi].toString()).where(isUsableWord).toList();
      if (words.isEmpty) continue;

      final verseNorm = words.map(normalize).toSet();
      final overlap = verseNorm.intersection(contextWords).length;
      final distance = (vi - verseIndex).abs();

      for (int wi = 0; wi < words.length; wi++) {
        final word = words[wi];
        final norm = normalize(word);
        if (excludeNorm.contains(norm)) continue;

        var score = (window - distance + 1) * 2.0 + overlap * 4.0;

        final lenDiff = (word.length - correctWord.length).abs();
        if (lenDiff <= 2) {
          score += 6.0;
        } else if (lenDiff <= 4) {
          score += 2.0;
        }

        if (correctNorm.length >= 2 &&
            norm.length >= 2 &&
            norm.substring(norm.length - 2) ==
                correctNorm.substring(correctNorm.length - 2)) {
          score += 8.0;
        }
        if (correctNorm.length >= 3 &&
            norm.length >= 3 &&
            norm.substring(norm.length - 3) ==
                correctNorm.substring(correctNorm.length - 3)) {
          score += 5.0;
        }
        if (wi == 0 || wi == words.length - 1) {
          score += 3.0;
        }

        final prev = best[norm];
        if (prev == null || score > prev.score) {
          best[norm] = (display: word, score: score);
        }
      }
    }

    final ranked = best.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return ranked.map((e) => e.display).take(targetCandidateCount).toList();
  }

  /// Pick [count] distractors without AI (shuffle within top band).
  List<String> pickWithoutAI(
    List<String> candidates, {
    int count = defaultDistractorCount,
  }) {
    if (candidates.isEmpty) return [];
    if (candidates.length <= count) {
      return List<String>.from(candidates)..shuffle(_random);
    }
    final band = min(candidates.length, max(count * 3, count + 5));
    final top = candidates.take(band).toList()..shuffle(_random);
    return top.take(count).toList();
  }

  /// Widen search if the first pool is too small.
  ///
  /// When [previousWord] is set, whole-Qur'an bigram twins that follow the
  /// same previous word are prepended (e.g. لقوم → يعقلون / يوقنون).
  List<String> ensureEnoughCandidates({
    required String correctWord,
    required String currentVerse,
    required int verseIndex,
    required List<dynamic> versesList,
    String? previousWord,
    int minCount = defaultDistractorCount,
  }) {
    final excludeNorm = <String>{normalize(correctWord)};
    for (final w in splitVerse(currentVerse)) {
      if (isUsableWord(w)) excludeNorm.add(normalize(w));
    }

    final merged = <String>[];
    final seen = <String>{};

    void addAll(Iterable<String> words) {
      for (final w in words) {
        if (!isUsableWord(w)) continue;
        final n = normalize(w);
        if (excludeNorm.contains(n)) continue;
        if (!seen.add(n)) continue;
        merged.add(w);
      }
    }

    // 1) Whole-Qur'an bigram twins (highest priority)
    final twins = _twinIndex?.twinsFor(
          correctWord,
          previousWord: previousWord,
        ) ??
        const <String>[];
    addAll(twins);

    // 2) Local neighbour pool
    var local = buildCandidates(
      correctWord: correctWord,
      currentVerse: currentVerse,
      verseIndex: verseIndex,
      versesList: versesList,
      window: neighbourWindow,
    );

    if (local.length < minCount) {
      local = buildCandidates(
        correctWord: correctWord,
        currentVerse: currentVerse,
        verseIndex: verseIndex,
        versesList: versesList,
        window: max(versesList.length, neighbourWindow * 3),
      );
    }
    addAll(local);

    if (merged.length < minCount) {
      final extras = <String>[];
      for (final v in versesList) {
        for (final w in splitVerse(v.toString())) {
          if (!isUsableWord(w)) continue;
          final n = normalize(w);
          if (excludeNorm.contains(n) || seen.contains(n)) continue;
          extras.add(w);
          if (extras.length >= targetCandidateCount) break;
        }
        if (extras.length >= targetCandidateCount) break;
      }
      extras.shuffle(_random);
      addAll(extras);
    }

    return merged.take(targetCandidateCount).toList();
  }

  /// Final option row: correct + distractors, capped, shuffled.
  List<String> buildOptions({
    required String correctWord,
    required List<String> distractors,
    int distractorCount = defaultDistractorCount,
  }) {
    final correctNorm = normalize(correctWord);
    final unique = <String>[];
    final seen = <String>{};

    for (final d in distractors) {
      if (!isUsableWord(d)) continue;
      final n = normalize(d);
      if (n == correctNorm) continue;
      if (!seen.add(n)) continue;
      unique.add(d);
      if (unique.length >= distractorCount) break;
    }

    final options = <String>[correctWord, ...unique]..shuffle(_random);

    if (!options.any((o) => normalize(o) == correctNorm)) {
      options.insert(0, correctWord);
    }

    if (options.length > distractorCount + 1) {
      final correct =
          options.firstWhere((o) => normalize(o) == correctNorm);
      final others =
          options.where((o) => normalize(o) != correctNorm).toList();
      return [correct, ...others.take(distractorCount)]..shuffle(_random);
    }

    return options;
  }
}
