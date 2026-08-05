import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/login_or_register_page.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  static const int _pageCount = 4;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());

    return AuthGradientScaffold(
      child: Stack(
        children: [
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: const [
              _WelcomeBrandPage(),
              _FeatureDetailPage(
                icon: Iconsax.calendar_1,
                accent: kAuthBrandBlue,
                title: 'Plan your hifdh',
                description:
                    'Set a clear daily path through the Quran and know exactly what to memorise next.',
                features: [
                  'Custom start and end points',
                  'Daily memorisation targets',
                  'Weekly schedule on Home',
                  'Edit your plan anytime',
                ],
              ),
              _FeatureDetailPage(
                icon: Iconsax.refresh,
                accent: Color(0xFF10B981),
                title: 'Stay consistent',
                description:
                    'Reviews are timed so what you memorise sticks for the long term — not just for today.',
                features: [
                  'Scheduled review sessions',
                  'Intensive or Flexible mode',
                  'Due reviews on your Home card',
                  'Track completion as you go',
                ],
              ),
              _FeatureDetailPage(
                icon: Iconsax.teacher,
                accent: Color(0xFFEF4444),
                title: 'Quiz yourself',
                description:
                    'Practise with interactive quizzes — create custom ones or take scheduled review quizzes.',
                features: [
                  'Drag and drop verses',
                  'Verse pairing',
                  'Fill in the blank (Pro)',
                  'What Comes Next speech quizzes (Pro)',
                ],
              ),
            ],
          ),
          Positioned(
            top: 8,
            right: 8,
            child: TextButton(
              onPressed: () => OnBoardingController.instance.skipPage(),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: Obx(() {
              final index = controller.currentPageIndex.value;
              final isLast = index >= _pageCount - 1;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthPageIndicator(count: _pageCount, index: index),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: isLast ? 'Get started' : 'Continue',
                    onPressed: () => OnBoardingController.instance.nextPage(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Screen 1 — brand only.
class _WelcomeBrandPage extends StatelessWidget {
  const _WelcomeBrandPage();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 140),
      child: Column(
        children: [
          const Spacer(flex: 2),
          const Image(
            height: 88,
            image: AssetImage('assets/app_logo.png'),
          ),
          const SizedBox(height: 20),
          Text(
            'Jadwal',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your personal Quran memorisation planner.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey.shade600,
              height: 1.45,
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

/// Feature pages with Settings Features Tour–style detail cards.
class _FeatureDetailPage extends StatelessWidget {
  const _FeatureDetailPage({
    required this.icon,
    required this.accent,
    required this.title,
    required this.description,
    required this.features,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String description;
  final List<String> features;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 140),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(icon, size: 40, color: accent),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withValues(alpha: 0.35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What you get',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...features.map(
                          (feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 2),
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accent.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 12,
                                    color: accent,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.grey.shade700,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  final pageController = PageController();
  final RxInt currentPageIndex = 0.obs;

  static const int _lastPageIndex = 3;

  void updatePageIndicator(int index) => currentPageIndex.value = index;

  void nextPage() {
    if (currentPageIndex.value >= _lastPageIndex) {
      Get.to(() => const LoginOrRegisterPage());
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void skipPage() {
    Get.to(() => const LoginOrRegisterPage());
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
