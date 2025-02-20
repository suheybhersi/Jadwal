import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FillBlankQuestion extends StatefulWidget {
  final Map<String, dynamic> question;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Function(bool wasCorrect) onNext;
  final VoidCallback onClose;

  const FillBlankQuestion({
    super.key,
    required this.question,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.onClose,
  });

  @override
  State<FillBlankQuestion> createState() => _FillBlankQuestionState();
}

class _FillBlankQuestionState extends State<FillBlankQuestion> {
  List<String> chosenWords = [];
  bool isChecking = false;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 20, bottom: 20),
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
                  value:
                      (widget.currentQuestionIndex + 1) / widget.totalQuestions,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${widget.currentQuestionIndex + 1}/${widget.totalQuestions}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.question['question'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 20),

                // Verse container with highlighted blanks and tappable words
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    textDirection: TextDirection.rtl,
                    children: widget.question['verseWords'].map<Widget>((word) {
                      bool isBlank = word == '____';
                      bool isFilledWord = chosenWords.contains(word);

                      if (isFilledWord) {
                        return GestureDetector(
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
                              fontSize: 24,
                              height: 1.6,
                              color: isFilledWord && isChecking
                                  ? isWordCorrect(
                                          word, chosenWords.indexOf(word))
                                      ? Colors.green.shade700
                                      : Colors.red.shade700
                                  : isFilledWord
                                      ? Colors.blue.shade700
                                      : isBlank
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade900,
                            ),
                          ),
                        );
                      } else {
                        return Text(
                          word,
                          style: GoogleFonts.scheherazadeNew(
                            letterSpacing: 0,
                            fontSize: 24,
                            height: 1.6,
                            color: isFilledWord && isChecking
                                ? isWordCorrect(word, chosenWords.indexOf(word))
                                    ? Colors.green.shade700
                                    : Colors.red.shade700
                                : isFilledWord
                                    ? Colors.blue.shade700
                                    : isBlank
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade900,
                          ),
                        );
                      }
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Options box with fixed height and two columns
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Column(
                  children: [
                    Expanded(
                      child: GridView.count(
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                        children:
                            widget.question['options'].map<Widget>((option) {
                          return ElevatedButton(
                            onPressed: isChecking
                                ? null
                                : () {
                                    List<String> words =
                                        widget.question['verseWords'];
                                    int blankIndex = words.indexOf('____');
                                    if (blankIndex != -1) {
                                      words[blankIndex] = option;
                                      setState(() {
                                        widget.question['verseWords'] = words;
                                        widget.question['options']
                                            .remove(option);
                                        chosenWords.add(option);
                                        updateChosenWordsOrder();
                                      });
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blue.shade700,
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: isChecking
                                    ? BorderSide.none
                                    : BorderSide(color: Colors.blue.shade200),
                              ),
                            ),
                            child: Text(
                              option,
                              style: GoogleFonts.scheherazadeNew(
                                letterSpacing: 0,
                                fontSize: 20,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (!widget.question['verseWords'].contains('____'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isChecking) {
                              // First click: Check answers
                              setState(() {
                                isChecking = true;
                              });
                            } else {
                              // Second click: Move to next question
                              bool allCorrect = true;
                              for (int i = 0; i < chosenWords.length; i++) {
                                if (!isWordCorrect(chosenWords[i], i)) {
                                  allCorrect = false;
                                  break;
                                }
                              }
                              widget.onNext(allCorrect);
                              setState(() {
                                chosenWords = [];
                                isChecking = false;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade700,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 24,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            isChecking ? 'Next' : 'Check',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
