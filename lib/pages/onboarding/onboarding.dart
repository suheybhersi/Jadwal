import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/login_or_register_page.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/services/spaced_repetition_service.dart';
import 'package:jadwal/utils/review_miss_utils.dart';

/// Pre-signup product demo: brand → path → interactive scenes → account.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    this.isReplay = false,
  });

  /// When true (e.g. from Settings), finishing or skipping returns instead of
  /// opening account creation.
  final bool isReplay;

  /// Drop any leftover controller so the next mount starts on page 0.
  static void resetController() {
    if (Get.isRegistered<OnBoardingController>()) {
      Get.delete<OnBoardingController>(force: true);
    }
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnBoardingController _controller;

  @override
  void initState() {
    super.initState();
    OnboardingScreen.resetController();
    _controller = Get.put(OnBoardingController(isReplay: widget.isReplay));
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: Stack(
        children: [
          Obx(() {
            final sceneCount = _controller.demoSceneCount;
            return PageView(
              controller: _controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: _controller.updatePageIndicator,
              children: [
                const _WelcomeBrandPage(),
                const _PathPickerPage(),
                for (var i = 0; i < sceneCount; i++)
                  _DemoScenePage(sceneIndex: i),
                const _ReadyPage(),
              ],
            );
          }),
          Positioned(
            top: 8,
            left: 8,
            child: Obx(() {
              final index = _controller.currentPageIndex.value;
              if (index <= 0) return const SizedBox(width: 48, height: 48);
              return TextButton(
                onPressed: () => OnBoardingController.instance.previousPage(),
                child: Text(
                  'Back',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              );
            }),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: TextButton(
              onPressed: () => OnBoardingController.instance.skipPage(),
              child: Text(
                widget.isReplay ? 'Close' : 'Skip',
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
              final index = _controller.currentPageIndex.value;
              final pageCount = _controller.pageCount;
              final isLast = index >= pageCount - 1;
              final onPathPage = index == 1;
              final canContinue = !onPathPage ||
                  _controller.selectedPath.value != DemoPath.unset;
              final isReplay = _controller.isReplay;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthPageIndicator(
                    count: pageCount,
                    index: index.clamp(0, pageCount - 1),
                  ),
                  const SizedBox(height: 24),
                  AuthPrimaryButton(
                    label: isLast
                        ? (isReplay ? 'Done' : 'Create account')
                        : (onPathPage && !canContinue
                            ? 'Choose a path'
                            : 'Continue'),
                    enabled: canContinue,
                    onPressed: canContinue
                        ? () => OnBoardingController.instance.nextPage()
                        : null,
                  ),
                  if (isLast && !isReplay) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Get.to(
                        () => const LoginOrRegisterPage(startWithLogin: true),
                      ),
                      child: Text(
                        'I already have an account',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

enum DemoPath { unset, memorising, huffadh }

class _DemoScene {
  const _DemoScene({
    required this.tipTitle,
    required this.tipBody,
    required this.mock,
  });

  final String tipTitle;
  final String tipBody;
  final Widget mock;
}

class OnBoardingController extends GetxController {
  OnBoardingController({this.isReplay = false});

  static OnBoardingController get instance => Get.find();

  final bool isReplay;
  final pageController = PageController();
  final RxInt currentPageIndex = 0.obs;
  final Rx<DemoPath> selectedPath = DemoPath.unset.obs;

  static const List<_DemoScene> _memorisingScenes = [
    _DemoScene(
      tipTitle: 'Your day on Home',
      tipBody:
          'See today’s memorisation and reviews in one place — tap to begin.',
      mock: _MockMemorisingHome(),
    ),
    _DemoScene(
      tipTitle: 'What is a review?',
      tipBody:
          'After you memorise, Jadwal schedules a quiz on those verses. Do well and the next one waits longer; struggle and it comes back sooner — so you revise just before you’d forget.',
      mock: _MockReviewExplained(),
    ),
    _DemoScene(
      tipTitle: 'Don’t skip reviews',
      tipBody:
          'Missed reviews are tagged and catch up later. Let too many pile up — or skip the same one too often — and new memorisation locks until you clear them.',
      mock: _MockReviewLock(),
    ),
    _DemoScene(
      tipTitle: 'Make your own quiz',
      tipBody:
          'Pick any verses and question types — Drag and Drop, Verse Pairing, Fill in the Blank, and more — whenever you want extra practice.',
      mock: _MockCustomQuiz(),
    ),
    _DemoScene(
      tipTitle: 'Read the mushaf',
      tipBody:
          'Open the Quran viewer anytime to read and revise at your own pace.',
      mock: _MockMushafPeek(),
    ),
  ];

  static const List<_DemoScene> _huffadhScenes = [
    _DemoScene(
      tipTitle: 'Huffadh support is early',
      tipBody:
          'Jadwal is built mainly for people still memorising. Use quizzes and the mushaf for now — and reset your plan from Home if you want daily memorisation again.',
      mock: _MockResetHint(),
    ),
    _DemoScene(
      tipTitle: 'Create quizzes',
      tipBody:
          'Your main tool right now: pick verses and question types to quiz yourself whenever you want.',
      mock: _MockCustomQuiz(),
    ),
    _DemoScene(
      tipTitle: 'Read the mushaf',
      tipBody:
          'Open the Quran viewer anytime to read and revise at your own pace.',
      mock: _MockMushafPeek(),
    ),
  ];

  int get demoSceneCount => selectedPath.value == DemoPath.huffadh
      ? _huffadhScenes.length
      : _memorisingScenes.length;

  /// Brand + path + demo scenes + ready.
  int get pageCount => 3 + demoSceneCount;

  _DemoScene _sceneAt(int index) {
    final path = selectedPath.value == DemoPath.huffadh
        ? DemoPath.huffadh
        : DemoPath.memorising;
    final list =
        path == DemoPath.huffadh ? _huffadhScenes : _memorisingScenes;
    return list[index.clamp(0, list.length - 1)];
  }

  void updatePageIndicator(int index) => currentPageIndex.value = index;

  void previousPage() {
    if (currentPageIndex.value <= 0) return;
    pageController.previousPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void nextPage() {
    final last = pageCount - 1;
    if (currentPageIndex.value >= last) {
      if (isReplay) {
        Get.back();
      } else {
        Get.to(() => const LoginOrRegisterPage(startWithLogin: false));
      }
      return;
    }
    if (currentPageIndex.value == 1 &&
        selectedPath.value == DemoPath.unset) {
      return;
    }
    pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void skipPage() {
    if (isReplay) {
      Get.back();
    } else {
      Get.to(() => const LoginOrRegisterPage());
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class _WelcomeBrandPage extends StatelessWidget {
  const _WelcomeBrandPage();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 160),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Text(
            'Welcome',
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
            'A short tour to show how you’ll plan, review, and stay consistent.',
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

class _PathPickerPage extends StatelessWidget {
  const _PathPickerPage();

  @override
  Widget build(BuildContext context) {
    final controller = OnBoardingController.instance;
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 160),
      child: Obx(() {
        final selected = controller.selectedPath.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How will you use Jadwal?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We’ll show a short demo for your path. You can change this later.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            _PathCard(
              selected: selected == DemoPath.memorising,
              icon: Iconsax.book_1,
              title: 'I’m memorising',
              subtitle: 'Daily hifdh, reviews, and a clear plan.',
              onTap: () => controller.selectedPath.value = DemoPath.memorising,
            ),
            const SizedBox(height: 12),
            _PathCard(
              selected: selected == DemoPath.huffadh,
              icon: Iconsax.cup,
              title: 'I’ve completed the Quran',
              subtitle: 'Quizzes and reading for now — more Huffadh tools later.',
              onTap: () => controller.selectedPath.value = DemoPath.huffadh,
            ),
          ],
        );
      }),
    );
  }
}

class _PathCard extends StatelessWidget {
  const _PathCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? kAuthBrandBlue.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? kAuthBrandBlue
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kAuthBrandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kAuthBrandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? kAuthBrandBlue : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DemoScenePage extends StatelessWidget {
  const _DemoScenePage({required this.sceneIndex});

  final int sceneIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 160),
      child: Obx(() {
        final scene = OnBoardingController.instance._sceneAt(sceneIndex);
        return Column(
          children: [
            Expanded(
              child: _PhoneFrame(child: scene.mock),
            ),
            const SizedBox(height: 16),
            _TipBanner(title: scene.tipTitle, body: scene.tipBody),
          ],
        );
      }),
    );
  }
}

class _TipBanner extends StatelessWidget {
  const _TipBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kAuthBrandBlue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAuthBrandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: kAuthBrandBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Iconsax.info_circle,
              size: 16,
              color: kAuthBrandBlue,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 22,
            alignment: Alignment.center,
            color: Colors.grey.shade100,
            child: Container(
              width: 72,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final pad = const EdgeInsets.fromLTRB(14, 12, 14, 16);
                final width = constraints.maxWidth - pad.horizontal;
                return Padding(
                  padding: pad,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      child: child,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMemorisingHome extends StatelessWidget {
  const _MockMemorisingHome();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Today',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        const SizedBox(height: 14),
        const _FakeTaskCard(
          color: Color(0xFF4979FB),
          label: 'New Memorisation',
          title: 'Al-Baqarah · Verse 42',
          cta: 'Start',
        ),
        const SizedBox(height: 10),
        const _FakeTaskCard(
          color: Color(0xFF64A377),
          label: 'Review',
          title: 'Al-Fatiha · 1–7',
          cta: 'Start Quiz',
        ),
      ],
    );
  }
}

class _FakeTaskCard extends StatelessWidget {
  const _FakeTaskCard({
    required this.color,
    required this.label,
    required this.title,
    required this.cta,
  });

  final Color color;
  final String label;
  final String title;
  final String cta;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              cta,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockReviewLock extends StatelessWidget {
  const _MockReviewLock();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF4979FB).withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4979FB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Iconsax.lock_1,
                  color: Color(0xFF4979FB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Memorisation paused',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clear some reviews before adding more memorisation. 5 due right now.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        height: 1.4,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF64A377), Color(0xFF7BB58A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Iconsax.refresh,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Review · 2 due',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const MissedReviewTag(onDark: true),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Al-Ikhlas · 1–4',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                'Skipped yesterday — due again today',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Start Quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64A377),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MockReviewExplained extends StatelessWidget {
  const _MockReviewExplained();

  /// Intervals from [SpacedRepetitionService] for a clean run (rating 4).
  /// Matches new reviews created in Firestore: `sm2: [0, 2.0, 1]`.
  static List<int> _exampleGaps() {
    final service = SpacedRepetitionService();
    var state = ReviewState.fromLegacyArray([0, 2.0, 1]);
    final gaps = <int>[state.interval]; // first review: 1 day
    for (var i = 0; i < 2; i++) {
      final result = service.calculateNextReview(
        rating: 4,
        currentState: state,
      );
      if (result.status != ReviewStatus.continue_ || result.nextInterval <= 0) {
        break;
      }
      gaps.add(result.nextInterval);
      state = result.newState;
    }
    return gaps;
  }

  static String _gapLabel(int days) => days == 1 ? '1 day' : '$days days';

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final gaps = _exampleGaps();
    final steps = [
      ('1', 'Memorise', 'You finish a new verse'),
      ('2', 'Quiz', 'A review quiz is scheduled'),
      ('3', 'Space out', 'Gaps grow when you do well'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reviews',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'A review is a quiz on verses you’ve already memorised.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            height: 1.4,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 14),
        ...steps.map(
          (step) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: kAuthBrandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    step.$1,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kAuthBrandBlue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        step.$2,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        step.$3,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF64A377).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF64A377).withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al-Ikhlas · 1–4',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Gaps if you do well',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (var i = 0; i < gaps.length; i++) ...[
                    if (i > 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.only(bottom: 18),
                          color: const Color(0xFF64A377).withValues(alpha: 0.35),
                        ),
                      ),
                    _ReviewDayChip(
                      label: _gapLabel(gaps[i]),
                      active: i == 0,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewDayChip extends StatelessWidget {
  const _ReviewDayChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? const Color(0xFF64A377) : Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            color: active ? const Color(0xFF64A377) : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}

class _MockCustomQuiz extends StatelessWidget {
  const _MockCustomQuiz();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final types = [
      (Iconsax.hierarchy_square_3, 'Drag and Drop', true, false),
      (Iconsax.link, 'Verse Pairing', true, false),
      (Iconsax.document_text, 'Fill in the Blank', false, true),
      (Iconsax.arrow_right, 'What Comes Next', false, true),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Create Quiz',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: kAuthBrandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kAuthBrandBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              const Icon(Iconsax.book_1, color: kAuthBrandBlue, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Al-Baqarah · 1–7',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
              Text(
                'Change',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kAuthBrandBlue,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Question types',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 6),
        ...types.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item.$3
                      ? kAuthBrandBlue.withValues(alpha: 0.45)
                      : Colors.grey.shade200,
                  width: item.$3 ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: item.$3
                          ? kAuthBrandBlue
                          : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      item.$1,
                      size: 14,
                      color: item.$3 ? Colors.white : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (item.$4)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: kAuthBrandBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Pro',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: kAuthBrandBlue,
                        ),
                      ),
                    ),
                  Icon(
                    item.$3 ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                    size: 18,
                    color: item.$3 ? kAuthBrandBlue : Colors.grey.shade300,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: kAuthBrandBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            'Create Quiz',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _MockResetHint extends StatelessWidget {
  const _MockResetHint();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4979FB).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 44,
              color: Color(0xFF4979FB),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "You've completed the Quran",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jadwal is still strongest for people memorising. For now, create quizzes and read the mushaf — fuller Huffadh tools are coming.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reset plan',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF4979FB),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Only if you want daily memorisation again',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MockMushafPeek extends StatelessWidget {
  const _MockMushafPeek();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final surahs = [
      (1, 'Al-Fatiha', 0.7),
      (2, 'Al-Baqarah', 0.35),
      (3, 'Aal-E-Imran', 0.1),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quran',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.book_1,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Holy Quran',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Overall Progress',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  Text(
                    '36/114 Surahs',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: 36 / 114,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.book_square,
                      color: Color(0xFF4979FB),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Continue Reading',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4979FB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...surahs.map(
          (s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${s.$1}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.$2,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: s.$3,
                            minHeight: 4,
                            backgroundColor: Colors.grey.shade200,
                            color: kAuthBrandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadyPage extends StatelessWidget {
  const _ReadyPage();

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;
    final isReplay = OnBoardingController.instance.isReplay;

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 56, 32, 180),
      child: Column(
        children: [
          const Spacer(flex: 2),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: kAuthBrandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Iconsax.tick_circle,
              size: 44,
              color: kAuthBrandBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            isReplay ? 'You’re all set' : 'Ready when you are',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isReplay
                ? 'That’s the tour — head back whenever you want a refresher from Settings.'
                : 'Create a free account to save your plan, reviews, and progress across devices.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 15,
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
