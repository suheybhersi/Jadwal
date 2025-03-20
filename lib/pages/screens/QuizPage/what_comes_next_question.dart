// Core Flutter imports
import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math' show max, min;

// Flutter packages
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

// Audio-related packages
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

// File/storage-related packages
import 'package:path_provider/path_provider.dart';

// Network & API packages
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WhatComesNextQuestion extends StatefulWidget {
  final Map<String, dynamic> question;
  final int currentQuestionIndex;
  final int totalQuestions;
  final Function(bool wasCorrect) onNext;
  final Map<int, Map<String, dynamic>> answeredQuestions;
  final VoidCallback onClose;

  const WhatComesNextQuestion({
    super.key,
    required this.question,
    required this.currentQuestionIndex,
    required this.totalQuestions,
    required this.onNext,
    required this.answeredQuestions,
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
  // Timer for maximum recording duration
  Timer? _recordingDurationTimer;

  String? apiKey = dotenv.env['API_KEY'];

  List<Map<String, dynamic>> comparison = [];

  // Add these new state variables at the top of the class
  bool isRecitationCorrect = false;
  String feedbackMessage = '';
  int incorrectWordCount = 0;
  bool hasSubmittedAnswer = false;

  @override
  void dispose() {
    // Ensure timers are cancelled
    _amplitudeTimer?.cancel();
    _recordingDurationTimer?.cancel();

    // Properly dispose of audio resources
    recorder.dispose();
    audioPlayer.stop().then((_) => audioPlayer.dispose());

    // Clean up any recording files
    cleanupRecordingFile();

    super.dispose();
  }

  Future<void> cleanupRecordingFile() async {
    if (recordingPath != null) {
      try {
        final file = File(recordingPath!);
        if (await file.exists()) {
          await file.delete();
          print('Recording file deleted: $recordingPath');
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
        double normalisedValue = 0.0;
        normalisedValue = ((amplitude.current + 80) / 80).clamp(0.0, 1.0);

        setState(() {
          amplitudes.removeAt(0);
          amplitudes.add(normalisedValue);
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
    try {
      var url = Uri.https('api.openai.com', 'v1/audio/transcriptions');

      // Validate API key exists
      if (apiKey == null || apiKey!.isEmpty) {
        throw Exception(
            'API key is missing. Please check your environment variables.');
      }

      var request = http.MultipartRequest('POST', url);
      request.headers.addAll({
        'Authorization': 'Bearer $apiKey',
      });
      request.fields['model'] = 'whisper-1';
      request.fields['language'] = 'ar';

      // Check if file exists before reading
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Recording file not found: $filePath');
      }

      request.files.add(http.MultipartFile.fromBytes(
        'file',
        file.readAsBytesSync(),
        filename: 'recording.wav',
        contentType: MediaType('audio', 'wav'),
      ));

      // Add timeout for network requests
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception(
              'Network request timed out. Please check your internet connection.');
        },
      );

      var newResponse = await http.Response.fromStream(streamedResponse);

      // Check for API errors
      if (newResponse.statusCode != 200) {
        final error = json.decode(utf8.decode(newResponse.bodyBytes));
        throw Exception(
            'API Error (${newResponse.statusCode}): ${error['error']?['message'] ?? 'Unknown error'}');
      }

      // Decode the response body explicitly with UTF-8
      final responseData = json.decode(utf8.decode(newResponse.bodyBytes));

      // Return the text value from the JSON response
      return responseData['text'] ?? '';
    } catch (e) {
      print('Speech-to-text conversion error: $e');
      return 'Error: Unable to convert speech to text. ${e.toString()}';
    }
  }

  String normaliseArabicText(String text) {
    // Define regex patterns once for better performance
    final harakatRegex = RegExp(
        r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+'); // Tanween, Fatha, Kasra, Damma, etc.
    final alifVariationsRegex = RegExp(r'[ـٰآٱـٰٓ]');
    final tatweelRegex = RegExp(r'[ٓـ]');
    const hamzaVariations = ['ء', 'ؤ', 'ئ', 'أ'];

    // Process the text with more efficient chaining of replacements
    String normalised = text
        .replaceAll(harakatRegex, '') // Remove diacritics and special marks
        .replaceAll(alifVariationsRegex, 'ا') // Normalise alif variations
        .replaceAllMapped(RegExp(r'[' + hamzaVariations.join() + r']'),
            (match) {
          return 'ء'; // Normalize all hamza forms to basic ء
        })
        .replaceAll('ءا', 'ا') // Normalise hamza+alif
        .replaceAll('ي', 'ى') // Normalise Ya and Alif Maqsura
        .replaceAll(tatweelRegex, '') // Remove tatweel characters
        .trim(); // Remove extra spaces

    return normalised;
  }

  List<Map<String, dynamic>> findDifferences(
      String correct, String transcribed) {
    String processedCorrect = normaliseArabicText(correct);
    String processedTranscribed = normaliseArabicText(transcribed);

    // If the processed texts are identical after normalisation, return no differences
    if (processedCorrect == processedTranscribed) {
      return [];
    }

    int lenCorrect = processedCorrect.length;
    int lenTranscribed = processedTranscribed.length;
    int lengthDifference = (lenCorrect - lenTranscribed).abs();
    List<Map<String, dynamic>> differences = [];

    // Special case: If the only difference is a missing alif ('ا') at index 3 or 4, ignore it
    if (lengthDifference == 1) {
      // Check if longer word has an alif at the position where the shorter word is missing it
      if (lenCorrect > lenTranscribed) {
        // Find where the first difference occurs
        int diffIndex = -1;
        for (int i = 0; i < lenTranscribed; i++) {
          if (processedCorrect[i] != processedTranscribed[i]) {
            diffIndex = i;
            break;
          }
        }

        // If difference is at index 3 or 4 (common positions for alif in demonstrative pronouns)
        // and the difference is just an alif, ignore it
        if ((diffIndex == 3 || diffIndex == 4) &&
            processedCorrect[diffIndex] == 'ا') {
          if (processedCorrect.substring(0, diffIndex) +
                  processedCorrect.substring(diffIndex + 1) ==
              processedTranscribed) {
            return []; // Consider them matching if only difference is a missing alif at position 3 or 4
          }
        }
      }
    }

    // This allows for minor variations like added/omitted characters
    if (lengthDifference > 2) {
      return [
        {"error": "Word is too different to be corrected"}
      ];
    }

    // For special cases with added/missing alif or other common variations,
    // we'll use a simple comparison check
    // Simple equality check instead of semantic similarity
    if (processedCorrect == processedTranscribed) {
      return []; // Consider them matching if they're identical after normalisation
    }

    // If difference is exactly 1 or 2, find the missing/extra character
    if (lengthDifference <= 2) {
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

              // Special case: if the missing character is an alif, we'll ignore it
              if (processedCorrect[i] == 'ا') {
                // Additional check: if this is the only difference, ignore it
                if (processedCorrect.substring(0, i) +
                        processedCorrect.substring(i + 1) ==
                    processedTranscribed) {
                  return []; // No differences to report
                }
              }

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

    // Initialise DP table
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

  /// Construct the final transcribed word, keeping Harakat intact and adding error information
  Map<String, dynamic> applyCorrections(String correct,
      List<Map<String, dynamic>> differences, String transcribed) {
    // If there are no differences, return the original transcribed text with no errors
    if (differences.isEmpty) {
      return {
        'text': correct,
        'isError': false,
      };
    }

    // Handle error case
    if (differences.length == 1 && differences[0]["error"] != null) {
      return {
        'text': transcribed,
        'isError': true,
      };
    }

    // Handle single difference
    if (differences.length == 1) {
      int index = differences[0]["index"] ?? 0;
      String? incorrect = differences[0]["incorrect"] as String?;
      String? correctChar = differences[0]["correct"] as String?;

      // If it's a substitution (both incorrect and correct are non-empty)
      if (incorrect != null &&
          correctChar != null &&
          incorrect.isNotEmpty &&
          correctChar.isNotEmpty) {
        // Create a copy of the original text
        List<String> correctChars = correct.split('');
        List<String> result = [];

        // Map the normalised index to the actual index in the text with diacritics
        int actualIndex = 0;
        int normalisedIndex = 0;
        const specialChars = ['ۜ', 'ۘ', 'ۙ', 'ۚ', 'ۛ', 'ۖ', 'ۗ'];
        final harakatRegex =
            RegExp(r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+');

        for (int i = 0; i < correctChars.length; i++) {
          String char = correctChars[i];

          // If not a special character or diacritic, increment normalised index
          if (!specialChars.contains(char) && !harakatRegex.hasMatch(char)) {
            if (normalisedIndex == index) {
              // Found the position to replace
              result.add(incorrect);
              actualIndex = i + 1;
              break;
            }
            normalisedIndex++;
          }
          result.add(char);
        }

        // Add the rest of the characters after the replaced one
        if (actualIndex < correctChars.length) {
          result.addAll(correctChars.sublist(actualIndex));
        }

        return {
          'text': result.join(),
          'isError': true,
        };
      }

      // For other cases (insertions or deletions), return the transcribed text
      return {
        'text': transcribed,
        'isError': true,
      };
    }

    // If there are multiple differences, return the transcribed text
    if (differences.length > 1) {
      return {
        'text': transcribed,
        'isError': true,
      };
    }

    return {
      'text': correct,
      'isError': false,
    };
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

  // Helper function to check if a word should be split (starts with يا variants)
  bool shouldSplitYaMadd(String word) {
    // Normalise by removing diacritics
    final harakatRegex =
        RegExp(r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+');
    String normalised = word.replaceAll(harakatRegex, '');

    if (normalised.length < 2) return false;

    // Check for ya-alif patterns
    if ((normalised[0] == 'ي' || normalised[0] == 'ى') &&
        (normalised[1] == 'ا' ||
            normalised[1] == 'ٰ' ||
            normalised[1] == 'ـ')) {
      return true;
    }

    return false;
  }

  // Find the split point for a ya-madd word
  int findYaMaddSplitPoint(String word) {
    final harakatRegex =
        RegExp(r'[\u064B-\u0652\u06D4\u0670\u0674\u06D5-\u06ED]+');
    int splitPoint = 0;
    int realCharCount = 0;

    // Find after the second non-diacritic character
    for (int i = 0; i < word.length; i++) {
      if (!harakatRegex.hasMatch(word[i])) {
        realCharCount++;
        if (realCharCount == 2) {
          // Found the second core character (typically alif)
          // The split point should be right after it and any diacritics
          for (int j = i + 1; j < word.length; j++) {
            if (!harakatRegex.hasMatch(word[j])) {
              // Found the first non-diacritic after alif
              return j;
            }
          }
          return i + 1; // Default to right after alif if no clear point
        }
      }
    }

    return splitPoint;
  }

  // Process words starting with يـٰ or similar to يا and split into two words
  List<String> preprocessYaMadd(List<String> words) {
    List<String> result = [];

    for (String word in words) {
      if (shouldSplitYaMadd(word) && word.length > 2) {
        int splitPoint = findYaMaddSplitPoint(word);

        // Add "يا" as a separate word
        result.add("يا");

        // Add the rest of the word if there's content after the split point
        if (splitPoint < word.length) {
          result.add(word.substring(splitPoint));
        }
      } else {
        // No need to split this word
        result.add(word);
      }
    }

    return result;
  }

  /// Main function to compare two verses word by word
  List<Map<String, dynamic>> compareVerses(String correct, String transcribed) {
    if (correct.isEmpty || transcribed.isEmpty) {
      return [];
    }

    // Split the verse into words
    List<String> originalCorrectWords =
        splitVerseManuallyWithSpecialChars(correct);

    // Create a record of which words should be split and their original form
    List<bool> wordShouldBeSplit = originalCorrectWords
        .map((word) => shouldSplitYaMadd(word) && word.length > 2)
        .toList();

    // Split words starting with يـٰ for comparison purposes
    List<String> correctWords = preprocessYaMadd(originalCorrectWords.toList());

    // Process transcribed words similarly
    List<String> originalTranscribedWords =
        splitVerseManuallyWithSpecialChars(transcribed);
    List<String> transcribedWords = preprocessYaMadd(originalTranscribedWords);

    if (correctWords.isEmpty) return [];

    // Perform word alignment to handle extra/missing words
    List<Map<String, dynamic>> alignmentResult =
        alignWords(correctWords, transcribedWords);

    // Build a mapping from split index to original index
    Map<int, int> splitToOriginalIndex = {};
    int splitIdx = 0;
    for (int i = 0; i < wordShouldBeSplit.length; i++) {
      if (wordShouldBeSplit[i]) {
        // This word was split into two
        splitToOriginalIndex[splitIdx] = i;
        splitToOriginalIndex[splitIdx + 1] = i;
        splitIdx += 2;
      } else {
        // This word wasn't split
        splitToOriginalIndex[splitIdx] = i;
        splitIdx += 1;
      }
    }

    // Create split comparison based on the alignment
    List<Map<String, dynamic>> splitComparison = [];

    for (var alignedPair in alignmentResult) {
      int correctIndex = alignedPair['correctIndex'];
      int transcribedIndex = alignedPair['transcribedIndex'];
      bool isInsertion = alignedPair['operation'] == 'insertion';
      bool isDeletion = alignedPair['operation'] == 'deletion';
      bool isSubstitution = alignedPair['operation'] == 'substitution';
      bool isMatch = alignedPair['operation'] == 'match';

      String actualWord = "";
      String processedWord = "";
      String processedTranscribedWord = "";
      List<Map<String, dynamic>> differences = [];

      if (correctIndex >= 0 && correctIndex < correctWords.length) {
        actualWord = correctWords[correctIndex];
        processedWord = normaliseArabicText(actualWord);
      }

      if (transcribedIndex >= 0 && transcribedIndex < transcribedWords.length) {
        processedTranscribedWord =
            normaliseArabicText(transcribedWords[transcribedIndex]);
      }

      // Find character-level differences
      if (isMatch || isSubstitution) {
        // For matches and substitutions, compare the words normally
        differences = findDifferences(processedWord, processedTranscribedWord);
      } else if (isInsertion) {
        // Extra word in transcription
        differences = [
          {"error": "Extra word in transcription"}
        ];
      } else if (isDeletion) {
        // Missing word in transcription
        differences = [
          {"error": "Missing word in transcription"}
        ];
      }

      Map<String, dynamic> correctionResult;
      if (isMatch || isSubstitution) {
        correctionResult = applyCorrections(
            actualWord,
            differences,
            transcribedIndex >= 0 && transcribedIndex < transcribedWords.length
                ? transcribedWords[transcribedIndex]
                : "");
      } else {
        // For insertion/deletion, mark as error
        correctionResult = {
          'text': isDeletion
              ? actualWord
              : (transcribedIndex < transcribedWords.length
                  ? transcribedWords[transcribedIndex]
                  : ""),
          'isError': true,
        };
      }

      int originalIndex = -1;
      if (correctIndex >= 0 &&
          correctIndex < correctWords.length &&
          splitToOriginalIndex.containsKey(correctIndex)) {
        originalIndex = splitToOriginalIndex[correctIndex]!;
      }

      splitComparison.add({
        "actual_word": actualWord,
        "original_index": originalIndex,
        "processed_word": processedWord,
        "processed_transcribed_word": processedTranscribedWord,
        "final_transcribed_word": correctionResult['text'],
        "isError": correctionResult['isError'],
        "differences": differences,
        "operation": alignedPair['operation'],
      });
    }

    // Recombine split words into their original form
    List<Map<String, dynamic>> finalComparison = [];
    int i = 0;

    while (i < splitComparison.length) {
      int originalIndex = splitComparison[i]["original_index"];

      // Skip entries with invalid original index (extras in transcription)
      if (originalIndex == -1) {
        finalComparison.add(splitComparison[i]);
        i += 1;
        continue;
      }

      // Check if this word was split (by checking if the next word has the same original index)
      bool wasSplit = i < splitComparison.length - 1 &&
          splitComparison[i + 1]["original_index"] == originalIndex &&
          originalIndex != -1;

      if (wasSplit) {
        // Get the original word
        String originalWord = originalCorrectWords[originalIndex];

        // Determine if there was an error in either part
        bool hasError =
            splitComparison[i]["isError"] || splitComparison[i + 1]["isError"];

        finalComparison.add({
          "actual_word": originalWord,
          "processed_word": normaliseArabicText(originalWord),
          "processed_transcribed_word": splitComparison[i]
                  ["processed_transcribed_word"] +
              splitComparison[i + 1]["processed_transcribed_word"],
          "final_transcribed_word":
              originalWord, // Use original word with diacritics
          "isError": hasError,
          "differences":
              [] // No need for detailed differences in the combined word
        });

        i += 2; // Skip both parts of the split word
      } else {
        // This word wasn't split, just include it as is
        finalComparison.add(splitComparison[i]);
        i += 1;
      }
    }

    return finalComparison;
  }

  // This function aligns words between correct and transcribed verses using dynamic programming
  List<Map<String, dynamic>> alignWords(
      List<String> correctWords, List<String> transcribedWords) {
    int correctLen = correctWords.length;
    int transcribedLen = transcribedWords.length;

    // Create a DP table to find the minimum edit distance
    List<List<int>> dp = List.generate(
        correctLen + 1, (i) => List.generate(transcribedLen + 1, (j) => 0));

    // Initialise the DP table
    for (int i = 0; i <= correctLen; i++) {
      dp[i][0] = i;
    }

    for (int j = 0; j <= transcribedLen; j++) {
      dp[0][j] = j;
    }

    // Fill the DP table
    for (int i = 1; i <= correctLen; i++) {
      for (int j = 1; j <= transcribedLen; j++) {
        String correctWord = normaliseArabicText(correctWords[i - 1]);
        String transcribedWord = normaliseArabicText(transcribedWords[j - 1]);

        if (correctWord == transcribedWord) {
          dp[i][j] = dp[i - 1][j - 1]; // Match
        } else {
          // Calculate costs for insertion, deletion, and substitution
          int insertCost = dp[i][j - 1] + 1;
          int deleteCost = dp[i - 1][j] + 1;
          int substituteCost = dp[i - 1][j - 1] + 1;

          // Choose the minimum cost operation
          dp[i][j] = [insertCost, deleteCost, substituteCost].reduce(min);
        }
      }
    }

    // Backtrack to find the alignment
    List<Map<String, dynamic>> alignment = [];
    int i = correctLen;
    int j = transcribedLen;

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        String correctWord = normaliseArabicText(correctWords[i - 1]);
        String transcribedWord = normaliseArabicText(transcribedWords[j - 1]);

        if (correctWord == transcribedWord) {
          // Match
          alignment.add({
            'correctIndex': i - 1,
            'transcribedIndex': j - 1,
            'operation': 'match'
          });
          i--;
          j--;
          continue;
        }
      }

      if (j > 0 && (i == 0 || dp[i][j] == dp[i][j - 1] + 1)) {
        // Insertion (extra word in transcribed)
        alignment.add({
          'correctIndex': -1,
          'transcribedIndex': j - 1,
          'operation': 'insertion'
        });
        j--;
      } else if (i > 0 && (j == 0 || dp[i][j] == dp[i - 1][j] + 1)) {
        // Deletion (missing word in transcribed)
        alignment.add({
          'correctIndex': i - 1,
          'transcribedIndex': -1,
          'operation': 'deletion'
        });
        i--;
      } else if (i > 0 && j > 0) {
        // Substitution
        alignment.add({
          'correctIndex': i - 1,
          'transcribedIndex': j - 1,
          'operation': 'substitution'
        });
        i--;
        j--;
      }
    }

    // Reverse to get the alignment in correct order
    return alignment.reversed.toList();
  }

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
        _recordingDurationTimer?.cancel(); // Cancel the duration timer
        String? filePath = await recorder.stop();
        setState(() {
          isRecording = false;
          _amplitudeTimer?.cancel(); // Cancel timer when stopping
        });

        if (filePath != null) {
          setState(() {
            recordingPath = filePath;
            text =
                "Processing your recording..."; // Show a processing indicator
            hasSubmittedAnswer = false;
            feedbackMessage = '';
          });

          // Convert to text with proper error handling
          String transcription = await convertSpeechToText(filePath);

          if (transcription.startsWith('Error:')) {
            setState(() {
              text = transcription;
              comparison = [];
              isRecitationCorrect = false;
              feedbackMessage = '';
              incorrectWordCount = 0;
            });
            return;
          }

          List<Map<String, dynamic>> comparisonResult =
              compareVerses(question['correctAnswer'], transcription);

          List<String> processedTranscribedWords = comparisonResult
              .map((e) => e['final_transcribed_word'] as String)
              .toList();

          String processedTranscribedWord =
              joinVerseManuallyWithSpecialChars(processedTranscribedWords);

          // Count number of incorrect words
          int totalIncorrectWords =
              comparisonResult.where((word) => word['isError'] == true).length;

          // Determine if recitation is correct based on the new criteria
          bool isCorrect = false;
          String message = '';

          if (totalIncorrectWords == 0) {
            isCorrect = true;
            message = 'Excellent! Your recitation is perfect.';
          } else if (totalIncorrectWords <= 2) {
            // Check if differences are minor (only a few letter differences)
            int totalDifferences = 0;
            for (var word in comparisonResult) {
              if (word['isError'] == true) {
                if (word['differences'] is List) {
                  totalDifferences += (word['differences'] as List).length;
                }
              }
            }

            if (totalDifferences <= 3) {
              isCorrect = true;
              message =
                  'Very good! Your recitation has minor differences but is essentially correct.';
            } else {
              isCorrect = false;
              message =
                  'Your recitation has some errors. Please review the highlighted words.';
            }
          } else {
            isCorrect = false;
            message =
                'Your recitation needs improvement. Please review the highlighted words.';
          }

          print(transcription);
          print(question['correctAnswer']);
          print(comparisonResult);

          setState(() {
            text = processedTranscribedWord;
            comparison = comparisonResult;
            isRecitationCorrect = isCorrect;
            feedbackMessage = message;
            incorrectWordCount = totalIncorrectWords;
          });
        }
      } else {
        // Start recording
        if (await recorder.hasPermission()) {
          // Cancel any existing timers
          _amplitudeTimer?.cancel();
          _recordingDurationTimer?.cancel();

          // Clean up any existing recording file
          await cleanupRecordingFile();

          // Ensure we have a valid directory path
          final dir = await getApplicationDocumentsDirectory();
          if (dir.path.isEmpty) {
            throw Exception('Could not get application documents directory');
          }

          final path =
              '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.wav';

          // Initialise recording with explicit configuration
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
            text = ''; // Clear any previous text
            comparison = []; // Clear any previous comparison
          });

          // Start updating amplitudes
          _updateAmplitudes();

          // Set a maximum recording duration (e.g., 30 seconds)
          _recordingDurationTimer = Timer(const Duration(seconds: 60), () {
            if (isRecording) {
              handleRecording(question); // Stop recording after max duration
            }
          });
        } else {
          throw Exception('Recording permission not granted');
        }
      }
    } catch (e, stackTrace) {
      print('Recording error: $e');
      print('Stack trace: $stackTrace');
      // Make sure to cancel any timers if an error occurs
      _recordingDurationTimer?.cancel();
      _amplitudeTimer?.cancel();

      setState(() {
        isRecording = false;
        text = 'Error recording audio. Please try again.';
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording audio: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => handleRecording(question),
            ),
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
                  height: max(2, amplitudes[index] * 35),
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

  // Add this helper method to extract the first n words
  String getFirstNWords(String text, int n) {
    if (text.isEmpty) return '';

    final words = splitVerseManuallyWithSpecialChars(text);
    if (words.length <= n) return text;

    return '... ${joinVerseManuallyWithSpecialChars(words.take(n).toList())}';
  }

  // Add this function to reset the recording state
  void resetRecording() {
    setState(() {
      text = '';
      comparison = [];
      hasSubmittedAnswer = false;
      feedbackMessage = '';
      isRecitationCorrect = false;
      incorrectWordCount = 0;
    });
    cleanupRecordingFile();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're in a loading state
    bool isProcessing = text == "Processing your recording...";
    bool hasError = text.startsWith('Error:');
    final Color primaryAccent = const Color(0xFF4979FB);
    final Color textColor = Colors.grey.shade800;

    // Get the first 5 words of the verse
    String truncatedVerse = '';
    final words = splitVerseManuallyWithSpecialChars(widget.question['verse']);
    if (words.length > 6) {
      final firstFourWords = words.take(4).toList();
      final lastTwoWords = words.skip(words.length - 2).take(2).toList();
      truncatedVerse =
          '${joinVerseManuallyWithSpecialChars(firstFourWords)} ... ${joinVerseManuallyWithSpecialChars(lastTwoWords)}';
    } else {
      truncatedVerse = widget.question['verse'];
    }

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
                            'What comes next?',
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
                    truncatedVerse,
                    style: GoogleFonts.scheherazadeNew(
                      letterSpacing: 0,
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
                    if (isProcessing) ...[
                      const SizedBox(height: 20),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      Text(
                        'Processing your recording...',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ] else if (hasError) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              text,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => handleRecording(widget.question),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade700,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      ),
                    ] else if (text.isNotEmpty && !isProcessing) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            if (feedbackMessage.isNotEmpty &&
                                hasSubmittedAnswer) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isRecitationCorrect
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isRecitationCorrect
                                        ? Colors.green.shade300
                                        : Colors.red.shade300,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isRecitationCorrect
                                          ? Icons.check_circle
                                          : Icons.error,
                                      color: isRecitationCorrect
                                          ? Colors.green.shade700
                                          : Colors.red.shade700,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        feedbackMessage,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: isRecitationCorrect
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 8,
                                textDirection: TextDirection.rtl,
                                children: comparison.map((word) {
                                  bool isError = word['isError'] == true;
                                  return isError
                                      ? GestureDetector(
                                          onTap: () {
                                            // Show popup with correct word
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: Colors.white,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            16),
                                                  ),
                                                  title: Center(
                                                    child: Text(
                                                      'Correct Word',
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Text(
                                                        word['actual_word'],
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: GoogleFonts
                                                            .scheherazadeNew(
                                                          letterSpacing: 0,
                                                          fontSize: 32,
                                                          height: 1.6,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                          height: 16),
                                                      if (word['differences']
                                                              is List &&
                                                          word['differences']
                                                              .isNotEmpty &&
                                                          !(word['differences']
                                                                      .length ==
                                                                  1 &&
                                                              word['differences']
                                                                          [0][
                                                                      'error'] !=
                                                                  null)) ...[
                                                        Text(
                                                          'Difference details:',
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontSize: 12,
                                                            color: Colors
                                                                .grey.shade700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        ...word['differences']
                                                            .map<Widget>(
                                                                (diff) {
                                                          if (diff['error'] !=
                                                              null) {
                                                            return Container();
                                                          }

                                                          String message = '';
                                                          if (diff['incorrect'] ==
                                                                  '' &&
                                                              diff['correct'] !=
                                                                  '') {
                                                            message =
                                                                'Missing: ${diff['correct']}';
                                                          } else if (diff[
                                                                      'incorrect'] !=
                                                                  '' &&
                                                              diff['correct'] ==
                                                                  '') {
                                                            message =
                                                                'Extra: ${diff['incorrect']}';
                                                          } else {
                                                            message =
                                                                'Replace ${diff['incorrect']} with ${diff['correct']}';
                                                          }

                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    bottom: 4),
                                                            child: Text(
                                                              message,
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontSize: 12,
                                                                color: Colors
                                                                    .grey
                                                                    .shade700,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ],
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text(
                                                        'OK',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          color: Colors
                                                              .blue.shade700,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          child: Text(
                                            word['final_transcribed_word'],
                                            style: GoogleFonts.scheherazadeNew(
                                              letterSpacing: 0,
                                              fontSize: 24,
                                              height: 1.6,
                                              color: Colors.red,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor:
                                                  Colors.red.withOpacity(0.7),
                                              decorationThickness: 1,
                                            ),
                                          ),
                                        )
                                      : Text(
                                          word['final_transcribed_word'],
                                          style: GoogleFonts.scheherazadeNew(
                                            letterSpacing: 0,
                                            fontSize: 24,
                                            height: 1.6,
                                            color: Colors.black,
                                          ),
                                        );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (text.isEmpty) ...[
                      _buildRecordButton(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
        if (text.isNotEmpty && !isProcessing && !hasError)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (!hasSubmittedAnswer) {
                        // First press: Show feedback
                        setState(() {
                          hasSubmittedAnswer = true;
                        });
                      } else {
                        // Second press: Go to next question
                        widget.onNext(isRecitationCorrect);
                        widget.answeredQuestions[widget.currentQuestionIndex] =
                            {
                          'user_answer': text,
                          'is_correct': isRecitationCorrect
                        };
                        setState(() {
                          text = '';
                          hasSubmittedAnswer = false;
                          feedbackMessage = '';
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      backgroundColor: hasSubmittedAnswer
                          ? (isRecitationCorrect
                              ? Colors.green.shade600
                              : Colors.red.shade600)
                          : const Color(0xFF4979FB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue',
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: resetRecording,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: const Color(0xFF4979FB).withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.refresh,
                        size: 22,
                        color: const Color(0xFF4979FB),
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
