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
  late FixedExtentScrollController surahScrollController;
  late FixedExtentScrollController verseScrollController;

  static const double itemHeight = 50.0;
  static const double pickerHeight = 200.0;

  @override
  void initState() {
    super.initState();
    selectedSurahIndex =
        widget.initialSurahIndex.clamp(0, widget.surahData.length - 1);
    selectedVerseNumber = widget.initialVerseNumber ?? 1;

    surahScrollController = FixedExtentScrollController(
      initialItem: selectedSurahIndex,
    );

    verseScrollController = FixedExtentScrollController(
      initialItem: (selectedVerseNumber! - 1).clamp(
        0,
        _verseCountFor(selectedSurahIndex) - 1,
      ),
    );
  }

  int _verseCountFor(int surahIndex) {
    if (surahIndex < 0 || surahIndex >= widget.surahData.length) return 1;
    return (widget.surahData[surahIndex]['verses'] as int?) ?? 1;
  }

  void _commitSelection() {
    final verse = selectedVerseNumber ?? 1;
    widget.onVerseSelected(
      widget.surahData[selectedSurahIndex]['surah'] as String,
      verse,
    );
  }

  void _onSurahIndexChanged(int index) {
    if (index == selectedSurahIndex) return;
    setState(() {
      selectedSurahIndex = index;
      selectedVerseNumber = 1;
    });
    // Reset verse wheel without notifying parent mid-fling.
    if (verseScrollController.hasClients) {
      verseScrollController.jumpToItem(0);
    }
  }

  void _onVerseIndexChanged(int index) {
    final verseNumber = index + 1;
    if (verseNumber == selectedVerseNumber) return;
    setState(() {
      selectedVerseNumber = verseNumber;
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Commit only when the user finishes scrolling (free fling + snap).
    if (notification is ScrollEndNotification) {
      _commitSelection();
    }
    return false;
  }

  @override
  void dispose() {
    surahScrollController.dispose();
    verseScrollController.dispose();
    super.dispose();
  }

  Widget _buildWheelPicker({
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    required FixedExtentScrollController controller,
    required ValueChanged<int> onSelectedItemChanged,
    double diameterRatio = 1.5,
  }) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: itemHeight,
        diameterRatio: diameterRatio,
        perspective: 0.003,
        // FixedExtent still snaps after a free ballistic fling.
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelectedItemChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: itemCount,
          builder: itemBuilder,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final surahs = widget.surahData;
    final selectedSurahVerses = _verseCountFor(selectedSurahIndex);

    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color unselectedTextColor = Theme.of(context).colorScheme.onSurface;
    final Color highlightColor = primaryColor.withValues(alpha: 0.1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
                            itemCount: surahs.length,
                            controller: surahScrollController,
                            onSelectedItemChanged: _onSurahIndexChanged,
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= surahs.length) {
                                return null;
                              }
                              final surahName = surahs[index]['surah'] as String;
                              final surahNumber = surahs[index]['surahNumber'];
                              final isSelected = index == selectedSurahIndex;
                              return SizedBox(
                                height: itemHeight,
                                child: Center(
                                  child: Text(
                                    '$surahNumber. $surahName',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.lato(
                                      fontSize: isSelected ? 18 : 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : unselectedTextColor.withValues(
                                              alpha: 0.8),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                margin: const EdgeInsets.symmetric(vertical: 20),
                color: Theme.of(context).dividerColor,
              ),
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
                            itemCount: selectedSurahVerses,
                            controller: verseScrollController,
                            onSelectedItemChanged: _onVerseIndexChanged,
                            diameterRatio: 2.0,
                            itemBuilder: (context, index) {
                              if (index < 0 || index >= selectedSurahVerses) {
                                return null;
                              }
                              final verseNumber = index + 1;
                              final isSelected =
                                  verseNumber == selectedVerseNumber;
                              return SizedBox(
                                height: itemHeight,
                                child: Center(
                                  child: Text(
                                    verseNumber.toString(),
                                    style: GoogleFonts.lato(
                                      fontSize: isSelected ? 20 : 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? primaryColor
                                          : unselectedTextColor.withValues(
                                              alpha: 0.8),
                                    ),
                                  ),
                                ),
                              );
                            },
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
