import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as developer;
import '../models/surah.dart';
import '../models/mushaf_line.dart';
import '../models/word.dart';

class DatabaseService {
  static Database? _layoutDb;
  static Map<String, dynamic>? _surahNamesCache;

  // Initialize all databases
  Future<void> initialize() async {
    try {
      await _initLayoutDb();
      await _initScriptDb();
      await _loadSurahNames();

      // Run debug to help diagnose script data structure
      await debugScriptData();
    } catch (e) {
      // Re-throw to allow handling at higher level
      throw Exception('Failed to initialize database service: $e');
    }
  }

  // Layout Database (pages)
  Future<Database> get layoutDb async {
    if (_layoutDb != null) return _layoutDb!;
    return await _initLayoutDb();
  }

  Future<Database> _initLayoutDb() async {
    try {
      final dbPath = await _getDatabasePath('assets/databases/layout.db');
      _layoutDb = await openDatabase(
        dbPath,
        readOnly:
            true, // Open in read-only mode since we're not modifying the database
      );

      // Verify database is accessible

      return _layoutDb!;
    } catch (e) {
      // Re-throw to allow handling at higher level
      throw Exception('Failed to initialize layout database: $e');
    }
  }

  // Script Database (words)
  Map<String, dynamic>? _scriptData;

  Future<Map<String, dynamic>> get scriptData async {
    if (_scriptData != null) return _scriptData!;
    return await _initScriptDb();
  }

  Future<Map<String, dynamic>> _initScriptDb() async {
    try {
      if (_scriptData != null) return _scriptData!;

      final scriptPath = await _getFilePath('assets/databases/script.json');
      final file = File(scriptPath);

      if (!await file.exists()) {
        // Copy asset to file system
        final ByteData data =
            await rootBundle.load('assets/databases/script.json');
        final bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await file.writeAsBytes(bytes, flush: true);
      }

      // Read and parse JSON
      final jsonString = await file.readAsString();
      _scriptData = json.decode(jsonString) as Map<String, dynamic>;

      return _scriptData!;
    } catch (e) {
      throw Exception('Failed to initialize script data: $e');
    }
  }

  // Helper method to get file path
  Future<String> _getFilePath(String assetPath) async {
    final fileName = basename(assetPath);
    return join((await getApplicationDocumentsDirectory()).path, fileName);
  }

  // Helper method to get database path
  Future<String> _getDatabasePath(String assetPath) async {
    final dbName = basename(assetPath);
    final dbPath =
        join((await getApplicationDocumentsDirectory()).path, dbName);

    if (!await databaseExists(dbPath)) {
      try {
        await Directory(dirname(dbPath)).create(recursive: true);
      } catch (_) {}

      final ByteData data = await rootBundle.load(assetPath);
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(dbPath).writeAsBytes(bytes, flush: true);
    }

    return dbPath;
  }

  // Surah Names (JSON)
  Future<void> _loadSurahNames() async {
    if (_surahNamesCache != null) return;

    try {
      final jsonString =
          await rootBundle.loadString('assets/databases/surahnames.json');
      _surahNamesCache = json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Failed to load surah names: $e');
    }
  }

  // Surah Data Methods
  Future<List<Surah>> getAllSurahs() async {
    await _loadSurahNames();
    if (_surahNamesCache == null) return [];

    final startPages = await _getSurahStartPages();

    return _surahNamesCache!.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      return Surah.fromJson(data, startPages[int.parse(entry.key)] ?? 1);
    }).toList();
  }

  Future<Map<int, int>> _getSurahStartPages() async {
    final db = await layoutDb;
    final pages = await db.query(
      'pages',
      where: 'line_type = ?',
      whereArgs: ['surah_name'],
      orderBy: 'page_number ASC',
    );

    final Map<int, int> startPages = {};
    for (final page in pages) {
      final surahNumber = page['surah_number'] as int?;
      final pageNumber = page['page_number'] as int?;
      if (surahNumber != null && pageNumber != null) {
        startPages[surahNumber] = pageNumber;
      }
    }
    return startPages;
  }

  Future<String> getSurahName(int surahNumber) async {
    await _loadSurahNames();
    final surahData =
        _surahNamesCache?[surahNumber.toString()] as Map<String, dynamic>?;
    return surahData?['name_arabic']?.toString() ?? 'سورة';
  }

  // Mushaf Layout Methods
  Future<List<MushafLine>> getPageLines(int pageNumber) async {
    final db = await layoutDb;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'pages',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC',
      );

      if (maps.isEmpty) {}

      return maps.map((map) => MushafLine.fromMap(map)).toList();
    } catch (e) {
      return [];
    }
  }

  // Quran Script Methods
  Future<List<Word>> getWordsInRange(int firstWordId, int lastWordId) async {
    try {
      final script = await scriptData;
      final List<Word> words = [];

      // Create a more efficient lookup map
      Map<int, Map<String, dynamic>> wordMap = {};

      // First pass: build index of words by wordIndex
      for (var entry in script.entries) {
        if (entry.value is Map<String, dynamic>) {
          final wordData = entry.value as Map<String, dynamic>;
          final wordIndex = wordData['word_index'];

          if (wordIndex is int &&
              wordIndex >= firstWordId &&
              wordIndex <= lastWordId) {
            wordMap[wordIndex] = wordData;
          }
        }
      }

      // Second pass: create Word objects in order and verify continuity
      int expectedIndex = firstWordId;

      for (int i = firstWordId; i <= lastWordId; i++) {
        final wordData = wordMap[i];
        if (wordData != null) {
          try {
            // Verify word index continuity
            if (wordData['word_index'] != expectedIndex) {
              developer.log(
                  'Warning: Word index discontinuity at $i. Expected $expectedIndex, got ${wordData['word_index']}');
              // If we find a gap, fill it with empty words
              while (expectedIndex < wordData['word_index']) {
                words.add(Word(
                  wordIndex: expectedIndex,
                  text: '',
                  location: '',
                ));
                expectedIndex++;
              }
            }

            // Create the Word object
            words.add(Word.fromMap({
              'word_index': wordData['word_index'],
              'location': wordData['location'],
              'text': wordData['text'],
            }));
            expectedIndex = i + 1;
          } catch (e) {
            developer.log('Error processing word $i: $e, data: $wordData',
                error: e);
          }
        } else {
          developer.log(
              'Warning: Missing word at index $i in range $firstWordId-$lastWordId');
          // Add an empty word for missing indices
          words.add(Word(
            wordIndex: i,
            text: '',
            location: '',
          ));
          expectedIndex = i + 1;
        }
      }

      // Verify we have the correct number of words
      if (words.length != (lastWordId - firstWordId + 1)) {
        developer.log(
            'Warning: Expected ${lastWordId - firstWordId + 1} words but got ${words.length}');
      }

      return words;
    } catch (e) {
      developer.log('Error getting words in range: $e', error: e);
      return [];
    }
  }

  // Debug method to examine script data structure
  Future<void> debugScriptData() async {
    try {
      final script = await scriptData;
      // Try to find a specific word index
      int targetIndex = 1; // Try to find word with index 1
      List<String> keysWithIndex = [];

      for (var entry in script.entries) {
        if (entry.value is Map<String, dynamic> &&
            (entry.value as Map<String, dynamic>)['word_index'] ==
                targetIndex) {
          keysWithIndex.add(entry.key);
        }
      }
    } catch (e) {
      throw Exception('Error in debugScriptData: $e');
    }
  }

  // Get words for a specific page using both layout and script data
  Future<List<Word>> getWordsForPage(int pageNumber) async {
    try {
      final lines = await getPageLines(pageNumber);
      final List<Word> pageWords = [];

      if (lines.isEmpty) {
        return [];
      }

      for (final line in lines) {
        switch (line.lineType) {
          case 'surah_name':
            if (line.surahNumber != null) {
              final surahNum = int.tryParse(line.surahNumber!) ?? 0;
              if (surahNum > 0) {
                final surahName = await getSurahName(surahNum);
                pageWords.add(Word.special(
                  text: surahName,
                  lineType: 'surah_name',
                  isCentered: line.isCentered,
                ));
              }
            }
            break;

          case 'basmallah':
            pageWords.add(Word.special(
              text: '﷽',
              lineType: 'basmallah',
              isCentered: line.isCentered,
            ));
            break;

          case 'ayah':
            if (line.firstWordId != null && line.lastWordId != null) {
              final firstId = int.tryParse(line.firstWordId!) ?? 0;
              final lastId = int.tryParse(line.lastWordId!) ?? 0;

              if (firstId > 0 && lastId > 0) {
                final List<Word> lineWords =
                    await getWordsInRange(firstId, lastId);
                // Mark all words in this line with the same centering property
                final words = lineWords
                    .map((w) => Word(
                          wordIndex: w.wordIndex,
                          text: w.text,
                          isCentered: line.isCentered,
                          location: w.location,
                          surah: w.surah,
                          ayah: w.ayah,
                          wordPosition: w.wordPosition,
                        ))
                    .toList();

                pageWords.addAll(words);
              }
            }
            break;
        }
      }

      return pageWords;
    } catch (e) {
      return [];
    }
  }

  // Cleanup
  Future<void> close() async {
    await _layoutDb?.close();
    _layoutDb = null;
    _scriptData = null;
    _surahNamesCache = null;
  }
}
