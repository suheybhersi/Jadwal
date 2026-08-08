import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jadwal/pages/screens/QuizPage/build_verse_question.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_controller.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_intro_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_results_page.dart';
import 'package:jadwal/pages/screens/QuizPage/what_comes_next_question.dart';
import 'package:jadwal/pages/screens/QuizPage/fill_blank_question.dart';
import 'package:jadwal/pages/screens/QuizPage/verse_pairing_question.dart';
import 'package:jadwal/services/distractor_service.dart';
import 'package:jadwal/services/quran_distractors_index.dart';
import 'package:jadwal/utils/quran_text_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> versesList;
  final String reviewTitle;
  final String review;
  final String id;
  final Future<Map<String, dynamic>?> Function(String, String, String) updateReview;

  // Question type flags
  final bool includeFillBlank;
  final bool includeDragDrop;
  final bool includeWhatNext;
  final bool includeVersePairing;
  final bool isCustomQuiz;
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
    this.isCustomQuiz = false,
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
  bool _didFinishLoading = false;
  String? _loadError;
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

  static const _minLoadingDuration = Duration(seconds: 5);

  // Progress fills to 99% over 5s, then holds until questions are ready.
  void _startProgressAnimation() {
    const durationMs = 5000;
    const interval = 100;
    int elapsed = 0;

    Future.microtask(() async {
      while (_isActive && mounted && _loadingProgress < 0.99) {
        if (!mounted || !_isActive) return;

        elapsed += interval;
        final progress = min(elapsed / durationMs, 0.99);

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
      if (questions.isEmpty && !_didFinishLoading) {
        setState(() {
          _currentMessageIndex =
              (_currentMessageIndex + 1) % _loadingMessages.length;
        });
        _cycleLoadingMessages();
      }
    });
  }

  Future<void> _waitForMinimumLoading(DateTime startedAt) async {
    final remaining = _minLoadingDuration - DateTime.now().difference(startedAt);
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
  }

  // Load questions; keep loading UI for at least 5s, then show quiz (or wait at 99%).
  Future<void> _loadQuestions() async {
    if (!mounted || !_isActive) return;
    final startedAt = DateTime.now();

    try {
      final generatedQuestions = await _generateQuestions();
      if (!mounted || !_isActive) return;

      await _waitForMinimumLoading(startedAt);
      if (!mounted || !_isActive) return;

      setState(() {
        questions = generatedQuestions;
        _loadingProgress = 1.0;
        _didFinishLoading = true;
        _loadError = generatedQuestions.isEmpty
            ? 'Couldn\'t create questions for the selected types and verse range. Try a wider range or different question types.'
            : null;
      });
    } catch (e) {
      if (!mounted || !_isActive) return;

      await _waitForMinimumLoading(startedAt);
      if (!mounted || !_isActive) return;

      setState(() {
        questions = [];
        _loadingProgress = 1.0;
        _didFinishLoading = true;
        _loadError = 'Error creating quiz: $e';
      });
    }
  }

  // Generate quiz questions with diverse question types
  Future<List<Map<String, dynamic>>> _generateQuestions() async {
    final enabledTypes = <String>[];
    if (widget.includeFillBlank) enabledTypes.add('fill_blank');
    if (widget.includeDragDrop) enabledTypes.add('drag_drop');
    if (widget.includeWhatNext) enabledTypes.add('what_next');
    if (widget.includeVersePairing) enabledTypes.add('verse_pairing');
    if (enabledTypes.isEmpty) return [];

    final verseCount = widget.versesList.length;
    double scaleFactor = 1.2;
    int rawCount = (verseCount * scaleFactor).round();
    int targetQuestionCount = ((rawCount + 2) ~/ 5) * 5;
    targetQuestionCount = max(5, min(targetQuestionCount, 50));
    targetQuestionCount = max(targetQuestionCount, enabledTypes.length);
    final questionsPerType =
        (targetQuestionCount / enabledTypes.length).ceil();

    // Same ayah may appear in different types; not twice within the same type.
    final usedPrimaryByType = <String, Set<int>>{
      for (final t in enabledTypes) t: {},
    };
    final byType = <String, List<Map<String, dynamic>>>{
      for (final t in enabledTypes) t: [],
    };

    List<int> spoilersFor(String type, int verseIndex) {
      switch (type) {
        case 'fill_blank':
          return [
            if (verseIndex > 0) verseIndex - 1,
            verseIndex,
          ];
        case 'what_next':
          return [verseIndex, verseIndex + 1];
        case 'verse_pairing':
          return [verseIndex - 1, verseIndex, verseIndex + 1];
        case 'drag_drop':
        default:
          return [verseIndex];
      }
    }

    bool isEligible(String type, int verseIndex) {
      final words = splitVerseManuallyWithSpecialChars(
        widget.versesList[verseIndex].toString(),
      );
      switch (type) {
        case 'fill_blank':
          return _isUsableFillBlankVerse(words, verseIndex);
        case 'drag_drop':
          return _isUsableDragDropVerse(words);
        case 'what_next':
          return verseIndex < verseCount - 1;
        case 'verse_pairing':
          return verseIndex > 0 && verseIndex < verseCount - 1;
        default:
          return false;
      }
    }

    Future<Map<String, dynamic>?> buildQuestion(
        String type, int verseIndex) async {
      final verse = widget.versesList[verseIndex].toString();
      switch (type) {
        case 'fill_blank':
          return _generateFillInTheBlankQuestion(verse, verseIndex);
        case 'drag_drop':
          return _generateDragAndDropQuestion(verse, verseIndex);
        case 'what_next':
          return _generateWhatComesNextQuestion(verseIndex);
        case 'verse_pairing':
          return await _generateVersePairingQuestion(verseIndex);
        default:
          return null;
      }
    }

    // Round-robin across types for balance. Reuse ayahs across types is OK.
    final typeOrder = List<String>.from(enabledTypes)..shuffle();
    var madeProgress = true;
    while (madeProgress) {
      madeProgress = false;
      for (final type in typeOrder) {
        if (!mounted || !_isActive) break;
        if (byType[type]!.length >= questionsPerType) continue;

        final candidates = List.generate(verseCount, (i) => i)..shuffle();
        for (final verseIndex in candidates) {
          if (usedPrimaryByType[type]!.contains(verseIndex)) continue;
          if (!isEligible(type, verseIndex)) continue;

          final question = await buildQuestion(type, verseIndex);
          if (question == null) continue;

          usedPrimaryByType[type]!.add(verseIndex);
          question['verseIndex'] = verseIndex;
          question['spoilerIndices'] = spoilersFor(type, verseIndex);
          byType[type]!.add(question);
          madeProgress = true;
          break;
        }
      }
    }

    final generatedQuestions = <Map<String, dynamic>>[
      for (final type in enabledTypes) ...byType[type]!,
    ];

    final ordered = _orderQuestionsAntiSpoiler(generatedQuestions);

    // Trim to multiple of 5 while keeping type balance when possible
    if (ordered.length >= 5) {
      final desiredCount = (ordered.length ~/ 5) * 5;
      if (ordered.length > desiredCount) {
        final typeCounts = <String, int>{};
        for (final q in ordered) {
          typeCounts[q['type']] = (typeCounts[q['type']] ?? 0) + 1;
        }
        while (ordered.length > desiredCount) {
          final typeToRemove = typeCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          final indexToRemove =
              ordered.lastIndexWhere((q) => q['type'] == typeToRemove);
          if (indexToRemove >= 0) {
            ordered.removeAt(indexToRemove);
            typeCounts[typeToRemove] = typeCounts[typeToRemove]! - 1;
          } else {
            ordered.removeLast();
          }
        }
      }
    }

    return ordered;
  }

  /// Orders questions so spoilers (same/adjacent ayahs) are not back-to-back
  /// when possible. Same ayah in different types later in the quiz is fine.
  List<Map<String, dynamic>> _orderQuestionsAntiSpoiler(
      List<Map<String, dynamic>> questions) {
    if (questions.length <= 1) return List.from(questions);

    final remaining = List<Map<String, dynamic>>.from(questions)..shuffle();
    final ordered = <Map<String, dynamic>>[];

    Set<int> spoilersOf(Map<String, dynamic> q) {
      final raw = q['spoilerIndices'];
      if (raw is List) {
        return raw.map((e) => e is int ? e : int.tryParse('$e') ?? -1).toSet();
      }
      final idx = q['verseIndex'];
      if (idx is int) return {idx};
      return {};
    }

    int conflictScore(
        Map<String, dynamic> candidate, List<Map<String, dynamic>> recent) {
      final cand = spoilersOf(candidate);
      if (cand.isEmpty) return 0;
      var score = 0;
      for (var r = 0; r < recent.length; r++) {
        final prev = spoilersOf(recent[recent.length - 1 - r]);
        final weight = recent.length - r; // closer = heavier
        for (final i in cand) {
          for (final j in prev) {
            final dist = (i - j).abs();
            if (dist == 0) {
              score += 100 * weight; // same ayah too soon
            } else if (dist == 1) {
              score += 50 * weight; // adjacent (what-next spoiler)
            } else if (dist == 2) {
              score += 10 * weight;
            }
          }
        }
      }
      return score;
    }

    while (remaining.isNotEmpty) {
      final recent = ordered.length >= 2
          ? ordered.sublist(ordered.length - 2)
          : List<Map<String, dynamic>>.from(ordered);

      remaining.sort((a, b) =>
          conflictScore(a, recent).compareTo(conflictScore(b, recent)));

      final bestScore = conflictScore(remaining.first, recent);
      final tied = remaining
          .where((q) => conflictScore(q, recent) == bestScore)
          .toList();
      Map<String, dynamic> pick = tied.first;
      if (ordered.isNotEmpty && tied.length > 1) {
        final lastType = ordered.last['type'];
        pick = tied.firstWhere(
          (q) => q['type'] != lastType,
          orElse: () => tied.first,
        );
      }

      ordered.add(pick);
      remaining.remove(pick);
    }

    return ordered;
  }

  /// Fill-blank needs enough words for start/end blanks (length~/3 and ~/4).
  /// Two-word ayahs produce 0 blanks with the current formula.
  static const int _minFillBlankWords = 3;

  /// Drag-drop keeps the first word fixed; need at least one more to arrange.
  static const int _minDragDropWords = 2;

  bool _isUsableFillBlankVerse(List<String> words, int verseIndex) =>
      verseIndex > 0 &&
      words.length >= _minFillBlankWords &&
      !words.contains('');

  bool _isUsableDragDropVerse(List<String> words) =>
      words.length >= _minDragDropWords && !words.contains('');

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

    // Drop Rub el Hizb, sajda, standalone pause marks — not spoken words
    return QuranTextUtils.speakableWords(processedWords);
  }

  Map<String, dynamic> _generateWhatComesNextQuestion(int index) {
    return {
      'type': 'what_next',
      'question': "What verse comes after this?",
      'verse': widget.versesList[index],
      'correctAnswer': widget.versesList[index + 1],
      'verseIndex': index,
      'spoilerIndices': [index, index + 1],
    };
  }

  Map<String, dynamic> _generateDragAndDropQuestion(String verse, int verseIndex) {
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
      'verseIndex': verseIndex,
      'spoilerIndices': [verseIndex],
    };
  }

  /// Returns null when the verse is too short to create any blanks.
  Future<Map<String, dynamic>?> _generateFillInTheBlankQuestion(
      String verse, int verseIndex) async {
    try {
      List<String> words = splitVerseManuallyWithSpecialChars(verse);
      if (!_isUsableFillBlankVerse(words, verseIndex)) return null;

      int prevIndex = verseIndex - 1;

      // Get previous verse if available (await so the ayah marker is set)
      String? previousVerse;
      String? verseNumber;
      if (verseIndex > 0) {
        previousVerse = widget.versesList[prevIndex]?.toString();
        try {
          final snapshot = await FirebaseFirestore.instance
              .collection('verses')
              .where('text', isEqualTo: previousVerse)
              .limit(1)
              .get();
          if (snapshot.docs.isNotEmpty) {
            final key = snapshot.docs.first.data()['key']?.toString() ?? '';
            if (key.contains(':')) {
              // Number of the previous ayah (shown between context and the blank verse)
              verseNumber = key.split(':')[1];
            }
          }
        } catch (_) {
          // Continue without verse marker if lookup fails
        }
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

      if (missingIndices.isEmpty) return null;

      // Create verse with blanks
      List<String> verseWithBlanks = List.from(words);
      for (int index in missingIndices) {
        verseWithBlanks[index] = '____';
      }

      final twinIndex = await QuranDistractorsIndex.load();
      final distractors = DistractorService(
        splitVerse: splitVerseManuallyWithSpecialChars,
        twinIndex: twinIndex,
      );

      // Options keyed by blank index (stable) and by correct word (legacy UI)
      final Map<String, List<String>> blankOptions = {};
      final Map<String, List<String>> wordOptions = {};

      for (int blankIdx = 0; blankIdx < missingWords.length; blankIdx++) {
        final missingWord = missingWords[blankIdx];
        final missingAt = missingIndices[blankIdx];

        // Word immediately before this blank (for bigram twin lookup)
        String? previousWord;
        if (missingAt > 0) {
          previousWord = words[missingAt - 1];
        } else if (previousVerseLastWords.isNotEmpty) {
          previousWord = previousVerseLastWords.last;
        }

        final candidates = distractors.ensureEnoughCandidates(
          correctWord: missingWord,
          currentVerse: verse,
          verseIndex: verseIndex,
          versesList: widget.versesList,
          previousWord: previousWord,
        );

        final chosenDistractors = distractors.pickWithoutAI(candidates);

        final options = distractors.buildOptions(
          correctWord: missingWord,
          distractors: chosenDistractors,
        );

        blankOptions['$blankIdx'] = options;
        wordOptions[missingWord] = options;
      }

      return {
        'type': 'fill_blank',
        'question':
            "Fill in the missing words at the beginning and end of the verse:",
        'verseWords': verseWithBlanks,
        'blankOptions': blankOptions,
        'wordOptions': wordOptions,
        'correctAnswers': missingWords,
        'missingIndices': missingIndices,
        'previousVerseWords': previousVerseLastWords,
        'verseNumber': verseNumber,
        'verseIndex': verseIndex,
        'spoilerIndices': [
          if (verseIndex > 0) verseIndex - 1,
          verseIndex,
        ],
      };
    } catch (e) {
      // Skip broken fill-blank rather than showing an unusable question
      return null;
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

  /// Pull random ayahs from the full Quran (Firestore) to pad option lists.
  Future<List<String>> _fetchQuranFillerVerses({
    required int count,
    required Set<String> exclude,
  }) async {
    if (count <= 0) return const [];

    const totalVerses = 6236;
    final random = Random();
    final fillers = <String>[];
    final triedIds = <int>{};
    var attempts = 0;
    final maxAttempts = count * 20;

    while (fillers.length < count && attempts < maxAttempts) {
      attempts++;
      final id = random.nextInt(totalVerses) + 1;
      if (!triedIds.add(id)) continue;

      try {
        final doc = await FirebaseFirestore.instance
            .collection('verses')
            .doc(id.toString())
            .get();
        final text = doc.data()?['text']?.toString().trim() ?? '';
        if (text.isEmpty) continue;
        if (exclude.contains(text) || fillers.contains(text)) continue;
        fillers.add(text);
      } catch (_) {
        // Skip failed lookups and keep trying.
      }
    }

    return fillers;
  }

  Future<void> _padVerseOptions(
    List<String> options, {
    required int target,
    required Set<String> exclude,
  }) async {
    if (options.length >= target) return;
    final fillers = await _fetchQuranFillerVerses(
      count: target - options.length,
      exclude: {...exclude, ...options},
    );
    options.addAll(fillers);
  }

  Future<Map<String, dynamic>?> _generateVersePairingQuestion(
      int verseIndex) async {
    // Need a true middle ayah (before + current + after).
    if (widget.versesList.length < 3) return null;

    // Skip first and last verses since they don't have verses before/after them respectively
    if (verseIndex <= 0 || verseIndex >= widget.versesList.length - 1) {
      final middleIndex = widget.versesList.length ~/ 2;
      if (middleIndex <= 0 || middleIndex >= widget.versesList.length - 1) {
        return null;
      }
      verseIndex = middleIndex;
    }

    String currentVerse = widget.versesList[verseIndex].toString();
    String verseBefore = widget.versesList[verseIndex - 1].toString();
    String verseAfter = widget.versesList[verseIndex + 1].toString();

    String? verseNumber;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('verses')
          .where('text', isEqualTo: currentVerse)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final key = snapshot.docs.first.data()['key']?.toString() ?? '';
        if (key.contains(':')) {
          verseNumber = key.split(':')[1];
        }
      }
    } catch (_) {
      // Continue without verse number if lookup fails
    }

    // Generate options for the "verse before" section
    List<String> beforeOptions = [verseBefore]; // Add correct answer

    // Generate options for the "verse after" section
    List<String> afterOptions = [verseAfter]; // Add correct answer

    // Add incorrect options from other verses
    List<String> allVerses = List.from(widget.versesList);
    allVerses.remove(currentVerse);
    allVerses.remove(verseBefore);
    allVerses.remove(verseAfter);

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
    // Add nearby verses first (more challenging)
    for (int i = 0; i < nearbyVerses.length && beforeOptions.length < 4; i++) {
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

    // Fill options for "after" section
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

    // Pad from the rest of the Quran when this review range is too short.
    final sharedExclude = <String>{currentVerse, verseBefore, verseAfter};
    await _padVerseOptions(
      beforeOptions,
      target: 4,
      exclude: sharedExclude,
    );
    await _padVerseOptions(
      afterOptions,
      target: 4,
      exclude: {...sharedExclude, ...beforeOptions},
    );

    beforeOptions.shuffle();
    afterOptions.shuffle();

    return {
      'type': 'verse_pairing',
      'question':
          "Complete the sequence by identifying verses before and after:",
      'currentVerse': currentVerse,
      'verseBefore': verseBefore,
      'verseAfter': verseAfter,
      'beforeOptions': beforeOptions,
      'afterOptions': afterOptions,
      'verseIndex': verseIndex,
      'verseNumber': verseNumber,
      'spoilerIndices': [verseIndex - 1, verseIndex, verseIndex + 1],
    };
  }

  @override
  Widget build(BuildContext context) {
    // Show error if generation finished with no questions
    if (questions.isEmpty && _didFinishLoading) {
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
                const SizedBox(height: 16),
                Text(
                  'Couldn\'t create this quiz',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loadError ??
                      'No questions were generated. Please try again with a different range or question types.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go back',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                                color: primaryColor.withValues(alpha: 0.03),
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
                                color: primaryColor.withValues(alpha: 0.08),
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
                                color: primaryColor.withValues(alpha: 0.2),
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
                                    color: primaryColor.withValues(alpha: 0.15),
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
                            .withValues(alpha: 0.3),
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
        onClose: widget.isCustomQuiz
            ? () {
                try {
                  Get.find<QuizCreationController>().resetAllState();
                } catch (_) {}
                final navigator = Navigator.of(context);
                navigator.pop(); // Leave quiz welcome
                navigator.pop(); // Leave create-quiz form → back to quiz history
              }
            : null,
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
        isCustomQuiz: widget.isCustomQuiz,
      );
    }

    var currentQuestion = questions[currentQuestionIndex];

    // For custom quizzes, close goes back to quiz history (pop twice + reset); otherwise just pop once.
    final void Function() onQuestionClose = widget.isCustomQuiz
        ? () {
            try {
              Get.find<QuizCreationController>().resetAllState();
            } catch (_) {}
            final navigator = Navigator.of(context);
            navigator.pop(); // Leave current question
            navigator.pop(); // Leave create-quiz form → back to quiz history
          }
        : () => Navigator.pop(context);

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
                onClose: onQuestionClose,
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
                    onClose: onQuestionClose,
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
                        onClose: onQuestionClose,
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
                        onClose: onQuestionClose,
                      ),
      ),
    );
  }
}
