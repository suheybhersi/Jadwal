import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class VersePairingQuestion extends StatefulWidget {
  final Map<String, dynamic> question;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Function(bool) onNext;
  final Function() onClose;
  final Map<int, Map<String, dynamic>> answeredQuestions;
  const VersePairingQuestion({
    super.key,
    required this.question,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.onClose,
    required this.answeredQuestions,
  });

  @override
  _VersePairingQuestionState createState() => _VersePairingQuestionState();
}

class _VersePairingQuestionState extends State<VersePairingQuestion>
    with SingleTickerProviderStateMixin {
  String? selectedBeforeVerse;
  String? selectedAfterVerse;
  String? activeSection;
  bool isChecking = false;
  bool allCorrect = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleSectionTap(String section) {
    setState(() {
      activeSection = section;
    });
  }

  void _handleOptionSelected(String option, String section) {
    if (isChecking) return;

    setState(() {
      if (section == 'before') {
        selectedBeforeVerse = option;
      } else {
        selectedAfterVerse = option;
      }

      // Auto-switch to the other section if it's empty
      if (section == 'before' && hasAfterPart && selectedAfterVerse == null) {
        activeSection = 'after';
      } else if (section == 'after' &&
          hasBeforePart &&
          selectedBeforeVerse == null) {
        activeSection = 'before';
      } else {
        activeSection = null; // Close options after selection
      }
    });
  }

  void checkAnswers() {
    bool beforeCorrect = true;
    bool afterCorrect = true;

    if (hasBeforePart) {
      String? correctBeforeOption;
      for (var option in widget.question['beforeOptions']) {
        if (option == widget.question['verseBefore']) {
          correctBeforeOption = option;
          break;
        }
      }
      beforeCorrect = selectedBeforeVerse == correctBeforeOption;
    }

    if (hasAfterPart) {
      String? correctAfterOption;
      for (var option in widget.question['afterOptions']) {
        if (option == widget.question['verseAfter']) {
          correctAfterOption = option;
          break;
        }
      }
      afterCorrect = selectedAfterVerse == correctAfterOption;
    }

    allCorrect = beforeCorrect && afterCorrect;

    setState(() {
      isChecking = true;
      activeSection = null;
    });

    widget.answeredQuestions[widget.currentQuestionIndex] = {
      'question': widget.question,
      'userAnswerBefore': selectedBeforeVerse,
      'userAnswerAfter': selectedAfterVerse,
      'is_correct': allCorrect,
    };
  }

  String? get correctBeforeVerse {
    if (!hasBeforePart) return null;
    return widget.question['verseBefore'];
  }

  String? get correctAfterVerse {
    if (!hasAfterPart) return null;
    return widget.question['verseAfter'];
  }

  bool get hasBeforePart {
    return widget.question['verseBefore'] != null &&
        widget.question['beforeOptions'] != null &&
        widget.question['beforeOptions'] is List &&
        (widget.question['beforeOptions'] as List).isNotEmpty;
  }

  bool get hasAfterPart {
    return widget.question['verseAfter'] != null &&
        widget.question['afterOptions'] != null &&
        widget.question['afterOptions'] is List &&
        (widget.question['afterOptions'] as List).isNotEmpty;
  }

  bool get canSubmit =>
      (selectedBeforeVerse != null || !hasBeforePart) &&
      (selectedAfterVerse != null || !hasAfterPart);

  @override
  Widget build(BuildContext context) {
    // Colors for question elements
    final textColor = Colors.grey.shade800;
    final containerBgColor = const Color(0xFFF5F9FF);
    final primaryAccent = Colors.blue;

    return Column(
      children: [
        // Header with progress and close button
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
                            'Verse Sequence',
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

                // Sequence selection area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Before verse section - NOW PLACED FIRST
                        if (hasBeforePart) ...[
                          GestureDetector(
                            onTap: () => _handleSectionTap('before'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: activeSection == 'before'
                                    ? primaryAccent.withOpacity(0.08)
                                    : isChecking
                                        ? (allCorrect ||
                                                selectedBeforeVerse ==
                                                    correctBeforeVerse
                                            ? Colors.green.shade50
                                            : Colors.red.shade50)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: activeSection == 'before'
                                      ? primaryAccent
                                      : isChecking
                                          ? (allCorrect ||
                                                  selectedBeforeVerse ==
                                                      correctBeforeVerse
                                              ? Colors.green.shade300
                                              : Colors.red.shade300)
                                          : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_upward,
                                            size: 16,
                                            color: isChecking
                                                ? (allCorrect ||
                                                        selectedBeforeVerse ==
                                                            correctBeforeVerse
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade600)
                                                : primaryAccent,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "VERSE BEFORE",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isChecking
                                                  ? (allCorrect ||
                                                          selectedBeforeVerse ==
                                                              correctBeforeVerse
                                                      ? Colors.green.shade600
                                                      : Colors.red.shade600)
                                                  : primaryAccent,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isChecking)
                                        Icon(
                                          allCorrect ||
                                                  selectedBeforeVerse ==
                                                      correctBeforeVerse
                                              ? Iconsax.tick_circle5
                                              : Iconsax.close_circle5,
                                          color: allCorrect ||
                                                  selectedBeforeVerse ==
                                                      correctBeforeVerse
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedBeforeVerse != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isChecking
                                            ? (allCorrect ||
                                                    selectedBeforeVerse ==
                                                        correctBeforeVerse
                                                ? Colors.green.shade50
                                                : Colors.red.shade50)
                                            : primaryAccent.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedBeforeVerse ==
                                                          correctBeforeVerse
                                                  ? Colors.green.shade200
                                                  : Colors.red.shade200)
                                              : primaryAccent.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        selectedBeforeVerse!,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 20,
                                          height: 1.5,
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedBeforeVerse ==
                                                          correctBeforeVerse
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700)
                                              : textColor,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.justify,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Text(
                                        "Tap to select verse before",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  if (activeSection == 'before' && !isChecking)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Select the verse that comes before:",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...widget.question['beforeOptions']
                                              .map<Widget>((option) {
                                            bool isSelected =
                                                selectedBeforeVerse == option;

                                            return GestureDetector(
                                              onTap: () =>
                                                  _handleOptionSelected(
                                                      option, 'before'),
                                              child: Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    bottom: 10),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? primaryAccent
                                                          .withOpacity(0.1)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  option,
                                                  style: GoogleFonts
                                                      .scheherazadeNew(
                                                    fontSize: 18,
                                                    height: 1.5,
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : textColor,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  textAlign: TextAlign.justify,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Current verse container PLACED IN THE MIDDLE
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Label for current verse
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.book,
                                    size: 16,
                                    color: primaryAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "CURRENT VERSE",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: primaryAccent,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Current verse text
                              Text(
                                widget.question['currentVerse'],
                                style: GoogleFonts.scheherazadeNew(
                                  fontSize: 22,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: textColor,
                                ),
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.justify,
                              ),
                            ],
                          ),
                        ),

                        // After verse section PLACED LAST
                        if (hasAfterPart) ...[
                          GestureDetector(
                            onTap: () => _handleSectionTap('after'),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: activeSection == 'after'
                                    ? primaryAccent.withOpacity(0.08)
                                    : isChecking
                                        ? (allCorrect ||
                                                selectedAfterVerse ==
                                                    correctAfterVerse
                                            ? Colors.green.shade50
                                            : Colors.red.shade50)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: activeSection == 'after'
                                      ? primaryAccent
                                      : isChecking
                                          ? (allCorrect ||
                                                  selectedAfterVerse ==
                                                      correctAfterVerse
                                              ? Colors.green.shade300
                                              : Colors.red.shade300)
                                          : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.arrow_downward,
                                            size: 16,
                                            color: isChecking
                                                ? (allCorrect ||
                                                        selectedAfterVerse ==
                                                            correctAfterVerse
                                                    ? Colors.green.shade600
                                                    : Colors.red.shade600)
                                                : primaryAccent,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "VERSE AFTER",
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isChecking
                                                  ? (allCorrect ||
                                                          selectedAfterVerse ==
                                                              correctAfterVerse
                                                      ? Colors.green.shade600
                                                      : Colors.red.shade600)
                                                  : primaryAccent,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (isChecking)
                                        Icon(
                                          allCorrect ||
                                                  selectedAfterVerse ==
                                                      correctAfterVerse
                                              ? Iconsax.tick_circle5
                                              : Iconsax.close_circle5,
                                          color: allCorrect ||
                                                  selectedAfterVerse ==
                                                      correctAfterVerse
                                              ? Colors.green.shade600
                                              : Colors.red.shade600,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (selectedAfterVerse != null)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isChecking
                                            ? (allCorrect ||
                                                    selectedAfterVerse ==
                                                        correctAfterVerse
                                                ? Colors.green.shade50
                                                : Colors.red.shade50)
                                            : primaryAccent.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedAfterVerse ==
                                                          correctAfterVerse
                                                  ? Colors.green.shade200
                                                  : Colors.red.shade200)
                                              : primaryAccent.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        selectedAfterVerse!,
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 20,
                                          height: 1.5,
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedAfterVerse ==
                                                          correctAfterVerse
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700)
                                              : textColor,
                                        ),
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.justify,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                          width: 1,
                                          style: BorderStyle.solid,
                                        ),
                                      ),
                                      child: Text(
                                        "Tap to select verse after",
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  if (activeSection == 'after' && !isChecking)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Select the verse that comes after:",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          ...widget.question['afterOptions']
                                              .map<Widget>((option) {
                                            bool isSelected =
                                                selectedAfterVerse == option;

                                            return GestureDetector(
                                              onTap: () =>
                                                  _handleOptionSelected(
                                                      option, 'after'),
                                              child: Container(
                                                width: double.infinity,
                                                margin: const EdgeInsets.only(
                                                    bottom: 10),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? primaryAccent
                                                          .withOpacity(0.1)
                                                      : Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : Colors.grey.shade300,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  option,
                                                  style: GoogleFonts
                                                      .scheherazadeNew(
                                                    fontSize: 18,
                                                    height: 1.5,
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : textColor,
                                                  ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  textAlign: TextAlign.justify,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],

                        // Feedback message (stays the same)
                        if (isChecking)
                          Builder(
                            builder: (context) {
                              Widget feedbackContent = Container(
                                margin:
                                    const EdgeInsets.only(top: 20, bottom: 20),
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
                                          allCorrect
                                              ? 'Correct!'
                                              : 'Not quite right',
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
                                        padding: const EdgeInsets.only(
                                            top: 8, left: 36),
                                        child: Text(
                                          'Check the highlighted verses and try again next time',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );

                              try {
                                return _animationController != null
                                    ? FadeTransition(
                                        opacity: _fadeAnimation,
                                        child: feedbackContent,
                                      )
                                    : feedbackContent;
                              } catch (e) {
                                return feedbackContent;
                              }
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Bottom button - stays the same
        if (canSubmit || isChecking)
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
                    if (_animationController.isAnimating) {
                      _animationController.stop();
                    }

                    try {
                      _animationController.reverse().then((_) {
                        setState(() {
                          selectedBeforeVerse = null;
                          selectedAfterVerse = null;
                          isChecking = false;
                        });
                      });
                    } catch (e) {
                      setState(() {
                        selectedBeforeVerse = null;
                        selectedAfterVerse = null;
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
