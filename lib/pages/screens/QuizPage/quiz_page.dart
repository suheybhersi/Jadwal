import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jadwal/pages/screens/QuizPage/build_verse_question.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_intro_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_results_page.dart';
import 'package:jadwal/pages/screens/QuizPage/what_comes_next_question.dart';
import 'package:jadwal/pages/screens/QuizPage/fill_blank_question.dart';
import 'package:jadwal/pages/screens/QuizPage/verse_pairing_question.dart';
import 'package:jadwal/services/openai_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> versesList;
  final String reviewTitle;
  final String review;
  final String id;
  final Function(String, String, String) updateReview;

  const QuizPage({
    super.key,
    required this.versesList,
    required this.reviewTitle,
    required this.review,
    required this.id,
    required this.updateReview,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> with TickerProviderStateMixin {
  int currentQuestionIndex = -1;
  int score = 0;
  late List<Map<String, dynamic>> questions = [];
  Map<int, Map<String, dynamic>> answeredQuestions = {};

  // Simplified progress tracking
  double _loadingProgress = 0.0;
  bool _isActive = true;
  final List<String> _loadingMessages = [
    "Generating questions...",
    "Almost there...",
    "Finalising your quiz..."
  ];
  int _currentMessageIndex = 0;

  // Animation controllers
  AnimationController? _pulseController;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    // Initialize animation controllers
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Start loading questions
    _startProgressAnimation();
    _loadQuestions();
    _cycleLoadingMessages();
  }

  @override
  void dispose() {
    _isActive = false;
    _pulseController!.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  // Simplified progress animation
  void _startProgressAnimation() {
    const duration = 20000; // 20 seconds to reach ~100%
    const interval = 100; // Update every 100ms
    int elapsed = 0;

    Future.microtask(() async {
      while (_isActive && mounted && _loadingProgress < 0.99) {
        if (!mounted || !_isActive) return;

        elapsed += interval;
        final progress = min(elapsed / duration, 0.99);

        setState(() => _loadingProgress = progress);
        await Future.delayed(const Duration(milliseconds: interval));
      }
    });
  }

  // Simplified message cycling
  void _cycleLoadingMessages() {
    if (!mounted || !_isActive) return;

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || !_isActive) return;
      if (questions.isEmpty) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _cycleLoadingMessages();
      }
    });
  }

  // Load questions with progress animation
  Future<void> _loadQuestions() async {
    if (!mounted || !_isActive) return;

    // Generate questions
    final generatedQuestions = await _generateQuestions();
    if (!mounted || !_isActive) return;

    setState(() {
      questions = generatedQuestions;
      _loadingProgress = 1.0;
    });
  }

  // Generate quiz questions with diverse question types
  Future<List<Map<String, dynamic>>> _generateQuestions() async {
    // Initialize question lists
    List<Map<String, dynamic>> generatedQuestions = [];
    List<Map<String, dynamic>> fillInTheBlankQuestions = [];
    List<Map<String, dynamic>> dragAndDropQuestions = [];
    List<Map<String, dynamic>> whatComesNextQuestions = [];
    List<Map<String, dynamic>> versePairingQuestions = [];

    // Determine target question count based on verse count
    int targetQuestionCount;
    final verseCount = widget.versesList.length;

    if (verseCount <= 3) {
      targetQuestionCount = 5;
    } else if (verseCount <= 7) {
      targetQuestionCount = 10;
    } else if (verseCount <= 12) {
      targetQuestionCount = 15;
    } else if (verseCount <= 20) {
      targetQuestionCount = 20;
    } else {
      targetQuestionCount = 30;
    }

    // Create and distribute verse indices for diverse question types
    final verseIndices = List.generate(verseCount, (i) => i)..shuffle();
    final totalTypes = 4; // Fill blank, drag-drop, what-next, verse-pairing
    final baseIndicesPerType = verseIndices.length ~/ totalTypes;

    // Distribute indices among question types
    final typeIndices = List.generate(totalTypes, (i) {
      final start = i * baseIndicesPerType;
      final end = (i == totalTypes - 1)
          ? verseIndices.length
          : (i + 1) * baseIndicesPerType;
      return verseIndices.sublist(start, end);
    });

    // Handle fill-in-blank questions (limit to 5)
    final fillInBlankLimit = 5;
    var fillBlankIndices = typeIndices[0];

    // Ensure we have enough indices for fill-in-blank
    if (fillBlankIndices.length < fillInBlankLimit) {
      for (int i = 1;
          i < typeIndices.length && fillBlankIndices.length < fillInBlankLimit;
          i++) {
        if (typeIndices[i].isNotEmpty) {
          fillBlankIndices.add(typeIndices[i].removeAt(0));
        }
      }
    }
    // Get evenly distributed indices for fill-in-blank
    fillBlankIndices = List.generate(fillBlankIndices.length, (i) => i)
        .where((i) =>
            i %
                (fillBlankIndices.length /
                        min(fillInBlankLimit, fillBlankIndices.length))
                    .ceil() ==
            0)
        .map((i) => fillBlankIndices[i])
        .take(min(fillInBlankLimit, fillBlankIndices.length))
        .toList();

    // Generate all question types
    await _generateAllQuestionTypes(
      fillBlankIndices: fillBlankIndices,
      typeIndices: typeIndices,
      fillInTheBlankQuestions: fillInTheBlankQuestions,
      dragAndDropQuestions: dragAndDropQuestions,
      whatComesNextQuestions: whatComesNextQuestions,
      versePairingQuestions: versePairingQuestions,
    );

    // Add questions based on target distribution
    generatedQuestions = _assembleQuestionSet(
      targetQuestionCount: targetQuestionCount,
      fillInTheBlankQuestions: fillInTheBlankQuestions,
      dragAndDropQuestions: dragAndDropQuestions,
      whatComesNextQuestions: whatComesNextQuestions,
      versePairingQuestions: versePairingQuestions,
      fillBlankIndices: fillBlankIndices,
    );

    return generatedQuestions;
  }

  // Generate all question types from their respective indices
  Future<void> _generateAllQuestionTypes({
    required List<int> fillBlankIndices,
    required List<List<int>> typeIndices,
    required List<Map<String, dynamic>> fillInTheBlankQuestions,
    required List<Map<String, dynamic>> dragAndDropQuestions,
    required List<Map<String, dynamic>> whatComesNextQuestions,
    required List<Map<String, dynamic>> versePairingQuestions,
  }) async {
    // CHANGE ORDER: Start with drag & drop questions first due to length restrictions
    // 1. Generate Drag & Drop questions FIRST
    for (int verseIndex in typeIndices[1]) {
      if (!mounted || !_isActive) break;

      String verse = widget.versesList[verseIndex];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      if (!words.contains('')) {
        dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
      }
    }

    // 2. Generate Fill-in-Blank questions
    for (int i = 0; i < fillBlankIndices.length; i++) {
      if (!mounted || !_isActive) break;

      int verseIndex = fillBlankIndices[i];
      String verse = widget.versesList[verseIndex];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      if (words.length > 1 && !words.contains('')) {
        fillInTheBlankQuestions
            .add(await _generateFillInTheBlankQuestion(verse, verseIndex));
      }
    }

    // 3. Generate What Comes Next questions
    for (int verseIndex in typeIndices[2]) {
      if (!mounted || !_isActive) break;
      if (verseIndex < widget.versesList.length - 1) {
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(verseIndex));
      }
    }

    // 4. Generate Verse Pairing questions
    for (int verseIndex in typeIndices[3]) {
      if (!mounted || !_isActive) break;
      if (verseIndex > 0 && verseIndex < widget.versesList.length - 1) {
        versePairingQuestions.add(_generateVersePairingQuestion(verseIndex));
      }
    }

    // Shuffle all question collections for variety
    fillInTheBlankQuestions.shuffle();
    dragAndDropQuestions.shuffle();
    whatComesNextQuestions.shuffle();
    versePairingQuestions.shuffle();
  }

  // Assemble the final question set with balanced distribution
  List<Map<String, dynamic>> _assembleQuestionSet({
    required int targetQuestionCount,
    required List<Map<String, dynamic>> fillInTheBlankQuestions,
    required List<Map<String, dynamic>> dragAndDropQuestions,
    required List<Map<String, dynamic>> whatComesNextQuestions,
    required List<Map<String, dynamic>> versePairingQuestions,
    required List<int> fillBlankIndices,
  }) {
    // First, collect all questions by type
    List<Map<String, dynamic>> generatedQuestions = [];

    // IMPROVED BALANCING: Create a more even distribution
    // Target a quarter of questions for each type, with minimum 0 and maximum 40% of total
    int perTypeTarget = (targetQuestionCount / 4).ceil();
    int maxPerType = (targetQuestionCount * 0.4).ceil(); // Max 40% per type

    // Calculate how many questions we want of each type
    int fillBlankTarget =
        min(min(perTypeTarget, fillInTheBlankQuestions.length), maxPerType);
    int dragDropTarget =
        min(min(perTypeTarget, dragAndDropQuestions.length), maxPerType);
    int whatNextTarget =
        min(min(perTypeTarget, whatComesNextQuestions.length), maxPerType);
    int verseMatchTarget =
        min(min(perTypeTarget, versePairingQuestions.length), maxPerType);

    // Take the desired number from each type
    List<Map<String, dynamic>> fillBlankList =
        fillInTheBlankQuestions.take(fillBlankTarget).toList();
    List<Map<String, dynamic>> dragDropList =
        dragAndDropQuestions.take(dragDropTarget).toList();
    List<Map<String, dynamic>> whatNextList =
        whatComesNextQuestions.take(whatNextTarget).toList();
    List<Map<String, dynamic>> pairingList =
        versePairingQuestions.take(verseMatchTarget).toList();
    // Create a list of question type groups to alternate between
    List<List<Map<String, dynamic>>> questionGroups = [
      fillBlankList,
      dragDropList,
      whatNextList,
      pairingList,
    ];

    // Remove any empty groups
    questionGroups.removeWhere((group) => group.isEmpty);

    // Arrange questions by alternating types
    // This ensures we don't get clusters of the same type
    String? lastType;
    while (generatedQuestions.length < targetQuestionCount &&
        questionGroups.any((g) => g.isNotEmpty)) {
      // Try to find a group with a different type than the last one
      List<List<Map<String, dynamic>>>? availableGroups;

      if (lastType != null) {
        // Look for non-empty groups with a different type
        availableGroups = questionGroups
            .where(
                (group) => group.isNotEmpty && group.first['type'] != lastType)
            .toList();

        // If all remaining groups are the same type, just use what we have
        if (availableGroups.isEmpty) {
          availableGroups =
              questionGroups.where((group) => group.isNotEmpty).toList();
        }
      } else {
        // For the first question, use any non-empty group
        availableGroups =
            questionGroups.where((group) => group.isNotEmpty).toList();
      }

      // Break if no groups are available
      if (availableGroups.isEmpty) break;

      // Pick a random group from available ones
      final randomIndex = Random().nextInt(availableGroups.length);
      final selectedGroup = availableGroups[randomIndex];

      // Add a question from this group
      if (selectedGroup.isNotEmpty) {
        final question = selectedGroup.removeAt(0);
        generatedQuestions.add(question);
        lastType = question['type'];
      }

      // Update our groups list by removing empty ones
      questionGroups.removeWhere((group) => group.isEmpty);
    }

    // If we still don't have enough questions, generate additional ones
    if (generatedQuestions.length < targetQuestionCount) {
      List<Map<String, dynamic>> additionalQuestions = [];
      _generateAdditionalQuestions(
        generatedQuestions: additionalQuestions,
        targetQuestionCount: targetQuestionCount - generatedQuestions.length,
        fillBlankIndices: fillBlankIndices,
      );

      // Add additional questions with alternating types
      for (var question in additionalQuestions) {
        if (generatedQuestions.length >= targetQuestionCount) break;

        // Only add if different from the last type, or if we have no choice
        if (lastType == null ||
            question['type'] != lastType ||
            additionalQuestions.length == 1) {
          generatedQuestions.add(question);
          lastType = question['type'];
        }
      }
    }

    // Ensure we have multiples of 5 for question count
    int desiredCount = (targetQuestionCount ~/ 5) * 5;
    if (generatedQuestions.length > desiredCount) {
      // Trim questions if we have too many, but maintain type alternation
      generatedQuestions = generatedQuestions.take(desiredCount).toList();
    }

    // If we're still under target, add more questions to reach exact count
    if (generatedQuestions.length < desiredCount &&
        generatedQuestions.isNotEmpty) {
      // Calculate how many more questions we need
      int shortfall = desiredCount - generatedQuestions.length;

      // Track which verses have been used for which question types
      Map<int, Set<String>> usedVerseQuestionTypes = {};

      // Map existing questions to track which verses were used for which types
      for (var question in generatedQuestions) {
        int verseIndex = -1;

        // Extract verse index based on question type
        if (question['type'] == 'what_next' && question.containsKey('verse')) {
          // For what-comes-next, extract from the verse data
          String verse = question['verse'];
          verseIndex = widget.versesList.indexOf(verse);
        } else if (question['type'] == 'verse_pairing' &&
            question.containsKey('currentVerse')) {
          // For verse pairing, extract from currentVerse
          String verse = question['currentVerse'];
          verseIndex = widget.versesList.indexOf(verse);
        } else if (question['type'] == 'drag_drop' &&
            question.containsKey('correctOrder')) {
          // For drag & drop, reconstruct verse and find index
          String firstWord = question['firstWord'];
          List<String> fullWords = [firstWord, ...question['correctOrder']];
          String verse = fullWords.join(' ');
          verseIndex = widget.versesList.indexOf(verse);

          // If exact match fails, try containment search
          if (verseIndex == -1) {
            for (int i = 0; i < widget.versesList.length; i++) {
              if (widget.versesList[i].contains(firstWord)) {
                verseIndex = i;
                break;
              }
            }
          }
        } else if (question['type'] == 'fill_blank' &&
            question.containsKey('verseWords')) {
          // We won't generate more fill_blank, but track them to avoid verse reuse
          // This is approximate since we can't easily recover the full verse
          // Just mark all verses as used for this type to be safe
          continue;
        }

        // Track this verse and question type combination
        if (verseIndex >= 0) {
          usedVerseQuestionTypes[verseIndex] ??= {};
          usedVerseQuestionTypes[verseIndex]!.add(question['type']);
        }
      }

      // Define allowed padding question types (excluding fill_blank)
      List<String> paddingTypes = ['drag_drop', 'what_next', 'verse_pairing'];

      // Calculate how many questions of each type to generate
      int baseCount = shortfall ~/ paddingTypes.length;
      List<int> typeCounts = List.filled(paddingTypes.length, baseCount);

      // Distribute any remainder questions
      int remainder = shortfall - (baseCount * paddingTypes.length);
      for (int i = 0; i < remainder; i++) {
        typeCounts[i]++;
      }

      // Get all possible verse indices
      List<int> allVerseIndices =
          List.generate(widget.versesList.length, (i) => i);

      // Add padding questions of each type
      List<Map<String, dynamic>> paddingQuestions = [];

      for (int typeIndex = 0; typeIndex < paddingTypes.length; typeIndex++) {
        String questionType = paddingTypes[typeIndex];
        int targetCount = typeCounts[typeIndex];

        // Handle each question type
        if (questionType == 'drag_drop') {
          // Find verses that haven't been used for drag_drop
          List<int> candidateIndices = allVerseIndices
              .where((i) =>
                  !usedVerseQuestionTypes.containsKey(i) ||
                  !usedVerseQuestionTypes[i]!.contains('drag_drop'))
              .toList()
            ..shuffle();

          for (int i = 0; i < min(targetCount, candidateIndices.length); i++) {
            int verseIndex = candidateIndices[i];
            String verse = widget.versesList[verseIndex];
            List<String> words = splitVerseManuallyWithSpecialChars(verse);

            if (!words.contains('')) {
              paddingQuestions.add(_generateDragAndDropQuestion(verse));

              // Mark as used
              usedVerseQuestionTypes[verseIndex] ??= {};
              usedVerseQuestionTypes[verseIndex]!.add('drag_drop');
            }
          }
        } else if (questionType == 'what_next') {
          // Find verses that haven't been used for what_next
          List<int> candidateIndices = allVerseIndices
              .where((i) =>
                  i < widget.versesList.length - 1 &&
                  (!usedVerseQuestionTypes.containsKey(i) ||
                      !usedVerseQuestionTypes[i]!.contains('what_next')))
              .toList()
            ..shuffle();

          for (int i = 0; i < min(targetCount, candidateIndices.length); i++) {
            int verseIndex = candidateIndices[i];
            paddingQuestions.add(_generateWhatComesNextQuestion(verseIndex));

            // Mark as used
            usedVerseQuestionTypes[verseIndex] ??= {};
            usedVerseQuestionTypes[verseIndex]!.add('what_next');
          }
        } else if (questionType == 'verse_pairing') {
          // Find verses that haven't been used for verse_pairing
          List<int> candidateIndices = allVerseIndices
              .where((i) =>
                  i > 0 &&
                  i < widget.versesList.length - 1 &&
                  (!usedVerseQuestionTypes.containsKey(i) ||
                      !usedVerseQuestionTypes[i]!.contains('verse_pairing')))
              .toList()
            ..shuffle();

          for (int i = 0; i < min(targetCount, candidateIndices.length); i++) {
            int verseIndex = candidateIndices[i];
            paddingQuestions.add(_generateVersePairingQuestion(verseIndex));

            // Mark as used
            usedVerseQuestionTypes[verseIndex] ??= {};
            usedVerseQuestionTypes[verseIndex]!.add('verse_pairing');
          }
        }
      }

      // If we still need more questions due to verse constraints
      if (paddingQuestions.length < shortfall) {
        // Get all verses as candidates
        List<int> allIndices = List.generate(widget.versesList.length, (i) => i)
          ..shuffle();
        int typeIndex = 0;

        for (int i = 0;
            i < allIndices.length && paddingQuestions.length < shortfall;
            i++) {
          int verseIndex = allIndices[i];
          String questionType = paddingTypes[typeIndex % paddingTypes.length];

          // Try generating this type of question for this verse
          Map<String, dynamic>? question;

          if (questionType == 'drag_drop') {
            String verse = widget.versesList[verseIndex];
            List<String> words = splitVerseManuallyWithSpecialChars(verse);

            if (!words.contains('')) {
              question = _generateDragAndDropQuestion(verse);
            }
          } else if (questionType == 'what_next' &&
              verseIndex < widget.versesList.length - 1) {
            question = _generateWhatComesNextQuestion(verseIndex);
          } else if (questionType == 'verse_pairing' &&
              verseIndex > 0 &&
              verseIndex < widget.versesList.length - 1) {
            question = _generateVersePairingQuestion(verseIndex);
          }

          // Add question if successfully generated
          if (question != null) {
            paddingQuestions.add(question);
            typeIndex++; // Move to next type for balance
          }
        }
      }

      // Add all padding questions to the final list
      generatedQuestions.addAll(paddingQuestions);
    }

    return generatedQuestions;
  }

  // Generate additional questions if needed to meet target count
  void _generateAdditionalQuestions({
    required List<Map<String, dynamic>> generatedQuestions,
    required int targetQuestionCount,
    required List<int> fillBlankIndices,
  }) {
    // Get unused verse indices
    List<int> unusedIndices = List.generate(widget.versesList.length, (i) => i);
    unusedIndices.removeWhere((i) => fillBlankIndices.contains(i));
    unusedIndices.shuffle();

    int i = 0;
    // Generate additional questions using the unused indices
    while (generatedQuestions.length < targetQuestionCount &&
        i < unusedIndices.length) {
      int verseIndex = unusedIndices[i];
      String verse = widget.versesList[verseIndex];

      // Generate question based on rotation pattern
      if (i % 3 == 0 && verseIndex < widget.versesList.length - 1) {
        // What comes next
        generatedQuestions.add(_generateWhatComesNextQuestion(verseIndex));
      } else if (i % 3 == 1 &&
          verseIndex > 0 &&
          verseIndex < widget.versesList.length - 1) {
        // Verse pairing
        generatedQuestions.add(_generateVersePairingQuestion(verseIndex));
      } else {
        // Drag and drop
        List<String> words = splitVerseManuallyWithSpecialChars(verse);
        if (!words.contains('')) {
          generatedQuestions.add(_generateDragAndDropQuestion(verse));
        }
      }
      i++;
    }
  }

  List<String> splitVerseManuallyWithSpecialChars(String verse) {
    const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
    List<String> words = verse.split(" ");
    List<String> processedWords = [];

    for (int i = 0; i < words.length; i++) {
      if (specialChars.any((char) => words[i].contains(char)) && i > 0) {
        processedWords[processedWords.length - 1] =
            "${words[i]} ${processedWords[processedWords.length - 1]}";
      } else {
        processedWords.add(words[i]);
      }
    }

    return processedWords;
  }

  Map<String, dynamic> _generateWhatComesNextQuestion(int index) {
    return {
      'type': 'what_next',
      'question': "What verse comes after this?",
      'verse': widget.versesList[index],
      'correctAnswer': widget.versesList[index + 1],
    };
  }

  Map<String, dynamic> _generateDragAndDropQuestion(String verse) {
    List<String> words = splitVerseManuallyWithSpecialChars(verse);
    String firstWord = words.first;
    List<String> shuffledWords = List.from(words.skip(1))..shuffle();

    return {
      'type': 'drag_drop',
      'question': "Arrange the verse correctly:",
      'firstWord': firstWord,
      'shuffledWords': shuffledWords,
      'correctOrder': words.skip(1).toList(),
      'questionId': UniqueKey().toString(),
    };
  }

  Future<Map<String, dynamic>> _generateFillInTheBlankQuestion(
      String verse, int verseIndex) async {
    try {
      List<String> words = splitVerseManuallyWithSpecialChars(verse);
      int prevIndex = verseIndex - 1;

      // Get previous verse if available
      String? previousVerse;
      String? verseNumber;
      if (verseIndex > 0) {
        previousVerse = widget.versesList[prevIndex];
        FirebaseFirestore.instance
            .collection('verses')
            .where('text', isEqualTo: previousVerse)
            .get()
            .then((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            verseNumber =
                snapshot.docs.first.data()['key'].split(':')[1].toString();
          }
        });
      }

      // Get the last 3 words of the previous verse (if available)
      List<String> previousVerseLastWords = [];
      if (previousVerse != null) {
        List<String> previousWords =
            splitVerseManuallyWithSpecialChars(previousVerse);
        int wordsToTake = previousWords.length > 3 ? 3 : previousWords.length;
        previousVerseLastWords =
            previousWords.sublist(previousWords.length - wordsToTake);
      }

      // Determine number of blanks at the start and end
      int startBlanksCount = min(3, words.length ~/ 3);
      int endBlanksCount = min(2, words.length ~/ 4);

      // Ensure we don't try to blank out the entire verse
      int totalBlanks = startBlanksCount + endBlanksCount;
      if (totalBlanks >= words.length) {
        startBlanksCount = min(2, words.length - 1);
        endBlanksCount = min(1, words.length - startBlanksCount);
      }

      // Keep track of missing words and their indices
      List<String> missingWords = [];
      List<int> missingIndices = [];

      // Add indices for blanks at the beginning
      for (int i = 0; i < startBlanksCount; i++) {
        missingIndices.add(i);
        missingWords.add(words[i]);
      }

      // Add indices for blanks at the end
      for (int i = 0; i < endBlanksCount; i++) {
        int index = words.length - endBlanksCount + i;
        missingIndices.add(index);
        missingWords.add(words[index]);
      }

      // Create verse with blanks
      List<String> verseWithBlanks = List.from(words);
      for (int index in missingIndices) {
        verseWithBlanks[index] = '____';
      }

      // Create a map to store options for each correct word
      Map<String, List<String>> wordOptions = {};

      // Number of options to generate per word
      final int optionsPerWord = 5;

      try {
        // Generate options for each missing word
        for (String missingWord in missingWords) {
          // Initialize options list with the correct answer
          List<String> wordOptionsList = [missingWord];

          // Get AI-generated wrong options
          List<String> aiOptions = await OpenAIService.generateWrongOptions(
            correctWord: missingWord,
            context: verse,
            numberOfOptions: optionsPerWord,
          );

          // Add AI options if available
          if (aiOptions.isNotEmpty) {
            wordOptionsList.addAll(aiOptions);
          } else {
            // Fallback to random words
            List<String> randomOptions =
                getRandomWords([missingWord], verse, optionsPerWord);
            wordOptionsList.addAll(randomOptions);
          }

          // Shuffle the options for this word
          wordOptionsList.shuffle();

          // Store options for this word
          wordOptions[missingWord] = wordOptionsList;
        }
      } catch (e) {
        // Fallback to random word selection
        for (String missingWord in missingWords) {
          List<String> randomOptions =
              getRandomWords([missingWord], verse, optionsPerWord);
          List<String> wordOptionsList = [missingWord, ...randomOptions];
          wordOptionsList.shuffle();
          wordOptions[missingWord] = wordOptionsList;
        }
      }

      return {
        'type': 'fill_blank',
        'question':
            "Fill in the missing words at the beginning and end of the verse:",
        'verseWords': verseWithBlanks,
        'wordOptions': wordOptions,
        'correctAnswers': missingWords,
        'missingIndices': missingIndices,
        'previousVerseWords': previousVerseLastWords,
        'verseNumber': verseNumber,
      };
    } catch (e) {
      // Provide a fallback question
      return {
        'type': 'fill_blank',
        'question': "Fill in the missing words:",
        'verseWords': [verse],
        'wordOptions': {
          'Option 1': ['Option 1', 'Option 2', 'Option 3', 'Option 4']
        },
        'correctAnswers': ['Option 1'],
        'missingIndices': [0],
        'previousVerseWords': [],
        'verseNumber': "Verse",
      };
    }
  }

  List<String> getRandomWords(
      List<String> missingWords, String currentVerse, int numberOfBlanks) {
    List<String> allWords = widget.versesList
        .where((verse) => verse != currentVerse)
        .expand((verse) => splitVerseManuallyWithSpecialChars(verse))
        .toList();
    allWords.removeWhere((word) => currentVerse.contains(word));
    allWords.shuffle();
    return allWords.take(numberOfBlanks == 3 ? 5 : 3 * numberOfBlanks).toList();
  }

  List<String> getRandomVerses(int index) {
    List<String> verses = List.from(widget.versesList);
    verses.removeAt(index);
    verses.removeAt(index);
    verses.shuffle();
    return verses.take(3).toList();
  }

  Map<String, dynamic> _generateVersePairingQuestion(int verseIndex) {
    String currentVerse = widget.versesList[verseIndex];
    String? verseBefore =
        verseIndex > 0 ? widget.versesList[verseIndex - 1] : null;
    String? verseAfter = verseIndex < widget.versesList.length - 1
        ? widget.versesList[verseIndex + 1]
        : null;

    // Generate options for the "verse before" section
    List<String> beforeOptions = [];
    if (verseBefore != null) {
      beforeOptions.add(verseBefore); // Add correct answer
    }

    // Generate options for the "verse after" section
    List<String> afterOptions = [];
    if (verseAfter != null) {
      afterOptions.add(verseAfter); // Add correct answer
    }

    // Add incorrect options from other verses
    List<String> allVerses = List.from(widget.versesList);
    allVerses.remove(currentVerse);
    if (verseBefore != null) allVerses.remove(verseBefore);
    if (verseAfter != null) allVerses.remove(verseAfter);

    // Shuffle remaining verses
    allVerses.shuffle();

    // Add nearby verses for more challenging distractors
    List<String> nearbyVerses = [];
    for (int i = 1; i <= 5; i++) {
      // Add verses that are nearby but not adjacent
      if (verseIndex - i - 1 >= 0) {
        nearbyVerses.add(widget.versesList[verseIndex - i - 1]);
      }
      if (verseIndex + i + 1 < widget.versesList.length) {
        nearbyVerses.add(widget.versesList[verseIndex + i + 1]);
      }
    }
    nearbyVerses.shuffle();

    // Fill options for "before" section
    if (verseBefore != null) {
      // Add nearby verses first (more challenging)
      for (int i = 0;
          i < nearbyVerses.length && beforeOptions.length < 4;
          i++) {
        if (!beforeOptions.contains(nearbyVerses[i])) {
          beforeOptions.add(nearbyVerses[i]);
        }
      }

      // Fill with random verses if needed
      for (int i = 0; i < allVerses.length && beforeOptions.length < 4; i++) {
        if (!beforeOptions.contains(allVerses[i])) {
          beforeOptions.add(allVerses[i]);
        }
      }
      beforeOptions.shuffle(); // Randomize order
    }

    // Fill options for "after" section
    if (verseAfter != null) {
      // Add nearby verses first (more challenging)
      for (int i = 0; i < nearbyVerses.length && afterOptions.length < 4; i++) {
        if (!afterOptions.contains(nearbyVerses[i]) &&
            !beforeOptions.contains(nearbyVerses[i])) {
          afterOptions.add(nearbyVerses[i]);
        }
      }

      // Fill with random verses if needed
      for (int i = 0; i < allVerses.length && afterOptions.length < 4; i++) {
        if (!afterOptions.contains(allVerses[i]) &&
            !beforeOptions.contains(allVerses[i])) {
          afterOptions.add(allVerses[i]);
        }
      }
      afterOptions.shuffle(); // Randomize order
    }

    return {
      'type': 'verse_pairing',
      'question':
          "Complete the sequence by identifying verses before and after:",
      'currentVerse': currentVerse,
      'verseBefore': verseBefore,
      'verseAfter': verseAfter,
      'beforeOptions': beforeOptions,
      'afterOptions': afterOptions,
    };
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while questions are being loaded
    if (questions.isEmpty) {
      final primaryColor = const Color.fromARGB(255, 73, 121, 251);

      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: primaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            "Quiz",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Loading animation - simplified but maintains visual
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing circle
                        AnimatedBuilder(
                          animation: _pulseController!,
                          builder: (context, child) {
                            return Container(
                              width: 200 + (_pulseController!.value * 20),
                              height: 200 + (_pulseController!.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.03),
                              ),
                            );
                          },
                        ),

                        // Middle pulsing circle
                        AnimatedBuilder(
                          animation: _pulseController!,
                          builder: (context, child) {
                            return Container(
                              width: 160 + (_pulseController!.value * 15),
                              height: 160 + (_pulseController!.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.08),
                              ),
                            );
                          },
                        ),

                        // Center icon
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.quiz_outlined,
                              size: 60,
                              color: Color.fromARGB(255, 73, 121, 251),
                            ),
                          ),
                        ),

                        // Rotating circle
                        AnimatedBuilder(
                          animation: _rotationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationController.value * 2 * pi,
                              child: Container(
                                width: 160,
                                height: 160,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.15),
                                    width: 2,
                                    strokeAlign: BorderSide.strokeAlignOutside,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // Loading message
                Text(
                  _loadingMessages[_currentMessageIndex],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),

                const Spacer(),

                // Progress indicator - simplified
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Generating questions...",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            "${(_loadingProgress * 100).toInt()}%",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Stack(
                        children: [
                          // Background track
                          Container(
                            height: 10,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          // Progress bar
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 10,
                            width: MediaQuery.of(context).size.width *
                                (_loadingProgress * 0.9), // Account for padding
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Tip message
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates,
                            color: primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Quiz Tip",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Your personalised quiz will test your knowledge with various question types.",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (currentQuestionIndex == -1) {
      return QuizIntroPage(
        reviewTitle: widget.reviewTitle,
        onStart: (int index) {
          setState(() => currentQuestionIndex = index);
        },
        questions: questions,
      );
    }

    if (currentQuestionIndex >= questions.length) {
      return QuizResultsPage(
        score: score,
        questions: questions,
        id: widget.id,
        review: widget.review,
        updateReview: widget.updateReview,
        answeredQuestions: answeredQuestions,
        currentQuestionIndex: currentQuestionIndex,
      );
    }

    var currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      body: SafeArea(
        child: currentQuestion['type'] == 'fill_blank'
            ? FillBlankQuestion(
                question: currentQuestion,
                currentQuestionIndex: currentQuestionIndex,
                totalQuestions: questions.length,
                onNext: (bool wasCorrect) {
                  if (wasCorrect) {
                    setState(() => score++);
                  }
                  setState(() => currentQuestionIndex++);
                },
                answeredQuestions: answeredQuestions,
                onClose: () => Navigator.pop(context),
              )
            : currentQuestion['type'] == 'what_next'
                ? WhatComesNextQuestion(
                    question: currentQuestion,
                    currentQuestionIndex: currentQuestionIndex,
                    totalQuestions: questions.length,
                    onNext: (bool wasCorrect) {
                      if (wasCorrect) {
                        setState(() => score++);
                      }
                      setState(() => currentQuestionIndex++);
                    },
                    answeredQuestions: answeredQuestions,
                    onClose: () => Navigator.pop(context),
                  )
                : currentQuestion['type'] == 'verse_pairing'
                    ? VersePairingQuestion(
                        question: currentQuestion,
                        currentQuestionIndex: currentQuestionIndex,
                        totalQuestions: questions.length,
                        onNext: (bool wasCorrect) {
                          if (wasCorrect) {
                            setState(() => score++);
                          }
                          setState(() => currentQuestionIndex++);
                        },
                        answeredQuestions: answeredQuestions,
                        onClose: () => Navigator.pop(context),
                      )
                    : BuildVerseQuestion(
                        currentQuestionIndex: currentQuestionIndex,
                        questions: questions,
                        totalQuestions: questions.length,
                        onNext: (bool wasCorrect) {
                          if (wasCorrect) {
                            setState(() => score++);
                          }
                          setState(() => currentQuestionIndex++);
                        },
                        answeredQuestions: answeredQuestions,
                        onClose: () => Navigator.pop(context),
                      ),
      ),
    );
  }
}
