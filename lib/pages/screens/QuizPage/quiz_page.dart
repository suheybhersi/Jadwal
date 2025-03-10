import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jadwal/pages/screens/QuizPage/build_verse_question.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_intro_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_results_page.dart';
import 'package:jadwal/pages/screens/QuizPage/what_comes_next_question.dart';
import 'package:jadwal/pages/screens/QuizPage/fill_blank_question.dart';
import 'package:jadwal/services/openai_service.dart';

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

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = -1;
  int score = 0;
  late List<Map<String, dynamic>> questions = [];
  Map<int, Map<String, dynamic>> answeredQuestions = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final generatedQuestions = await _generateQuestions();
    setState(() {
      questions = generatedQuestions..shuffle();
    });
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

  Future<List<Map<String, dynamic>>> _generateQuestions() async {
    List<Map<String, dynamic>> generatedQuestions = [];

    // Generate fill in the blank questions
    List<Map<String, dynamic>> fillInTheBlankQuestions = [];
    List<Map<String, dynamic>> dragAndDropQuestions = [];
    List<Map<String, dynamic>> whatComesNextQuestions = [];

    for (int i = 0; i < widget.versesList.length; i++) {
      String verse = widget.versesList[i];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      // Generate what comes next questions
      if (i < widget.versesList.length - 1) {
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(i));
      }

      // Only add fill in the blank for verses with more than 1 word
      if (!words.contains('')) {
        // Use await here since _generateFillInTheBlankQuestion is now async
        fillInTheBlankQuestions
            .add(await _generateFillInTheBlankQuestion(verse));
      }

      // Only add drag and drop for verses between 2 and 7 words
      if (!words.contains('') && words.length < 15) {
        dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
      }
    }

    dragAndDropQuestions.shuffle();
    fillInTheBlankQuestions.shuffle();
    whatComesNextQuestions.shuffle();

    // Add drag and drop questions
    generatedQuestions.addAll(dragAndDropQuestions.length > 7
        ? dragAndDropQuestions.take(7)
        : dragAndDropQuestions);

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

    return generatedQuestions;
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
          // Initialize options list for this word with the correct answer
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
            wordOptions, // New format: options organized by correct word
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

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while questions are being loaded
    if (questions.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  "Generating questions...",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
