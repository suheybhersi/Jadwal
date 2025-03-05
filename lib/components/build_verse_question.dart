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

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];

    // Initialize with previous answer or default state
    if (widget.answeredQuestions.containsKey(widget.currentQuestionIndex)) {
      selectedWords = List.from(widget
          .answeredQuestions[widget.currentQuestionIndex]!['user_answer']);
      usedWordIndices = _getUsedWordIndices(selectedWords);
    } else {
      selectedWords = [question['firstWord']];
      usedWordIndices = {
        question['firstWord']: [shuffledWords.indexOf(question['firstWord'])]
      };
    }

    correctOrder = [question['firstWord'], ...question['correctOrder']];
    shuffledWords = List.from(question['shuffledWords']);
  }

  Map<String, List<int>> _getUsedWordIndices(List<String> selectedWords) {
    Map<String, List<int>> usedIndices = {};
    for (var word in selectedWords) {
      if (!usedIndices.containsKey(word)) {
        usedIndices[word] = [];
      }
      usedIndices[word]!.add(shuffledWords.indexOf(word));
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
      // Remove the word from selectedWords
      selectedWords.removeAt(selectedIndex);

      // Remove the corresponding index from usedWordIndices
      if (usedWordIndices.containsKey(word)) {
        usedWordIndices[word]!.removeAt(0); // Remove the first occurrence
        if (usedWordIndices[word]!.isEmpty) {
          usedWordIndices.remove(word);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];
    final Color primaryAccent = const Color(0xFF4979FB);
    final Color textColor = Colors.grey.shade800;

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
                            'Arrange the verse',
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(227, 242, 253, 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
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
                      });
                    }
                  },
                  builder: (context, candidateData, rejectedData) {
                    return Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      alignment: WrapAlignment.start,
                      textDirection: TextDirection.rtl,
                      children: selectedWords.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        return Container(
                          child: isChecking
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: word == question['firstWord']
                                        ? Colors.green.shade100
                                        : _isWordCorrect(word, index)
                                            ? Colors.green.shade100
                                            : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    word,
                                    style: GoogleFonts.scheherazadeNew(
                                      letterSpacing: 0,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                )
                              : DragTarget<Map<String, dynamic>>(
                                  onWillAcceptWithDetails: (details) =>
                                      details.data['source'] == 'answers' &&
                                      index != 0,
                                  onAcceptWithDetails: (details) {
                                    if (details.data['source'] == 'answers') {
                                      final draggedWord =
                                          details.data['word'] as String;
                                      final oldIndex =
                                          selectedWords.indexOf(draggedWord);
                                      if (oldIndex != 0 && index != 0) {
                                        setState(() {
                                          selectedWords.removeAt(oldIndex);
                                          selectedWords.insert(
                                              index, draggedWord);
                                        });
                                      }
                                    }
                                  },
                                  builder:
                                      (context, candidateData, rejectedData) {
                                    return Draggable<Map<String, dynamic>>(
                                      data: word == question['firstWord']
                                          ? null
                                          : {
                                              'word': word,
                                              'source': 'answers',
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
                                            style: GoogleFonts.scheherazadeNew(
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
                                          if (word != question['firstWord']) {
                                            _removeWord(word, index);
                                          }
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: word == question['firstWord']
                                                ? Colors.blue.shade200
                                                : Colors.blue.shade100,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            word,
                                            style: GoogleFonts.scheherazadeNew(
                                              letterSpacing: 0,
                                              fontSize: 20,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        // Bottom Section with Options
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Available Words Area
              if (!isChecking)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: shuffledWords.asMap().entries.map((entry) {
                      final wordIndex = entry.key;
                      final word = entry.value;
                      final bool isUsed =
                          usedWordIndices[word]?.contains(wordIndex) ?? false;
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
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    word,
                                    style: GoogleFonts.scheherazadeNew(
                                      letterSpacing: 0,
                                      fontSize: 20,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                        childWhenDragging: isUsed
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  word,
                                  style: GoogleFonts.scheherazadeNew(
                                    letterSpacing: 0,
                                    fontSize: 20,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                      Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  word,
                                  style: GoogleFonts.scheherazadeNew(
                                    letterSpacing: 0,
                                    fontSize: 20,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                        child: GestureDetector(
                          onTap: isUsed
                              ? null
                              : () {
                                  setState(() {
                                    if (!usedWordIndices.containsKey(word)) {
                                      usedWordIndices[word] = [];
                                    }
                                    usedWordIndices[word]!.add(wordIndex);
                                    selectedWords.add(word);
                                  });
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUsed ? Colors.grey.shade200 : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: isUsed
                                      ? Colors.grey.shade200
                                      : Colors.blue.shade200),
                            ),
                            child: Text(
                              word,
                              style: GoogleFonts.scheherazadeNew(
                                letterSpacing: 0,
                                fontSize: 20,
                                color: isUsed
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              if (isChecking)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: selectedWords.join(' ') == correctOrder.join(' ')
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selectedWords.join(' ') == correctOrder.join(' ')
                            ? Colors.green.shade200
                            : Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          selectedWords.join(' ') == correctOrder.join(' ')
                              ? 'Excellent! That\'s correct! 🎉'
                              : 'Almost there! Here\'s the correct order:',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (selectedWords.join(' ') !=
                            correctOrder.join(' ')) ...[
                          const SizedBox(height: 12),
                          Text(
                            correctOrder.join(' '),
                            style: GoogleFonts.scheherazadeNew(
                              letterSpacing: 0,
                              fontSize: 24,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

              // Check Answer/Next Button
              Padding(
                padding: const EdgeInsets.all(20),
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
                            usedWordIndices = {
                              question['firstWord']: [
                                shuffledWords.indexOf(question['firstWord'])
                              ]
                            };
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
}
