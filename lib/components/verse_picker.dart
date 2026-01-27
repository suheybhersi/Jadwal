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
  QuranVersePickerState createState() => QuranVersePickerState();
}

class QuranVersePickerState extends State<QuranVersePicker> {
  late int selectedSurahIndex;
  int? selectedVerseNumber;
  late FixedExtentScrollController? surahScrollController;
  late FixedExtentScrollController? verseScrollController;

  // Constants for the wheel picker
  static const double itemHeight = 50.0;
  static const double pickerHeight = 200.0;

  @override
  void initState() {
    super.initState();
    selectedSurahIndex =
        widget.initialSurahIndex.clamp(0, widget.surahData.length - 1);
    selectedVerseNumber = widget.initialVerseNumber;

    surahScrollController = FixedExtentScrollController(
      initialItem: selectedSurahIndex,
    );

    verseScrollController = FixedExtentScrollController(
      initialItem: selectedVerseNumber != null ? selectedVerseNumber! - 1 : 0,
    );
  }

  void _onSurahSelected(int index) {
    setState(() {
      selectedSurahIndex = index;
      selectedVerseNumber = null;
      verseScrollController?.jumpToItem(0);
    });
  }

  void _onVerseSelected(int index) {
    final verseNumber = index + 1;
    setState(() {
      selectedVerseNumber = verseNumber;
    });

    // Auto-confirm selection
    widget.onVerseSelected(
      widget.surahData[selectedSurahIndex]['surah'],
      verseNumber,
    );
  }

  @override
  void dispose() {
    surahScrollController?.dispose();
    verseScrollController?.dispose();
    super.dispose();
  }

  Widget _buildWheelPicker({
    required List<Widget> children,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
    double diameterRatio = 1.5,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: itemHeight,
      diameterRatio: diameterRatio,
      perspective: 0.001,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: onSelectedItemChanged,
      childDelegate: ListWheelChildListDelegate(
        children: children,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.surahData;
    final selectedSurahVerses =
        surahs[selectedSurahIndex]['verses'] as int? ?? 0;

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color unselectedTextColor = Theme.of(context).colorScheme.onSurface;
    final Color highlightColor = primaryColor.withValues(alpha: 0.1);

    // Build surah items
    final surahItems = List<Widget>.generate(surahs.length, (index) {
      final surahName = surahs[index]['surah'] as String;
      final surahNumber = surahs[index]['surahNumber'];
      final isSelected = index == selectedSurahIndex;

      return Container(
        height: itemHeight,
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.lato(
            fontSize: isSelected ? 18 : 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? primaryColor
                : unselectedTextColor.withValues(alpha: 0.8),
          ),
          child: Text(
            '$surahNumber. $surahName',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    });

    // Build verse items
    final verseItems = List<Widget>.generate(selectedSurahVerses, (index) {
      final verseNumber = index + 1;
      final isSelected = verseNumber == selectedVerseNumber;

      return Container(
        height: itemHeight,
        alignment: Alignment.center,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.lato(
            fontSize: isSelected ? 20 : 18,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? primaryColor
                : unselectedTextColor.withValues(alpha: 0.8),
          ),
          child: Text(
            verseNumber.toString(),
          ),
        ),
      );
    });

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Wheel picker UI
        Container(
          height: pickerHeight,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Surah wheel picker
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 12, left: 16, right: 16),
                      child: Text(
                        'Surah',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          // Center highlight
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                height: itemHeight,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: highlightColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildWheelPicker(
                            children: surahItems,
                            controller: surahScrollController!,
                            onSelectedItemChanged: _onSurahSelected,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Vertical divider
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 20),
                color: Theme.of(context).dividerColor,
              ),

              // Verse wheel picker
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 12, left: 16, right: 16),
                      child: Text(
                        'Verse',
                        style: GoogleFonts.lato(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          // Center highlight
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                height: itemHeight,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: highlightColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: primaryColor.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildWheelPicker(
                            children: verseItems,
                            controller: verseScrollController!,
                            onSelectedItemChanged: _onVerseSelected,
                            diameterRatio: 2.0,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Selection indicator
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark,
                size: 18,
                color: primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                selectedVerseNumber != null
                    ? 'Surah ${surahs[selectedSurahIndex]['surah']}, Verse $selectedVerseNumber'
                    : 'Select a verse',
                style: GoogleFonts.lato(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
