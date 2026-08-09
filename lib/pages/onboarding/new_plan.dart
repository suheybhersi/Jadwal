import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/daily_amount_picker.dart';
import 'package:jadwal/components/onboarding_ui.dart';
import 'package:jadwal/components/schedule_day_picker.dart';
import 'package:jadwal/components/verse_picker.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';
import 'dart:math';

class NewPlanScreen extends StatefulWidget {
  const NewPlanScreen({
    super.key,
    this.onBackToQuestion,
  });

  /// When set, Back on the first plan step returns to the hafidh question.
  final VoidCallback? onBackToQuestion;

  @override
  State<NewPlanScreen> createState() => _NewPlanScreenState();
}

class _NewPlanScreenState extends State<NewPlanScreen> {
  @override
  void initState() {
    super.initState();
    // Remove any existing controller so we get a fresh form (no prefilled
    // data from a previous plan when re-entering after reset).
    Get.delete<NewPlanController>(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NewPlanController());
    final FirestoreService firestoreService = FirestoreService(
      auth: FirebaseAuth.instance,
      uid: FirebaseAuth.instance.currentUser!.uid,
    );

    Future<void> storeNewPlan() async {
      if (controller.isCreatingPlan.value) return;
      controller.isCreatingPlan.value = true;
      String fromKey = '${controller.isBackToFront.value ? '114' : '1'}:1';
      String toKey =
          '${controller.selectedToSurahData.value?['surahNumber']}:${controller.selectedToVerse.value}';
      int lines = controller.selectedUnit.value == 'Lines'
          ? int.tryParse(controller.inputController.text) ?? 1
          : (int.tryParse(controller.inputController.text) ?? 1) * 15;
      if (lines < 1) lines = 1;

      try {
        await firestoreService.addPlan(controller.isBackToFront.value, fromKey,
            toKey, lines, controller.selectedDays.toList());

        // Check if hifdhs list has values before setting planCreated to true
        final hifdhs = await firestoreService.getHifdhsStream().first;
        if (hifdhs.docs.isNotEmpty) {
          controller.planCreated.value = true;
        }
      } catch (_) {
        controller.isCreatingPlan.value = false;
        rethrow;
      }
    }

    return AuthGradientScaffold(
      child: Obx(() {
          if (controller.isCreatingPlan.value) {
            return CreatingPlanPage(
              isCompleted: controller.planCreated,
            );
          }

          return StreamBuilder(
            stream: firestoreService.getSurahsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: kAuthBrandBlue),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No data available.',
                    style:
                        GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final surahsList = snapshot.data!.docs;
              surahsList
                  .sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

              final allData = surahsList
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              final surahNames =
                  allData.map((data) => data['surah'] as String).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
                    child: Obx(() {
                      final index = controller.currentPageIndex.value;
                      final canGoBackInPlan = index != 0;
                      final canGoToQuestion =
                          index == 0 && widget.onBackToQuestion != null;
                      return Row(
                        children: [
                          if (canGoBackInPlan)
                            OnboardingBackButton(
                              onPressed: () =>
                                  controller.jumpToPageSafe(index - 1),
                            )
                          else if (canGoToQuestion)
                            OnboardingBackButton(
                              onPressed: () => widget.onBackToQuestion!(),
                            )
                          else
                            const SizedBox(width: 44, height: 44),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OnboardingProgressBar(
                              current: controller.currentPageIndex.value,
                              total: controller.totalSteps,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  Expanded(
                    child: Obx(() => PageView(
                          controller: controller.pageController,
                          onPageChanged: controller.updatePageIndicator,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            const IntroPage(),
                            if (controller.hasMemorisedBefore.value) ...[
                              MemorisedPage(
                                surahNames: surahNames,
                                controller: controller,
                                allData: allData,
                              ),
                            ],
                            const PlanDetailsPage(),
                            const PlanModePage(),
                            const ReviewPage(
                              title: 'Review your plan',
                              description:
                                  'Confirm everything looks right before we create your schedule.',
                            ),
                          ],
                        )),
                  ),
                  BottomNavigation(
                    controller: controller,
                    onNextPressed: storeNewPlan,
                  ),
                ],
              );
            },
          );
        }),
    );
  }
}

class CreatingPlanPage extends StatelessWidget {
  final RxBool isCompleted;

  const CreatingPlanPage({
    super.key,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: kAuthBrandBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: kAuthBrandBlue,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Creating your plan…',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Setting up your daily schedule and reviews.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BottomNavigation extends StatelessWidget {
  const BottomNavigation({
    super.key,
    required this.controller,
    required this.onNextPressed,
  });

  final NewPlanController controller;
  final VoidCallback onNextPressed;

  @override
  Widget build(BuildContext context) {
    return OnboardingBottomBar(
      child: Obx(() {
        final isReview = controller.currentPageIndex.value ==
            controller.reviewPageIndex;
        final busy = controller.isAdvancing.value ||
            controller.isCreatingPlan.value;
        final onIntro = controller.currentPageIndex.value == 0;
        final introReady = controller.answeredMemorisedBefore.value &&
            controller.answeredDirection.value;
        final canContinue = !busy && (!onIntro || introReady);
        return AuthPrimaryButton(
          label: isReview ? 'Confirm & create' : 'Continue',
          enabled: canContinue,
          onPressed: !canContinue
              ? null
              : () async {
                  final reviewIndex = controller.reviewPageIndex;
                  final modeIndex = controller.modePageIndex;
                  if (controller.currentPageIndex.value == reviewIndex) {
                    onNextPressed();
                  } else if (controller.currentPageIndex.value == modeIndex) {
                    if (controller.selectedMode.value == null) {
                      controller.modePageError.value =
                          'Please select a mode to continue.';
                    } else {
                      controller.modePageError.value = '';
                      controller.isAdvancing.value = true;
                      try {
                        final prefsService =
                            Provider.of<UserPreferencesService>(
                          context,
                          listen: false,
                        );
                        await prefsService
                            .setUsageMode(controller.selectedMode.value!);
                        await prefsService.completeModeSelection();
                        if (!context.mounted) return;
                        controller.jumpToPageSafe(reviewIndex);
                      } finally {
                        controller.isAdvancing.value = false;
                      }
                    }
                  } else {
                    controller.nextPage();
                  }
                },
        );
      }),
    );
  }
}

class IntroPage extends StatelessWidget {
  const IntroPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();
    final labelColor = Theme.of(context)
        .colorScheme
        .inversePrimary
        .withValues(alpha: 0.75);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Obx(() {
        final answeredFirst = controller.answeredMemorisedBefore.value;
        final memorisedBefore = controller.hasMemorisedBefore.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingStepHeader(
              title: 'Build your plan',
              subtitle:
                  'Tell us a bit about your memorisation so we can set a realistic daily schedule.',
            ),
            const SizedBox(height: 16),
            if (!answeredFirst) ...[
              Text(
                'Have you memorised before?',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              OnboardingChoiceCard(
                icon: Iconsax.tick_circle,
                title: 'Yes, I have',
                subtitle: 'We’ll ask how far you’ve reached',
                selected: false,
                onTap: () {
                  controller.hasMemorisedBefore.value = true;
                  controller.answeredMemorisedBefore.value = true;
                },
              ),
              const SizedBox(height: 8),
              OnboardingChoiceCard(
                icon: Iconsax.add_circle,
                title: 'No, starting fresh',
                subtitle: 'We’ll begin from the start of your path',
                selected: false,
                onTap: () {
                  controller.hasMemorisedBefore.value = false;
                  controller.selectedToSurah.value = null;
                  controller.selectedToVerse.value = null;
                  controller.selectedToSurahData.value = null;
                  controller.answeredMemorisedBefore.value = true;
                },
              ),
            ] else ...[
              OnboardingReviewTile(
                title: 'Have you memorised before?',
                content: memorisedBefore ? 'Yes, I have' : 'No, starting fresh',
                icon: memorisedBefore
                    ? Iconsax.tick_circle
                    : Iconsax.add_circle,
                onEdit: () {
                  controller.answeredMemorisedBefore.value = false;
                  controller.answeredDirection.value = false;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Direction',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
              const SizedBox(height: 8),
              OnboardingChoiceCard(
                icon: Iconsax.arrow_right_1,
                title: 'Front to back',
                subtitle: 'Start from Al-Fatiha',
                selected: controller.answeredDirection.value &&
                    !controller.isBackToFront.value,
                onTap: () {
                  controller.isBackToFront.value = false;
                  controller.answeredDirection.value = true;
                },
              ),
              const SizedBox(height: 8),
              OnboardingChoiceCard(
                icon: Iconsax.arrow_left_1,
                title: 'Back to front',
                subtitle: 'Start from An-Nas',
                selected: controller.answeredDirection.value &&
                    controller.isBackToFront.value,
                onTap: () {
                  controller.isBackToFront.value = true;
                  controller.answeredDirection.value = true;
                },
              ),
            ],
          ],
        );
      }),
    );
  }
}

class MemorisedPage extends StatelessWidget {
  const MemorisedPage({
    super.key,
    required this.surahNames,
    required this.controller,
    required this.allData,
  });

  final List<String> surahNames;
  final NewPlanController controller;
  final List<Map<String, dynamic>> allData;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingStepHeader(
            title: 'Where did you stop?',
            subtitle:
                'We start from the beginning of your path. Tell us the last surah and verse you’ve memorised so far.',
          ),
          const SizedBox(height: 16),

          // Fixed start of the memorised range
          Text(
            '1. Started from',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .inversePrimary
                  .withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final startSurah =
                controller.isBackToFront.value ? 'An-Nas' : 'Al-Fatiha';
            return OnboardingSurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kOnboardingAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.flag,
                      size: 20,
                      color: kOnboardingAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          startSurah,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color:
                                Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        Text(
                          'Verse 1 · based on your direction',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Fixed',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),

          // End of the memorised range (user picks)
          Text(
            '2. Stopped at',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context)
                  .colorScheme
                  .inversePrimary
                  .withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final endSurah = controller.selectedToSurah.value;
            final endVerse = controller.selectedToVerse.value;
            final hasSelection = endSurah != null && endVerse != null;

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openStoppedAtPicker(context),
                borderRadius: BorderRadius.circular(14),
                child: OnboardingSurfaceCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: kOnboardingAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Iconsax.location,
                          size: 20,
                          color: kOnboardingAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hasSelection ? endSurah : 'Choose surah & verse',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                            Text(
                              hasSelection
                                  ? 'Verse $endVerse'
                                  : 'Tap to select where you stopped',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Iconsax.arrow_right_3,
                        size: 16,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Live range summary
          Obx(() {
            final startSurah =
                controller.isBackToFront.value ? 'An-Nas' : 'Al-Fatiha';
            final endSurah = controller.selectedToSurah.value;
            final endVerse = controller.selectedToVerse.value;
            if (endSurah == null || endVerse == null) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: kOnboardingAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Memorised so far: $startSurah 1 → $endSurah $endVerse',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kOnboardingAccent,
                  ),
                ),
              ),
            );
          }),

          Obx(() {
            final errorMessage = controller.toPageError.value;
            if (errorMessage.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                errorMessage,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _openStoppedAtPicker(BuildContext context) {
    final backToFront = controller.isBackToFront.value;
    final ordered = List<Map<String, dynamic>>.from(allData);
    int parseNum(Map<String, dynamic> s) =>
        int.tryParse(s['surahNumber']?.toString() ?? '') ?? 0;
    ordered.sort((a, b) {
      final aNum = parseNum(a);
      final bNum = parseNum(b);
      return backToFront ? bNum.compareTo(aNum) : aNum.compareTo(bNum);
    });

    if (ordered.isEmpty) return;

    final selectedSurahData = controller.selectedToSurahData.value;
    final selectedVerse = controller.selectedToVerse.value;
    var initialSurahIndex = 0;
    if (selectedSurahData != null) {
      final idx = ordered.indexWhere(
        (s) => s['surah'] == selectedSurahData['surah'],
      );
      if (idx >= 0) initialSurahIndex = idx;
    }

    String pendingSurah = ordered[initialSurahIndex]['surah'] as String;
    int pendingVerse = selectedVerse ?? 1;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          height: MediaQuery.of(sheetContext).size.height * 0.55,
          decoration: BoxDecoration(
            color: Theme.of(sheetContext).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Where did you stop?',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .inversePrimary,
                    ),
                  ),
                ),
                Expanded(
                  child: QuranVersePicker(
                    key: ValueKey('memorised-sheet-$backToFront'),
                    surahData: ordered,
                    initialSurahIndex: initialSurahIndex,
                    initialVerseNumber: selectedVerse,
                    onVerseSelected: (surahName, verseNumber) {
                      pendingSurah = surahName;
                      pendingVerse = verseNumber;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: AuthPrimaryButton(
                    label: 'Done',
                    onPressed: () {
                      final selectedSurah = ordered.firstWhere(
                        (surah) => surah['surah'] == pendingSurah,
                      );
                      controller.updateSelectedToSurah(
                          pendingSurah, selectedSurah);
                      controller.updateSelectedToVerse(pendingVerse);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class PlanDetailsPage extends StatelessWidget {
  const PlanDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Obx(() {
        final amountDone = controller.answeredDailyAmount.value;
        final scheduleDone = controller.answeredSchedule.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const OnboardingStepHeader(
              title: 'Daily amount & schedule',
              subtitle:
                  'Choose how much you memorise each day and on which days.',
            ),
            const SizedBox(height: 16),
            if (!amountDone) ...[
              Text(
                'Daily amount',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 8),
              OnboardingSurfaceCard(
                child: DailyAmountPicker(
                  compact: true,
                  unit: controller.selectedUnit.value,
                  amount: max(
                      1, int.tryParse(controller.inputValue.value) ?? 1),
                  onUnitChanged: (unit) {
                    controller.selectedUnit.value = unit;
                  },
                  onAmountChanged: (amount) {
                    controller.inputController.text =
                        max(1, amount).toString();
                    controller.update();
                  },
                ),
              ),
            ] else ...[
              OnboardingReviewTile(
                title: 'Daily amount',
                content: controller.dailyAmountSummary,
                icon: Iconsax.chart_2,
                onEdit: () {
                  controller.answeredDailyAmount.value = false;
                  controller.answeredSchedule.value = false;
                },
              ),
              const SizedBox(height: 16),
              if (!scheduleDone) ...[
                Text(
                  'Schedule',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context)
                        .colorScheme
                        .inversePrimary
                        .withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 8),
                OnboardingSurfaceCard(
                  child: ScheduleDayPicker(
                    compact: true,
                    selectedDays: controller.selectedDays.toList(),
                    onChanged: (days) {
                      controller.selectedDays.assignAll(days);
                    },
                  ),
                ),
              ] else
                OnboardingReviewTile(
                  title: 'Schedule',
                  content: controller.scheduleSummary,
                  icon: Iconsax.calendar_1,
                  onEdit: () {
                    controller.answeredSchedule.value = false;
                  },
                ),
            ],
            if (controller.planDetailsError.value.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                controller.planDetailsError.value,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      }),
    );
  }
}

class PlanModePage extends StatelessWidget {
  const PlanModePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingStepHeader(
            title: 'Choose your path',
            subtitle:
                'How should Jadwal support your reviews and consistency?',
          ),
          const SizedBox(height: 16),
          Obx(() => _ModeCard(
                mode: UsageMode.flexible,
                icon: Iconsax.timer_pause,
                color: const Color(0xFF10B981),
                isSelected:
                    controller.selectedMode.value == UsageMode.flexible,
                onTap: () =>
                    controller.selectedMode.value = UsageMode.flexible,
              )),
          const SizedBox(height: 10),
          Obx(() => _ModeCard(
                mode: UsageMode.intensive,
                icon: Iconsax.flash_1,
                color: kOnboardingAccent,
                isSelected:
                    controller.selectedMode.value == UsageMode.intensive,
                isRecommended: true,
                onTap: () =>
                    controller.selectedMode.value = UsageMode.intensive,
              )),
          const SizedBox(height: 8),
          Text(
            'You can change this anytime in Settings.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          Obx(() => controller.modePageError.value.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    controller.modePageError.value,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade700,
                      fontSize: 12,
                    ),
                  ),
                )
              : const SizedBox.shrink()),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    this.isRecommended = false,
  });

  final UsageMode mode;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final modeName = UserPreferencesService.getModeName(mode);
    final modeDescription = UserPreferencesService.getModeDescription(mode);
    final modeFeatures = UserPreferencesService.getModeFeatures(mode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            modeName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .inversePrimary,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Recommended',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: isSelected ? color : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                modeDescription,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ...modeFeatures.take(3).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Iconsax.tick_circle, size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
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
      ),
    );
  }
}

class ReviewPage extends StatelessWidget {
  const ReviewPage({
    super.key,
    required this.title,
    required this.description,
  });

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NewPlanController>();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OnboardingStepHeader(
            title: title,
            subtitle: description,
          ),
          const SizedBox(height: 16),
          OnboardingReviewTile(
            title: 'Direction',
            content: controller.isBackToFront.value
                ? 'Back to front'
                : 'Front to back',
            icon: Iconsax.arrow_swap_horizontal,
            onEdit: () => controller.jumpToPageSafe(0),
          ),
          const SizedBox(height: 10),
          OnboardingReviewTile(
            title: 'Previously memorised',
            content: controller.hasMemorisedBefore.value
                ? '${controller.isBackToFront.value ? 'An-Nas' : 'Al-Fatiha'} 1 – ${controller.selectedToSurah.value} ${controller.selectedToVerse.value}'
                : 'Starting fresh',
            icon: Iconsax.bookmark,
            onEdit: () => controller.jumpToPageSafe(
                controller.hasMemorisedBefore.value ? 1 : 0),
          ),
          const SizedBox(height: 10),
          OnboardingReviewTile(
            title: 'Schedule',
            content: controller.selectedDays
                .asMap()
                .entries
                .where((entry) => entry.value)
                .map((entry) => [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun'
                    ][entry.key])
                .join(', '),
            icon: Iconsax.calendar_1,
            onEdit: () => controller.jumpToPageSafe(
                controller.hasMemorisedBefore.value ? 2 : 1),
          ),
          const SizedBox(height: 10),
          OnboardingReviewTile(
            title: 'Daily amount',
            content:
                '${controller.inputController.text} ${controller.selectedUnit.value.toLowerCase()}',
            icon: Iconsax.chart_2,
            onEdit: () => controller.jumpToPageSafe(
                controller.hasMemorisedBefore.value ? 2 : 1),
          ),
          const SizedBox(height: 10),
          OnboardingReviewTile(
            title: 'Mode',
            content: controller.selectedMode.value != null
                ? UserPreferencesService.getModeName(
                    controller.selectedMode.value!)
                : 'Not selected',
            icon: Iconsax.setting_2,
            onEdit: () =>
                controller.jumpToPageSafe(controller.modePageIndex),
          ),
        ],
      ),
    );
  }
}

class NewPlanController extends GetxController {
  static NewPlanController get instance => Get.find();

  final pageController = PageController();
  final RxBool isAdvancing = false.obs;
  Rx<int> currentPageIndex = 0.obs;
  final inputController = TextEditingController();
  final RxString selectedUnit = 'Lines'.obs;

  final Rxn<Map<String, dynamic>> selectedToSurahData =
      Rxn<Map<String, dynamic>>();

  final Rxn<String> selectedToSurah = Rxn<String>();

  final Rxn<int> selectedToVerse = Rxn<int>();

  final RxList<bool> selectedDays = List.generate(7, (index) => false).obs;

  final RxString toPageError = ''.obs;
  final RxString planDetailsError = ''.obs;

  final RxBool isBackToFront = false.obs;
  final RxBool hasMemorisedBefore = false.obs;

  /// Intro step: first question answered → show summary + direction.
  final RxBool answeredMemorisedBefore = false.obs;
  final RxBool answeredDirection = false.obs;

  /// Plan details: amount confirmed → show schedule; schedule confirmed → summaries.
  final RxBool answeredDailyAmount = false.obs;
  final RxBool answeredSchedule = false.obs;

  final RxBool isCreatingPlan = false.obs;
  final RxBool planCreated = false.obs;

  // Add this new reactive variable
  final RxString inputValue = '1'.obs;

  @override
  void onInit() {
    super.onInit();
    inputController.text = '1';
    // Listen to changes in the text controller
    inputController.addListener(() {
      inputValue.value = inputController.text;
    });
  }

  @override
  void onClose() {
    inputController.dispose();
    super.onClose();
  }

  // Update "To" selection
  void updateSelectedToSurah(
      String? surahName, Map<String, dynamic> surahData) {
    selectedToSurah.value = surahName;
    selectedToSurahData.value = surahData;
    selectedToVerse.value = null; // Clear verse when surah changes
  }

  void updateSelectedToVerse(int? verse) {
    selectedToVerse.value = verse;
  }

  void updatePageIndicator(index) => currentPageIndex.value = index;

  final Rxn<UsageMode> selectedMode = Rxn<UsageMode>();
  final RxString modePageError = ''.obs;

  int get modePageIndex => hasMemorisedBefore.value ? 3 : 2;
  int get reviewPageIndex => hasMemorisedBefore.value ? 4 : 3;
  int get totalSteps => hasMemorisedBefore.value ? 5 : 4;

  void jumpToPageSafe(int page) {
    currentPageIndex.value = page;
    if (pageController.hasClients) {
      pageController.jumpToPage(page);
      return;
    }
    // Provider rebuilds after prefs save can detach the PageView mid-await.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.jumpToPage(page);
      }
    });
  }

  void nextPage() {
    if (currentPageIndex.value == 0) {
      if (!answeredMemorisedBefore.value || !answeredDirection.value) {
        return;
      }
      jumpToPageSafe(1);
    } else if (currentPageIndex.value == 1 && hasMemorisedBefore.value) {
      if (selectedToSurah.value != null && selectedToVerse.value != null) {
        toPageError.value = '';
        jumpToPageSafe(2);
      } else {
        toPageError.value = 'Please select a Surah and Verse to proceed.';
      }
    } else if (currentPageIndex.value == (hasMemorisedBefore.value ? 2 : 1)) {
      final amount = int.tryParse(inputController.text) ?? 0;
      final lines = selectedUnit.value == 'Lines' ? amount : amount * 15;
      if (lines < 1) {
        planDetailsError.value = 'Daily amount must be at least 1 line.';
        return;
      }
      if (!answeredDailyAmount.value) {
        planDetailsError.value = '';
        answeredDailyAmount.value = true;
        return;
      }
      if (!answeredSchedule.value) {
        if (!selectedDays.contains(true)) {
          planDetailsError.value = 'Please select at least one day.';
          return;
        }
        planDetailsError.value = '';
        answeredSchedule.value = true;
        return;
      }
      planDetailsError.value = '';
      jumpToPageSafe(modePageIndex);
    }
  }

  String get dailyAmountSummary {
    final amount = max(1, int.tryParse(inputController.text) ?? 1);
    final unit = selectedUnit.value.toLowerCase();
    return '$amount $unit';
  }

  String get scheduleSummary {
    final days = selectedDays.toList();
    if (!days.contains(true)) return 'No days selected';
    if (days.every((d) => d)) return 'Every day';
    final weekdays = days[0] &&
        days[1] &&
        days[2] &&
        days[3] &&
        days[4] &&
        !days[5] &&
        !days[6];
    if (weekdays) return 'Weekdays (Mon–Fri)';
    final weekends = !days[0] &&
        !days[1] &&
        !days[2] &&
        !days[3] &&
        !days[4] &&
        days[5] &&
        days[6];
    if (weekends) return 'Weekends (Sat–Sun)';
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return [
      for (var i = 0; i < days.length; i++)
        if (days[i]) names[i],
    ].join(', ');
  }
}
