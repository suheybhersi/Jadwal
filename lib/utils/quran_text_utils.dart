/// Helpers for Qur'anic text used in quizzes.
///
/// Structural marks (Rub el Hizb, sajda, standalone pause signs) are not
/// spoken words — they must not appear as fill-blank options or be required
/// in What Comes Next speech matching.
class QuranTextUtils {
  QuranTextUtils._();

  /// Standalone / structural symbols that are never recited as words.
  static const Set<String> structuralSymbols = {
    '۞', // Rub el Hizb (U+06DE)
    '۩', // Sajda (U+06E9)
    'ۜ',
    'ۘ',
    'ۙ',
    'ۚ',
    'ۛ',
    'ۖ',
    'ۗ',
  };

  /// Pause / Tajweed marks that attach to words (kept on the word for display,
  /// but a token that is *only* these is not a speakable word).
  static const Set<String> pauseMarks = {
    'ۜ',
    'ۘ',
    'ۙ',
    'ۚ',
    'ۛ',
    'ۖ',
    'ۗ',
  };

  /// True if [token] is only a mushaf symbol / pause mark, not a real word.
  static bool isNonSpokenToken(String token) {
    final t = token.trim();
    if (t.isEmpty) return true;
    if (structuralSymbols.contains(t)) return true;

    // Token is only pause marks / spaces / tatweel
    final withoutMarks = t.replaceAll(RegExp(r'[\s\u0640]'), '');
    if (withoutMarks.isEmpty) return true;
    if (withoutMarks.runes.every((r) {
      final s = String.fromCharCode(r);
      return pauseMarks.contains(s) || structuralSymbols.contains(s);
    })) {
      return true;
    }

    // No Arabic letters (ء–ي / alef variants) → not a reciteable word
    final hasLetter = RegExp(
      r'[\u0621-\u063A\u0641-\u064A\u066E\u066F\u0671-\u06D3\u06FA-\u06FF]',
    ).hasMatch(t);
    return !hasLetter;
  }

  /// Keeps only tokens that can be quiz options / speech targets.
  static List<String> speakableWords(List<String> words) {
    return words.where((w) => !isNonSpokenToken(w)).toList();
  }

  /// Removes structural symbols from a verse string (space-separated).
  static String stripStructuralSymbols(String verse) {
    return verse
        .split(' ')
        .where((w) => !isNonSpokenToken(w))
        .join(' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
