import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BuildVerseQuestion extends StatefulWidget {
  final int currentQuestionIndex;
  final List<Map<String, dynamic>> questions;
  final Function(int) onNextQuestion;
  final Function() onPreviousQuestion;

  const BuildVerseQuestion({
    super.key,
    required this.currentQuestionIndex,
    required this.questions,
    required this.onNextQuestion,
    required this.onPreviousQuestion,
  });

  @override
  State<BuildVerseQuestion> createState() => _BuildVerseQuestionState();
}

class _BuildVerseQuestionState extends State<BuildVerseQuestion> {
  List<String> correctOrder = [];
  List<String> shuffledWords = [];
  List<String> selectedWords = [];

  @override
  void initState() {
    super.initState();
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];
    correctOrder = [question['firstWord'], ...question['correctOrder']];
    shuffledWords = List.from(question['shuffledWords']);
    selectedWords = [question['firstWord']];
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> question =
        widget.questions[widget.currentQuestionIndex];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 20, bottom: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  widget.onPreviousQuestion();
                  setState(() {
                    question = widget.questions[widget.currentQuestionIndex == 0
                        ? 0
                        : widget.currentQuestionIndex - 1];
                    if (question['type'] == 'drag_drop') {
                      correctOrder = [
                        question['firstWord'],
                        ...question['correctOrder']
                      ];
                      shuffledWords = List.from(question['shuffledWords']);
                      selectedWords = [question['firstWord']];
                    }
                  });
                },
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

        // Question text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            question['question'],
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 20),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(227, 242, 253, 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: DragTarget<Map<String, dynamic>>(
              onAcceptWithDetails: (details) {
                if (details.data['source'] == 'options') {
                  final word = details.data['word'] as String;
                  setState(() {
                    shuffledWords.remove(word);
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
                    return DragTarget<Map<String, dynamic>>(
                      onWillAcceptWithDetails: (details) =>
                          details.data['source'] == 'answers' && index != 0,
                      onAcceptWithDetails: (details) {
                        if (details.data['source'] == 'answers') {
                          final draggedWord = details.data['word'] as String;
                          final oldIndex = selectedWords.indexOf(draggedWord);
                          if (oldIndex != 0 && index != 0) {
                            setState(() {
                              selectedWords.removeAt(oldIndex);
                              selectedWords.insert(index, draggedWord);
                            });
                          }
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Draggable<Map<String, dynamic>>(
                          data: {
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
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word,
                                style: GoogleFonts.scheherazadeNew(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          childWhenDragging: const SizedBox.shrink(),
                          child: GestureDetector(
                            onTap: () {
                              if (word != question['firstWord']) {
                                setState(() {
                                  selectedWords.remove(word);
                                  shuffledWords.add(word);
                                });
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
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                word,
                                style: GoogleFonts.scheherazadeNew(
                                  fontSize: 20,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ),

        const Spacer(),

        // Bottom section with options
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Available words area
              Container(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: shuffledWords.map((word) {
                    return Draggable<Map<String, dynamic>>(
                      data: {
                        'word': word,
                        'source': 'options',
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: const SizedBox.shrink(),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            shuffledWords.remove(word);
                            selectedWords.add(word);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 20,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Check Answer button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () {
                    bool isCorrect =
                        selectedWords.join(' ') == correctOrder.join(' ');
                    if (isCorrect) {
                      setState(() {
                        widget.onNextQuestion(widget.currentQuestionIndex + 1);
                        question = widget.questions[
                            widget.currentQuestionIndex ==
                                    widget.questions.length - 1
                                ? widget.currentQuestionIndex
                                : widget.currentQuestionIndex + 1];
                        if (question['type'] == 'drag_drop') {
                          correctOrder = [
                            question['firstWord'],
                            ...question['correctOrder']
                          ];
                          shuffledWords = List.from(question['shuffledWords']);
                          selectedWords = [question['firstWord']];
                        }
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Incorrect, try again!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Check Answer',
                    style: TextStyle(
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
