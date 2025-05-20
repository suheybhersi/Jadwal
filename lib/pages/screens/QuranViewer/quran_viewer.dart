import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:jadwal/components/quran_page.dart';
import 'package:jadwal/services/database_service.dart';
import 'package:jadwal/services/font_service.dart';
import 'dart:developer' as developer;

class QuranViewer extends StatefulWidget {
  final int initialPage;
  final int totalPages;
  final String verseToHighlight;
  final String pageToHighlight;
  final String endVerseToHighlight;
  final String endPageToHighlight;
  final String prevVerseKey;

  const QuranViewer({
    super.key,
    required this.initialPage,
    this.totalPages = 604,
    this.verseToHighlight = '',
    this.pageToHighlight = '',
    this.endVerseToHighlight = '',
    this.endPageToHighlight = '',
    this.prevVerseKey = '',
  });

  @override
  State<QuranViewer> createState() => _QuranViewerState();
}

class _QuranViewerState extends State<QuranViewer> {
  late PageController _pageController;
  bool _isLoading = true;
  DatabaseService? _databaseService;

  @override
  void initState() {
    super.initState();

    // Initialize PageController with reversed index because we want page 1 on the right
    _pageController = PageController(
      initialPage: widget.totalPages - widget.initialPage,
    );

    // Initialize database service directly
    _databaseService = DatabaseService();
    _initializeServices();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // We don't need this anymore as we're creating our own DatabaseService
    // but keeping it for future reference if we want to switch back to Provider
  }

  // Helper method to safely show a SnackBar
  void _showSnackBar(String message) {
    // Use a post-frame callback to show the SnackBar after the current frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }

  Future<void> _initializeServices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize database if needed
      if (_databaseService != null) {
        await _databaseService!.initialize();

        // Preload font for the initial page
        await FontService.loadPageFont(widget.initialPage);

        // Preload a few adjacent pages for smooth scrolling
        _preloadAdjacentPageFonts(widget.initialPage);

        // Debug information for verse highlighting
        if (widget.verseToHighlight.isNotEmpty) {
          developer.log(
              'QuranViewer initialized with verse to highlight: ${widget.verseToHighlight}');
          if (widget.endVerseToHighlight.isNotEmpty) {
            developer
                .log('End verse to highlight: ${widget.endVerseToHighlight}');
          }
          if (widget.prevVerseKey.isNotEmpty) {
            developer.log('Previous verse key: ${widget.prevVerseKey}');
          }
          developer.log('Initial page: ${widget.initialPage}');
          developer.log('Page to highlight: ${widget.pageToHighlight}');

          // Log end page if available
          if (widget.endPageToHighlight.isNotEmpty) {
            developer
                .log('End page to highlight: ${widget.endPageToHighlight}');
          }
        }

        // Run debug to help diagnose script data structure
        await _databaseService!.debugScriptData();
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Ensure we're on the right page after loading
        if (widget.verseToHighlight.isNotEmpty) {
          // Optional: give a slight delay to let page build properly
          Future.delayed(Duration(milliseconds: 300), () {
            if (mounted) {
              _pageController
                  .jumpToPage(widget.totalPages - widget.initialPage);
            }
          });
        }
      }
    } catch (e) {
      developer.log('Error initializing services: $e', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSnackBar('Error initializing services: $e');
      }
    }
  }

  // Preload fonts for adjacent pages
  Future<void> _preloadAdjacentPageFonts(int currentPage) async {
    // Preload next page
    if (currentPage < widget.totalPages) {
      FontService.loadPageFont(currentPage + 1);
    }

    // Preload previous page
    if (currentPage > 1) {
      FontService.loadPageFont(currentPage - 1);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _databaseService?.close(); // Properly close the database service
    super.dispose();
  }

  Widget _buildPageView() {
    return PageView.builder(
      controller: _pageController,
      reverse: false, // Right to left direction
      onPageChanged: (index) {
        final newPage = widget.totalPages - index;
        // Preload adjacent page fonts when page changes
        _preloadAdjacentPageFonts(newPage);
      },
      itemCount: widget.totalPages,
      itemBuilder: (context, index) {
        final pageNumber = widget.totalPages - index;

        // Enhanced debugging for page-based highlighting
        if (pageNumber == int.tryParse(widget.pageToHighlight)) {
          developer.log('Rendering start page: $pageNumber');
        }

        if (widget.endPageToHighlight.isNotEmpty &&
            pageNumber == int.tryParse(widget.endPageToHighlight)) {
          developer.log('Rendering end page: $pageNumber');
        }

        // Pass the database service directly to QuranPage
        return QuranPage(
          pageNumber: pageNumber,
          verseToHighlight: widget.verseToHighlight,
          pageToHighlight: widget.pageToHighlight, // Always pass start page
          endVerseToHighlight: widget.endVerseToHighlight,
          endPageToHighlight: widget.endPageToHighlight,
          prevVerseKey: widget.prevVerseKey,
          databaseService: _databaseService,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildPageView(),
    );
  }
}
