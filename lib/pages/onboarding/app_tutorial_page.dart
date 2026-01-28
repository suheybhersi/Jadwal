import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:provider/provider.dart';

class AppTutorialPage extends StatefulWidget {
  const AppTutorialPage({super.key});

  @override
  State<AppTutorialPage> createState() => _AppTutorialPageState();
}

class _AppTutorialPageState extends State<AppTutorialPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialPageData> _pages = [
    TutorialPageData(
      icon: Iconsax.home,
      title: 'Home Dashboard',
      description:
          'Your home screen shows upcoming memorization tasks, reviews, and your weekly schedule. Tap on any day to see detailed tasks.',
      color: const Color(0xFF4979FB),
    ),
    TutorialPageData(
      icon: Iconsax.book_1,
      title: 'Digital Mushaf',
      description:
          'Read and navigate through the complete Quran. Use this to memorize your assigned verses and review what you\'ve learned.',
      color: const Color(0xFF10B981),
    ),
    TutorialPageData(
      icon: Iconsax.document_text,
      title: 'Your Plan',
      description:
          'View your memorization plan details, progress, and completed memorizations. Edit your plan anytime from here.',
      color: const Color(0xFFF59E0B),
    ),
    TutorialPageData(
      icon: Iconsax.document_text,
      title: 'Quizzes & Reviews',
      description:
          'Test your memorization with custom quizzes or scheduled reviews. Choose from multiple question types to practice.',
      color: const Color(0xFFEF4444),
    ),
    TutorialPageData(
      icon: Iconsax.profile_circle,
      title: 'Profile & Achievements',
      description:
          'Track your progress, view achievements, and see your memorization statistics. Celebrate your milestones!',
      color: const Color(0xFF8B5CF6),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeTutorial();
    }
  }

  void _skipTutorial() {
    _completeTutorial();
  }

  Future<void> _completeTutorial() async {
    final tutorialService =
        Provider.of<TutorialService>(context, listen: false);
    await tutorialService.completeTutorial();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipTutorial,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildTutorialPage(_pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? _pages[index].color
                          : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Text(
                        'Previous',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _pages[_currentPage].color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      _currentPage == _pages.length - 1
                          ? 'Get Started'
                          : 'Next',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(TutorialPageData data) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 60,
              color: data.color,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            data.description,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class TutorialPageData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const TutorialPageData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
