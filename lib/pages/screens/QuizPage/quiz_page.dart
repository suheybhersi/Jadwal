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

  // Progress tracking variables
  double _loadingProgress = 0.0;
  double _targetProgress = 0.0;
  bool _isLoadingText = true;
  final List<String> _loadingMessages = [
    "Generating questions...",
    "Almost there...",
    "Finalising your quiz..."
  ];
  int _currentMessageIndex = 0;

  // Animation controllers
  AnimationController? _loadingAnimationController;
  AnimationController? _rotationAnimationController;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // Initialise animation controllers
    _loadingAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _rotationAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();

    // Start animations and load questions
    _startSmoothProgressAnimation();
    _loadQuestions();
    _startLoadingTextAnimation();
  }

  @override
  void dispose() {
    // First set flag to stop all animations
    _isActive = false;

    // Make sure to stop all controllers first
    _loadingAnimationController?.stop();
    _rotationAnimationController?.stop();

    // Then dispose controllers with proper null safety checks
    if (_loadingAnimationController != null) {
      _loadingAnimationController!.dispose();
      _loadingAnimationController = null;
    }

    if (_rotationAnimationController != null) {
      _rotationAnimationController!.dispose();
      _rotationAnimationController = null;
    }

    // Make sure super.dispose() is called last
    super.dispose();
  }

  // Consistent smooth progress animation
  void _startSmoothProgressAnimation() {
    Future.microtask(() async {
      while (_isActive &&
          mounted &&
          (questions.isEmpty || _loadingProgress < 1.0)) {
        // Only animate if we haven't reached the target
        if (_loadingProgress < _targetProgress) {
          if (!mounted || !_isActive) return;

          setState(() {
            // Apply appropriate step size based on current progress
            double step;

            if (_loadingProgress < 0.3) {
              step = 0.005; // Faster in the beginning (0-30%)
            } else if (_loadingProgress < 0.7) {
              step = 0.003; // Slower in the middle (30-70%)
            } else {
              step = 0.004; // Medium speed at the end (70-100%)
            }

            // Cap step size based on distance to target
            double maxStep = (_targetProgress - _loadingProgress) * 0.5;
            if (step > maxStep && maxStep > 0.001) {
              step = maxStep;
            }

            _loadingProgress += step;

            // Ensure we don't overshoot the target
            if (_loadingProgress > _targetProgress) {
              _loadingProgress = _targetProgress;
            }

            // Force to 100% if we're very close and target is 100%
            if (_targetProgress >= 0.99 && _loadingProgress >= 0.98) {
              _loadingProgress = 1.0;
            }
          });
        }

        await Future.delayed(const Duration(milliseconds: 30));
        if (!mounted || !_isActive) return;
      }
    });
  }

  // Safe setState wrapper for progress updates
  void _updateTargetProgress(double target) {
    if (!mounted || !_isActive) return;
    setState(() => _targetProgress = target);
  }

  // Text animation with proper lifecycle checks
  void _startLoadingTextAnimation() {
    if (!mounted || !_isActive) return;

    Future.delayed(Duration(seconds: 3), () {
      if (!mounted || !_isActive) return;
      if (questions.isEmpty) {
        setState(() => _isLoadingText = false);

        Future.delayed(Duration(milliseconds: 500), () {
          if (!mounted || !_isActive) return;
          if (questions.isEmpty) {
            setState(() {
              _currentMessageIndex =
                  (_currentMessageIndex + 1) % _loadingMessages.length;
              _isLoadingText = true;
            });
            _startLoadingTextAnimation();
          }
        });
      }
    });
  }

  // Load questions with evenly distributed progress updates
  Future<void> _loadQuestions() async {
    if (!mounted || !_isActive) return;

    // Initial progress
    _updateTargetProgress(0.05);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || !_isActive) return;

    _updateTargetProgress(0.15);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || !_isActive) return;

    // Generate questions
    final generatedQuestions = await _generateQuestions();
    if (!mounted || !_isActive) return;

    // Final progress updates
    _updateTargetProgress(0.95);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted || !_isActive) return;

    _updateTargetProgress(1.0);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_isActive) return;

    setState(() {
      questions = generatedQuestions..shuffle();
      _loadingProgress = 1.0;
    });

    // Wait before transitioning
    await Future.delayed(const Duration(milliseconds: 800));
  }

  Future<List<Map<String, dynamic>>> _generateQuestions() async {
    List<Map<String, dynamic>> generatedQuestions = [];
    List<Map<String, dynamic>> fillInTheBlankQuestions = [];
    List<Map<String, dynamic>> dragAndDropQuestions = [];
    List<Map<String, dynamic>> whatComesNextQuestions = [];
    List<Map<String, dynamic>> versePairingQuestions = [];

    // Start with 25% progress
    _updateTargetProgress(0.25);

    // Distribute 45% of progress across verse processing
    final totalVerses = widget.versesList.length;
    final verseProgressIncrement = 0.45 / totalVerses;

    // Process each verse
    for (int i = 0; i < widget.versesList.length; i++) {
      if (!mounted || !_isActive) break;

      String verse = widget.versesList[i];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      // Generate what comes next questions
      if (i < widget.versesList.length - 1) {
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(i));
      }

      // Generate verse pairing questions for each verse except first and last
      if (i > 0 && i < widget.versesList.length - 1) {
        versePairingQuestions.add(_generateVersePairingQuestion(i));
      }

      // Update progress incrementally
      _updateTargetProgress(0.25 + (verseProgressIncrement * (i + 1)));

      // Add small delays occasionally for smooth animation
      if (i % 5 == 0) {
        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted || !_isActive) break;
      }

      // Only add fill in the blank for verses with more than 1 word
      if (!words.contains('')) {
        fillInTheBlankQuestions
            .add(await _generateFillInTheBlankQuestion(verse));
      }

      // Only add drag and drop for verses between 2 and 7 words
      if (!words.contains('') && words.length < 15) {
        dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
      }
    }

    // Progress updates for question processing phase
    _updateTargetProgress(0.70);
    await _safeDelay(150);

    // Shuffle questions
    dragAndDropQuestions.shuffle();
    fillInTheBlankQuestions.shuffle();
    whatComesNextQuestions.shuffle();
    versePairingQuestions.shuffle();

    // Add drag and drop questions
    generatedQuestions.addAll(dragAndDropQuestions.length > 7
        ? dragAndDropQuestions.take(7)
        : dragAndDropQuestions);

    _updateTargetProgress(0.78);
    await _safeDelay(150);

    // Adding what comes next questions
    int dDCount = (20 - generatedQuestions.length + 1) ~/ 2;
    int count = 1;

    for (int i = 0;
        i < whatComesNextQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Check if this what_next question's first word matches any drag_drop question's first word
      bool hasMatchingDragDrop = generatedQuestions.any((q) {
        String whatNextFirstWord = splitVerseManuallyWithSpecialChars(
                whatComesNextQuestions[i]['verse'])
            .first;
        return q['firstWord'] == whatNextFirstWord;
      });

      // Only add if there's no matching drag_drop question and within count limit
      if (!hasMatchingDragDrop && count <= dDCount) {
        generatedQuestions.add(whatComesNextQuestions[i]);
        count++;
      }
    }

    _updateTargetProgress(0.85);
    await _safeDelay(150);

    // Adding fill in the blank questions
    for (int i = 0;
        i < fillInTheBlankQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Get first word of the current fill_blank question
      String fillBlankFirstWord =
          fillInTheBlankQuestions[i]['verseWords'].first;

      // Check for matches with drag_drop and what_next questions
      bool hasMatchingQuestion = generatedQuestions.any((q) {
        if (q['type'] == 'drag_drop') {
          return q['firstWord'] == fillBlankFirstWord;
        } else if (q['type'] == 'what_next') {
          String whatNextCorrectFirstWord =
              splitVerseManuallyWithSpecialChars(q['correctAnswer']).first;
          return whatNextCorrectFirstWord == fillBlankFirstWord;
        }
        return false;
      });

      // Only add if there's no matching question
      if (!hasMatchingQuestion) {
        generatedQuestions.add(fillInTheBlankQuestions[i]);
      }
    }

    _updateTargetProgress(0.90);
    await _safeDelay(150);

    // Final questions
    for (int i = 0;
        i < fillInTheBlankQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Check for matches with drag_drop and what_next questions
      bool hasMatchingQuestion = generatedQuestions.any((q) {
        if (q['type'] == 'fill_blank') {
          return fillInTheBlankQuestions[i]['correctAnswers']
              .contains(q['correctAnswers'].first);
        }
        return false;
      });

      // Only add if there's no matching question
      if (!hasMatchingQuestion) {
        generatedQuestions.add(fillInTheBlankQuestions[i]);
      }
    }

    _updateTargetProgress(0.95);
    await _safeDelay(150);

    // Shuffle verse pairing questions
    versePairingQuestions.shuffle();

    // Add verse pairing questions (allocate ~30% of quiz to this type)
    int pairingCount = min(6, versePairingQuestions.length);
    generatedQuestions.addAll(versePairingQuestions.take(pairingCount));

    return generatedQuestions;
  }

  // Helper method for safe delays with lifecycle checks
  Future<void> _safeDelay(int milliseconds) async {
    if (!mounted || !_isActive) return;
    await Future.delayed(Duration(milliseconds: milliseconds));
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
      String verse) async {
    try {
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      // Create a map to track word frequencies
      Map<String, int> wordFrequency = {};
      for (String word in words) {
        wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
      }

      // Determine number of blanks based on verse length
      int numberOfBlanks = words.length >= 18
          ? 3
          : words.length >= 10
              ? 2
              : 1;

      // Keep track of missing words and their indices
      List<String> missingWords = [];
      List<int> missingIndices = [];

      // Generate unique random indices for blanks
      while (missingIndices.length < numberOfBlanks) {
        int index = Random().nextInt(words.length);

        // Skip if word is a special character or already selected or appears multiple times
        if (missingIndices.contains(index) ||
            wordFrequency[words[index]]! > 1) {
          continue;
        }

        missingIndices.add(index);
      }

      // Sort indices to maintain original word order
      missingIndices.sort();

      // Add words in correct order
      missingWords = missingIndices.map((index) => words[index]).toList();
      print('Selected missing words: $missingWords');

      // Create verse with blanks
      List<String> verseWithBlanks = List.from(words);
      for (int i = 0; i < missingIndices.length; i++) {
        verseWithBlanks[missingIndices[i]] = '____';
      }

      // Create a map to store options for each correct word
      Map<String, List<String>> wordOptions = {};

      // Number of options to generate per word
      final int optionsPerWord = 5; // Generate 5 options per word

      try {
        // Generate options for each missing word
        for (String missingWord in missingWords) {
          // Initialise options list for this word with the correct answer
          List<String> wordOptionsList = [missingWord];

          // Create context by replacing the current blank with a placeholder
          String context = verse;

          // Get AI-generated wrong options
          List<String> aiOptions = await OpenAIService.generateWrongOptions(
            correctWord: missingWord,
            context: context,
            numberOfOptions: optionsPerWord,
          );

          // Add AI options if available
          if (aiOptions.isNotEmpty) {
            print(
                'Received ${aiOptions.length} AI-generated options for $missingWord: $aiOptions');
            wordOptionsList.addAll(aiOptions);
          } else {
            print('No AI-generated options received for word: $missingWord');
            // Fallback to random words for this specific word
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
        print('Error using OpenAI for options: $e');
        // Fallback to the original method if OpenAI fails
        print('Falling back to random word selection for all words');

        for (String missingWord in missingWords) {
          List<String> randomOptions =
              getRandomWords([missingWord], verse, optionsPerWord);
          List<String> wordOptionsList = [missingWord, ...randomOptions];
          wordOptionsList.shuffle();
          wordOptions[missingWord] = wordOptionsList;
        }
      }

      // For debugging
      print('Word options map: $wordOptions');

      return {
        'type': 'fill_blank',
        'question': numberOfBlanks > 1
            ? "Fill in the missing words:"
            : "Fill in the missing word:",
        'verseWords': verseWithBlanks,
        'wordOptions':
            wordOptions, // New format: options organised by correct word
        'correctAnswers': missingWords,
        'missingIndices': missingIndices,
      };
    } catch (e) {
      print('Error generating fill-in-the-blank question: $e');
      // Provide a fallback question if there's an error
      return {
        'type': 'fill_blank',
        'question': "Fill in the missing word:",
        'verseWords': [verse],
        'wordOptions': {
          'Option 1': ['Option 1', 'Option 2', 'Option 3', 'Option 4']
        },
        'correctAnswers': ['Option 1'],
        'missingIndices': [0],
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
      // Get app primary color from the app's theme (matching homepage)
      final primaryColor = Color.fromARGB(255, 73, 121, 251);

      return Scaffold(
        backgroundColor: Colors.white,
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
              color: Colors.black,
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
                SizedBox(height: 40),

                // Simplified animation area - just a pulsing central element
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsing circle
                        AnimatedBuilder(
                          animation: _loadingAnimationController!,
                          builder: (context, child) {
                            return Container(
                              width: 200 +
                                  (_loadingAnimationController!.value * 20),
                              height: 200 +
                                  (_loadingAnimationController!.value * 20),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.03),
                              ),
                            );
                          },
                        ),

                        // Middle pulsing circle
                        AnimatedBuilder(
                          animation: _loadingAnimationController!,
                          builder: (context, child) {
                            return Container(
                              width: 160 +
                                  (_loadingAnimationController!.value * 15),
                              height: 160 +
                                  (_loadingAnimationController!.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withOpacity(0.08),
                              ),
                            );
                          },
                        ),

                        // Inner circle with icon
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.2),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.quiz_outlined,
                              size: 60,
                              color: primaryColor,
                            ),
                          ),
                        ),

                        // Rotating circle around the main icon
                        AnimatedBuilder(
                          animation: _rotationAnimationController!,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle:
                                  _rotationAnimationController!.value * 2 * pi,
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

                // Animated message with fade transition
                AnimatedOpacity(
                  opacity: _isLoadingText ? 1.0 : 0.0,
                  duration: Duration(milliseconds: 500),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      _loadingMessages[_currentMessageIndex],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),

                Spacer(),
                // Enhanced progress indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10),
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
                      SizedBox(height: 10),
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
                            duration: Duration(milliseconds: 300),
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

                SizedBox(height: 40),

                // Tip message in card format similar to home page
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade100,
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(20),
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
                          SizedBox(width: 8),
                          Text(
                            "Quiz Tip",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
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
