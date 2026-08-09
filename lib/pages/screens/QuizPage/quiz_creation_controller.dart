import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_verse_pool.dart';
import 'package:provider/provider.dart';

class QuizCreationController extends GetxController {
  final FirestoreService firestoreService;

  QuizCreationController({required this.firestoreService});

  late final PageController pageController;
  final RxInt currentPage = 0.obs;

  final RxBool isLoading = false.obs;

  final Rxn<String> selectedStartSurahName = Rxn<String>();
  final Rxn<Map<String, dynamic>> selectedStartSurahData =
      Rxn<Map<String, dynamic>>();
  final Rxn<int> selectedStartVerse = Rxn<int>();
  final Rxn<String> selectedEndSurahName = Rxn<String>();
  final Rxn<Map<String, dynamic>> selectedEndSurahData =
      Rxn<Map<String, dynamic>>();
  final Rxn<int> selectedEndVerse = Rxn<int>();

  // Question type selection state (Pro types default off; gated in UI)
  final RxBool includeFillBlank = false.obs;
  final RxBool includeDragDrop = true.obs;
  final RxBool includeWhatNext = false.obs;
  final RxBool includeVersePairing = true.obs;

  final RxString selectionErrorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  static int? parseSurahNumber(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static int indexOfSurah(
    List<Map<String, dynamic>> allData,
    Map<String, dynamic>? selected,
  ) {
    if (selected == null || allData.isEmpty) return 0;
    final number = parseSurahNumber(selected['surahNumber']);
    final name = selected['surah']?.toString();
    final index = allData.indexWhere((surah) {
      final n = parseSurahNumber(surah['surahNumber']);
      if (number != null && n == number) return true;
      if (name != null && surah['surah']?.toString() == name) return true;
      return false;
    });
    return index >= 0 ? index : 0;
  }

  Map<String, dynamic>? _findSurah(
    List<Map<String, dynamic>> allData,
    String surahName,
  ) {
    try {
      return allData.firstWhere((surah) => surah['surah'] == surahName);
    } catch (_) {
      return null;
    }
  }

  /// Re-bind start/end maps to the current [allData] snapshot so validation
  /// never compares stale Firestore map instances.
  void rebindSelectionsToData(List<Map<String, dynamic>> allData) {
    if (allData.isEmpty) return;

    if (selectedStartSurahName.value != null) {
      final start = _findSurah(allData, selectedStartSurahName.value!);
      if (start != null) {
        selectedStartSurahData.value = start;
      }
    }
    if (selectedEndSurahName.value != null) {
      final end = _findSurah(allData, selectedEndSurahName.value!);
      if (end != null) {
        selectedEndSurahData.value = end;
      }
    }
    validateSelection();
  }

  void goToPage(int page) {
    currentPage.value = page;
    if (pageController.hasClients) {
      pageController.jumpToPage(page);
    }
  }

  void resetAllState({bool jumpPage = true}) {
    selectedStartSurahName.value = null;
    selectedStartSurahData.value = null;
    selectedStartVerse.value = null;
    selectedEndSurahName.value = null;
    selectedEndSurahData.value = null;
    selectedEndVerse.value = null;
    includeFillBlank.value = false;
    includeDragDrop.value = true;
    includeWhatNext.value = false;
    includeVersePairing.value = true;
    selectionErrorMessage.value = '';
    isLoading.value = false;
    currentPage.value = 0;
    if (jumpPage && pageController.hasClients) {
      pageController.jumpToPage(0);
    }
    update();
  }

  void goBack() {
    Get.back();
  }

  void goToNextPage() {
    // Kept for compatibility; creation UI is a single screen.
  }

  /// Default start to Al-Fatiha 1; always refresh map from current [allData].
  void setDefaultStartVerseIfNeeded(List<Map<String, dynamic>> allData) {
    if (allData.isEmpty) return;

    if (selectedStartSurahName.value == null) {
      final firstSurah = allData.first;
      final surahName = firstSurah['surah'] as String?;
      if (surahName == null) return;
      selectedStartSurahName.value = surahName;
      selectedStartSurahData.value = firstSurah;
      selectedStartVerse.value = 1;

      // Seed end to the same point so End step starts coherent.
      selectedEndSurahName.value = surahName;
      selectedEndSurahData.value = firstSurah;
      selectedEndVerse.value = 1;
      selectionErrorMessage.value = '';
      update();
      return;
    }

    rebindSelectionsToData(allData);
  }

  void handleStartVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    final selectedSurah = _findSurah(allData, surahName);
    if (selectedSurah == null) {
      selectionErrorMessage.value = 'Could not find surah "$surahName"';
      update();
      return;
    }

    selectedStartSurahName.value = surahName;
    selectedStartSurahData.value = selectedSurah;
    selectedStartVerse.value = verseNumber;

    // Keep end coherent with start.
    final endName = selectedEndSurahName.value;
    final endVerse = selectedEndVerse.value;
    if (endName == null || endVerse == null) {
      selectedEndSurahName.value = surahName;
      selectedEndSurahData.value = selectedSurah;
      selectedEndVerse.value = verseNumber;
    } else if (endName == surahName && endVerse < verseNumber) {
      selectedEndVerse.value = verseNumber;
      selectedEndSurahData.value = selectedSurah;
    } else if (endName != surahName) {
      final endSurahNumber = parseSurahNumber(
          selectedEndSurahData.value?['surahNumber']);
      final startSurahNumber = parseSurahNumber(selectedSurah['surahNumber']);
      if (endSurahNumber != null &&
          startSurahNumber != null &&
          endSurahNumber < startSurahNumber) {
        selectedEndSurahName.value = surahName;
        selectedEndSurahData.value = selectedSurah;
        selectedEndVerse.value = verseNumber;
      } else {
        rebindSelectionsToData(allData);
      }
    }

    validateSelection();
    update();
  }

  /// After start is chosen, seed a valid end (at least one verse after start)
  /// and clear invalid end selections that fall before start.
  void prepareEndDefaultAfterStart(List<Map<String, dynamic>> allData) {
    final startSurah = selectedStartSurahData.value;
    final startVerse = selectedStartVerse.value;
    if (startSurah == null || startVerse == null) return;

    final startNum = parseSurahNumber(startSurah['surahNumber']);
    if (startNum == null) return;

    final startVerseCount = (startSurah['verses'] as int?) ?? 1;
    Map<String, dynamic>? endSurah = startSurah;
    int endVerse = startVerse + 1;

    if (startVerse >= startVerseCount) {
      final startIndex = indexOfSurah(allData, startSurah);
      if (startIndex + 1 < allData.length) {
        endSurah = allData[startIndex + 1];
        endVerse = 1;
      } else {
        // No valid end after this start — keep current and let validation show.
        validateSelection();
        update();
        return;
      }
    }

    selectedEndSurahName.value = endSurah['surah'] as String?;
    selectedEndSurahData.value = endSurah;
    selectedEndVerse.value = endVerse;
    validateSelection();
    update();
  }

  /// Surahs available for the end picker (nothing before start).
  List<Map<String, dynamic>> endSurahOptions(
    List<Map<String, dynamic>> allData,
  ) {
    final startSurah = selectedStartSurahData.value;
    final startVerse = selectedStartVerse.value;
    if (startSurah == null || startVerse == null) return allData;

    final startNum = parseSurahNumber(startSurah['surahNumber']);
    if (startNum == null) return allData;

    final result = <Map<String, dynamic>>[];
    for (final surah in allData) {
      final n = parseSurahNumber(surah['surahNumber']);
      if (n == null) continue;
      if (n < startNum) continue;
      if (n == startNum) {
        final verses = (surah['verses'] as int?) ?? 1;
        if (startVerse >= verses) continue;
      }
      result.add(surah);
    }
    return result;
  }

  /// Min verse on the first surah of [endOptions] (start+1 when same surah).
  int endMinVerseForFilteredList(List<Map<String, dynamic>> endOptions) {
    final startSurah = selectedStartSurahData.value;
    final startVerse = selectedStartVerse.value;
    if (startSurah == null || startVerse == null || endOptions.isEmpty) {
      return 1;
    }

    final startNum = parseSurahNumber(startSurah['surahNumber']);
    final firstNum = parseSurahNumber(endOptions.first['surahNumber']);
    if (startNum == null || firstNum == null || firstNum != startNum) {
      return 1;
    }

    final startVerseCount = (startSurah['verses'] as int?) ?? 1;
    if (startVerse >= startVerseCount) return 1;
    return startVerse + 1;
  }

  void handleEndVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    final selectedSurah = _findSurah(allData, surahName);
    if (selectedSurah == null) {
      selectionErrorMessage.value = 'Could not find surah "$surahName"';
      update();
      return;
    }

    selectedEndSurahName.value = surahName;
    selectedEndSurahData.value = selectedSurah;
    selectedEndVerse.value = verseNumber;

    rebindSelectionsToData(allData);
    validateSelection();
    update();
  }

  void validateSelection() {
    if (selectedStartSurahName.value == null ||
        selectedStartVerse.value == null ||
        selectedEndSurahName.value == null ||
        selectedEndVerse.value == null) {
      selectionErrorMessage.value = '';
      return;
    }

    final startSurahNumber =
        parseSurahNumber(selectedStartSurahData.value?['surahNumber']);
    final endSurahNumber =
        parseSurahNumber(selectedEndSurahData.value?['surahNumber']);

    if (startSurahNumber == null || endSurahNumber == null) {
      selectionErrorMessage.value = 'Invalid surah selection. Please reselect.';
      return;
    }

    if (startSurahNumber > endSurahNumber) {
      selectionErrorMessage.value = 'End surah cannot come before start surah';
      return;
    }

    if (startSurahNumber == endSurahNumber &&
        selectedStartVerse.value! > selectedEndVerse.value!) {
      selectionErrorMessage.value = 'End verse cannot come before start verse';
      return;
    }

    if (startSurahNumber == endSurahNumber &&
        selectedStartVerse.value == selectedEndVerse.value) {
      selectionErrorMessage.value =
          'Choose a range of at least two verses (start and end must differ)';
      return;
    }

    selectionErrorMessage.value = '';
  }

  bool isAnyTypeSelected() {
    return includeFillBlank.value ||
        includeDragDrop.value ||
        includeWhatNext.value ||
        includeVersePairing.value;
  }

  bool isRangeSelected() {
    return selectedStartSurahName.value != null &&
        selectedStartVerse.value != null &&
        selectedEndSurahName.value != null &&
        selectedEndVerse.value != null &&
        (selectedEndVerse.value != selectedStartVerse.value ||
            selectedEndSurahName.value != selectedStartSurahName.value) &&
        selectionErrorMessage.value.isEmpty;
  }

  bool canCreateQuiz() {
    return !isLoading.value && isRangeSelected() && isAnyTypeSelected();
  }

  /// Full contiguous fetch when the range is at most this many ayahs.
  static const int _fullFetchThreshold = 80;

  /// How many random anchors to sample for large ranges (buffer above the
  /// 50-question quiz cap).
  static const int _sampleAnchorCount = 60;

  static const int _quranVerseCount = 6236;
  static const int _fetchConcurrency = 25;

  Future<QuizVersePool> fetchVerses(int startSurahNumber, int startVerse,
      int endSurahNumber, int endVerse) async {
    final String startKey = '$startSurahNumber:$startVerse';
    final String endKey = '$endSurahNumber:$endVerse';

    final QuerySnapshot startVerseSnapshot = await FirebaseFirestore.instance
        .collection('verses')
        .where('key', isEqualTo: startKey)
        .limit(1)
        .get();

    if (startVerseSnapshot.docs.isEmpty) {
      throw Exception('Start verse not found with key: $startKey');
    }

    final QuerySnapshot endVerseSnapshot = await FirebaseFirestore.instance
        .collection('verses')
        .where('key', isEqualTo: endKey)
        .limit(1)
        .get();

    if (endVerseSnapshot.docs.isEmpty) {
      throw Exception('End verse not found with key: $endKey');
    }

    final int startId = int.parse(startVerseSnapshot.docs.first.id);
    final int endId = int.parse(endVerseSnapshot.docs.first.id);
    if (endId < startId) {
      throw Exception('End verse is before start verse');
    }

    final int rangeSize = endId - startId + 1;

    if (rangeSize <= _fullFetchThreshold) {
      final byId = await _fetchVerseTextsByIds(
        List<int>.generate(rangeSize, (i) => startId + i),
      );
      final verses = <dynamic>[
        for (var id = startId; id <= endId; id++)
          if (byId.containsKey(id)) byId[id],
      ];
      if (verses.isEmpty) {
        throw Exception('No verses found in the selected range');
      }
      return QuizVersePool(verses: verses);
    }

    // Large range: sample anchors, fetch each with ±1 neighbours so adjacency
    // questions stay correct without downloading the whole range.
    final random = Random();
    final want = min(_sampleAnchorCount, rangeSize);
    final anchors = <int>{};
    var guard = 0;
    while (anchors.length < want && guard < want * 20) {
      anchors.add(startId + random.nextInt(rangeSize));
      guard++;
    }

    final sortedAnchors = anchors.toList()..sort();
    final idsToFetch = <int>{};
    for (final anchor in sortedAnchors) {
      for (var delta = -1; delta <= 1; delta++) {
        final id = anchor + delta;
        if (id >= 1 && id <= _quranVerseCount) {
          idsToFetch.add(id);
        }
      }
    }

    final byId = await _fetchVerseTextsByIds(idsToFetch.toList());
    final verses = <dynamic>[];
    final anchorIndices = <int>{};
    final anchorsWithPrev = <int>{};
    final anchorsWithNext = <int>{};

    for (final anchor in sortedAnchors) {
      if (!byId.containsKey(anchor)) continue;

      final windowIds = <int>[
        for (var delta = -1; delta <= 1; delta++)
          if (byId.containsKey(anchor + delta)) anchor + delta,
      ];
      if (windowIds.isEmpty) continue;

      final startIndex = verses.length;
      for (final id in windowIds) {
        verses.add(byId[id]);
      }
      final offset = windowIds.indexOf(anchor);
      if (offset < 0) continue;

      final anchorIndex = startIndex + offset;
      anchorIndices.add(anchorIndex);
      if (windowIds.contains(anchor - 1)) {
        anchorsWithPrev.add(anchorIndex);
      }
      if (windowIds.contains(anchor + 1)) {
        anchorsWithNext.add(anchorIndex);
      }
    }

    if (verses.isEmpty || anchorIndices.isEmpty) {
      throw Exception('No verses found in the selected range');
    }

    return QuizVersePool(
      verses: verses,
      anchorIndices: anchorIndices,
      anchorsWithPrev: anchorsWithPrev,
      anchorsWithNext: anchorsWithNext,
    );
  }

  Future<Map<int, String>> _fetchVerseTextsByIds(List<int> ids) async {
    final result = <int, String>{};
    if (ids.isEmpty) return result;

    for (var i = 0; i < ids.length; i += _fetchConcurrency) {
      final end = min(i + _fetchConcurrency, ids.length);
      final chunk = ids.sublist(i, end);
      final docs = await Future.wait(
        chunk.map(
          (id) => FirebaseFirestore.instance
              .collection('verses')
              .doc(id.toString())
              .get(),
        ),
      );
      for (var j = 0; j < chunk.length; j++) {
        final data = docs[j].data();
        final text = data?['text']?.toString();
        if (text != null && text.isNotEmpty) {
          result[chunk[j]] = text;
        }
      }
    }
    return result;
  }

  Future<void> createQuiz(
      List<Map<String, dynamic>> allData, BuildContext context) async {
    rebindSelectionsToData(allData);

    if (!isRangeSelected()) {
      if (selectionErrorMessage.value.isEmpty) {
        selectionErrorMessage.value = 'Please select start and end verses';
      }
      return;
    }

    if (!isAnyTypeSelected()) {
      selectionErrorMessage.value = 'Please select at least one question type';
      return;
    }

    final subscription =
        Provider.of<SubscriptionService>(context, listen: false);
    if (!subscription.isPro) {
      if (includeFillBlank.value || includeWhatNext.value) {
        await subscription.openPaywall(context);
        return;
      }
    }

    final allowed = await subscription.ensureCanStartQuiz(context);
    if (!allowed) return;

    isLoading.value = true;
    selectionErrorMessage.value = '';

    try {
      final int? startSurahNumber =
          parseSurahNumber(selectedStartSurahData.value!['surahNumber']);
      final int? endSurahNumber =
          parseSurahNumber(selectedEndSurahData.value!['surahNumber']);
      if (startSurahNumber == null || endSurahNumber == null) {
        throw Exception('Invalid surah numbers');
      }

      final int startVerse = selectedStartVerse.value!;
      final int endVerse = selectedEndVerse.value!;

      final String quizId =
          'custom_quiz_${DateTime.now().millisecondsSinceEpoch}';

      // Fetch verses while the quiz loading screen is already showing.
      final versesFuture =
          fetchVerses(startSurahNumber, startVerse, endSurahNumber, endVerse);

      final String reviewTitle = startSurahNumber == endSurahNumber
          ? 'Quiz: ${selectedStartSurahName.value} $startVerse-$endVerse'
          : 'Quiz: ${selectedStartSurahName.value} $startVerse to ${selectedEndSurahName.value} $endVerse';

      final isPro = subscription.isPro;

      await Get.to(() => QuizPage(
            versesList: const [],
            versesFuture: versesFuture,
            reviewTitle: reviewTitle,
            review: '$startSurahNumber:$startVerse - $endSurahNumber:$endVerse',
            id: quizId,
            updateReview: (id, title, review) async => null,
            includeFillBlank: isPro && includeFillBlank.value,
            includeDragDrop: includeDragDrop.value,
            includeWhatNext: isPro && includeWhatNext.value,
            includeVersePairing: includeVersePairing.value,
            isCustomQuiz: true,
          ));

      // Fresh form when returning from a finished/abandoned quiz.
      resetAllState();
    } catch (e) {
      selectionErrorMessage.value = 'Error creating quiz: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}
