import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranPage extends StatelessWidget {
  final DocumentSnapshot pageData;

  const QuranPage({
    super.key,
    required this.pageData,
  });

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = pageData.data() as Map<String, dynamic>;

    // Debug print to console
    debugPrint('Page ${pageData.id} data: $data');

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 70.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: _buildPageContent(data, context),
      ),
    );
  }

  Widget _buildPageContent(Map<String, dynamic> data, BuildContext context) {
    final allLines = data['all_lines'] as List;
    return Column(
        mainAxisAlignment: data['all_lines'].length < 13
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: data['all_lines'].length < 13
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.stretch,
        children: [
          ...allLines.map((line) {
            return FittedBox(
              fit: BoxFit.fitWidth,
              child: _buildStyledText(line, context),
            );
          }),
        ]);
  }

  Widget _buildStyledText(String text, BuildContext context) {
    // Regular expression to match both Arabic numerals (٠-٩) and Indo-Arabic numerals (0-9)
    RegExp numbersRegex = RegExp(r'[\u0660-\u0669\u06F0-\u06F9\d]+');

    // Find all matches of numerals in the text
    Iterable<RegExpMatch> matches = numbersRegex.allMatches(text);

    // If no numerals found, return simple text
    if (matches.isEmpty) {
      return Text(
        text,
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.inversePrimary,
          letterSpacing: text.split(' ').length > 8 ? 0 : 0.5,
          fontWeight:
              text.split(' ').length > 8 ? FontWeight.w600 : FontWeight.w500,
        ),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      );
    }

    // Build a RichText widget with different styles for numbers
    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (var match in matches) {
      // Add text before the number
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: GoogleFonts.scheherazadeNew(
            fontSize: 24,
            color: Theme.of(context).colorScheme.inversePrimary,
            letterSpacing: 0,
            fontWeight: FontWeight.w600,
          ),
        ));
      }

      // Add the verse number with special styling
      spans.add(WidgetSpan(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text.substring(match.start, match.end),
            style: GoogleFonts.scheherazadeNew(
              fontSize: 20,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ));

      lastEnd = match.end;
    }

    // Add any remaining text after the last number
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.inversePrimary,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
        ),
      ));
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.inversePrimary,
          letterSpacing: 0,
          fontWeight: FontWeight.w600,
        ),
        children: spans,
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }
}
