import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
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
    if (currentPage.value > 0) {
      currentPage.value--;
      if (pageController.hasClients) {
        pageController.jumpToPage(currentPage.value);
      }
    } else {
      Get.back();
    }
  }

  void goToNextPage() {
    if (currentPage.value < 2) {
      currentPage.value++;
      if (pageController.hasClients) {
        pageController.jumpToPage(currentPage.value);
      }
    }
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

  Future<List<dynamic>> fetchVerses(int startSurahNumber, int startVerse,
      int endSurahNumber, int endVerse) async {
    final List<dynamic> versesList = [];

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

    final String startVerseId = startVerseSnapshot.docs.first.id;

    final QuerySnapshot endVerseSnapshot = await FirebaseFirestore.instance
        .collection('verses')
        .where('key', isEqualTo: endKey)
        .limit(1)
        .get();

    if (endVerseSnapshot.docs.isEmpty) {
      throw Exception('End verse not found with key: $endKey');
    }

    final String endVerseId = endVerseSnapshot.docs.first.id;

    int currentId = int.parse(startVerseId);
    final int endId = int.parse(endVerseId);

    while (currentId <= endId) {
      try {
        final DocumentSnapshot verseDoc = await FirebaseFirestore.instance
            .collection('verses')
            .doc(currentId.toString())
            .get();

        if (verseDoc.exists) {
          final data = verseDoc.data() as Map<String, dynamic>;
          versesList.add(data['text']);
        }
      } catch (_) {
        // Skip failed docs and continue.
      }
      currentId++;
    }

    if (versesList.isEmpty) {
      throw Exception('No verses found in the selected range');
    }

    return versesList;
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

      final List<dynamic> versesList = await fetchVerses(
          startSurahNumber, startVerse, endSurahNumber, endVerse);

      final String reviewTitle = startSurahNumber == endSurahNumber
          ? 'Quiz: ${selectedStartSurahName.value} $startVerse-$endVerse'
          : 'Quiz: ${selectedStartSurahName.value} $startVerse to ${selectedEndSurahName.value} $endVerse';

      final isPro = subscription.isPro;

      await Get.to(() => QuizPage(
            versesList: versesList,
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
