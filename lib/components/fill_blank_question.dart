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

  // Initialize controllers directly to avoid late initialization errors
  AnimationController? _animationController;
  Animation<double> _fadeAnimation = const AlwaysStoppedAnimation<double>(1.0);

  @override
  void initState() {
    super.initState();
    // Initialize the animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    // Set the animation after controller is initialized
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  bool isWordCorrect(String word, int index) {
    return widget.question['correctAnswers'][index] == word;
  }

  void updateChosenWordsOrder() {
    List<String> words = widget.question['verseWords'];
    List<String> newChosenWords = [];

    // Rebuild chosenWords list in verse order
    for (String word in words) {
      if (chosenWords.contains(word)) {
        newChosenWords.add(word);
      }
    }

    chosenWords = newChosenWords;
  }

  void checkAnswers() {
    allCorrect = true;
    for (int i = 0; i < chosenWords.length; i++) {
      if (!isWordCorrect(chosenWords[i], i)) {
        allCorrect = false;
        break;
      }
    }
    setState(() {
      isChecking = true;
    });

    // Ensure animation controller is initialized before using it
    if (_animationController != null) {
      if (_animationController!.isAnimating) {
        _animationController!.stop();
      }
      _animationController!.reset();
      _animationController!.forward();
    }
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: containerBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 12,
                    textDirection: TextDirection.rtl,
                    children: widget.question['verseWords'].map<Widget>((word) {
                      bool isBlank = word == '____';
                      bool isFilledWord = chosenWords.contains(word);

                      // Define word colors based on state
                      Color wordColor;
                      if (isChecking && isFilledWord) {
                        wordColor =
                            isWordCorrect(word, chosenWords.indexOf(word))
                                ? Colors.green.shade600
                                : Colors.red.shade600;
                      } else if (isFilledWord) {
                        wordColor = primaryAccent;
                      } else if (isBlank) {
                        wordColor = Colors.grey.shade400;
                      } else {
                        wordColor = textColor;
                      }

                      if (isFilledWord) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isChecking
                                ? isWordCorrect(word, chosenWords.indexOf(word))
                                    ? Colors.green.shade50
                                    : Colors.red.shade50
                                : primaryAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isChecking
                                  ? isWordCorrect(
                                          word, chosenWords.indexOf(word))
                                      ? Colors.green.shade300
                                      : Colors.red.shade300
                                  : primaryAccent.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          child: GestureDetector(
                            onTap: isChecking
                                ? null
                                : () {
                                    setState(() {
                                      List<String> words =
                                          widget.question['verseWords'];
                                      int wordIndex = words.indexOf(word);
                                      words[wordIndex] = '____';
                                      widget.question['verseWords'] = words;
                                      widget.question['options'].add(word);
                                      chosenWords.remove(word);
                                    });
                                  },
                            child: Text(
                              word,
                              style: GoogleFonts.scheherazadeNew(
                                letterSpacing: 0,
                                fontSize: 20,
                                height: 1.2,
                                color: wordColor,
                              ),
                            ),
                          ),
                        );
                      } else if (isBlank) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
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
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              letterSpacing: 0,
                              fontSize: 20,
                              height: 1.2,
                              color: wordColor,
                            ),
                          ),
                        );
                      }
                    }).toList(),
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
              ],
            ),
          ),
        ),

        // Word options section - only show when not checking
        if (!isChecking && widget.question['verseWords'].contains('____')) ...[
          // Word options area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Word Options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Select the correct words to complete the verse',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                widget.question['options'].isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'All words have been placed',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        constraints: BoxConstraints(
                          minHeight: 100,
                          maxHeight: MediaQuery.of(context).size.height * 0.3,
                        ),
                        child: AdaptiveWordOptionsGrid(
                          options: widget.question['options'],
                          isChecking: isChecking,
                          isDark: false,
                          tertiaryColor: Colors.grey.shade200,
                          primaryAccent: primaryAccent,
                          onSelectOption: (option) {
                            if (isChecking) return;

                            List<String> words = widget.question['verseWords'];
                            int blankIndex = words.indexOf('____');
                            if (blankIndex != -1) {
                              words[blankIndex] = option;
                              setState(() {
                                widget.question['verseWords'] = words;
                                widget.question['options'].remove(option);
                                chosenWords.add(option);
                                updateChosenWordsOrder();
                              });
                            }
                          },
                        ),
                      ),
              ],
            ),
          ),
        ],
        // Fixed position button at the bottom
        if (!widget.question['verseWords'].contains('____'))
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
