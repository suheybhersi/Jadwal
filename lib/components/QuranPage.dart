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
    final List allLines = data['all_lines'] as List;
    final bool isShortPage = allLines.length < 13;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 70.0),
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
          children: allLines
              .map((line) => FittedBox(
                    fit: BoxFit.fitWidth,
                    child: _buildStyledText(line, context),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildStyledText(String text, BuildContext context) {
    // Regular expression to match verse numbers (Arabic and Indo-Arabic numerals)
    RegExp numbersRegex = RegExp(r'[\u0660-\u0669\u06F0-\u06F9\d]+');
    final matches = numbersRegex.allMatches(text);

    // If no verse numbers, return simple text
    if (matches.isEmpty) {
      return Text(
        text,
        style: _getTextStyle(context, text),
        textAlign: TextAlign.justify,
        textDirection: TextDirection.rtl,
      );
    }

    // Build RichText with styled verse numbers
    List<InlineSpan> spans = [];
    int lastEnd = 0;

    for (var match in matches) {
      // Text before the verse number
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: _getTextStyle(context, text),
        ));
      }

      // Verse number with decorative parentheses
      spans.add(TextSpan(
        text: "﴿${text.substring(match.start, match.end)}﴾",
        style: GoogleFonts.scheherazadeNew(
          fontSize: 24,
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ));

      lastEnd = match.end;
    }

    // Text after the last verse number
    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: _getTextStyle(context, text),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
    );
  }

  TextStyle _getTextStyle(BuildContext context, String text) {
    final bool isLongText = text.split(' ').length > 8;

    return GoogleFonts.scheherazadeNew(
      fontSize: 24,
      color: Theme.of(context).colorScheme.inversePrimary,
      letterSpacing: isLongText ? 0 : 0.5,
      fontWeight: isLongText ? FontWeight.w600 : FontWeight.w500,
    );
  }
}
