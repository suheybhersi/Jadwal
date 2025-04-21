import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';

class QuizCreationController extends GetxController {
  final FirestoreService firestoreService;

  QuizCreationController({required this.firestoreService});

  // Page controller
  final Rx<PageController> _pageController =
      Rx<PageController>(PageController(initialPage: 0));
  PageController get pageController => _pageController.value;
  final RxInt currentPage = 0.obs;

  // Loading state
  final RxBool isLoading = false.obs;

  // Selection state
  final Rxn<String> selectedStartSurahName = Rxn<String>();
  final Rxn<Map<String, dynamic>> selectedStartSurahData =
      Rxn<Map<String, dynamic>>();
  final Rxn<int> selectedStartVerse = Rxn<int>();
  final Rxn<String> selectedEndSurahName = Rxn<String>();
  final Rxn<Map<String, dynamic>> selectedEndSurahData =
      Rxn<Map<String, dynamic>>();
  final Rxn<int> selectedEndVerse = Rxn<int>();

  // Question type selection state
  final RxBool includeFillBlank = true.obs;
  final RxBool includeDragDrop = true.obs;
  final RxBool includeWhatNext = true.obs;
  final RxBool includeVersePairing = true.obs;

  // Error message
  final RxString selectionErrorMessage = ''.obs;

  @override
  void onClose() {
    _pageController.value.dispose();
    super.onClose();
  }

  void goToPage(int page) {
    currentPage.value = page;
    _pageController.value.jumpToPage(page);
  }

  void goBack() {
    if (currentPage.value > 0) {
      currentPage.value--;
      _pageController.value.jumpToPage(currentPage.value);
    } else {
      Get.back(); // Exit quiz creation
    }
  }

  void goToNextPage() {
    if (currentPage.value < 2) {
      currentPage.value++;
      _pageController.value.jumpToPage(currentPage.value);
    }
  }

  void resetSelection() {
    selectedEndSurahName.value = null;
    selectedEndSurahData.value = null;
    selectedEndVerse.value = null;
    selectedStartSurahName.value = null;
    selectedStartSurahData.value = null;
    selectedStartVerse.value = null;
    selectionErrorMessage.value = '';

    // Call update to notify GetBuilder and force rebuild where needed
    update();
  }

  void handleStartVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    // Find the full surah data
    final selectedSurah =
        allData.firstWhere((surah) => surah['surah'] == surahName);

    // Update start selection
    selectedStartSurahName.value = surahName;
    selectedStartSurahData.value = selectedSurah;
    selectedStartVerse.value = verseNumber;
    selectionErrorMessage.value = '';

    // Reset end verse if necessary
    if (selectedEndSurahName.value == surahName &&
        selectedEndVerse.value != null &&
        selectedEndVerse.value! < verseNumber) {
      selectedEndVerse.value = verseNumber;
    } else if (selectedEndSurahName.value != surahName) {
      // If different surah is selected, reset end surah
      selectedEndSurahName.value = surahName;
      selectedEndSurahData.value = selectedSurah;
      selectedEndVerse.value = verseNumber;
    }

    // Call update to notify GetBuilder and force rebuild where needed
    update();
  }

  void handleEndVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    // Find the full surah data
    final selectedSurah =
        allData.firstWhere((surah) => surah['surah'] == surahName);

    // Set the end selection
    selectedEndSurahName.value = surahName;
    selectedEndSurahData.value = selectedSurah;
    selectedEndVerse.value = verseNumber;
    selectionErrorMessage.value = '';

    // Validate selection
    validateSelection();

    // Call update to notify GetBuilder and force rebuild where needed
    update();
  }

  void validateSelection() {
    if (selectedStartSurahName.value == null ||
        selectedStartVerse.value == null ||
        selectedEndSurahName.value == null ||
        selectedEndVerse.value == null) {
      return;
    }

    // Compare surah numbers
    int startSurahNumber = selectedStartSurahData.value!['surahNumber'];
    int endSurahNumber = selectedEndSurahData.value!['surahNumber'];

    if (startSurahNumber > endSurahNumber) {
      selectionErrorMessage.value = 'End surah cannot come before start surah';
      return;
    }

    if (startSurahNumber == endSurahNumber &&
        selectedStartVerse.value! > selectedEndVerse.value!) {
      selectionErrorMessage.value = 'End verse cannot come before start verse';
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
    return !isLoading.value && isRangeSelected();
  }

  // Fetch verses from Firestore based on surah and verse range
  Future<List<dynamic>> fetchVerses(int startSurahNumber, int startVerse,
      int endSurahNumber, int endVerse) async {
    final List<dynamic> versesList = [];

    try {
      // Construct the verse keys for start and end
      final String startKey = '$startSurahNumber:$startVerse';
      final String endKey = '$endSurahNumber:$endVerse';

      // Step 1: Find the start verse document ID using its key
      final QuerySnapshot startVerseSnapshot = await FirebaseFirestore.instance
          .collection('verses')
          .where('key', isEqualTo: startKey)
          .limit(1)
          .get();

      if (startVerseSnapshot.docs.isEmpty) {
        throw Exception('Start verse not found with key: $startKey');
      }

      final String startVerseId = startVerseSnapshot.docs.first.id;

      // Step 2: Find the end verse document ID using its key
      final QuerySnapshot endVerseSnapshot = await FirebaseFirestore.instance
          .collection('verses')
          .where('key', isEqualTo: endKey)
          .limit(1)
          .get();

      if (endVerseSnapshot.docs.isEmpty) {
        throw Exception('End verse not found with key: $endKey');
      }

      final String endVerseId = endVerseSnapshot.docs.first.id;

      // Step 3: Use a while loop to iterate through all IDs in the range
      int currentId = int.parse(startVerseId);
      int endId = int.parse(endVerseId);

      // Use while loop to fetch each verse by ID
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

          // Move to next ID
          currentId++;
        } catch (e) {
          currentId++; // Continue with the next ID even if one fails
        }
      }

      if (versesList.isEmpty) {
        throw Exception('No verses found in the selected range');
      }

      return versesList;
    } catch (e) {
      // Re-throw the exception to be caught by the caller
      rethrow;
    }
  }

  Future<void> createQuiz(
      List<Map<String, dynamic>> allData, BuildContext context) async {
    if (!isRangeSelected()) {
      selectionErrorMessage.value = 'Please select start and end verses';
      return;
    }

    if (!isAnyTypeSelected()) {
      selectionErrorMessage.value = 'Please select at least one question type';
      return;
    }

    isLoading.value = true;
    selectionErrorMessage.value = '';

    try {
      // Get surah numbers from selected data
      final int startSurahNumber = selectedStartSurahData.value!['surahNumber'];
      final int endSurahNumber = selectedEndSurahData.value!['surahNumber'];
      final int startVerse = selectedStartVerse.value!;
      final int endVerse = selectedEndVerse.value!;

      // Create a temporary ID for the quiz
      final String quizId =
          "custom_quiz_${DateTime.now().millisecondsSinceEpoch}";

      // Fetch verses from Firestore
      final List<dynamic> versesList = await fetchVerses(
          startSurahNumber, startVerse, endSurahNumber, endVerse);

      // Create review title
      final String reviewTitle = startSurahNumber == endSurahNumber
          ? 'Quiz: ${selectedStartSurahName.value} $startVerse-$endVerse'
          : 'Quiz: ${selectedStartSurahName.value} $startVerse to ${selectedEndSurahName.value} $endVerse';

      // Navigate to the quiz page with the selected question types
      Get.to(() => QuizPage(
            versesList: versesList,
            reviewTitle: reviewTitle,
            review: 'custom',
            id: quizId,
            updateReview: (id, title, review) {
              // For custom quizzes, we don't need to update anything in Firestore
            },
            includeFillBlank: includeFillBlank.value,
            includeDragDrop: includeDragDrop.value,
            includeWhatNext: includeWhatNext.value,
            includeVersePairing: includeVersePairing.value,
          ));
    } catch (e) {
      // Show error message
      selectionErrorMessage.value = 'Error creating quiz: ${e.toString()}';
    } finally {
      isLoading.value = false;
    }
  }
}
