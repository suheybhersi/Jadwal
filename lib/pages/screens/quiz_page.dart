import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/components/build_verse_question.dart';
import 'package:hifdh_planner_app/components/what_comes_next_question.dart';
import 'package:hifdh_planner_app/components/fill_blank_question.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> versesList;
  final String reviewTitle;
  final String id;
  final Function(String, String, String) updateReview;

  const QuizPage({
    super.key,
    required this.versesList,
    required this.reviewTitle,
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
  Map<int, List<String>> answeredQuestions = {};

  @override
  void initState() {
    super.initState();
    questions = generateQuestions()..shuffle();
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

  List<Map<String, dynamic>> generateQuestions() {
    //split up the types of questions
    List<Map<String, dynamic>> generatedQuestions = [];
    List<Map<String, dynamic>> fillInTheBlankQuestions = [];
    List<Map<String, dynamic>> whatComesNextQuestions = [];
    List<Map<String, dynamic>> dragAndDropQuestions = [];

    for (int i = 0; i < widget.versesList.length; i++) {
      String verse = widget.versesList[i];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      if (i < widget.versesList.length - 1) {
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(i));
      }

      // Only add fill in the blank for verses with more than 1 word
      if (!words.contains('')) {
        fillInTheBlankQuestions.add(_generateFillInTheBlankQuestion(verse));
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

  Map<String, dynamic> _generateFillInTheBlankQuestion(String verse) {
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
      if (missingIndices.contains(index) || wordFrequency[words[index]]! > 1) {
        continue;
      }

      missingIndices.add(index);
    }

    // Sort indices to maintain original word order
    missingIndices.sort();

    // Add words in correct order
    missingWords = missingIndices.map((index) => words[index]).toList();

    // Create verse with blanks
    List<String> verseWithBlanks = List.from(words);
    for (int i = 0; i < missingIndices.length; i++) {
      verseWithBlanks[missingIndices[i]] = '____';
    }

    return {
      'type': 'fill_blank',
      'question': numberOfBlanks > 1
          ? "Fill in the missing words:"
          : "Fill in the missing word:",
      'verseWords': verseWithBlanks,
      'options': [
        ...missingWords,
        ...getRandomWords(missingWords, verse, numberOfBlanks)
      ]..shuffle(),
      'correctAnswers': missingWords,
      'missingIndices': missingIndices,
    };
  }

  Map<String, dynamic> _generateWhatComesNextQuestion(int index) {
    return {
      'type': 'what_next',
      'question': "What verse comes after this?",
      'verse': widget.versesList[index],
      'options': [widget.versesList[index + 1], ...getRandomVerses(index)]
        ..shuffle(),
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
    if (currentQuestionIndex == -1) {
      return _buildIntroScreen();
    }

    if (currentQuestionIndex >= questions.length) {
      return _buildResultScreen();
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
                    onClose: () => Navigator.pop(context),
                  )
                : BuildVerseQuestion(
                    currentQuestionIndex: currentQuestionIndex,
                    questions: questions,
                    onNextQuestion: (int index) {
                      setState(() {
                        score++;
                        currentQuestionIndex = index;
                      });
                    },
                    answeredQuestions: answeredQuestions,
                    onClose: () => Navigator.pop(context),
                  ),
      ),
    );
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Close Button
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      'Welcome to the Quiz!',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    Text(
                      'Test your knowledge and see how well you do. Complete all questions and challenge yourself!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    // Updated box with verses
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    Icon(Icons.school, size: 60, color: Colors.blue.shade700),
                    const SizedBox(height: 16),
                    Text(
                      widget.reviewTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Start Button at bottom
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => currentQuestionIndex = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Start Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Text(
            'Quiz Completed! Your Score: $score/${questions.length}',
            style: GoogleFonts.poppins(fontSize: 24),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
