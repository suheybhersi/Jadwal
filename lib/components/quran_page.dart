import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;

// Helper class to return both widget and state from text styling
class _StyledTextResult {
  final Widget widget;
  final bool foundStartVerse;
  final bool foundEndVerse;
  final bool foundPrevVerse;
  final String pageToHighlight;
  final String endPageToHighlight;
  _StyledTextResult({
    required this.widget,
    required this.foundStartVerse,
    required this.foundEndVerse,
    required this.foundPrevVerse,
    required this.pageToHighlight,
    required this.endPageToHighlight,
  });
}

class QuranPage extends StatelessWidget {
  final DocumentSnapshot pageData;
  final String verseToHighlight;
  final String pageToHighlight;
  final String endVerseToHighlight;
  final String endPageToHighlight;
  final String prevVerseKey;

  const QuranPage({
    super.key,
    required this.pageData,
    this.verseToHighlight = '',
    this.pageToHighlight = '',
    this.endVerseToHighlight = '',
    this.endPageToHighlight = '',
    this.prevVerseKey = '',
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = pageData.data() as Map<String, dynamic>;
    final List allLines = data['all_lines'] as List;
    final bool isShortPage = allLines.length < 13;

    // Parse verse to highlight
    int startVerseToHighlightNum = 0;
    int endVerseToHighlightNum = 0;
    int startChapter = 0;
    int endChapter = 0;

    // Parse previous verse
    int prevVerseNum = 0;
    int prevChapter = 0;

    if (verseToHighlight.isNotEmpty) {
      final parts = verseToHighlight.split(':');
      if (parts.length == 2) {
        startChapter = int.tryParse(parts[0]) ?? 0;
        startVerseToHighlightNum = int.tryParse(parts[1]) ?? 0;

        if (endVerseToHighlight.isNotEmpty) {
          final endParts = endVerseToHighlight.split(':');
          if (endParts.length == 2) {
            endChapter = int.tryParse(endParts[0]) ?? 0;
            endVerseToHighlightNum = int.tryParse(endParts[1]) ?? 0;
          } else {
            // If no end verse specified, highlight only the start verse
            endVerseToHighlightNum = startVerseToHighlightNum;
            endChapter = startChapter;
          }
        } else {
          // If no end verse specified, highlight only the start verse
          endVerseToHighlightNum = startVerseToHighlightNum;
          endChapter = startChapter;
        }

        // Parse previous verse key if provided
        if (prevVerseKey.isNotEmpty) {
          final prevParts = prevVerseKey.split(':');
          if (prevParts.length == 2) {
            prevChapter = int.tryParse(prevParts[0]) ?? 0;
            prevVerseNum = int.tryParse(prevParts[1]) ?? 0;
            developer.log('Previous verse: $prevChapter:$prevVerseNum');
          }
        } else {
          // If no previous verse key provided and this is not the first verse of a surah,
          // we'll assume it's the verse before the start verse in the same surah
          if (startVerseToHighlightNum > 1) {
            prevVerseNum = startVerseToHighlightNum - 1;
            prevChapter = startChapter;
          }
        }

        developer.log(
            'Highlighting verses from $startChapter:$startVerseToHighlightNum to $endChapter:$endVerseToHighlightNum');
        if (prevVerseNum > 0) {
          developer.log('Previous verse: $prevChapter:$prevVerseNum');
        }
      }
    }

    // Store the global highlighting state across lines
    bool foundStartVerseInPage = false;
    bool foundEndVerseInPage = false;
    bool foundPrevVerseInPage = false;

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
                startVerseToHighlight: startVerseToHighlightNum,
                endVerseToHighlight: endVerseToHighlightNum,
                startChapter: startChapter,
                endChapter: endChapter,
                prevVerseNum: prevVerseNum,
                prevChapter: prevChapter,
                foundStartVerse: foundStartVerseInPage,
                foundEndVerse: foundEndVerseInPage,
                foundPrevVerse: foundPrevVerseInPage,
                pageToHighlight: pageToHighlight,
                endPageToHighlight: endPageToHighlight,
              );

              // Update the global state based on this line's processing
              foundStartVerseInPage = result.foundStartVerse;
              foundEndVerseInPage = result.foundEndVerse;
              foundPrevVerseInPage = result.foundPrevVerse;

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
    int startVerseToHighlight = 0,
    int endVerseToHighlight = 0,
    int startChapter = 0,
    int endChapter = 0,
    int prevVerseNum = 0,
    int prevChapter = 0,
    bool foundStartVerse = false,
    bool foundEndVerse = false,
    bool foundPrevVerse = false,
    String pageToHighlight = '',
    String endPageToHighlight = '',
  }) {
    if (text.isEmpty) {
      return _StyledTextResult(
        widget: const SizedBox(),
        foundStartVerse: foundStartVerse,
        foundEndVerse: foundEndVerse,
        foundPrevVerse: foundPrevVerse,
        pageToHighlight: pageToHighlight,
        endPageToHighlight: endPageToHighlight,
      );
    }

    // Parse current page and pages to highlight
    int currentPage = int.tryParse(pageData.id) ?? 0;
    int startPage = int.tryParse(pageToHighlight) ?? 0;
    int endPage = int.tryParse(endPageToHighlight) ?? 0;

    // Regular expression to match verse numbers - moved before the condition
    RegExp numbersRegex = RegExp(r'[\u0660-\u0669\u06F0-\u06F9\d]+');
    final matches = numbersRegex.allMatches(text);

    // If no verse numbers in this text
    if (matches.isEmpty) {
      // Check if we're in highlight range
      bool isInPageRange =
          currentPage >= startPage && (endPage == 0 || currentPage <= endPage);

      // Determine if we should highlight this text without verse numbers
      bool shouldHighlight = false;

      // If we're on or after the start page and within end page range
      if (isInPageRange) {
        // On the start page, highlight if we've found the start verse or prev verse
        if (currentPage == startPage) {
          shouldHighlight = (foundStartVerse && !foundEndVerse) ||
              (foundPrevVerse && !foundStartVerse);
        }
        // On pages after start page but before or on end page, highlight if we haven't found end verse
        else if (currentPage > startPage && !foundEndVerse) {
          shouldHighlight = true;
        }
      }

      return _StyledTextResult(
        widget: Text(
          text,
          style: _getTextStyle(context, text, highlighted: shouldHighlight),
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
        ),
        foundStartVerse: foundStartVerse,
        foundEndVerse: foundEndVerse,
        foundPrevVerse: foundPrevVerse,
        pageToHighlight: pageToHighlight,
        endPageToHighlight: endPageToHighlight,
      );
    }

    // For debugging
    developer.log(
        'Current page: $currentPage, Start page: $startPage, End page: $endPage, '
        'Found prev verse: $foundPrevVerse, '
        'Found start verse: $foundStartVerse, '
        'Found end verse: $foundEndVerse');

    // Check if we're within the page range for highlighting
    bool isInPageRange =
        currentPage >= startPage && (endPage == 0 || currentPage <= endPage);

    // CRITICAL CHANGE: On pages after the start page, we should consider the start verse as already found
    // This ensures highlighting continues across pages
    if (currentPage > startPage) {
      foundStartVerse = true;
      foundPrevVerse =
          true; // Also consider prev verse found on subsequent pages
    }

    // Build RichText with multiple spans for verse styling and highlighting
    List<InlineSpan> spans = [];
    int lastEnd = 0;
    bool localFoundStartVerse = foundStartVerse;
    bool localFoundEndVerse = foundEndVerse;
    bool localFoundPrevVerse = foundPrevVerse;
    bool stopHighlightingNow = false;
    int currentChapter = 0;

    // Try to extract chapter information from the page data
    try {
      if (pageData.data() != null) {
        final Map<String, dynamic> data =
            pageData.data() as Map<String, dynamic>;
        if (data.containsKey('chapter')) {
          currentChapter = data['chapter'] as int;
        }
      }
    } catch (e) {
      developer.log('Error getting chapter: $e');
    }

    for (var i = 0; i < matches.length; i++) {
      var match = matches.elementAt(i);
      String matchText = text.substring(match.start, match.end);
      int currentVerseNum = _parseArabicOrWesternNumeral(matchText);

      // Check if this is our previous, start, or end verse
      bool isPrevVerse = (currentPage == startPage) &&
          currentVerseNum == prevVerseNum &&
          (currentChapter == 0 || currentChapter == prevChapter);

      bool isStartVerse = (currentPage == startPage) &&
          currentVerseNum == startVerseToHighlight &&
          (currentChapter == 0 || currentChapter == startChapter);

      bool isEndVerse = currentVerseNum == endVerseToHighlight &&
          (currentChapter == 0 || currentChapter == endChapter);

      // If we find the previous verse, mark it so we can highlight from this point forward
      if (isPrevVerse) {
        localFoundPrevVerse = true;
        developer
            .log('Found previous verse on page $currentPage: $currentVerseNum');
      }

      // Process the text before the verse number
      if (match.start > lastEnd) {
        // Determine if this text should be highlighted
        // Highlight if:
        // 1. We're in the page range AND
        // 2. Either:
        //    a. We've found the start verse but not the end verse
        //    b. OR we've found the previous verse but haven't found the start verse yet (only if this verse is the start verse)
        //    c. OR we're on a page after the start page but before finding the end verse
        bool shouldHighlight = isInPageRange &&
            ((localFoundStartVerse && !localFoundEndVerse) ||
                (localFoundPrevVerse &&
                    !localFoundStartVerse &&
                    isStartVerse) ||
                (currentPage > startPage &&
                    currentPage <= endPage &&
                    !localFoundEndVerse));

        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _getTextStyle(context, text, highlighted: shouldHighlight),
        ));
      }

      // If this is the start verse, update state
      if (isStartVerse) {
        localFoundStartVerse = true;
        developer
            .log('Found start verse on page $currentPage: $currentVerseNum');
      }

      // If this is the end verse, update state
      if (isEndVerse) {
        localFoundEndVerse = true;
        stopHighlightingNow = true;
        developer.log('Found end verse on page $currentPage: $currentVerseNum');
      }

      // Determine if the verse number should be highlighted
      bool shouldHighlightVerseNum = isInPageRange &&
          (isStartVerse ||
              isEndVerse ||
              (localFoundStartVerse && !localFoundEndVerse) ||
              (currentPage > startPage &&
                  currentPage <= endPage &&
                  !localFoundEndVerse));

      // Process the verse number with its parentheses
      spans.add(TextSpan(
        text: "﴿$matchText﴾",
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.inversePrimary,
          fontWeight: FontWeight.bold,
          backgroundColor: shouldHighlightVerseNum
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : null,
        ),
      ));

      lastEnd = match.end;
    }

    // Process the text after the last verse number
    if (lastEnd < text.length) {
      // Determine if the text after the last verse number should be highlighted
      bool shouldHighlight = isInPageRange &&
          ((localFoundStartVerse && !localFoundEndVerse) ||
              (localFoundPrevVerse && !localFoundStartVerse));

      // If we're on a page after the start page but before finding end verse, highlight everything
      if (isInPageRange &&
          currentPage > startPage &&
          currentPage <= endPage &&
          !localFoundEndVerse) {
        shouldHighlight = true;
      }

      // If we found the end verse in this line, don't highlight after it
      if (stopHighlightingNow) {
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
      foundStartVerse: localFoundStartVerse,
      foundEndVerse: localFoundEndVerse,
      foundPrevVerse: localFoundPrevVerse,
      pageToHighlight: pageToHighlight,
      endPageToHighlight: endPageToHighlight,
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
