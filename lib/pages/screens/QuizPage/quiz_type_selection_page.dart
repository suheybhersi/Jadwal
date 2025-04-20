import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizTypeSelectionPage extends StatefulWidget {
  final int startSurahNumber;
  final int endSurahNumber;
  final int startVerse;
  final int endVerse;
  final String quizId;
  final String reviewTitle;

  const QuizTypeSelectionPage({
    super.key,
    required this.startSurahNumber,
    required this.endSurahNumber,
    required this.startVerse,
    required this.endVerse,
    required this.quizId,
    required this.reviewTitle,
  });

  @override
  State<QuizTypeSelectionPage> createState() => _QuizTypeSelectionPageState();
}

class _QuizTypeSelectionPageState extends State<QuizTypeSelectionPage> {
  // Question type selection
  bool _includeFillBlank = true;
  bool _includeDragDrop = true;
  bool _includeWhatNext = true;
  bool _includeVersePairing = true;

  // Loading state
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color.fromARGB(255, 73, 121, 251);
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Select Question Types',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                primaryColor.withOpacity(0.8),
                                primaryColor,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.clipboard_text,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Select Question Types for Your Quiz',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Choose the types of questions you want to include in your quiz.',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Fill in the Blank
                        _buildQuestionTypeCard(
                          icon: Iconsax.document_text,
                          title: 'Fill in the Blank',
                          description:
                              'Complete verses by filling in missing words.',
                          isSelected: _includeFillBlank,
                          onToggle: (value) {
                            setState(() {
                              _includeFillBlank = value;
                            });
                          },
                        ),

                        // Drag and Drop
                        _buildQuestionTypeCard(
                          icon: Iconsax.hierarchy_square_3,
                          title: 'Drag and Drop',
                          description:
                              'Arrange words in the correct order to form complete verses.',
                          isSelected: _includeDragDrop,
                          onToggle: (value) {
                            setState(() {
                              _includeDragDrop = value;
                            });
                          },
                        ),

                        // What Comes Next
                        _buildQuestionTypeCard(
                          icon: Iconsax.arrow_right,
                          title: 'What Comes Next',
                          description:
                              'Choose the correct verse that follows the given verse.',
                          isSelected: _includeWhatNext,
                          onToggle: (value) {
                            setState(() {
                              _includeWhatNext = value;
                            });
                          },
                        ),

                        // Verse Pairing
                        _buildQuestionTypeCard(
                          icon: Iconsax.link,
                          title: 'Verse Pairing',
                          description:
                              'Match related verses together correctly.',
                          isSelected: _includeVersePairing,
                          onToggle: (value) {
                            setState(() {
                              _includeVersePairing = value;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // Warning when no type is selected
                        if (!_isAnyTypeSelected())
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Please select at least one question type',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Error message when verse fetching fails
                        if (_errorMessage.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: Colors.red.shade800,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.red.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Start Quiz Button
              _buildStartQuizButton(primaryColor),
            ],
          ),

          // Loading overlay
          if (_isLoading) _buildLoadingOverlay(primaryColor, textColor),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isSelected,
    required Function(bool) onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isSelected
              ? const Color.fromARGB(255, 73, 121, 251).withOpacity(0.5)
              : Colors.grey.withOpacity(0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => onToggle(!isSelected),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color.fromARGB(255, 73, 121, 251)
                      : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSelected,
                onChanged: onToggle,
                activeColor: const Color.fromARGB(255, 73, 121, 251),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartQuizButton(Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isAnyTypeSelected() && !_isLoading
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _isAnyTypeSelected() && !_isLoading
              ? _fetchVersesAndCreateQuiz
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade500,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Iconsax.play, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Create Quiz',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay(Color primaryColor, Color textColor) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 30),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  color: primaryColor,
                  strokeWidth: 5,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Preparing your quiz...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This might take a moment',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isAnyTypeSelected() {
    return _includeFillBlank ||
        _includeDragDrop ||
        _includeWhatNext ||
        _includeVersePairing;
  }

  Future<void> _fetchVersesAndCreateQuiz() async {
    if (!_isAnyTypeSelected()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Fetch verses from Firestore
      final List<dynamic> versesList = await _fetchVerses(
          widget.startSurahNumber,
          widget.startVerse,
          widget.endSurahNumber,
          widget.endVerse);

      if (!mounted) return;

      if (versesList.isEmpty) {
        setState(() {
          _errorMessage = 'No verses found in the selected range';
          _isLoading = false;
        });
        return;
      }

      // Navigate to the quiz page with our selected question types
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            versesList: versesList,
            reviewTitle: widget.reviewTitle,
            review: 'custom',
            id: widget.quizId,
            updateReview: (id, title, review) {
              // For custom quizzes, we don't need to update anything in Firestore
            },
            includeFillBlank: _includeFillBlank,
            includeDragDrop: _includeDragDrop,
            includeWhatNext: _includeWhatNext,
            includeVersePairing: _includeVersePairing,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Error creating quiz: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Fetch verses from Firestore based on surah and verse range
  Future<List<dynamic>> _fetchVerses(int startSurahNumber, int startVerse,
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
}
