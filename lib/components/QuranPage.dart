import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;

// Helper class to return both widget and state from text styling
class _StyledTextResult {
  final Widget widget;
  final bool foundPrevVerse;
  final bool foundHighlightedVerse;

  _StyledTextResult({
    required this.widget,
    required this.foundPrevVerse,
    required this.foundHighlightedVerse,
  });
}

class QuranPage extends StatelessWidget {
  final DocumentSnapshot pageData;
  final String verseToHighlight;

  const QuranPage({
    super.key,
    required this.pageData,
    this.verseToHighlight = '',
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = pageData.data() as Map<String, dynamic>;
    final List allLines = data['all_lines'] as List;
    final bool isShortPage = allLines.length < 13;

    // Parse verse to highlight
    int verseToHighlightNum = 0;
    int prevVerseNum = 0;

    if (verseToHighlight.isNotEmpty) {
      final parts = verseToHighlight.split(':');
      if (parts.length == 2) {
        verseToHighlightNum = int.tryParse(parts[1]) ?? 0;
        if (verseToHighlightNum > 0) {
          prevVerseNum = verseToHighlightNum - 1;
          developer.log(
              'Looking for verse: $verseToHighlightNum (previous verse: $prevVerseNum)');
        }
      }
    }

    // Store the global highlighting state across lines
    bool foundPrevVerseInPage = false;
    bool foundHighlightedVerseInPage = false;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(
            left: 20.0, right: 20.0, bottom: 0.0, top: 40.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: isShortPage
              ? MainAxisAlignment.center
              : MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: isShortPage
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            ...allLines.map((line) {
              // Process each line with current state
              final result = _buildStyledText(
                line.toString(),
                context,
                verseToHighlight: verseToHighlightNum,
                prevVerseNum: prevVerseNum,
                foundPrevVerse: foundPrevVerseInPage,
                foundHighlightedVerse: foundHighlightedVerseInPage,
              );

              // Update the global state based on this line's processing
              foundPrevVerseInPage = result.foundPrevVerse;
              foundHighlightedVerseInPage = result.foundHighlightedVerse;

              return FittedBox(
                fit: BoxFit.fitWidth,
                child: result.widget,
              );
            }),
            SizedBox(height: 30),
            Center(
              child: Text(
                pageData.id,
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _StyledTextResult _buildStyledText(
    String text,
    BuildContext context, {
    int verseToHighlight = 0,
    int prevVerseNum = 0,
    bool foundPrevVerse = false,
    bool foundHighlightedVerse = false,
  }) {
    if (text.isEmpty) {
      return _StyledTextResult(
        widget: const SizedBox(),
        foundPrevVerse: foundPrevVerse,
        foundHighlightedVerse: foundHighlightedVerse,
      );
    }

    // Regular expression to match verse numbers
    RegExp numbersRegex = RegExp(r'[\u0660-\u0669\u06F0-\u06F9\d]+');
    final matches = numbersRegex.allMatches(text);

    // If no verse numbers in this line
    if (matches.isEmpty) {
      bool shouldHighlight = foundPrevVerse && !foundHighlightedVerse;

      return _StyledTextResult(
        widget: Text(
          text,
          style: _getTextStyle(context, text, highlighted: shouldHighlight),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
        foundPrevVerse: foundPrevVerse,
        foundHighlightedVerse: foundHighlightedVerse,
      );
    }

    // Build RichText with multiple spans for precise highlighting
    List<InlineSpan> spans = [];
    int lastEnd = 0;
    bool localFoundPrevVerse = foundPrevVerse;
    bool localFoundHighlightedVerse = foundHighlightedVerse;
    bool startHighlightAfterThisMatch =
        false; // Flag to start highlighting after this match
    bool stopHighlightingAfterThisMatch =
        false; // Flag to stop highlighting after this match

    for (var i = 0; i < matches.length; i++) {
      var match = matches.elementAt(i);
      String matchText = text.substring(match.start, match.end);
      int currentVerseNum = _parseArabicOrWesternNumeral(matchText);

      bool isPreviousVerse = currentVerseNum == prevVerseNum;
      bool isHighlightedVerse = currentVerseNum == verseToHighlight;

      // Process the text before the verse number
      if (match.start > lastEnd) {
        // Should we highlight this text?
        bool shouldHighlight =
            localFoundPrevVerse && !localFoundHighlightedVerse;

        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _getTextStyle(context, text, highlighted: shouldHighlight),
        ));
      }

      // Process the verse number with its parentheses
      spans.add(TextSpan(
        text: "﴿$matchText﴾",
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.inversePrimary,
          fontWeight: FontWeight.bold,
          backgroundColor: isHighlightedVerse
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : null,
        ),
      ));

      // Update state after processing this verse number
      if (isPreviousVerse) {
        localFoundPrevVerse = true;
        startHighlightAfterThisMatch = true;
      }

      if (isHighlightedVerse) {
        localFoundHighlightedVerse = true;
        stopHighlightingAfterThisMatch = true;
      }

      lastEnd = match.end;
    }

    // Process the text after the last verse number
    if (lastEnd < text.length) {
      // Should we highlight this text?
      bool shouldHighlight = localFoundPrevVerse && !localFoundHighlightedVerse;

      // If we found the prev verse in this line but haven't started highlighting yet
      if (startHighlightAfterThisMatch && !stopHighlightingAfterThisMatch) {
        shouldHighlight = true;
      }

      // If we found the highlighted verse in this line, don't highlight after it
      if (stopHighlightingAfterThisMatch) {
        shouldHighlight = false;
      }

      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _getTextStyle(context, text, highlighted: shouldHighlight),
      ));
    }

    return _StyledTextResult(
      widget: RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      ),
      foundPrevVerse: localFoundPrevVerse,
      foundHighlightedVerse: localFoundHighlightedVerse,
    );
  }

  // Parse Arabic or Western numerals
  int _parseArabicOrWesternNumeral(String text) {
    // Convert Arabic/Indo-Arabic numerals to Western
    const arabicNumerals = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String westernText = text;

    for (int i = 0; i < arabicNumerals.length; i++) {
      westernText = westernText.replaceAll(arabicNumerals[i], i.toString());
    }

    return int.tryParse(westernText) ?? 0;
  }

  TextStyle _getTextStyle(BuildContext context, String text,
      {bool highlighted = false}) {
    final bool isLongText = text.split(' ').length > 8;

    return GoogleFonts.scheherazadeNew(
      fontSize: 24,
      color: Theme.of(context).colorScheme.inversePrimary,
      letterSpacing: isLongText ? 0 : 0.5,
      fontWeight: isLongText ? FontWeight.w600 : FontWeight.w500,
      backgroundColor: highlighted
          ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
          : null,
    );
  }
}
