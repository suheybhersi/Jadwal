import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranVersePicker extends StatefulWidget {
  const QuranVersePicker({
    super.key,
    required this.surahData,
    required this.onVerseSelected,
    this.initialSurahIndex = 0,
    this.initialVerseNumber,
  });

  final List<Map<String, dynamic>> surahData;
  final void Function(String surahName, int verseNumber) onVerseSelected;
  final int initialSurahIndex;
  final int? initialVerseNumber;

  @override
  _QuranVersePickerState createState() => _QuranVersePickerState();
}

class _QuranVersePickerState extends State<QuranVersePicker> {
  late int selectedSurahIndex;
  int? selectedVerseNumber;
  late ScrollController surahScrollController;
  late ScrollController verseScrollController;

  @override
  void initState() {
    super.initState();
    selectedSurahIndex =
        widget.initialSurahIndex.clamp(0, widget.surahData.length - 1);
    selectedVerseNumber = widget.initialVerseNumber;
    surahScrollController = ScrollController();
    verseScrollController = ScrollController();

    // Scroll to the initial Surah and Verse
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCenter(surahScrollController, selectedSurahIndex);
      if (selectedVerseNumber != null) {
        _scrollToCenter(verseScrollController, selectedVerseNumber! - 1);
      }
    });
  }

  void _scrollToCenter(ScrollController controller, int index) {
    // Assuming each item has a height of 56.0 (adjust as necessary)
    final itemHeight = 56.0;
    final offset = (index * itemHeight) -
        (controller.position.viewportDimension / 2) +
        (itemHeight / 2);
    controller.jumpTo(offset.clamp(0.0, controller.position.maxScrollExtent));
  }

  @override
  void dispose() {
    surahScrollController.dispose();
    verseScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.surahData;
    final selectedSurahVerses =
        surahs[selectedSurahIndex]['verses'] as int? ?? 0;

    return Column(
      children: [
        // Main Verse Picker UI
        Container(
          height: 350,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(2, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Surah Column
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Surahs',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        controller: surahScrollController,
                        itemCount: surahs.length,
                        itemBuilder: (context, index) {
                          final surahName = surahs[index]['surah'] as String;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedSurahIndex = index;
                                selectedVerseNumber = null; // Reset verse
                                // Scroll to the selected Surah
                                _scrollToCenter(surahScrollController, index);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                  top: 4, bottom: 4, left: 16, right: 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedSurahIndex == index
                                    ? Colors.blue.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                surahName,
                                style: GoogleFonts.lato(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: selectedSurahIndex == index
                                      ? Colors.blue.shade700
                                      : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Divider
              VerticalDivider(
                color: Colors.grey.shade300,
                thickness: 1,
                indent: 35,
                width: 10,
              ),

              // Verses Column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Verses',
                        style: GoogleFonts.lato(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        controller: verseScrollController,
                        itemCount: selectedSurahVerses,
                        itemBuilder: (context, verseIndex) {
                          final verseNumber = verseIndex + 1;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedVerseNumber = verseNumber;
                                widget.onVerseSelected(
                                  surahs[selectedSurahIndex]['surah'],
                                  verseNumber,
                                );
                                // Scroll to the selected Verse
                                _scrollToCenter(
                                    verseScrollController, verseNumber - 1);
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(
                                  top: 4, bottom: 4, left: 8, right: 16),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: selectedVerseNumber == verseNumber
                                    ? Colors.blue.shade100
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade200,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  verseNumber.toString(),
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: selectedVerseNumber == verseNumber
                                        ? Colors.blue.shade700
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        selectedVerseNumber != null
            ? Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  'Surah ${surahs[selectedSurahIndex]['surah']}, Verse $selectedVerseNumber',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
            : Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                  ),
                ),
                child: Text(
                  'Please select the surah and verse',
                  style: GoogleFonts.lato(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
      ],
    );
  }
}
