import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'dart:math' show max, min;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';

class WhatComesNextQuestion extends StatefulWidget {
  final Map<String, dynamic> question;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Function(bool wasCorrect) onNext;
  final VoidCallback onClose;

  const WhatComesNextQuestion({
    super.key,
    required this.question,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.onClose,
  });

  @override
  State<WhatComesNextQuestion> createState() => _WhatComesNextQuestionState();
}

class _WhatComesNextQuestionState extends State<WhatComesNextQuestion> {
  final AudioRecorder recorder = AudioRecorder();
  AudioPlayer audioPlayer = AudioPlayer();

  bool isRecording = false;
  String? recordingPath;
  bool isPlaying = false;
  String text = '';

  List<double> amplitudes = List.generate(30, (index) => 0.0);
  Timer? _amplitudeTimer;

  String? apiSecretKey = Platform.environment['apiSecretKey'];

  @override
  void dispose() {
    cleanupRecordingFile();
    _amplitudeTimer?.cancel();
    recorder.dispose();
    audioPlayer.dispose();
    super.dispose();
  }

  Future<void> cleanupRecordingFile() async {
    if (recordingPath != null) {
      try {
        final file = File(recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
        recordingPath = null;
      } catch (e) {
        print('Error deleting recording file: $e');
      }
    }
  }

  void _updateAmplitudes() {
    if (!isRecording) {
      _amplitudeTimer?.cancel();
      setState(() {
        amplitudes = List.generate(30, (index) => 0.0);
      });
      return;
    }

    _amplitudeTimer =
        Timer.periodic(const Duration(milliseconds: 50), (timer) async {
      if (!isRecording) {
        timer.cancel();
        return;
      }

      try {
        final amplitude = await recorder.getAmplitude();
        double normalizedValue = 0.0;
        normalizedValue = ((amplitude.current + 160) / 160).clamp(0.0, 1.0);

        setState(() {
          amplitudes.removeAt(0);
          amplitudes.add(normalizedValue);
        });
      } catch (e) {
        print('Amplitude error: $e');
        setState(() {
          amplitudes.removeAt(0);
          amplitudes.add(0.0);
        });
      }
    });
  }

  Future<String> convertSpeechToText(String filePath) async {
    var url = Uri.https('api.openai.com', 'v1/audio/transcriptions');
    var request = http.MultipartRequest('POST', url);
    request.headers.addAll({
      'Authorization': 'Bearer $apiSecretKey',
    });
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'ar';

    request.files.add(http.MultipartFile.fromBytes(
      'file',
      File(filePath).readAsBytesSync(),
      filename: 'recording.wav',
      contentType: MediaType('audio', 'wav'),
    ));
    var response = await request.send();
    var newResponse = await http.Response.fromStream(response);

    // Decode the response body explicitly with UTF-8
    final responseData = json.decode(utf8.decode(newResponse.bodyBytes));

    // Return the text value from the JSON response
    return responseData['text'];
  }

  String normaliseArabicText(String text) {
    // Remove diacritical marks (Harakat, Shadda, Sakt, etc.)
    final harakatRegex = RegExp(
        r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+'); // Tanween, Fatha, Kasra, Damma, etc.
    //take out madd and special
    text = text.replaceAll(harakatRegex, '');

    // Normalize Alif variations
    text = text.replaceAll(RegExp(r'[آٱ]'), 'ا');

    // Normalize Ya at end of word (convert ى to ي)
    text = text.replaceAll('ي', 'ى');
    text = text.replaceAll('ٓ', '');
    //tatweel
    text = text.replaceAll('ـ', '');
    //remove extra spaces
    text = text.trim();

    return text;
  }

  List<Map<String, dynamic>> findDifferences(
      String correct, String transcribed) {
    String processedCorrect = normaliseArabicText(correct);
    String processedTranscribed = normaliseArabicText(transcribed);

    int lenCorrect = processedCorrect.length;
    int lenTranscribed = processedTranscribed.length;
    int lengthDifference = (lenCorrect - lenTranscribed).abs();
    List<Map<String, dynamic>> differences = [];

    // If difference in length is greater than 1, mark as incorrect
    if (lengthDifference > 1) {
      return [
        {"error": "Word is too different to be corrected"}
      ];
    }

    // If difference is exactly 1, find the missing/extra character
    if (lengthDifference == 1) {
      if (processedCorrect[lenCorrect - 1] !=
              processedTranscribed[lenTranscribed - 1] &&
          lenCorrect > lenTranscribed &&
          processedCorrect[lenCorrect - 1] == 'ء') {
        processedTranscribed = processedTranscribed.replaceRange(
            lenTranscribed - 1, lenTranscribed, 'ء');
      } else {
        // First check if it's just an extra/missing character causing a shift
        bool foundShift = false;
        for (int i = 0; i < min(lenCorrect, lenTranscribed); i++) {
          if (processedCorrect[i] != processedTranscribed[i]) {
            // Check if rest of string matches after skipping one character
            if (i + 1 < lenTranscribed &&
                processedCorrect.substring(i) ==
                    processedTranscribed.substring(i + 1)) {
              // Extra character in transcribed
              differences.add({
                "index": i,
                "incorrect": processedTranscribed[i],
                "correct": ""
              });
              foundShift = true;
              break;
            } else if (i + 1 < lenCorrect &&
                processedCorrect.substring(i + 1) ==
                    processedTranscribed.substring(i)) {
              // Missing character in transcribed
              differences.add({
                "index": i,
                "incorrect": "",
                "correct": processedCorrect[i]
              });
              foundShift = true;
              break;
            }
          }
        }

        // If no shift was found, fall back to character-by-character comparison
        if (!foundShift) {
          for (int i = 0; i < min(lenCorrect, lenTranscribed); i++) {
            if (processedCorrect[i] != processedTranscribed[i]) {
              differences.add({
                "index": i,
                "incorrect": processedTranscribed[i],
                "correct": processedCorrect[i]
              });
            }
          }
        }
        return differences.reversed.toList();
      }
    }

    // Use dynamic programming for normal comparison when lengths are the same
    List<List<int>> dp = List.generate(
        lenCorrect + 1, (i) => List.filled(lenTranscribed + 1, 0));

    // Initialize DP table
    for (int i = 0; i <= lenCorrect; i++) {
      dp[i][0] = i;
    }
    for (int j = 0; j <= lenTranscribed; j++) {
      dp[0][j] = j;
    }

    // Compute Levenshtein distance table
    for (int i = 1; i <= lenCorrect; i++) {
      for (int j = 1; j <= lenTranscribed; j++) {
        if (processedCorrect[i - 1] == processedTranscribed[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1]; // No change
        } else {
          dp[i][j] = 1 +
              [dp[i - 1][j], dp[i][j - 1], dp[i - 1][j - 1]]
                  .reduce((a, b) => a < b ? a : b);
        }
      }
    }

    // Backtrack to find the actual operations

    int i = lenCorrect, j = lenTranscribed;

    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          processedCorrect[i - 1] == processedTranscribed[j - 1]) {
        i--;
        j--;
      } else if (i > 0 && (j == 0 || dp[i][j] == dp[i - 1][j] + 1)) {
        // Deletion (missing letter in transcribed text)
        differences.add({
          "index": i - 1,
          "incorrect": "",
          "correct": processedCorrect[i - 1]
        });
        i--;
      } else if (j > 0 && (i == 0 || dp[i][j] == dp[i][j - 1] + 1)) {
        // Insertion (extra letter in transcribed text)
        differences.add({
          "index": i,
          "incorrect": processedTranscribed[j - 1],
          "correct": ""
        });
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        // Substitution (incorrect letter)
        differences.add({
          "index": i - 1,
          "incorrect": processedTranscribed[j - 1],
          "correct": processedCorrect[i - 1]
        });
        i--;
        j--;
      }
    }

    return differences.reversed.toList(); // Reverse to maintain correct order
  }

  /// Construct the final transcribed word, keeping Harakat intact
  String applyCorrections(String correct,
      List<Map<String, dynamic>> differences, String transcribed) {
    // If there are no differences, return the original transcribed text
    if (differences.isEmpty) {
      return correct;
    }

    List<String> finalTranscribedChars = correct.split('');

    // Handle error case
    if (differences.length == 1 && differences[0]["error"] != null) {
      return transcribed;
    }

    // Handle single difference
    if (differences.length == 1) {
      int index = differences[0]["index"] ?? 0;
      if (index >= finalTranscribedChars.length) {
        return transcribed;
      }

      String? incorrect = differences[0]["incorrect"] as String?;
      String? correctChar = differences[0]["correct"] as String?;

      if (incorrect != null &&
          correctChar != null &&
          incorrect.isNotEmpty &&
          correctChar.isNotEmpty) {
        for (int i = 0; i < finalTranscribedChars.length; i++) {
          if (index == 0) {
            finalTranscribedChars[i] = incorrect;
            break;
          }
          //if the character is one of the special characters or harakat skip else -1 from the index
          const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
          final harakatRegex =
              RegExp(r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+');
          if (!specialChars.contains(finalTranscribedChars[i]) &&
              !harakatRegex.hasMatch(finalTranscribedChars[i])) {
            index = index - 1;
          }
        }
      }

      return finalTranscribedChars.join();
    }
//Todo: Handle missing word since each word will be in the wrong place
    // If there are multiple differences, return the transcribed text
    if (differences.length > 1) {
      return transcribed;
    }

    return correct;
  }

  /// Main function to compare two verses word by word
  List<Map<String, dynamic>> compareVerses(String correct, String transcribed) {
    if (correct.isEmpty || transcribed.isEmpty) {
      return [];
    }

    List<String> correctWords = splitVerseManuallyWithSpecialChars(correct);
    List<String> transcribedWords =
        splitVerseManuallyWithSpecialChars(transcribed);

    if (correctWords.isEmpty) {
      return [];
    }

    int length = correctWords.length;
    List<Map<String, dynamic>> comparison = [];

    for (int i = 0; i < length; i++) {
      String actualWord = (i < correctWords.length) ? correctWords[i] : "";
      String processedWord = normaliseArabicText(actualWord);
      String processedTranscribedWord = (i < transcribedWords.length)
          ? normaliseArabicText(transcribedWords[i])
          : "";

      List<Map<String, dynamic>> differences = [];
      if (i < transcribedWords.length) {
        differences = findDifferences(processedWord, processedTranscribedWord);
      } else {
        differences = [
          {"error": "Missing word in transcription"}
        ];
      }

      // Construct the final transcribed word based on differences
      String finalTranscribedWord = applyCorrections(actualWord, differences,
          i < transcribedWords.length ? transcribedWords[i] : "");

      comparison.add({
        "actual_word": actualWord,
        "processed_word": processedWord,
        "processed_transcribed_word": processedTranscribedWord,
        "final_transcribed_word": finalTranscribedWord,
        "differences": differences
      });
    }

    return comparison;
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

  //make a join verse manually with special chars
  String joinVerseManuallyWithSpecialChars(List<String> words) {
    const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
    List<String> processedWords = [];

    for (String word in words) {
      // Check if the word contains a special character
      if (specialChars.any((char) => word.contains(char))) {
        // Extract the special character
        String specialChar = '';
        for (String char in specialChars) {
          if (word.contains(char)) {
            specialChar = char;
            break;
          }
        }
        // Remove the special character and add it to the end
        String cleanWord = word.replaceAll(specialChar, '');
        processedWords.add(
            '$cleanWord $specialChar'); // Removed space before special char
      } else {
        processedWords.add(word);
      }
    }

    return processedWords
        .join(' ')
        .replaceAll('  ', ' ')
        .trim(); // Remove any double spaces
  }

  Future<void> handleRecording(Map<String, dynamic> question) async {
    try {
      if (isRecording) {
        // Stop recording
        String? filePath = await recorder.stop();
        setState(() {
          isRecording = false;
          _amplitudeTimer?.cancel(); // Cancel timer when stopping
        });

        if (filePath != null) {
          // Convert to text only after successful stop
          String transcription = await convertSpeechToText(filePath);

          List<Map<String, dynamic>> comparison =
              compareVerses(question['correctAnswer'], transcription);
          List<String> processedTranscribedWords = comparison
              .map((e) => e['final_transcribed_word'] as String)
              .toList();

          String processedTranscribedWord =
              joinVerseManuallyWithSpecialChars(processedTranscribedWords);

          print(transcription);
          print(question['correctAnswer']);
          print(comparison);

          setState(() {
            recordingPath = filePath;
            text = processedTranscribedWord;
          });

          // Don't delete the file here anymore - we'll delete it after playback
        }
      } else {
        // Start recording
        if (await recorder.hasPermission()) {
          // Ensure we have a valid directory path
          final dir = await getApplicationDocumentsDirectory();
          if (dir.path.isEmpty) {
            throw Exception('Could not get application documents directory');
          }

          final path =
              '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

          // Initialize recording with explicit configuration
          await recorder.start(
            RecordConfig(
              sampleRate: 44100,
              bitRate: 128000,
              encoder: AudioEncoder.wav,
              numChannels: 1,
            ),
            path: path,
          );

          setState(() {
            isRecording = true;
            recordingPath = path;
          });

          // Start updating amplitudes
          _updateAmplitudes();
        } else {
          throw Exception('Recording permission not granted');
        }
      }
    } catch (e, stackTrace) {
      print('Recording error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isRecording = false;
        _amplitudeTimer?.cancel();
        recordingPath = null;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording audio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRecordButton() {
    return Column(
      children: [
        if (isRecording)
          Container(
            height: 50,
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                20,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 50),
                  width: 4,
                  height: max(2, amplitudes[index] * 40),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => handleRecording(widget.question),
          child: Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.shade500,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                widget.question['question'],
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 40),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: Text(
                    widget.question['verse'],
                    style: GoogleFonts.scheherazadeNew(
                      fontSize: 24,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildRecordButton(),
                    if (text.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Text(
                            text,
                            style: GoogleFonts.scheherazadeNew(
                              fontSize: 24,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () {
                bool isCorrect = text == widget.question['correctAnswer'];
                widget.onNext(isCorrect);
                setState(() {
                  text = '';
                });
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
    );
  }
}
