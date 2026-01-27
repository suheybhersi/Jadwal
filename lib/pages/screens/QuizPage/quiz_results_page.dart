import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:get/get.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_controller.dart';

class QuizResultsPage extends StatefulWidget {
  final int score;
  final List<Map<String, dynamic>> questions;
  final String id;
  final String review;
  final Function(String, String, String) updateReview;
  final Map<int, Map<String, dynamic>> answeredQuestions;
  final int currentQuestionIndex;
  final bool isCustomQuiz;

  const QuizResultsPage({
    super.key,
    required this.score,
    required this.questions,
    required this.id,
    required this.review,
    required this.updateReview,
    required this.answeredQuestions,
    required this.currentQuestionIndex,
    this.isCustomQuiz = false,
  });

  @override
  State<QuizResultsPage> createState() => QuizResultsPageState();
}

class QuizResultsPageState extends State<QuizResultsPage> {
  bool showAllQuestions = false;
  bool _isSaving = false;

  // Function to save quiz results to Firestore
  Future<void> _saveQuizResultsToFirestore() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Get FirestoreService instance
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      // Format date as DD-MM-YYYY
      String dateCompleted = DateTime.now().toString().split(' ')[0];
      final dateComponents = dateCompleted.split('-');
      dateCompleted =
          '${dateComponents[2]}-${dateComponents[1]}-${dateComponents[0]}';

      // Save quiz history using FirestoreService
      await firestoreService.saveQuizHistory(
        dateCompleted: dateCompleted,
        isCustomQuiz: widget.isCustomQuiz,
        score: widget.score,
        totalQuestions: widget.questions.length,
        questions: widget.questions,
        answeredQuestions: widget.answeredQuestions
            .map((key, value) => MapEntry(key.toString(), value)),
        quizId: widget.id,
        quizContent: widget.review,
      );
    } catch (e) {
      // Handle errors
      debugPrint('Error saving quiz results: $e');
      // Could show a snackbar here if needed
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  String joinVerseManuallyWithSpecialChars(List<String> words) {
    const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
    List<String> processedWords = [];

    for (String word in words) {
      // Check if the word contains a special character
      if (specialChars.any((char) => word.contains(char))) {
        // Extract the special character
        String specialChar = '';
        for (String char in specialChars) {
          if (word.contains(char)) {
            specialChar = char;
            break;
          }
        }
        // Remove the special character and add it to the end
        String cleanWord = word.replaceAll(specialChar, '');
        processedWords.add(
            '$cleanWord $specialChar'); // Removed space before special char
      } else {
        processedWords.add(word);
      }
    }

    return processedWords
        .join(' ')
        .replaceAll('  ', ' ')
        .trim(); // Remove any double spaces
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (widget.score / widget.questions.length) * 100;
    String resultMessage;
    Color resultColor;
    IconData resultIcon;

    if (percentage >= 90) {
      resultMessage = 'Excellent! You mastered it!';
      resultColor = Colors.green.shade700;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 70) {
      resultMessage = 'Very good! Keep it up!';
      resultColor = Colors.blue.shade700;
      resultIcon = Icons.thumb_up;
    } else if (percentage >= 50) {
      resultMessage = 'Good effort! Practice more!';
      resultColor = Colors.amber.shade700;
      resultIcon = Icons.trending_up;
    } else {
      resultMessage = 'Keep practicing! You can do better!';
      resultColor = Colors.red.shade700;
      resultIcon = Icons.refresh;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header with close button
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () {
                      if (widget.isCustomQuiz) {
                        // For custom quizzes, pop until we reach the quiz history page
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      } else {
                        // For regular quizzes, just pop once
                        Navigator.pop(context);
                      }
                    },
                    icon: const Icon(Icons.close),
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  Text(
                    'Results',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the header
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),

                      // Title with decorative element
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 32,
                            decoration: BoxDecoration(
                              color: resultColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Quiz Completed!',
                              style: GoogleFonts.poppins(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      Text(
                        resultMessage,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: resultColor,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 32),

                      // Score card with animation - redesigned and smaller
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              resultColor.withValues(alpha: 0.7),
                              resultColor,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: resultColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Left side - Icon and label
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                resultIcon,
                                size: 32,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Middle - Score text
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Your Score',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${widget.score}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        '/${widget.questions.length}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Right side - Percentage indicator
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 60,
                                    height: 60,
                                    child: CircularProgressIndicator(
                                      value: widget.score /
                                          widget.questions.length,
                                      strokeWidth: 8,
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.2),
                                      valueColor:
                                          const AlwaysStoppedAnimation<Color>(
                                              Colors.white),
                                    ),
                                  ),
                                  Text(
                                    '${(percentage).toInt()}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Question Review Section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Show All / Hide All button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question Review',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showAllQuestions =
                                        !showAllQuestions; // Toggle the state
                                  });
                                },
                                child: Text(
                                  showAllQuestions ? 'Hide All' : 'Show All',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // List of questions with status
                          Column(
                            children: List.generate(
                              showAllQuestions ? widget.questions.length : 3,
                              (index) {
                                final question = widget.questions[index];
                                final isCorrect = widget
                                    .answeredQuestions[index]!['is_correct'];

                                return _buildQuestionItem(
                                  context: context,
                                  index: index,
                                  question: question,
                                  isCorrect: isCorrect,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          String rating =
                              ((widget.score / widget.questions.length) * 5)
                                  .round()
                                  .toString();
                          widget.updateReview(widget.id, widget.review, rating);
                          await _saveQuizResultsToFirestore();
                          if (!mounted) return;
                          if (!context.mounted) return;
                          if (widget.isCustomQuiz) {
                            // Reset quiz creation state
                            final controller =
                                Get.find<QuizCreationController>();
                            controller.resetAllState();
                            // Pop until we reach the quiz history page
                            Navigator.of(context)
                                .popUntil((route) => route.isFirst);
                          } else {
                            // For regular quizzes, just pop once
                            Navigator.pop(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _isSaving
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Finish',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionItem({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> question,
    required bool isCorrect,
  }) {
    // Get question text based on question type
    String questionText = '';
    if (question['type'] == 'fill_blank') {
      questionText = 'Fill in the blank';
    } else if (question['type'] == 'what_next') {
      questionText = 'What comes next';
    } else if (question['type'] == 'drag_drop') {
      questionText = 'Arrange the verse';
    } else if (question['type'] == 'verse_pairing') {
      questionText = 'What comes before and after';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isCorrect ? Colors.green.shade800 : Colors.red.shade800,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _showQuestionDetailsDialog(context, question, index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCorrect
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check : Icons.close,
                  color: isCorrect ? Colors.green : Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),

              // Question info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Question ${index + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    Text(
                      questionText,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .inversePrimary
                            .withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Tap to view indicator
              Icon(
                Icons.info_outline,
                size: 20,
                color: Theme.of(context)
                    .colorScheme
                    .inversePrimary
                    .withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuestionDetailsDialog(
      BuildContext context, Map<String, dynamic> question, int index) {
    final isCorrect = widget.answeredQuestions[index]!['is_correct'];

    // Determine question type and extract relevant information
    String questionTitle = '';
    String questionContent = '';
    String userAnswer = '';
    String correctAnswer = '';

    if (question['type'] == 'fill_blank') {
      questionTitle = 'Fill in the blank';
      List<String> correctAnswers =
          List<String>.from(question['correctAnswers']);

      // Create verse with blanks
      List<String> verseWithBlanks = List.from(question['verseWords']);
      for (int i = 0; i < question['missingIndices'].length; i++) {
        verseWithBlanks[question['missingIndices'][i]] = '____';
      }
      questionContent = joinVerseManuallyWithSpecialChars(verseWithBlanks);

      // User's answers if available
      List<String> userAnswers =
          List<String>.from(widget.answeredQuestions[index]!['user_answer']);

      // Format for display
      userAnswer =
          userAnswers.isEmpty ? 'Not answered' : userAnswers.join(', ');
      correctAnswer = correctAnswers.join(', ');
    } else if (question['type'] == 'what_next') {
      questionTitle = 'What comes next';
      questionContent = question['verse'];
      correctAnswer = question['correctAnswer'];
      userAnswer =
          widget.answeredQuestions[index]!['user_answer'] ?? 'Not answered';
    } else if (question['type'] == 'drag_drop') {
      questionTitle = 'Arrange the verse';
      questionContent = '${question['firstWord']} ...';
      correctAnswer = question['correctOrder'].join(' ');

      // For drag and drop, user answers might be in a different format
      userAnswer = widget.answeredQuestions[index]!['user_answer'].join(' ') ??
          'Not attempted';
    } else if (question['type'] == 'verse_pairing') {
      questionTitle = 'What comes before and after';
      questionContent = question['currentVerse'];
      correctAnswer =
          '${question['verseBefore']} ... ${question['verseAfter']}';
      userAnswer =
          '${widget.answeredQuestions[index]!['userAnswerBefore']} ... ${widget.answeredQuestions[index]!['userAnswerAfter']}';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                'Question ${index + 1}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isCorrect ? 'Correct' : 'Incorrect',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color:
                      isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Question type
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  questionTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Question content
              Text(
                'Question:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                questionContent,
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),

              // User's answer
              Text(
                'Your Answer:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                userAnswer,
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 16,
                  color:
                      isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 16),

              // Correct answer
              Text(
                'Correct Answer:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correctAnswer,
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 16,
                  color: Colors.green.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
