import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/onboarding_ui.dart';
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

  final List<TutorialPageData> _pages = const [
    TutorialPageData(
      icon: Iconsax.home,
      title: 'Home',
      description:
          'See today’s memorisation, reviews, and your weekly schedule at a glance.',
      color: kOnboardingAccent,
    ),
    TutorialPageData(
      icon: Iconsax.book_1,
      title: 'Quran',
      description:
          'Open the digital mushaf to read and memorise your assigned verses.',
      color: Color(0xFF10B981),
    ),
    TutorialPageData(
      icon: Iconsax.document_text,
      title: 'Quizzes',
      description:
          'Practise with interactive quizzes — custom or from your review schedule.',
      color: Color(0xFFEF4444),
    ),
    TutorialPageData(
      icon: Iconsax.calendar_1,
      title: 'Plan',
      description:
          'Track progress, edit your daily amount, and manage your schedule.',
      color: Color(0xFFF59E0B),
    ),
    TutorialPageData(
      icon: Iconsax.profile_circle,
      title: 'Profile',
      description:
          'View achievements, activity, and your memorisation stats.',
      color: Color(0xFF8B5CF6),
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
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeTutorial();
    }
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
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _completeTutorial,
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _TutorialSlide(data: _pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: OnboardingProgressBar(
                current: _currentPage,
                total: _pages.length,
              ),
            ),
            OnboardingBottomBar(
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: Text(
                        'Back',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 64),
                  const Spacer(),
                  SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: page.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get started'
                            : 'Continue',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
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
    );
  }
}

class _TutorialSlide extends StatelessWidget {
  const _TutorialSlide({required this.data});

  final TutorialPageData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(data.icon, size: 40, color: data.color),
          ),
          const SizedBox(height: 28),
          Text(
            data.title,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
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
