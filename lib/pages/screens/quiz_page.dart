import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/pages/screens/api_key.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:http/http.dart' as http;
import 'package:hifdh_planner_app/components/build_verse_question.dart';

class QuizPage extends StatefulWidget {
  final List<dynamic> versesList;
  final String reviewTitle;
  final String id;
  final Function(String, String, String) updateReview;

  const QuizPage({
    super.key,
    required this.versesList,
    required this.reviewTitle,
    required this.id,
    required this.updateReview,
  });

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = -1;
  int score = 0;
  late List<Map<String, dynamic>> questions = [];

  final AudioRecorder recorder = AudioRecorder();
  AudioPlayer audioPlayer = AudioPlayer();

  bool isRecording = false;
  String? recordingPath;
  bool isPlaying = false;
  String text = '';

  List<String> chosenWords = [];

  Future<String> convertSpeechToText(String filePath) async {
    var url = Uri.https('api.openai.com', 'v1/audio/transcriptions');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $apiSecretKey',
    });
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'ar';

    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();
    var newResponse = await http.Response.fromStream(response);

    // Decode the response body explicitly with UTF-8
    final responseData = json.decode(utf8.decode(newResponse.bodyBytes));

    // Return the text value from the JSON response
    return responseData['text'];
  }

  @override
  void initState() {
    super.initState();
    questions = generateQuestions()..shuffle();
  }

  List<String> splitVerseManuallyWithSpecialChars(String verse) {
    const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
    List<String> words = verse.split(" ");
    List<String> processedWords = [];

    for (int i = 0; i < words.length; i++) {
      if (specialChars.any((char) => words[i].contains(char)) && i > 0) {
        processedWords[processedWords.length - 1] =
            "${words[i]} ${processedWords[processedWords.length - 1]}";
      } else {
        processedWords.add(words[i]);
      }
    }

    return processedWords;
  }

  List<Map<String, dynamic>> generateQuestions() {
    //split up the types of questions
    List<Map<String, dynamic>> generatedQuestions = [];
    List<Map<String, dynamic>> fillInTheBlankQuestions = [];
    List<Map<String, dynamic>> whatComesNextQuestions = [];
    List<Map<String, dynamic>> dragAndDropQuestions = [];

    for (int i = 0; i < widget.versesList.length; i++) {
      String verse = widget.versesList[i];
      List<String> words = splitVerseManuallyWithSpecialChars(verse);

      if (i < widget.versesList.length - 1) {
        whatComesNextQuestions.add(_generateWhatComesNextQuestion(i));
      }

      // Only add fill in the blank for verses with more than 1 word
      if (!words.contains('')) {
        fillInTheBlankQuestions.add(_generateFillInTheBlankQuestion(verse));
      }

      // Only add drag and drop for verses between 2 and 7 words
      if (!words.contains('') && words.length < 15) {
        dragAndDropQuestions.add(_generateDragAndDropQuestion(verse));
      }
    }

    dragAndDropQuestions.shuffle();
    fillInTheBlankQuestions.shuffle();
    whatComesNextQuestions.shuffle();

    // Add drag and drop questions
    generatedQuestions.addAll(dragAndDropQuestions.length > 7
        ? dragAndDropQuestions.take(7)
        : dragAndDropQuestions);

    int dDCount = (20 - generatedQuestions.length + 1) ~/ 2;
    int count = 1;

    for (int i = 0;
        i < whatComesNextQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Check if this what_next question's first word matches any drag_drop question's first word
      bool hasMatchingDragDrop = generatedQuestions.any((q) {
        String whatNextFirstWord = splitVerseManuallyWithSpecialChars(
                whatComesNextQuestions[i]['verse'])
            .first;
        return q['firstWord'] == whatNextFirstWord;
      });

      // Only add if there's no matching drag_drop question and within count limit
      if (!hasMatchingDragDrop && count <= dDCount) {
        generatedQuestions.add(whatComesNextQuestions[i]);
        count++;
      }
    }

    for (int i = 0;
        i < fillInTheBlankQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Get first word of the current fill_blank question
      String fillBlankFirstWord =
          fillInTheBlankQuestions[i]['verse'].split(' ').first;

      // Check for matches with drag_drop and what_next questions
      bool hasMatchingQuestion = generatedQuestions.any((q) {
        if (q['type'] == 'drag_drop') {
          return q['firstWord'] == fillBlankFirstWord;
        } else if (q['type'] == 'what_next') {
          String whatNextCorrectFirstWord =
              splitVerseManuallyWithSpecialChars(q['correctAnswer']).first;
          return whatNextCorrectFirstWord == fillBlankFirstWord;
        }
        return false;
      });

      // Only add if there's no matching question
      if (!hasMatchingQuestion) {
        generatedQuestions.add(fillInTheBlankQuestions[i]);
      }
    }

    for (int i = 0;
        i < fillInTheBlankQuestions.length && generatedQuestions.length < 20;
        i++) {
      // Check for matches with drag_drop and what_next questions
      bool hasMatchingQuestion = generatedQuestions.any((q) {
        if (q['type'] == 'fill_blank') {
          return fillInTheBlankQuestions[i]['correctAnswers']
              .contains(q['correctAnswers'].first);
        }
        return false;
      });

      // Only add if there's no matching question
      if (!hasMatchingQuestion) {
        generatedQuestions.add(fillInTheBlankQuestions[i]);
      }
    }

    return generatedQuestions;
  }

  Map<String, dynamic> _generateFillInTheBlankQuestion(String verse) {
    List<String> words = verse.split(' ');

    // Determine number of blanks based on verse length
    int numberOfBlanks = words.length >= 18
        ? 3
        : words.length >= 10
            ? 2
            : 1;

    // Keep track of missing words and their indices
    List<String> missingWords = [];
    List<int> missingIndices = [];
    const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];

    // Generate unique random indices for blanks
    while (missingIndices.length < numberOfBlanks) {
      int index = Random().nextInt(words.length);

      if (specialChars.contains(words[index])) {
        continue;
      }

      if (!missingIndices.contains(index)) {
        missingIndices.add(index);
      }
    }

    missingIndices.sort();
    for (int i = 0; i < missingIndices.length; i++) {
      missingWords.add(words[missingIndices[i]]);
    }

    // Create verse with blanks
    List<String> verseWithBlanks = List.from(words);
    for (int i = 0; i < missingIndices.length; i++) {
      verseWithBlanks[missingIndices[i]] = '____';
    }

    return {
      'type': 'fill_blank',
      'question': numberOfBlanks > 1
          ? "Fill in the missing words:"
          : "Fill in the missing word:",
      'verse': verseWithBlanks.join(' '),
      'options': [
        ...missingWords,
        ...getRandomWords(missingWords, verse, numberOfBlanks)
      ]..shuffle(),
      'correctAnswers': missingWords,
      'missingIndices': missingIndices,
    };
  }

  Map<String, dynamic> _generateWhatComesNextQuestion(int index) {
    return {
      'type': 'what_next',
      'question': "What verse comes after this?",
      'verse': widget.versesList[index],
      'options': [widget.versesList[index + 1], ...getRandomVerses(index)]
        ..shuffle(),
      'correctAnswer': widget.versesList[index + 1],
    };
  }

  Map<String, dynamic> _generateDragAndDropQuestion(String verse) {
    List<String> words = splitVerseManuallyWithSpecialChars(verse);
    String firstWord = words.first;
    List<String> shuffledWords = List.from(words.skip(1))..shuffle();

    return {
      'type': 'drag_drop',
      'question': "Arrange the verse correctly:",
      'firstWord': firstWord,
      'shuffledWords': shuffledWords,
      'correctOrder': words.skip(1).toList(),
    };
  }

  List<String> getRandomWords(
      List<String> missingWords, String currentVerse, int numberOfBlanks) {
    List<String> allWords = widget.versesList
        .where((verse) => verse != currentVerse)
        .expand((verse) => splitVerseManuallyWithSpecialChars(verse))
        .toList();
    allWords.removeWhere((word) => missingWords.contains(word));
    allWords.shuffle();
    return allWords.take(numberOfBlanks == 3 ? 5 : 3 * numberOfBlanks).toList();
  }

  List<String> getRandomVerses(int index) {
    List<String> verses = List.from(widget.versesList);
    verses.removeAt(index);
    verses.removeAt(index);
    verses.shuffle();
    return verses.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (currentQuestionIndex == -1) {
      return _buildIntroScreen();
    }

    if (currentQuestionIndex >= questions.length) {
      return _buildResultScreen();
    }

    var currentQuestion = questions[currentQuestionIndex];

    return Scaffold(
      body: SafeArea(
          child: currentQuestion['type'] == 'fill_blank'
              ? _buildFillInTheBlankQuestion(currentQuestion)
              : currentQuestion['type'] == 'what_next'
                  ? _buildWhatComesNextQuestion(currentQuestion)
                  : _buildVerseQuestion(currentQuestion)),
    );
  }

  Widget _buildIntroScreen() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Column(
            children: [
              // App Bar with centered title
              Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      BackButton(),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                  Text(
                    'Review Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // Quiz Icon with a subtle shadow and animation
              Icon(
                Icons.quiz,
                size: 100,
                color: Colors.blue.shade700,
              ),

              const SizedBox(height: 20),

              // Quiz Information
              Text(
                'Review Quiz for:',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.reviewTitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),

              const Spacer(),

              // Start Button with gradient and hover effect
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: ElevatedButton(
                  onPressed: () => setState(() => currentQuestionIndex = 0),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Start Quiz',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    return Scaffold(
      body: Center(
        child: Text(
          'Quiz Completed! Your Score: $score/${questions.length}',
          style: GoogleFonts.poppins(fontSize: 24),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildFillInTheBlankQuestion(Map<String, dynamic> question) {
    return Column(
      children: [
        // Header with back button and progress
        Padding(
          padding:
              const EdgeInsets.only(left: 4, right: 20, top: 0, bottom: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    currentQuestionIndex--;
                    chosenWords = [];
                  });
                },
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentQuestionIndex + 1}/${questions.length}',
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
                  question['question'],
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
                    children:
                        splitVerseManuallyWithSpecialChars(question['verse'])
                            .map<Widget>((word) {
                      bool isBlank = word == '____';
                      bool isFilledWord =
                          !isBlank && chosenWords.contains(word);

                      if (isFilledWord) {
                        return GestureDetector(
                          onTap: () {
                            List<String> words =
                                splitVerseManuallyWithSpecialChars(
                                    question['verse']);
                            int wordIndex = words.indexOf(word);
                            words[wordIndex] = '____';
                            setState(() {
                              question['verse'] = words.join(' ');
                              question['options'].add(word);
                              chosenWords.remove(word);
                            });
                          },
                          child: Text(
                            word,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 24,
                              height: 1.6,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        );
                      } else {
                        return Text(
                          word,
                          style: GoogleFonts.scheherazadeNew(
                            fontSize: 24,
                            height: 1.6,
                            color: Colors.grey.shade900,
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
                        physics: NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 2.5,
                        children: question['options'].map<Widget>((option) {
                          bool isSelected =
                              question['verse'].split(' ').contains(option);
                          return ElevatedButton(
                            onPressed: () {
                              List<String> words = question['verse'].split(' ');
                              int blankIndex = words.indexOf('____');
                              if (blankIndex != -1) {
                                if (isSelected) {
                                  words[blankIndex] = '____';
                                  setState(() {
                                    question['verse'] = words.join(' ');
                                    question['options'].add(option);
                                    chosenWords.remove(option);
                                  });
                                } else {
                                  words[blankIndex] = option;
                                  setState(() {
                                    question['verse'] = words.join(' ');
                                    question['options'].remove(option);
                                    chosenWords.add(option);
                                  });
                                }
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
                                side: BorderSide(color: Colors.blue.shade200),
                              ),
                            ),
                            child: Text(
                              option,
                              style: GoogleFonts.scheherazadeNew(
                                fontSize: 20,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (!question['verse'].contains('____'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            bool allCorrect =
                                chosenWords.isEmpty ? true : false;

                            if (question['correctAnswers'].length ==
                                chosenWords.length) {
                              allCorrect = true;
                              for (int i = 0;
                                  i < question['correctAnswers'].length;
                                  i++) {
                                if (question['correctAnswers'][i] !=
                                    chosenWords[i]) {
                                  allCorrect = false;
                                  break;
                                }
                              }
                            }

                            if (allCorrect) {
                              setState(() {
                                score++;
                                currentQuestionIndex++;
                                chosenWords = [];
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Some answers are incorrect. Try again!'),
                                  duration: Duration(seconds: 2),
                                  backgroundColor: Colors.red,
                                ),
                              );
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
                            'Next',
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

  Widget _buildWhatComesNextQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
              const EdgeInsets.only(left: 4, right: 20, top: 0, bottom: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => currentQuestionIndex--),
              ),
              Expanded(
                child: LinearProgressIndicator(
                  value: (currentQuestionIndex + 1) / questions.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${currentQuestionIndex + 1}/${questions.length}',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),

        // Question Text
        Text(
          question['question'],
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        // Display Verse
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            question['verse'],
            style: GoogleFonts.scheherazadeNew(
              fontSize: 22,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),

        const SizedBox(height: 20),

        // Record Button
        ElevatedButton(
          onPressed: () async {
            if (isRecording) {
              String? filePath = await recorder.stop();
              if (filePath != null) {
                String transcription = await convertSpeechToText(filePath);
                setState(() {
                  isRecording = false;
                  recordingPath = filePath;
                  text = transcription;
                });
              }
            } else {
              if (await recorder.hasPermission()) {
                final Directory appDocumentsDirectory =
                    await getApplicationDocumentsDirectory();
                final path = '${appDocumentsDirectory.path}/recording.wav';
                // Configure recording options
                final RecordConfig config = RecordConfig(
                  sampleRate: 44100, // High quality
                  bitRate: 128000, // Optional: High bitrate for better quality
                  encoder: AudioEncoder.wav,
                );

                await recorder.start(config, path: path);

                setState(() {
                  isRecording = true;
                  recordingPath = path; // Save the path for later use
                });
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            shape: CircleBorder(),
            padding: const EdgeInsets.all(10),
          ),
          child: Icon(isRecording ? Icons.stop : Icons.mic, size: 30),
        ),

        // SizedBox(
        //   width: MediaQuery.of(context).size.width,
        //   child: Column(
        //     children: [
        //       if (recordingPath != null)
        //         MaterialButton(
        //           onPressed: () async {
        //             if (audioPlayer.playing) {
        //               audioPlayer.stop();
        //               setState(() {
        //                 isPlaying = false;
        //               });
        //             } else {
        //               setState(() {
        //                 isPlaying = true;
        //               });
        //               await audioPlayer.setFilePath(recordingPath!);
        //               await audioPlayer.play();
        //             }
        //           },
        //           color: Colors.blue.shade700,
        //           child: Text(isPlaying ? 'Stop' : 'Play Recording',
        //               style: const TextStyle(color: Colors.white)),
        //         ),
        //       if (recordingPath == null) Text('No recording'),
        //     ],
        //   ),
        // ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: ElevatedButton(
            onPressed: () async {
              if (text == question['correctAnswer']) {
                setState(() {
                  score++;
                });
              }
              setState(() {
                text = '';
                currentQuestionIndex++;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              'Next',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        Text(text, style: GoogleFonts.notoNaskhArabic(fontSize: 20)),
      ],
    );
  }

  Widget _buildVerseQuestion(Map<String, dynamic> question) {
    return BuildVerseQuestion(
      currentQuestionIndex: currentQuestionIndex,
      questions: questions,
      onNextQuestion: (int index) {
        setState(() {
          score++;
          currentQuestionIndex = index;
        });
      },
      onPreviousQuestion: () {
        setState(() {
          currentQuestionIndex--;
        });
      },
    );
  }
}
