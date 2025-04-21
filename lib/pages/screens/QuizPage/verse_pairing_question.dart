import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  // Add scroll controller
  final ScrollController _scrollController = ScrollController();

  // Add keys for scrolling to specific widgets
  final GlobalKey _beforeSectionKey = GlobalKey();
  final GlobalKey _afterSectionKey = GlobalKey();

  // Add separate keys for options
  final GlobalKey _beforeOptionsKey = GlobalKey();
  final GlobalKey _afterOptionsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Add scroll to widget method with offset parameter
  void _scrollToWidget(GlobalKey key, {double offset = 0.0}) {
    if (key.currentContext != null) {
      final RenderObject? renderObject = key.currentContext!.findRenderObject();
      if (renderObject != null) {
        final RenderAbstractViewport viewport =
            RenderAbstractViewport.of(renderObject);
        final double position =
            viewport.getOffsetToReveal(renderObject, 0.0).offset;

        _scrollController.animateTo(
          position + offset, // Apply additional offset to fine-tune position
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _handleSectionTap(String section) {
    setState(() {
      activeSection = section;
    });

    // Scroll to the appropriate section's options
    Future.delayed(const Duration(milliseconds: 100), () {
      if (section == 'before' && _beforeOptionsKey.currentContext != null) {
        // For before section, use a small offset for subtle positioning
        _scrollToWidget(_beforeOptionsKey, offset: -20.0);
      } else if (section == 'after' &&
          _afterOptionsKey.currentContext != null) {
        // For after section, use a larger negative offset to prevent aggressive scrolling
        _scrollToWidget(_afterOptionsKey, offset: -100.0);
      }
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
        // Schedule scrolling after state is updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_afterSectionKey.currentContext != null) {
            _scrollToWidget(_afterSectionKey);
          }
        });
      } else if (section == 'after' &&
          hasBeforePart &&
          selectedBeforeVerse == null) {
        activeSection = 'before';
        // Schedule scrolling after state is updated
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_beforeSectionKey.currentContext != null) {
            _scrollToWidget(_beforeSectionKey);
          }
        });
      } else {
        activeSection = null; // Close options after selection
        // Scroll back to show the current verse
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        });
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

  // Add this helper method to truncate verse text
  String _truncateVerse(String verse, {int maxWords = 10}) {
    final words = verse.split(' ');
    if (words.length <= maxWords) {
      return verse;
    }
    return '${words.take(maxWords).join(' ')} ...';
  }

  @override
  Widget build(BuildContext context) {
    // Colors for question elements

    final primaryAccent = const Color(0xFF4979FB);

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
                color: Theme.of(context).colorScheme.inversePrimary,
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
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const Spacer(),
                        if (widget.currentQuestionIndex <
                            widget.totalQuestions) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              if (!isChecking) {
                                // First click: Check answers
                                checkAnswers();
                              }
                              widget.answeredQuestions[
                                  widget.currentQuestionIndex] = {
                                'question': widget.question,
                                'userAnswerBefore': selectedBeforeVerse,
                                'userAnswerAfter': selectedAfterVerse,
                                'is_correct': allCorrect,
                              };

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
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Skip',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (widget.currentQuestionIndex + 1) /
                            widget.totalQuestions,
                        backgroundColor: Theme.of(context).colorScheme.tertiary,
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
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 24),

                // Sequence selection area
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Before verse section - NOW PLACED FIRST
                        if (hasBeforePart) ...[
                          GestureDetector(
                            key: _beforeSectionKey,
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
                                        : Theme.of(context).colorScheme.surface,
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
                                          : Theme.of(context)
                                              .colorScheme
                                              .tertiary,
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
                                        // Display full verse when checking answers, truncated version otherwise
                                        isChecking
                                            ? selectedBeforeVerse!
                                            : _truncateVerse(
                                                selectedBeforeVerse!),
                                        style: GoogleFonts.scheherazadeNew(
                                          letterSpacing: 0,
                                          fontSize: 20,
                                          height: 1.5,
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedBeforeVerse ==
                                                          correctBeforeVerse
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  if (activeSection == 'before' && !isChecking)
                                    Padding(
                                      key: _beforeOptionsKey,
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
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
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  // Always truncate in the options list, even if selected
                                                  _truncateVerse(option),
                                                  style: GoogleFonts
                                                      .scheherazadeNew(
                                                    letterSpacing: 0,
                                                    fontSize: 18,
                                                    height: 1.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
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
                            color: Theme.of(context).colorScheme.surface,
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
                              color: Theme.of(context).colorScheme.primary,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
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
                                  letterSpacing: 0,
                                  fontSize: 22,
                                  height: 1.5,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
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
                            key: _afterSectionKey,
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
                                        : Theme.of(context).colorScheme.surface,
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
                                          : Theme.of(context)
                                              .colorScheme
                                              .tertiary,
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
                                        // Display full verse when checking answers, truncated version otherwise
                                        isChecking
                                            ? selectedAfterVerse!
                                            : _truncateVerse(
                                                selectedAfterVerse!),
                                        style: GoogleFonts.scheherazadeNew(
                                          letterSpacing: 0,
                                          fontSize: 20,
                                          height: 1.5,
                                          color: isChecking
                                              ? (allCorrect ||
                                                      selectedAfterVerse ==
                                                          correctAfterVerse
                                                  ? Colors.green.shade700
                                                  : Colors.red.shade700)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
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
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface,
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
                                      key: _afterOptionsKey,
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
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inversePrimary,
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
                                                      : Theme.of(context)
                                                          .colorScheme
                                                          .surface,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: isSelected
                                                        ? primaryAccent
                                                        : Theme.of(context)
                                                            .colorScheme
                                                            .tertiary,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: Text(
                                                  // Always truncate in the options list, even if selected
                                                  _truncateVerse(option),
                                                  style: GoogleFonts
                                                      .scheherazadeNew(
                                                    letterSpacing: 0,
                                                    fontSize: 18,
                                                    height: 1.5,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary,
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
            padding: const EdgeInsets.only(left: 20.0, right: 20.0),
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
