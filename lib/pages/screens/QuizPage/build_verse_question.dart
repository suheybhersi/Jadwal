import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class BuildVerseQuestion extends StatefulWidget {
  final int currentQuestionIndex;
  final List<Map<String, dynamic>> questions;
  final Function(bool wasCorrect) onNext;
  final int totalQuestions;
  final Map<int, Map<String, dynamic>> answeredQuestions;
  final VoidCallback onClose;

  const BuildVerseQuestion({
    super.key,
    required this.currentQuestionIndex,
    required this.questions,
    required this.onNext,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.onClose,
  });

  @override
  State<BuildVerseQuestion> createState() => _BuildVerseQuestionState();
}

class _BuildVerseQuestionState extends State<BuildVerseQuestion> {
  List<String> selectedWords = [];
  Map<String, List<int>> usedWordIndices = {}; // Track indices of used words
  List<String> correctOrder = [];
  List<String> shuffledWords = [];
  bool isChecking = false;
  final ScrollController _answerScrollController =
      ScrollController(); // Add scroll controller
  final ScrollController _optionsScrollController =
      ScrollController(); // Add options scroll controller
  int? focusedOptionIndex;
  bool isSmallScreen = false;
  int activeTab = 0;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];

    correctOrder = [question['firstWord'], ...question['correctOrder']];
    shuffledWords = List.from(question['shuffledWords']);

    // Initialise with previous answer or default state
    if (widget.answeredQuestions.containsKey(widget.currentQuestionIndex)) {
      selectedWords = List.from(widget
          .answeredQuestions[widget.currentQuestionIndex]!['user_answer']);
    } else {
      selectedWords = [question['firstWord']];
    }
    usedWordIndices = _getUsedWordIndices(selectedWords);
  }

  /// Maps each selected word to a distinct chip index in [shuffledWords]
  /// (handles repeated words correctly).
  Map<String, List<int>> _getUsedWordIndices(List<String> words) {
    final usedIndices = <String, List<int>>{};
    final nextSearchFrom = <String, int>{};
    for (final word in words) {
      usedIndices.putIfAbsent(word, () => []);
      final start = nextSearchFrom[word] ?? 0;
      final idx = shuffledWords.indexOf(word, start);
      if (idx >= 0) {
        usedIndices[word]!.add(idx);
        nextSearchFrom[word] = idx + 1;
      }
    }
    return usedIndices;
  }

  @override
  void didUpdateWidget(BuildVerseQuestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentQuestionIndex != widget.currentQuestionIndex) {
      _initializeState();
    }
  }

  bool _isWordCorrect(String word, int index) {
    return correctOrder[index] == word;
  }

  void _removeWord(String word, int selectedIndex) {
    setState(() {
      selectedWords.removeAt(selectedIndex);
      usedWordIndices = _getUsedWordIndices(selectedWords);
    });
  }

  // Add this method to handle adding a word
  void _addWord(String word, int wordIndex) {
    setState(() {
      if (!usedWordIndices.containsKey(word)) {
        usedWordIndices[word] = [];
      }
      usedWordIndices[word]!.add(wordIndex);
      selectedWords.add(word);
      // Scroll to bottom after adding a word
      _scrollToBottom();
    });
  }

  // Add method to scroll to bottom of answer area
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_answerScrollController.hasClients) {
        _answerScrollController.animateTo(
          _answerScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearAllWords() {
    // Get the first word from the current question
    final firstWord =
        widget.questions[widget.currentQuestionIndex]['firstWord'];

    setState(() {
      selectedWords = [firstWord];
      usedWordIndices = _getUsedWordIndices(selectedWords);
    });

    // Show a confirmation to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Arrangement cleared',
          style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.inversePrimary),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(20),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _answerScrollController.dispose(); // Clean up controller
    _optionsScrollController.dispose(); // Clean up options scroll controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];
    final Color primaryAccent = const Color(0xFF4979FB);
    final Color textColor = Theme.of(context).colorScheme.inversePrimary;

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
                        if (widget.currentQuestionIndex <
                            widget.totalQuestions) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              bool isCorrect = selectedWords.join(' ') ==
                                  correctOrder.join(' ');
                              widget.answeredQuestions[
                                  widget.currentQuestionIndex] = {
                                'user_answer': selectedWords,
                                'is_correct': isCorrect
                              };
                              if (isCorrect) {
                                setState(() {
                                  isChecking = false;
                                });
                              } else {
                                setState(() {
                                  isChecking = false;
                                  // Reset the words if incorrect
                                  selectedWords = [question['firstWord']];
                                  usedWordIndices =
                                      _getUsedWordIndices(selectedWords);
                                });
                              }
                              widget.onNext(isCorrect);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryAccent.withValues(alpha: 0.1),
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

        // Question Text
        Padding(
          padding:
              const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question['question'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Question Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 150, // Fixed height for scrollable container
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.3),
                        blurRadius: 5,
                        spreadRadius: 1,
                      )
                    ]),
                child: DragTarget<Map<String, dynamic>>(
                  onAcceptWithDetails: (details) {
                    if (!isChecking && details.data['source'] == 'options') {
                      final word = details.data['word'] as String;
                      final wordIndex = details.data['index'] as int;
                      setState(() {
                        if (!usedWordIndices.containsKey(word)) {
                          usedWordIndices[word] = [];
                        }
                        usedWordIndices[word]!.add(wordIndex);
                        selectedWords.add(word);
                        // Scroll to bottom after adding a word
                        _scrollToBottom();
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    // Schedule scroll to bottom when builder runs
                    _scrollToBottom();
                    return SingleChildScrollView(
                      controller: _answerScrollController,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        alignment: WrapAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: selectedWords.asMap().entries.map((entry) {
                          final index = entry.key;
                          final word = entry.value;
                          return Container(
                            child: isChecking
                                ? Builder(builder: (_) {
                                    // Position-based check only (repeated firstWord
                                    // elsewhere must not count as correct).
                                    final bool isCorrectHere =
                                        index < correctOrder.length &&
                                            _isWordCorrect(word, index);
                                    final String? expected =
                                        index < correctOrder.length
                                            ? correctOrder[index]
                                            : null;
                                    final String displayWord =
                                        (!isCorrectHere && expected != null)
                                            ? expected
                                            : word;

                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isCorrectHere
                                            ? Colors.green.shade100
                                            : Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (!isCorrectHere) ...[
                                            Text(
                                              word,
                                              style:
                                                  GoogleFonts.scheherazadeNew(
                                                letterSpacing: 0,
                                                fontSize: 14,
                                                color: Colors.red.shade400,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                                decorationColor:
                                                    Colors.red.shade400,
                                              ),
                                            ),
                                          ],
                                          Text(
                                            displayWord,
                                            style: GoogleFonts.scheherazadeNew(
                                              letterSpacing: 0,
                                              fontSize: 20,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                : DragTarget<Map<String, dynamic>>(
                                    onWillAcceptWithDetails: (details) =>
                                        details.data['source'] == 'answers' &&
                                        index != 0,
                                    onAcceptWithDetails: (details) {
                                      if (details.data['source'] == 'answers') {
                                        final draggedWord =
                                            details.data['word'] as String;
                                        final oldIndex =
                                            details.data['selectedIndex']
                                                as int;
                                        if (oldIndex != 0 &&
                                            index != 0 &&
                                            oldIndex != index) {
                                          setState(() {
                                            selectedWords.removeAt(oldIndex);
                                            final insertAt = oldIndex < index
                                                ? index - 1
                                                : index;
                                            selectedWords.insert(
                                                insertAt, draggedWord);
                                            usedWordIndices =
                                                _getUsedWordIndices(
                                                    selectedWords);
                                          });
                                        }
                                      }
                                    },
                                    builder:
                                        (context, candidateData, rejectedData) {
                                      final isLockedFirst = index == 0;
                                      return Draggable<Map<String, dynamic>>(
                                        data: isLockedFirst
                                            ? null
                                            : {
                                                'word': word,
                                                'source': 'answers',
                                                'selectedIndex': index,
                                              },
                                        feedback: Material(
                                          color: Colors.transparent,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              word,
                                              style:
                                                  GoogleFonts.scheherazadeNew(
                                                letterSpacing: 0,
                                                fontSize: 20,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ),
                                        childWhenDragging:
                                            const SizedBox.shrink(),
                                        child: GestureDetector(
                                          onTap: () {
                                            if (!isLockedFirst) {
                                              _removeWord(word, index);
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              word,
                                              style:
                                                  GoogleFonts.scheherazadeNew(
                                                letterSpacing: 0,
                                                fontSize: 20,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              // Add Clear All button if there are selected words beyond the first one
              if (!isChecking && selectedWords.length > 1)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: _clearAllWords,
                      icon: Icon(
                        Icons.refresh,
                        size: 18,
                        color: Colors.blue.shade700,
                      ),
                      label: Text(
                        'Clear All',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const Spacer(),

        // Bottom Section with Options
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            children: [
              // Available Words Area
              _buildOptionsArea(
                  context, question, primaryAccent, false, textColor),

              if (isChecking)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: selectedWords.join(' ') == correctOrder.join(' ')
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Text(
                            'Excellent! That\'s correct!',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade700,
                            ),
                          ),
                        )
                      : Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Iconsax.close_circle5,
                                    color: Colors.red.shade600,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Not quite right',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Correct:',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                correctOrder.join(' '),
                                textAlign: TextAlign.right,
                                textDirection: TextDirection.rtl,
                                style: GoogleFonts.scheherazadeNew(
                                  letterSpacing: 0,
                                  fontSize: 22,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

              // Check Answer/Next Button
              Padding(
                padding:
                    const EdgeInsets.only(left: 20.0, right: 20.0, top: 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!isChecking) {
                        // Check if all words are used before allowing check
                        if (selectedWords.length < correctOrder.length) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Please use all available words before checking',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.blue.shade700,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(20),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        // First click: Check answers
                        setState(() {
                          isChecking = true;
                        });
                      } else {
                        // Second click: Move to next question
                        bool isCorrect =
                            selectedWords.join(' ') == correctOrder.join(' ');
                        widget.answeredQuestions[widget.currentQuestionIndex] =
                            {
                          'user_answer': selectedWords,
                          'is_correct': isCorrect
                        };
                        if (isCorrect) {
                          setState(() {
                            isChecking = false;
                          });
                        } else {
                          setState(() {
                            isChecking = false;
                            // Reset the words if incorrect
                            selectedWords = [question['firstWord']];
                            usedWordIndices =
                                _getUsedWordIndices(selectedWords);
                          });
                        }
                        widget.onNext(isCorrect);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: isChecking
                          ? (selectedWords.join(' ') == correctOrder.join(' ')
                              ? Colors.green.shade600
                              : Colors.red.shade600)
                          : const Color(0xFF4979FB), // primaryAccent color
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
          ),
        )
      ],
    );
  }

  // Word options area widget
  Widget _buildOptionsArea(BuildContext context, Map<String, dynamic> question,
      Color primaryAccent, bool highContrastMode, Color textColor) {
    return !isChecking
        ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              height: 200, // Fixed height container
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          'Available Words',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${shuffledWords.length - selectedWords.length + 1} remaining',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: highContrastMode
                                ? Colors.grey.shade300
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.tertiary,
                        ),
                      ),
                      child: SingleChildScrollView(
                        controller: _optionsScrollController,
                        padding: const EdgeInsets.all(16),
                        physics: const BouncingScrollPhysics(),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 12,
                          alignment: WrapAlignment.center,
                          children: shuffledWords.asMap().entries.map((entry) {
                            final wordIndex = entry.key;
                            final word = entry.value;
                            final bool isUsed =
                                usedWordIndices[word]?.contains(wordIndex) ??
                                    false;
                            final bool isFocused = focusedOptionIndex != null &&
                                !isUsed &&
                                shuffledWords
                                        .asMap()
                                        .entries
                                        .where((e) => !(usedWordIndices[e.value]
                                                ?.contains(e.key) ??
                                            false))
                                        .toList()[focusedOptionIndex!]
                                        .key ==
                                    wordIndex;

                            return Draggable<Map<String, dynamic>>(
                              data: (isUsed || isChecking)
                                  ? null
                                  : {
                                      'word': word,
                                      'index': wordIndex,
                                      'source': 'options',
                                    },
                              feedback: (isUsed || isChecking)
                                  ? const SizedBox.shrink()
                                  : Material(
                                      color: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: highContrastMode
                                              ? Colors.blue.shade700
                                              : Colors.blue.shade100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          word,
                                          style: GoogleFonts.scheherazadeNew(
                                            letterSpacing: 0,
                                            fontSize: 20,
                                            color: highContrastMode
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                              childWhenDragging: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: highContrastMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: highContrastMode
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade200),
                                ),
                                child: Text(
                                  word,
                                  style: GoogleFonts.scheherazadeNew(
                                    letterSpacing: 0,
                                    fontSize: 20,
                                    color: highContrastMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              child: Semantics(
                                label: isUsed
                                    ? 'Word already used: $word'
                                    : 'Available word: $word',
                                button: !isUsed,
                                enabled: !isUsed,
                                child: GestureDetector(
                                  onTap: isUsed
                                      ? null
                                      : () {
                                          _addWord(word, wordIndex);
                                          // Switch to answer tab on small screens
                                          if (isSmallScreen) {
                                            setState(() => activeTab = 0);
                                          }
                                        },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                        color: isUsed
                                            ? Theme.of(context)
                                                .colorScheme
                                                .inversePrimary
                                                .withValues(alpha: 0.1)
                                            : isFocused
                                                ? primaryAccent
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          isUsed
                                              ? BoxShadow()
                                              : BoxShadow(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .tertiary
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 5,
                                                  spreadRadius: 1,
                                                )
                                        ]),
                                    child: Text(
                                      word,
                                      style: GoogleFonts.scheherazadeNew(
                                          letterSpacing: 0,
                                          fontSize: 20,
                                          color: isUsed
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .tertiary
                                              : Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        : const SizedBox.shrink(); // Hide options when checking
  }
}
