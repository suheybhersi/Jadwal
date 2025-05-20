import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/font_service.dart';
import 'package:google_fonts/google_fonts.dart';

class MushafLineWidget extends StatelessWidget {
  final List<Word> words;
  final int pageNumber;
  final String verseToHighlight;
  final String endVerseToHighlight;
  final String prevVerseKey;

  const MushafLineWidget({
    super.key,
    required this.words,
    required this.pageNumber,
    this.verseToHighlight = '',
    this.endVerseToHighlight = '',
    this.prevVerseKey = '',
  });

  @override
  Widget build(BuildContext context) {
    if (words.isEmpty) {
      return const SizedBox.shrink();
    }

    // Check if this is a special line (surah name or bismillah)
    if (words.first.isSpecial) {
      return _buildSpecialLine(words.first, context);
    }

    // Regular ayah line
    return _buildAyahLine(words, context);
  }

  Widget _buildSpecialLine(Word word, BuildContext context) {
    // Special lines like surah names and bismillah
    if (word.lineType == 'surah_name') {
      return _buildSurahName(word, context);
    }

    if (word.lineType == 'basmallah') {
      return _buildBismillah(word, context);
    }

    // Other special text
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          word.text,
          style: GoogleFonts.scheherazadeNew(
            fontSize: 22.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildSurahName(Word word, BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 8.0,
        bottom: pageNumber > 2 ? 0.0 : 16.0,
      ),
      child: Container(
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          word.text,
          style: GoogleFonts.scheherazadeNew(
            fontSize: 20.0,
            letterSpacing: 0.0,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
        ),
      ),
    );
  }

  Widget _buildBismillah(Word word, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.5,
          child: Image.asset(
            'assets/images/bismillah.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAyahLine(List<Word> words, BuildContext context) {
    // Get the page-specific font family
    final fontFamily = FontService.getPageFontFamily(pageNumber);
    return Wrap(
      alignment: WrapAlignment.center,
      textDirection: TextDirection.rtl,
      children: words
          .map((word) => _buildWordWidget(word, fontFamily, context))
          .toList(),
    );
  }

  Widget _buildWordWidget(Word word, String fontFamily, BuildContext context) {
    // Check if this word should be highlighted
    bool shouldHighlight = false;
    bool isPrevVerse = false;

    if (verseToHighlight.isNotEmpty && !word.isSpecial) {
      final parts = verseToHighlight.split(':');
      if (parts.length == 2) {
        final targetSurah = int.tryParse(parts[0]);
        final targetAyah = int.tryParse(parts[1]);

        if (targetSurah != null && targetAyah != null) {
          // Check if this word is part of the target verse
          if (word.surah == targetSurah && word.ayah == targetAyah) {
            shouldHighlight = true;
          }

          // Check if this word is part of the end verse (for range highlighting)
          if (endVerseToHighlight.isNotEmpty) {
            final endParts = endVerseToHighlight.split(':');
            if (endParts.length == 2) {
              final endSurah = int.tryParse(endParts[0]);
              final endAyah = int.tryParse(endParts[1]);

              if (endSurah != null && endAyah != null) {
                // Check if this word is between start and end verses
                if (targetSurah == endSurah) {
                  // Same surah case
                  if (word.surah == targetSurah &&
                      word.ayah >= targetAyah &&
                      word.ayah <= endAyah) {
                    shouldHighlight = true;
                  }
                } else {
                  // Different surahs case
                  if ((word.surah == targetSurah && word.ayah >= targetAyah) ||
                      (word.surah == endSurah && word.ayah <= endAyah) ||
                      (word.surah > targetSurah && word.surah < endSurah)) {
                    shouldHighlight = true;
                  }
                }
              }
            }
          }
        }
      }
    }

    // Check if this word is part of the previous verse (for context)
    if (prevVerseKey.isNotEmpty && !word.isSpecial) {
      final parts = prevVerseKey.split(':');
      if (parts.length == 2) {
        final prevSurah = int.tryParse(parts[0]);
        final prevAyah = int.tryParse(parts[1]);

        if (prevSurah != null &&
            prevAyah != null &&
            word.surah == prevSurah &&
            word.ayah == prevAyah) {
          isPrevVerse = true;
        }
      }
    }

    return Container(
      decoration: shouldHighlight
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            )
          : null,
      child: Text(
        word.text,
        style: TextStyle(
          fontFamily: fontFamily,
          fontSize: 26.0,
          height: 1.3,
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }
}
