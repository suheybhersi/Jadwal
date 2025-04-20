import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/components/verse_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jadwal/services/firestore.dart';

class QuizCreationPage extends StatefulWidget {
  const QuizCreationPage({super.key});

  @override
  State<QuizCreationPage> createState() => _QuizCreationPageState();
}

class _QuizCreationPageState extends State<QuizCreationPage> {
  // Services
  final FirestoreService _firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

  // Selection state
  String? _selectedStartSurahName;
  Map<String, dynamic>? _selectedStartSurahData;
  int? _selectedStartVerse;
  String? _selectedEndSurahName;
  Map<String, dynamic>? _selectedEndSurahData;
  int? _selectedEndVerse;

  // State tracking
  String _selectionErrorMessage = '';
  bool _isLoading = false;

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
          'Create Quiz',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getSurahsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading(primaryColor);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoData();
          }

          // Process surah data
          final surahsList = snapshot.data!.docs;
          surahsList.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
          final allData = surahsList
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          return Stack(
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
                            // Selected range summary
                            if (_isRangeSelected())
                              _buildRangeSummary(primaryColor),

                            // First verse selection
                            if (_selectedStartVerse == null)
                              _buildStartVerseSelection(
                                  allData, primaryColor, textColor),

                            // Second verse selection
                            if (_selectedStartVerse != null &&
                                (_selectedEndVerse == null ||
                                    _selectedStartVerse == _selectedEndVerse))
                              _buildEndVerseSelection(
                                  allData, primaryColor, textColor),

                            // Error message
                            if (_selectionErrorMessage.isNotEmpty)
                              _buildErrorMessage(),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Create Quiz Button
                  _buildCreateQuizButton(allData, primaryColor),
                ],
              ),

              // Loading overlay
              if (_isLoading) _buildLoadingOverlay(primaryColor, textColor),
            ],
          );
        },
      ),
    );
  }

  bool _isRangeSelected() {
    return _selectedStartSurahName != null &&
        _selectedStartVerse != null &&
        _selectedEndSurahName != null &&
        _selectedEndVerse != null &&
        (_selectedEndVerse != _selectedStartVerse ||
            _selectedEndSurahName != _selectedStartSurahName) &&
        _selectionErrorMessage.isEmpty;
  }

  bool _canCreateQuiz() {
    return !_isLoading && _isRangeSelected();
  }

  Widget _buildLoading(Color primaryColor) {
    return Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  Widget _buildNoData() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.information,
            size: 60,
            color: Colors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No surahs data available',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSummary(Color primaryColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Iconsax.tick_circle,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quiz Range Selected',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'FROM',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_selectedStartSurahName',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Verse $_selectedStartVerse',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'TO',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$_selectedEndSurahName',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Verse $_selectedEndVerse',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _resetSelection,
            icon: Icon(Iconsax.edit, size: 16, color: Colors.white),
            label: Text(
              'Change Selection',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _resetSelection() {
    setState(() {
      _selectedEndSurahName = null;
      _selectedEndSurahData = null;
      _selectedEndVerse = null;
      _selectedStartSurahName = null;
      _selectedStartSurahData = null;
      _selectedStartVerse = null;
      _selectionErrorMessage = '';
    });
  }

  Widget _buildStartVerseSelection(
      List<Map<String, dynamic>> allData, Color primaryColor, Color textColor) {
    return Column(
      children: [
        // Instructions container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.book_1,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Select Start Verse',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Verse picker
        _buildVersePicker(
          allData,
          _selectedStartSurahData,
          _selectedStartVerse,
          (surahName, verseNumber) =>
              _handleStartVerseSelection(allData, surahName, verseNumber),
        ),
      ],
    );
  }

  void _handleStartVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    setState(() {
      // Find the full surah data
      final selectedSurah =
          allData.firstWhere((surah) => surah['surah'] == surahName);

      _selectedStartSurahName = surahName;
      _selectedStartSurahData = selectedSurah;
      _selectedStartVerse = verseNumber;
      _selectionErrorMessage = '';

      // Reset end verse if necessary
      if (_selectedEndSurahName == surahName &&
          _selectedEndVerse != null &&
          _selectedEndVerse! < verseNumber) {
        _selectedEndVerse = verseNumber;
      } else if (_selectedEndSurahName != surahName) {
        // If different surah is selected, reset end surah
        _selectedEndSurahName = surahName;
        _selectedEndSurahData = selectedSurah;
        _selectedEndVerse = verseNumber;
      }
    });
  }

  Widget _buildEndVerseSelection(
      List<Map<String, dynamic>> allData, Color primaryColor, Color textColor) {
    return Column(
      children: [
        // Instructions container
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.bookmark,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Select End Verse',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Verse picker
        _buildVersePicker(
          allData,
          _selectedEndSurahData ?? _selectedStartSurahData,
          _selectedEndVerse ?? _selectedStartVerse,
          (surahName, verseNumber) =>
              _handleEndVerseSelection(allData, surahName, verseNumber),
        ),
      ],
    );
  }

  void _handleEndVerseSelection(
      List<Map<String, dynamic>> allData, String surahName, int verseNumber) {
    setState(() {
      // Find the full surah data
      final selectedSurah =
          allData.firstWhere((surah) => surah['surah'] == surahName);

      // Set the end selection
      _selectedEndSurahName = surahName;
      _selectedEndSurahData = selectedSurah;
      _selectedEndVerse = verseNumber;
      _selectionErrorMessage = '';

      // Validate selection
      _validateSelection();
    });
  }

  Widget _buildVersePicker(
    List<Map<String, dynamic>> allData,
    Map<String, dynamic>? selectedSurahData,
    int? selectedVerse,
    Function(String, int) onVerseSelected,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: QuranVersePicker(
        surahData: allData,
        initialSurahIndex:
            selectedSurahData != null ? allData.indexOf(selectedSurahData) : 0,
        initialVerseNumber: selectedVerse,
        onVerseSelected: onVerseSelected,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.error_outline,
              color: Colors.red.shade800,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _selectionErrorMessage,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.red.shade800,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateQuizButton(
      List<Map<String, dynamic>> allData, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: _canCreateQuiz()
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
          onPressed: _canCreateQuiz() ? () => _createQuiz(allData) : null,
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

  // Validate that the verse selection makes sense
  void _validateSelection() {
    if (_selectedStartSurahName == null ||
        _selectedStartVerse == null ||
        _selectedEndSurahName == null ||
        _selectedEndVerse == null) {
      return;
    }

    // Compare surah numbers
    int startSurahNumber = _selectedStartSurahData!['surahNumber'];
    int endSurahNumber = _selectedEndSurahData!['surahNumber'];

    if (startSurahNumber > endSurahNumber) {
      _selectionErrorMessage = 'End surah cannot come before start surah';
      return;
    }

    if (startSurahNumber == endSurahNumber &&
        _selectedStartVerse! > _selectedEndVerse!) {
      _selectionErrorMessage = 'End verse cannot come before start verse';
      return;
    }

    _selectionErrorMessage = '';
  }

  // Create quiz and navigate to quiz page
  Future<void> _createQuiz(List<Map<String, dynamic>> allData) async {
    if (_selectedStartSurahName == null ||
        _selectedStartVerse == null ||
        _selectedEndSurahName == null ||
        _selectedEndVerse == null) {
      setState(() {
        _selectionErrorMessage = 'Please select start and end verses';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get surah numbers from selected data
      final int startSurahNumber = _selectedStartSurahData!['surahNumber'];
      final int endSurahNumber = _selectedEndSurahData!['surahNumber'];
      final int startVerse = _selectedStartVerse!;
      final int endVerse = _selectedEndVerse!;

      // Create a temporary ID for the quiz
      final String quizId =
          "custom_quiz_${DateTime.now().millisecondsSinceEpoch}";

      // Fetch verses from Firestore
      final List<dynamic> versesList = await _fetchVerses(
          startSurahNumber, startVerse, endSurahNumber, endVerse);

      // Create review title
      final String reviewTitle = startSurahNumber == endSurahNumber
          ? 'Quiz: $_selectedStartSurahName $startVerse-$endVerse'
          : 'Quiz: $_selectedStartSurahName $startVerse to $_selectedEndSurahName $endVerse';

      if (!mounted) return;

      // Navigate to the quiz page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizPage(
            versesList: versesList,
            reviewTitle: reviewTitle,
            review: 'custom',
            id: quizId,
            updateReview: (id, title, review) {
              // For custom quizzes, we don't need to update anything in Firestore
            },
          ),
        ),
      );
    } catch (e) {
      // Show error message
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating quiz: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      // Show error in UI
      setState(() {
        _selectionErrorMessage = 'Error fetching verses: ${e.toString()}';
      });
      return [];
    }
  }
}
