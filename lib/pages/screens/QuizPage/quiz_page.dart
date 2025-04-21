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

  // Question type flags
  final bool includeFillBlank;
  final bool includeDragDrop;
  final bool includeWhatNext;
  final bool includeVersePairing;

  const QuizPage({
    super.key,
    required this.versesList,
    required this.reviewTitle,
    required this.review,
    required this.id,
    required this.updateReview,
    this.includeFillBlank = true,
    this.includeDragDrop = true,
    this.includeWhatNext = true,
    this.includeVersePairing = true,
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

    // Get list of enabled question types
    List<String> enabledTypes = [];
    if (widget.includeFillBlank) enabledTypes.add('fill_blank');
    if (widget.includeDragDrop) enabledTypes.add('drag_drop');
    if (widget.includeWhatNext) enabledTypes.add('what_next');
    if (widget.includeVersePairing) enabledTypes.add('verse_pairing');

    // If no types were selected, return empty list
    if (enabledTypes.isEmpty) {
      return [];
    }

    // Determine target question count dynamically based on verse count
    int targetQuestionCount;
    final verseCount = widget.versesList.length;

    // Scale question count with number of verses (approximately 1.3-1.5 questions per verse)
    // but ensure it's a multiple of 5 and within bounds
    double scaleFactor = 1.2; // Questions per verse
    int rawCount = (verseCount * scaleFactor).round();

    // Round to nearest multiple of 5
    targetQuestionCount = ((rawCount + 2) ~/ 5) * 5;

    // Set minimum and maximum bounds
    targetQuestionCount = max(5, min(targetQuestionCount, 50));

    // Ensure we have at least the number of enabled types
    targetQuestionCount = max(targetQuestionCount, enabledTypes.length);

    // Calculate questions per type
    int questionsPerType = (targetQuestionCount / enabledTypes.length).ceil();

    // Create a randomized list of all verse indices
    final allVerseIndices = List.generate(verseCount, (i) => i)..shuffle();

    // Split the verses evenly among enabled types
    Map<String, List<int>> verseIndicesPerType = {};

    // First, calculate how many verses each type needs
    int versesPerType = (allVerseIndices.length / enabledTypes.length).ceil();

    // Distribute verses to each enabled type
    for (int i = 0; i < enabledTypes.length; i++) {
      int start = i * versesPerType;
      int end = min((i + 1) * versesPerType, allVerseIndices.length);

      // Handle edge case where we might run out of indices
      if (start >= allVerseIndices.length) {
        // Reuse some indices from the beginning
        start = 0;
        end = min(versesPerType, allVerseIndices.length);
      }

      verseIndicesPerType[enabledTypes[i]] =
          allVerseIndices.sublist(start, end);
    }

    // Generate questions for each enabled type
    if (widget.includeFillBlank) {
      List<int> fillBlankVerses = verseIndicesPerType['fill_blank'] ?? [];
      // For fill-blank, limit the max number of questions
      int count = min(questionsPerType, fillBlankVerses.length);

      // Use the first 'count' verses for fill-blank questions
      for (int i = 0; i < count; i++) {
        if (!mounted || !_isActive) break;
        if (i >= fillBlankVerses.length) break;

        int verseIndex = fillBlankVerses[i];
        String verse = widget.versesList[verseIndex];
        List<String> words = splitVerseManuallyWithSpecialChars(verse);

        if (words.length > 1 && !words.contains('')) {
          var question =
              await _generateFillInTheBlankQuestion(verse, verseIndex);
          fillInTheBlankQuestions.add(question);
        }
      }
    }

    if (widget.includeDragDrop) {
      List<int> dragDropVerses = verseIndicesPerType['drag_drop'] ?? [];
      int count = min(questionsPerType, dragDropVerses.length);

      for (int i = 0; i < count; i++) {
        if (!mounted || !_isActive) break;
        if (i >= dragDropVerses.length) break;

        int verseIndex = dragDropVerses[i];
        String verse = widget.versesList[verseIndex];
        List<String> words = splitVerseManuallyWithSpecialChars(verse);

        if (!words.contains('')) {
          dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
        }
      }
    }

    if (widget.includeWhatNext) {
      List<int> whatNextVerses = verseIndicesPerType['what_next'] ?? [];
      int count = min(questionsPerType, whatNextVerses.length);

      for (int i = 0; i < count; i++) {
        if (!mounted || !_isActive) break;
        if (i >= whatNextVerses.length) break;

        int verseIndex = whatNextVerses[i];
        // Only create question if there's a next verse
        if (verseIndex < widget.versesList.length - 1) {
          whatComesNextQuestions
              .add(_generateWhatComesNextQuestion(verseIndex));
        } else if (i < whatNextVerses.length - 1) {
          // Try the next verse if this one doesn't work
          i++;
          verseIndex = whatNextVerses[i];
          if (verseIndex < widget.versesList.length - 1) {
            whatComesNextQuestions
                .add(_generateWhatComesNextQuestion(verseIndex));
          }
        }
      }
    }

    if (widget.includeVersePairing) {
      List<int> pairingVerses = verseIndicesPerType['verse_pairing'] ?? [];
      int count = min(questionsPerType, pairingVerses.length);

      for (int i = 0; i < count; i++) {
        if (!mounted || !_isActive) break;
        if (i >= pairingVerses.length) break;

        int verseIndex = pairingVerses[i];
        // Only create question if there's a verse before and after
        if (verseIndex > 0 && verseIndex < widget.versesList.length - 1) {
          versePairingQuestions.add(_generateVersePairingQuestion(verseIndex));
        } else if (i < pairingVerses.length - 1) {
          // Try the next verse if this one doesn't work
          i++;
          verseIndex = pairingVerses[i];
          if (verseIndex > 0 && verseIndex < widget.versesList.length - 1) {
            versePairingQuestions
                .add(_generateVersePairingQuestion(verseIndex));
          }
        }
      }
    }

    // If we have fewer questions than expected for some type, try to use more verses
    if (widget.includeFillBlank &&
        fillInTheBlankQuestions.length < questionsPerType) {
      // Find unused verses
      List<int> usedVerses = fillInTheBlankQuestions.map((q) {
        return widget.versesList.indexOf(q['verseWords']?.first ?? '');
      }).toList();

      List<int> unusedVerses =
          allVerseIndices.where((idx) => !usedVerses.contains(idx)).toList();
      unusedVerses.shuffle();

      for (int i = 0;
          i < unusedVerses.length &&
              fillInTheBlankQuestions.length < questionsPerType;
          i++) {
        int verseIndex = unusedVerses[i];
        String verse = widget.versesList[verseIndex];
        List<String> words = splitVerseManuallyWithSpecialChars(verse);

        if (words.length > 1 && !words.contains('')) {
          var question =
              await _generateFillInTheBlankQuestion(verse, verseIndex);
          fillInTheBlankQuestions.add(question);
        }
      }
    }

    if (widget.includeDragDrop &&
        dragAndDropQuestions.length < questionsPerType) {
      // Find unused verses for drag and drop
      List<int> usedVerses = [];
      for (var q in dragAndDropQuestions) {
        String firstWord = q['firstWord'];
        for (int i = 0; i < widget.versesList.length; i++) {
          if (widget.versesList[i].startsWith(firstWord)) {
            usedVerses.add(i);
            break;
          }
        }
      }

      List<int> unusedVerses =
          allVerseIndices.where((idx) => !usedVerses.contains(idx)).toList();
      unusedVerses.shuffle();

      for (int i = 0;
          i < unusedVerses.length &&
              dragAndDropQuestions.length < questionsPerType;
          i++) {
        int verseIndex = unusedVerses[i];
        String verse = widget.versesList[verseIndex];
        List<String> words = splitVerseManuallyWithSpecialChars(verse);

        if (!words.contains('')) {
          dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
        }
      }
    }

    if (widget.includeWhatNext &&
        whatComesNextQuestions.length < questionsPerType) {
      // Find unused verses for what comes next
      List<int> usedVerses = whatComesNextQuestions.map((q) {
        return widget.versesList.indexOf(q['verse']);
      }).toList();

      List<int> unusedVerses = allVerseIndices
          .where((idx) =>
              !usedVerses.contains(idx) && idx < widget.versesList.length - 1)
          .toList();
      unusedVerses.shuffle();

      for (int i = 0;
          i < unusedVerses.length &&
              whatComesNextQuestions.length < questionsPerType;
          i++) {
        int verseIndex = unusedVerses[i];
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(verseIndex));
      }
    }

    if (widget.includeVersePairing &&
        versePairingQuestions.length < questionsPerType) {
      // Find unused verses for verse pairing
      List<int> usedVerses = versePairingQuestions.map((q) {
        return widget.versesList.indexOf(q['currentVerse']);
      }).toList();

      List<int> unusedVerses = allVerseIndices
          .where((idx) =>
              !usedVerses.contains(idx) &&
              idx > 0 &&
              idx < widget.versesList.length - 1)
          .toList();
      unusedVerses.shuffle();

      for (int i = 0;
          i < unusedVerses.length &&
              versePairingQuestions.length < questionsPerType;
          i++) {
        int verseIndex = unusedVerses[i];
        versePairingQuestions.add(_generateVersePairingQuestion(verseIndex));
      }
    }

    // Shuffle all question collections for variety
    fillInTheBlankQuestions.shuffle();
    dragAndDropQuestions.shuffle();
    whatComesNextQuestions.shuffle();
    versePairingQuestions.shuffle();

    // Make sure we have the correct number per type
    if (widget.includeFillBlank &&
        fillInTheBlankQuestions.length > questionsPerType) {
      fillInTheBlankQuestions =
          fillInTheBlankQuestions.sublist(0, questionsPerType);
    }
    if (widget.includeDragDrop &&
        dragAndDropQuestions.length > questionsPerType) {
      dragAndDropQuestions = dragAndDropQuestions.sublist(0, questionsPerType);
    }
    if (widget.includeWhatNext &&
        whatComesNextQuestions.length > questionsPerType) {
      whatComesNextQuestions =
          whatComesNextQuestions.sublist(0, questionsPerType);
    }
    if (widget.includeVersePairing &&
        versePairingQuestions.length > questionsPerType) {
      versePairingQuestions =
          versePairingQuestions.sublist(0, questionsPerType);
    }

    // Combine questions from all enabled types
    if (widget.includeFillBlank) {
      generatedQuestions.addAll(fillInTheBlankQuestions);
    }
    if (widget.includeDragDrop) {
      generatedQuestions.addAll(dragAndDropQuestions);
    }
    if (widget.includeWhatNext) {
      generatedQuestions.addAll(whatComesNextQuestions);
    }
    if (widget.includeVersePairing) {
      generatedQuestions.addAll(versePairingQuestions);
    }

    // Shuffle for variety but maintain equal distribution
    generatedQuestions.shuffle();

    // Ensure we have multiples of 5 for question count if we have enough questions
    if (generatedQuestions.length >= 5) {
      int desiredCount = (generatedQuestions.length ~/ 5) * 5;
      if (generatedQuestions.length > desiredCount) {
        // When trimming, make sure we maintain equal distribution
        Map<String, int> typeCounts = {};
        for (var question in generatedQuestions) {
          typeCounts[question['type']] =
              (typeCounts[question['type']] ?? 0) + 1;
        }

        // Find types with more questions to remove from
        while (generatedQuestions.length > desiredCount) {
          String typeToRemove = typeCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;

          // Find the index of a question of this type
          int indexToRemove =
              generatedQuestions.indexWhere((q) => q['type'] == typeToRemove);
          if (indexToRemove >= 0) {
            generatedQuestions.removeAt(indexToRemove);
            typeCounts[typeToRemove] = typeCounts[typeToRemove]! - 1;
          } else {
            // Shouldn't happen, but just in case
            generatedQuestions.removeLast();
          }
        }
      }
    }

    return generatedQuestions;
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
        isCustomQuiz: widget.review == 'custom',
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
