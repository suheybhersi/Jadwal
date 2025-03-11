import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class FillBlankQuestion extends StatefulWidget {
  final Map<String, dynamic> question;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Function(bool wasCorrect) onNext;
  final VoidCallback onClose;
  final Map<int, Map<String, dynamic>> answeredQuestions;

  const FillBlankQuestion({
    super.key,
    required this.question,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.onClose,
    required this.answeredQuestions,
  });

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion>
    with SingleTickerProviderStateMixin {
  List<String> chosenWords = [];
  bool isChecking = false;
  bool allCorrect = false;
  final Color primaryAccent = const Color(0xFF4979FB);

  // Track the currently selected blank index
  int? selectedBlankIndex;
  // Options for the currently selected blank
  List<String> currentBlankOptions = [];

  // Initialise controllers directly to avoid late initialisation errors
  AnimationController? _animationController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();

    // Initialise the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Set the animation after controller is initialised
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    // Initialise chosen words list
    _initializeChosenWords();

    // Automatically select the first blank after initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if there are any blanks
      List<String> words = widget.question['verseWords'];
      if (words.contains('____')) {
        // Directly set the first blank as selected
        setState(() {
          selectedBlankIndex = 0;
          _loadOptionsForBlank(0);
        });
      }
    });
  }

  void _initializeChosenWords() {
    // Initialise chosen words list based on already filled blanks
    List<String> words = widget.question['verseWords'];
    for (String word in words) {
      if (word != '____' && !chosenWords.contains(word)) {
        // Check if this word is one of the correct answers
        if (widget.question['correctAnswers'].contains(word)) {
          chosenWords.add(word);
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  bool isWordCorrect(String word, int index) {
    // Check if the index is valid
    if (index < 0 || index >= widget.question['correctAnswers'].length) {
      return false;
    }

    // Compare the word with the correct answer at this index
    String correctWord = widget.question['correctAnswers'][index];
    return correctWord == word;
  }

  void updateChosenWordsOrder() {
    List<String> words = widget.question['verseWords'];
    List<int> missingIndices =
        List<int>.from(widget.question['missingIndices']);

    // Create a map to store the filled words at their correct positions
    Map<int, String> filledWordsMap = {};

    // Find all filled blanks and map them to their positions in missingIndices
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (word != '____') {
        // Check if this position was originally a blank
        int missingIndexPosition = missingIndices.indexOf(i);
        if (missingIndexPosition != -1) {
          // This is a filled blank, store it with its position in correctAnswers
          filledWordsMap[missingIndexPosition] = word;
        }
      }
    }

    // Create a new ordered list of chosen words
    List<String> orderedChosenWords = [];
    for (int i = 0; i < missingIndices.length; i++) {
      if (filledWordsMap.containsKey(i)) {
        orderedChosenWords.add(filledWordsMap[i]!);
      }
    }

    chosenWords = orderedChosenWords;
  }

  void checkAnswers() {
    // Make sure chosen words are in the correct order
    updateChosenWordsOrder();

    // Check if all blanks are filled
    List<int> missingIndices =
        List<int>.from(widget.question['missingIndices']);
    if (chosenWords.length != missingIndices.length) {
      // Not all blanks are filled, so it can't be correct
      allCorrect = false;
    } else {
      // Check if all filled words are correct
      allCorrect = true;
      for (int i = 0; i < chosenWords.length; i++) {
        if (!isWordCorrect(chosenWords[i], i)) {
          allCorrect = false;
          break;
        }
      }
    }

    setState(() {
      isChecking = true;
      selectedBlankIndex = null; // Clear selected blank when checking
    });

    // Ensure animation controller is initialised before using it
    if (_animationController != null) {
      if (_animationController!.isAnimating) {
        _animationController!.stop();
      }
      _animationController!.reset();
      _animationController!.forward();
    }
  }

  // Handle selecting a blank
  void _handleBlankTap(int blankIndex) {
    if (isChecking) {
      return;
    }

    // If this blank is already selected, deselect it
    if (selectedBlankIndex == blankIndex) {
      setState(() {
        selectedBlankIndex = null;
        currentBlankOptions = [];
      });
    } else {
      // Otherwise, show options for this blank
      setState(() {
        selectedBlankIndex = blankIndex;
        _loadOptionsForBlank(blankIndex);
      });
    }
  }

  // Helper method to map a current blank index to the original correct answer index
  int _getCorrectAnswerIndexForBlank(int currentBlankIndex) {
    List<String> words = widget.question['verseWords'];
    List<int> missingIndices =
        List<int>.from(widget.question['missingIndices']);

    // Count blanks to find the corresponding missing index
    int blankCount = 0;
    int foundIndex = -1;

    for (int i = 0; i < words.length; i++) {
      if (words[i] == '____') {
        if (blankCount == currentBlankIndex) {
          // Find which original missing index this corresponds to
          for (int j = 0; j < missingIndices.length; j++) {
            if (missingIndices[j] == i) {
              foundIndex = j;
              break;
            }
          }
          break;
        }
        blankCount++;
      }
    }

    return foundIndex;
  }

  // Helper method to select the first available blank
  void _selectFirstAvailableBlank() {
    if (isChecking) return;

    List<String> words = widget.question['verseWords'];

    // Check if there are any blanks
    bool hasBlank = words.contains('____');

    if (!hasBlank) {
      return;
    }

    // Find the first blank position
    int firstBlankPosition = -1;
    for (int i = 0; i < words.length; i++) {
      if (words[i] == '____') {
        firstBlankPosition = i;
        break;
      }
    }

    // If we found a blank, select it
    if (firstBlankPosition != -1) {
      // The first blank should always have index 0
      setState(() {
        selectedBlankIndex = 0;
        _loadOptionsForBlank(0);
      });
    } else {}
  }

  // Handle selecting an option for the current blank
  void _handleOptionSelected(String option) {
    if (isChecking || selectedBlankIndex == null) return;

    // Get the current blank index
    int blankIndex = selectedBlankIndex!;

    // Find the verse index for the selected blank
    int verseBlankIndex = _findVerseIndexForBlank(blankIndex);

    if (verseBlankIndex != -1) {
      List<String> words = List<String>.from(widget.question['verseWords']);
      words[verseBlankIndex] = option;

      setState(() {
        widget.question['verseWords'] = words;
        if (!chosenWords.contains(option)) {
          chosenWords.add(option);
        }
        updateChosenWordsOrder();

        selectedBlankIndex = null; // Clear selection after filling
        currentBlankOptions = [];

        // Find and select the next available blank
        _selectNextAvailableBlank();
      });
    }
  }

  // Helper method to find and select the next available blank
  void _selectNextAvailableBlank() {
    // Simply use the first available blank method since it does the same thing
    _selectFirstAvailableBlank();
  }

  // Helper method to find the verse index for a given blank index
  int _findVerseIndexForBlank(int blankIndex) {
    List<String> words = widget.question['verseWords'];
    int currentBlankCount = 0;

    // Iterate through the verse words to find the blank at the specified index
    for (int i = 0; i < words.length; i++) {
      if (words[i] == '____') {
        if (currentBlankCount == blankIndex) {
          return i; // Found the blank at the specified index
        }
        currentBlankCount++;
      }
    }

    return -1; // Blank not found
  }

  // Helper method to select a blank at a specific position
  void _selectBlankAtPosition(int position) {
    if (isChecking) return;

    List<String> words = widget.question['verseWords'];

    // Make sure this position is a blank
    if (words[position] != '____') return;

    // Calculate the blank index and select it
    int blankIndex = _calculateBlankIndexForPosition(position);

    // Now select this blank and show options immediately
    setState(() {
      selectedBlankIndex = blankIndex;
      _loadOptionsForBlank(blankIndex);
    });
  }

  // Helper method to load options for a blank
  void _loadOptionsForBlank(int blankIndex) {
    // Get options for this blank
    int correctAnswerIndex = _getCorrectAnswerIndexForBlank(blankIndex);

    if (correctAnswerIndex != -1 &&
        correctAnswerIndex < widget.question['correctAnswers'].length) {
      // Get the correct word for this blank
      String correctWord =
          widget.question['correctAnswers'][correctAnswerIndex];

      // Get options for this specific word from the wordOptions map
      if (widget.question.containsKey('wordOptions') &&
          widget.question['wordOptions'] is Map &&
          widget.question['wordOptions'].containsKey(correctWord)) {
        // Use the options specific to this word
        currentBlankOptions =
            List<String>.from(widget.question['wordOptions'][correctWord]);
      } else if (widget.question.containsKey('options')) {
        // Fallback to the old format if needed
        currentBlankOptions = List<String>.from(widget.question['options']);
      } else {
        // Empty list as a last resort
        currentBlankOptions = [];
      }
    } else {
      // Fallback to empty list if we can't find the correct answer
      currentBlankOptions = [];
    }
  }

  // Helper method to calculate the blank index for a position
  int _calculateBlankIndexForPosition(int position) {
    List<String> words = widget.question['verseWords'];
    int blankCount = 0;

    // For the first blank at this position, the index should be 0
    // We only count blanks that come before this position
    for (int j = 0; j < position; j++) {
      if (words[j] == '____') {
        blankCount++;
      }
    }

    return blankCount;
  }

  // Helper method to remove a word and select the blank at that position
  void _removeWordAndSelectBlank(int position, String word) {
    if (isChecking) return;

    List<String> words = List<String>.from(widget.question['verseWords']);

    // Remove the word
    words[position] = '____';

    setState(() {
      widget.question['verseWords'] = words;
      chosenWords.remove(word);
    });

    // After the state is updated, select the blank at this position
    _selectBlankAtPosition(position);
  }

  @override
  Widget build(BuildContext context) {
    // Colors for question elements
    final textColor = Colors.grey.shade800;
    final containerBgColor = const Color(0xFFF5F9FF);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 24, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Iconsax.close_circle),
                color: Colors.grey.shade600,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Question ${widget.currentQuestionIndex + 1}/${widget.totalQuestions}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Fill in the Blanks',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.currentQuestionIndex + 1) /
                            widget.totalQuestions,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(primaryAccent),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Question text
                Text(
                  widget.question['question'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Verse container with highlighted blanks
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.35,
                  margin:
                      const EdgeInsets.only(bottom: 16), // Add margin at bottom
                  decoration: BoxDecoration(
                    color: containerBgColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                        spreadRadius: 1,
                      ),
                    ],
                    border: Border.all(
                      color: Colors.blue.shade100,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Verse title with gradient background
                      if (widget.question.containsKey('verseReference') &&
                          widget.question['verseReference'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                primaryAccent.withOpacity(0.1),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(24),
                              topRight: Radius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.book,
                                size: 16,
                                color: primaryAccent,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.question['verseReference'],
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: primaryAccent,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Verse content with scrolling
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Wrap(
                              alignment: WrapAlignment.start,
                              textDirection: TextDirection.rtl,
                              spacing: 8,
                              runSpacing: 16,
                              children: _buildVerseWords(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Show feedback message when checking answers
                if (isChecking)
                  Builder(
                    builder: (context) {
                      // Use a safer approach to animation
                      Widget feedbackContent = Container(
                        margin: const EdgeInsets.only(top: 20, bottom: 20),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: allCorrect
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: allCorrect
                                ? Colors.green.shade300
                                : Colors.red.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  allCorrect
                                      ? Iconsax.tick_circle5
                                      : Iconsax.close_circle5,
                                  color: allCorrect
                                      ? Colors.green.shade600
                                      : Colors.red.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  allCorrect ? 'Correct!' : 'Not quite right',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: allCorrect
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (!allCorrect)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 8, left: 36),
                                child: Text(
                                  'Check the highlighted words and try again next time',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );

                      // Try to use animation if it's working properly
                      try {
                        return _animationController != null
                            ? FadeTransition(
                                opacity: _fadeAnimation,
                                child: feedbackContent,
                              )
                            : feedbackContent;
                      } catch (e) {
                        // Fallback to no animation if there's an error
                        return feedbackContent;
                      }
                    },
                  ),

                // Show options for selected blank
                if (selectedBlankIndex != null && !isChecking) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Select the correct word:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: 100,
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: AdaptiveWordOptionsGrid(
                        options: currentBlankOptions,
                        isChecking: false,
                        isDark: false,
                        tertiaryColor: Colors.grey.shade200,
                        primaryAccent: primaryAccent,
                        onSelectOption: (option) =>
                            _handleOptionSelected(option.toString()),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Fixed position button at the bottom - only show when all blanks are filled or when checking
        if (!widget.question['verseWords'].contains('____') || isChecking)
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (!isChecking) {
                    // First click: Check answers
                    checkAnswers();
                  } else {
                    // Second click: Move to next question

                    widget.answeredQuestions[widget.currentQuestionIndex] = {
                      'user_answer': chosenWords,
                      'is_correct': allCorrect
                    };

                    // Safely handle animation
                    if (_animationController != null) {
                      if (_animationController!.isAnimating) {
                        _animationController!.stop();
                      }
                    }

                    // Use a try-catch to handle any animation errors
                    try {
                      if (_animationController != null) {
                        _animationController!.reverse().then((_) {
                          setState(() {
                            chosenWords = [];
                            isChecking = false;
                          });
                        });
                      }
                    } catch (e) {
                      // Fallback if animation fails
                      setState(() {
                        chosenWords = [];
                        isChecking = false;
                      });
                    }

                    widget.onNext(allCorrect);
                  }
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: isChecking
                      ? (allCorrect
                          ? Colors.green.shade600
                          : Colors.red.shade600)
                      : primaryAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  isChecking ? 'Continue' : 'Check Answer',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Build verse words with interactive blanks
  List<Widget> _buildVerseWords() {
    List<Widget> wordWidgets = [];
    List<String> words = widget.question['verseWords'];
    int blankCount = 0;

    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      bool isBlank = word == '____';
      bool isFilledWord =
          !isBlank && widget.question['correctAnswers'].contains(word);

      if (isBlank) {
        // This is a blank - get its index
        int currentBlankIndex = blankCount;
        blankCount++;

        // Check if this blank is selected
        bool isSelected = selectedBlankIndex == currentBlankIndex;

        // Define word colors based on state
        Color wordColor = isSelected ? primaryAccent : Colors.grey.shade400;

        wordWidgets.add(
          GestureDetector(
            onTap: isChecking ? null : () => _handleBlankTap(currentBlankIndex),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryAccent.withOpacity(0.1)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? primaryAccent : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Text(
                '___',
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 20,
                  height: 1.0,
                  color: wordColor,
                ),
              ),
            ),
          ),
        );
      } else if (isFilledWord ||
          widget.question['correctAnswers']
              .any((correctWord) => correctWord == word)) {
        // Filled word that can be tapped to remove

        // Find the position of this word in the missing indices
        int missingIndexPosition = -1;
        List<int> missingIndices =
            List<int>.from(widget.question['missingIndices']);
        for (int j = 0; j < missingIndices.length; j++) {
          if (missingIndices[j] == i) {
            missingIndexPosition = j;
            break;
          }
        }

        // Determine if this word is correct in this position
        bool isCorrectHere = false;
        if (missingIndexPosition != -1 &&
            missingIndexPosition < widget.question['correctAnswers'].length) {
          isCorrectHere =
              widget.question['correctAnswers'][missingIndexPosition] == word;
        }

        // Define word colors based on state
        Color wordColor = isChecking
            ? (isCorrectHere ? Colors.green.shade600 : Colors.red.shade600)
            : primaryAccent;

        wordWidgets.add(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isChecking
                  ? (isCorrectHere ? Colors.green.shade50 : Colors.red.shade50)
                  : primaryAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isChecking
                    ? (isCorrectHere
                        ? Colors.green.shade300
                        : Colors.red.shade300)
                    : primaryAccent.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: GestureDetector(
              onTap:
                  isChecking ? null : () => _removeWordAndSelectBlank(i, word),
              child: Text(
                word,
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 20,
                  height: 1.2,
                  color: wordColor,
                  fontWeight: isChecking ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
        );
      } else {
        // Regular word - now we need to check if this is actually a filled blank that wasn't recognised
        bool isActuallyFilledBlank =
            widget.question['missingIndices'].contains(i);

        if (isActuallyFilledBlank) {
          // This is a filled blank that wasn't recognised as such

          // Determine if this word is correct in this position
          bool isCorrectHere = false;
          List<int> missingIndices =
              List<int>.from(widget.question['missingIndices']);
          int missingIndexPosition = missingIndices.indexOf(i);

          if (missingIndexPosition != -1 &&
              missingIndexPosition < widget.question['correctAnswers'].length) {
            isCorrectHere =
                widget.question['correctAnswers'][missingIndexPosition] == word;
          }

          // Define word colors based on state
          Color wordColor = isChecking
              ? (isCorrectHere ? Colors.green.shade600 : Colors.red.shade600)
              : primaryAccent;

          wordWidgets.add(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isChecking
                    ? (isCorrectHere
                        ? Colors.green.shade50
                        : Colors.red.shade50)
                    : primaryAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isChecking
                      ? (isCorrectHere
                          ? Colors.green.shade300
                          : Colors.red.shade300)
                      : primaryAccent.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: GestureDetector(
                onTap: isChecking
                    ? null
                    : () => _removeWordAndSelectBlank(i, word),
                child: Text(
                  word,
                  style: GoogleFonts.scheherazadeNew(
                    letterSpacing: 0,
                    fontSize: 20,
                    height: 1.2,
                    color: wordColor,
                    fontWeight:
                        isChecking ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        } else {
          // Regular word
          wordWidgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                word,
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: 20,
                  height: 1.2,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
          );
        }
      }
    }

    return wordWidgets;
  }
}

// Custom widget for adaptive word options grid
class AdaptiveWordOptionsGrid extends StatelessWidget {
  final List<dynamic> options;
  final bool isChecking;
  final bool isDark;
  final Color tertiaryColor;
  final Color primaryAccent;
  final Function(dynamic) onSelectOption;

  const AdaptiveWordOptionsGrid({
    super.key,
    required this.options,
    required this.isChecking,
    required this.isDark,
    required this.tertiaryColor,
    required this.primaryAccent,
    required this.onSelectOption,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Define optimal button width
      final double screenWidth = MediaQuery.of(context).size.width;
      final double optimalButtonWidth = screenWidth > 600 ? 180 : 140;

      // Calculate how many buttons can fit in a row
      int crossAxisCount = (constraints.maxWidth / optimalButtonWidth).floor();
      crossAxisCount =
          crossAxisCount < 2 ? 2 : (crossAxisCount > 3 ? 3 : crossAxisCount);

      // Calculate button size and spacing
      final double horizontalSpacing = 8;
      final double verticalSpacing = 8;
      final double buttonWidth =
          (constraints.maxWidth - ((crossAxisCount - 1) * horizontalSpacing)) /
              crossAxisCount;

      return Wrap(
        spacing: horizontalSpacing,
        runSpacing: verticalSpacing,
        alignment: WrapAlignment.start,
        children: options.map<Widget>((option) {
          return Container(
            width: buttonWidth,
            margin: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton(
              onPressed: isChecking ? null : () => onSelectOption(option),
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: buttonWidth < 150 ? 6 : 8,
                ),
                backgroundColor: isDark ? tertiaryColor : Colors.white,
                foregroundColor: primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? Colors.grey.shade700 : Colors.blue.shade200,
                    width: 1.5,
                  ),
                ),
              ),
              child: Text(
                option.toString(),
                style: GoogleFonts.scheherazadeNew(
                  letterSpacing: 0,
                  fontSize: buttonWidth < 150 ? 18 : 20,
                  height: 1.4,
                  color: isDark ? Colors.white : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}
