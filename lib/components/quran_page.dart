import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:developer' as developer;

import '../services/database_service.dart';
import '../services/font_service.dart';
import '../models/mushaf_line.dart';
import '../models/word.dart';
import 'mushaf_line_widget.dart';

class QuranPage extends StatefulWidget {
  final int pageNumber;
  final String verseToHighlight;
  final String pageToHighlight;
  final String endVerseToHighlight;
  final String endPageToHighlight;
  final String prevVerseKey;
  final DatabaseService? databaseService;

  const QuranPage({
    super.key,
    required this.pageNumber,
    this.verseToHighlight = '',
    this.pageToHighlight = '',
    this.endVerseToHighlight = '',
    this.endPageToHighlight = '',
    this.prevVerseKey = '',
    this.databaseService,
  });

  @override
  State<QuranPage> createState() => _QuranPageState();
}

class _QuranPageState extends State<QuranPage> {
  late DatabaseService _dbService;
  List<MushafLine> _pageLines = [];
  final Map<int, List<Word>> _lineWords = {};
  bool _isLoading = true;
  String _error = '';
  bool _fontLoaded = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _dbService = widget.databaseService ?? DatabaseService();
    _initializePage();
  }

  Future<void> _initializePage() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // 1. Load the page-specific font first
      await FontService.loadPageFont(widget.pageNumber);

      // 2. Initialize database service to access layout.db, script.json, and surahnames.json
      await _dbService.initialize();

      // 3. Get page lines from layout.db
      _pageLines = await _dbService.getPageLines(widget.pageNumber);

      // 4. Process each line based on its type
      for (var line in _pageLines) {
        try {
          switch (line.lineType) {
            case 'surah_name':
              if (line.surahNumber != null && line.surahNumber!.isNotEmpty) {
                // Get surah name from surahnames.json
                final surahName =
                    await _dbService.getSurahName(int.parse(line.surahNumber!));
                _lineWords[line.lineNumber] = [
                  Word.special(
                    text:
                        'سورة $surahName', // Format surah name with "سورة" prefix
                    lineType: 'surah_name',
                    isCentered: line.isCentered,
                  )
                ];
              }
              break;

            case 'basmallah':
              _lineWords[line.lineNumber] = [
                Word.special(
                  text: '﷽',
                  lineType: 'basmallah',
                  isCentered: line.isCentered,
                )
              ];
              break;

            case 'ayah':
              if (line.firstWordId != null && line.lastWordId != null) {
                // Skip empty word IDs
                if (line.firstWordId!.isEmpty || line.lastWordId!.isEmpty) {
                  continue;
                }

                // Parse word IDs
                final firstWordId = int.tryParse(line.firstWordId!);
                final lastWordId = int.tryParse(line.lastWordId!);

                if (firstWordId == null ||
                    lastWordId == null ||
                    firstWordId <= 0 ||
                    lastWordId <= 0) {
                  developer.log(
                      'Invalid word IDs for line ${line.lineNumber}: first=${line.firstWordId}, last=${line.lastWordId}');
                  continue;
                }

                // Get words from script.json using word IDs
                final lineWords =
                    await _dbService.getWordsInRange(firstWordId, lastWordId);

                // Apply line properties to all words
                _lineWords[line.lineNumber] = lineWords
                    .map((word) => Word(
                          wordIndex: word.wordIndex,
                          text: word.text,
                          isCentered: line.isCentered,
                          location: word.location,
                          surah: word.surah,
                          ayah: word.ayah,
                          wordPosition: word.wordPosition,
                        ))
                    .toList();
              }
              break;

            default:
              developer.log(
                  'Unknown line type: ${line.lineType} for line ${line.lineNumber}');
              break;
          }
        } catch (e) {
          developer.log('Error processing line ${line.lineNumber}: $e',
              error: e);
          continue;
        }
      }

      setState(() {
        _isLoading = false;
        _fontLoaded = true;
      });
    } catch (e) {
      developer.log('Error loading page: $e', error: e);
      setState(() {
        _isLoading = false;
        _error = 'Error loading page: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_fontLoaded || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _initializePage,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pageLines.isEmpty) {
      return const Center(child: Text('No content available for this page'));
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        extendBodyBehindAppBar: true,
        appBar: _showControls
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40.0),
                child: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  toolbarHeight: 40,
                  title: Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: const Text(''),
                  ),
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      size: 20,
                    ),
                    padding: const EdgeInsets.only(bottom: 20.0),
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              )
            : null,
        body: Padding(
          padding: const EdgeInsets.only(
              top: 70.0, bottom: 40.0, left: 8.0, right: 8.0),
          child: Container(
            color: Colors.white,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 4.0),
                    child: Column(
                      mainAxisAlignment: widget.pageNumber > 2
                          ? MainAxisAlignment.spaceEvenly
                          : MainAxisAlignment.start,
                      children: _buildPageContent(),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Text(
                    widget.pageNumber.toString(),
                    style: GoogleFonts.scheherazadeNew(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPageContent() {
    // Sort lines by line number to ensure correct order
    _pageLines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

    return _pageLines.map((line) {
      final words = _lineWords[line.lineNumber] ?? [];
      return FittedBox(
        fit: BoxFit.fitWidth,
        child: MushafLineWidget(
          words: words,
          pageNumber: widget.pageNumber,
          verseToHighlight: widget.verseToHighlight,
          endVerseToHighlight: widget.endVerseToHighlight,
          prevVerseKey: widget.prevVerseKey,
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    if (widget.databaseService == null) {
      _dbService.close();
    }
    super.dispose();
  }
}
