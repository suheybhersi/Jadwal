import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jadwal/components/QuranPage.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:provider/provider.dart';
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
  late int _currentPage;
  List<DocumentSnapshot>? _pages;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;

    // Debug information for verse highlighting
    if (widget.verseToHighlight.isNotEmpty) {
      developer.log(
          'QuranViewer initialized with verse to highlight: ${widget.verseToHighlight}');
      if (widget.endVerseToHighlight.isNotEmpty) {
        developer.log('End verse to highlight: ${widget.endVerseToHighlight}');
      }
      if (widget.prevVerseKey.isNotEmpty) {
        developer.log('Previous verse key: ${widget.prevVerseKey}');
      }
      developer.log('Initial page: ${widget.initialPage}');
      developer.log('Page to highlight: ${widget.pageToHighlight}');

      // Log end page if available
      if (widget.endPageToHighlight.isNotEmpty) {
        developer.log('End page to highlight: ${widget.endPageToHighlight}');
      }
    }

    // Initialize PageController with reversed index because we want page 1 on the right
    _pageController = PageController(
      initialPage: widget.totalPages - widget.initialPage,
    );
    _loadPages();
  }

  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      _pages = await firestoreService.getAllPages();

      setState(() {
        _isLoading = false;
      });

      // Ensure we're on the right page after loading
      if (widget.verseToHighlight.isNotEmpty && mounted) {
        // Optional: give a slight delay to let page build properly
        Future.delayed(Duration(milliseconds: 300), () {
          if (mounted) {
            _pageController.jumpToPage(widget.totalPages - widget.initialPage);
          }
        });
      }
    } catch (e) {
      developer.log('Error loading pages: $e', error: e);
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading pages: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageView() {
    if (_pages != null && _pages!.isNotEmpty) {
      // Verify that pages are in correct numerical order
      final pageIds = _pages!.map((doc) => int.parse(doc.id)).toList();
      for (int i = 1; i < pageIds.length; i++) {
        if (pageIds[i] != pageIds[i - 1] + 1) {
          developer.log(
              'Warning: Pages not in sequence. Expected ${pageIds[i - 1] + 1} but got ${pageIds[i]}');
        }
      }

      return PageView.builder(
        controller: _pageController,
        reverse: false, // Right to left direction
        onPageChanged: (index) {
          setState(() {
            _currentPage = widget.totalPages - index;
          });
        },
        itemCount: widget.totalPages,
        itemBuilder: (context, index) {
          final pageNumber = widget.totalPages - index;

          // Find the correct page by ID
          final pageIndex =
              _pages!.indexWhere((doc) => int.parse(doc.id) == pageNumber);

          if (pageIndex >= 0) {
            // Enhanced debugging for page-based highlighting
            if (pageNumber == int.tryParse(widget.pageToHighlight)) {
              developer.log('Rendering start page: $pageNumber');
            }

            if (widget.endPageToHighlight.isNotEmpty &&
                pageNumber == int.tryParse(widget.endPageToHighlight)) {
              developer.log('Rendering end page: $pageNumber');
            }

            // We always pass the start page as pageToHighlight
            // This is the reference point for highlighting logic
            return QuranPage(
              pageData: _pages![pageIndex],
              verseToHighlight: widget.verseToHighlight,
              pageToHighlight: widget.pageToHighlight, // Always pass start page
              endVerseToHighlight: widget.endVerseToHighlight,
              endPageToHighlight: widget.endPageToHighlight,
              prevVerseKey: widget.prevVerseKey,
            );
          }
          return null;
        },
      );
    } else {
      return const Center(child: Text('No pages available'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(onPressed: _showPageInfo, icon: const Icon(Icons.info)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pages == null || _pages!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('No pages available'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadPages,
                        child: const Text('Retry Loading'),
                      ),
                      const SizedBox(height: 16),
                      Text('Pages loaded: ${_pages?.length ?? 0}'),
                    ],
                  ),
                )
              : _buildPageView(),
    );
  }

  // Method to show detailed page info for debugging
  void _showPageInfo() async {
    if (_pages == null || _pages!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pages loaded to inspect')),
      );
      return;
    }

    final pageIndex = widget.totalPages - _currentPage;
    if (pageIndex < 0 || pageIndex >= _pages!.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current page index out of range')),
      );
      return;
    }

    final currentPageDoc = _pages![pageIndex];
    final pageId = currentPageDoc.id;

    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      final pageStructure = await firestoreService.getPageStructure(pageId);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Page $pageId Structure'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                    'Fields: ${pageStructure['fields']?.join(', ') ?? 'None'}'),
                const Divider(),
                ...pageStructure.entries
                    .where((e) =>
                        e.key != 'fields' && e.key != 'exists' && e.key != 'id')
                    .map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text('${e.key}: ${e.value}'),
                        )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting page structure: $e')),
      );
    }
  }
}
