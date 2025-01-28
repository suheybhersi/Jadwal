import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> versesList;
  final String reviewTitle;
  final String id;
  final Function(String, String, String) updateReview;

  const QuizPage({
    Key? key,
    required this.versesList,
    required this.reviewTitle,
    required this.id,
    required this.updateReview,
  }) : super(key: key);

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = -1;
  int score = 0;
  late List<Map<String, dynamic>> questions = [];

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
        processedWords[processedWords.length - 1] += " ${words[i]}";
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
      String fillBlankFirstWord = splitVerseManuallyWithSpecialChars(
              fillInTheBlankQuestions[i]['verse'])
          .first;

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
          return fillInTheBlankQuestions[i]['correctAnswer'] ==
              q['correctAnswer'];
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
    int missingIndex = Random().nextInt(words.length);
    String missingWord = words[missingIndex];
    words[missingIndex] = '____';

    return {
      'type': 'fill_blank',
      'question': "Fill in the missing word:",
      'verse': words.join(' '),
      'options': [missingWord, ...getRandomWords(verse)]..shuffle(),
      'correctAnswer': missingWord,
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
    };
  }

  List<String> getRandomWords(String currentVerse) {
    List<String> allWords = widget.versesList
        .where((verse) => verse != currentVerse)
        .expand((verse) => splitVerseManuallyWithSpecialChars(verse))
        .toList();
    allWords.shuffle();
    return allWords.take(3).toList();
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
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: currentQuestion['type'] == 'fill_blank'
              ? _buildFillInTheBlankQuestion(currentQuestion)
              : currentQuestion['type'] == 'what_next'
                  ? _buildWhatComesNextQuestion(currentQuestion)
                  : _buildClickToSelectQuestion(currentQuestion),
        ),
      ),
    );
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.quiz, size: 50, color: Colors.blue.shade700),
              const SizedBox(height: 20),
              Text(
                'Review Quiz',
                style: GoogleFonts.poppins(
                    fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Test your memorization for: "${widget.reviewTitle}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    currentQuestionIndex++;
                  });
                },
                child: const Text('Start Quiz',
                    style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      body: Center(
        child: Text(
          'Quiz Completed! Your Score: $score/${questions.length}',
          style: GoogleFonts.poppins(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFillInTheBlankQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: (currentQuestionIndex + 1) / questions.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 30),
        Text(
          question['question'],
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            question['verse'],
            style: GoogleFonts.scheherazadeNew(fontSize: 22, height: 1.5),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 20),
        ...question['options'].map<Widget>((option) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ElevatedButton(
              onPressed: () {
                if (option == question['correctAnswer']) {
                  score++;
                }
                setState(() {
                  currentQuestionIndex++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              child: Text(
                option,
                style: GoogleFonts.scheherazadeNew(fontSize: 20),
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildWhatComesNextQuestion(Map<String, dynamic> question) {
    // Helper function to truncate the verse
    String truncateVerse(String verse, int maxLength) {
      if (verse.length > maxLength) {
        return '${verse.substring(0, maxLength)}...';
      }
      return verse;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Bar
        LinearProgressIndicator(
          value: (currentQuestionIndex + 1) / questions.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 30),

        // Question Text
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        // Display Verse with Truncation
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            truncateVerse(question['verse'], 60), // Truncate verse to 50 chars
            style: GoogleFonts.scheherazadeNew(
              fontSize: 22,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ),

        const SizedBox(height: 20),

        // Options
        ...question['options'].map<Widget>((option) {
          return Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ElevatedButton(
              onPressed: () {
                if (option == question['correctAnswer']) {
                  score++;
                }
                setState(() {
                  currentQuestionIndex++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue.shade700,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
              child: Text(
                truncateVerse(option, 60),
                style: GoogleFonts.scheherazadeNew(
                  fontSize: 20,
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildClickToSelectQuestion(Map<String, dynamic> question) {
    List<String> correctOrder = [
      question['firstWord'],
      ...question['correctOrder']
    ];
    List<String> shuffledWords = List.from(question['shuffledWords']);
    List<String> selectedWords = [question['firstWord']];

    return StatefulBuilder(
      builder: (context, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 30),
            Text(
              question['question'],
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    children: selectedWords.map((word) {
                      return GestureDetector(
                        onTap: () {
                          // Allow removal of words except the first word
                          if (word != question['firstWord']) {
                            setState(() {
                              selectedWords.remove(word);
                              shuffledWords.add(word);
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 20,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    runAlignment: WrapAlignment.start,
                    children: shuffledWords.map((word) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            shuffledWords.remove(word);
                            selectedWords.add(word);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    bool isCorrect =
                        selectedWords.join(' ') == correctOrder.join(' ');
                    if (isCorrect) {
                      setState(() {
                        score++;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Correct!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      setState(() {
                        currentQuestionIndex++;
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Incorrect, try again!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Check Answer',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
