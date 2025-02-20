import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildVerseQuestion extends StatefulWidget {
  final int currentQuestionIndex;
  final List<Map<String, dynamic>> questions;
  final Function(int) onNextQuestion;
  final Map<int, List<String>> answeredQuestions;
  final VoidCallback onClose;

  const BuildVerseQuestion({
    super.key,
    required this.currentQuestionIndex,
    required this.questions,
    required this.onNextQuestion,
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
      selectedWords =
          List.from(widget.answeredQuestions[widget.currentQuestionIndex]!);
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

  void _saveCurrentState() {
    widget.answeredQuestions[widget.currentQuestionIndex] =
        List.from(selectedWords);
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

    return Column(
      children: [
        // Progress and Close Button
        Padding(
          padding:
              const EdgeInsets.only(left: 4, right: 20, top: 0, bottom: 20),
          child: Row(
            children: [
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
                color: Colors.grey.shade600,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (widget.currentQuestionIndex + 1) /
                      widget.questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.currentQuestionIndex + 1}/${widget.questions.length}',
                style: GoogleFonts.poppins(fontSize: 14),
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
              Text(
                question['question'],
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
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
                      _saveCurrentState();
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
                      widget.onNextQuestion(widget.currentQuestionIndex + 1);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    isChecking ? 'Next' : 'Check Answer',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
