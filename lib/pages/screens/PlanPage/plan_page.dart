import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/components/firestore_error_view.dart';
import 'package:jadwal/pages/screens/PlanPage/edit_plan_page.dart';
import 'package:jadwal/components/quiz_options_sheet.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:jadwal/services/tutorial_service.dart';
import 'package:jadwal/components/smart_showcase.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:provider/provider.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final FirestoreService firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

  final GlobalKey _editPlanKey = GlobalKey();

  /// Plan id we last called reviewMissed for (reschedule missed → today).
  String? _reviewMissedPlanId;

  @override
  void initState() {
    super.initState();
    // Start showcase after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startShowcaseIfNeeded();
    });
  }

  void _startShowcaseIfNeeded() {
    final tutorialService =
        Provider.of<TutorialService>(context, listen: false);
    if (!tutorialService.hasSeenTooltip('edit_plan_button')) {
      // Add a delay to ensure widget is fully built
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ShowcaseView.get().startShowCase([_editPlanKey]);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPageHeader(context),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestoreService.getPlansStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const FirestoreErrorView();
                  }

                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 73, 121, 251),
                      ),
                    );
                  }

                  if (snapshot.hasData) {
                    List plansList = snapshot.data!.docs;

                    if (plansList.isNotEmpty) {
                      Map<String, dynamic> plan =
                          plansList[0].data() as Map<String, dynamic>;
                      final String planId = plansList[0].id;
                      final bool isHuffadh = plan['planCompleted'] == true;

                      // Reschedule missed reviews to today (same as non-Huffadh flow)
                      if (_reviewMissedPlanId != planId) {
                        _reviewMissedPlanId = planId;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          firestoreService.reviewMissed(planId);
                        });
                      }

                      // Huffadh: Revision page — incomplete reviews when intensive mode
                      if (isHuffadh) {
                        return SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                            child: Consumer<UserPreferencesService>(
                              builder: (context, prefsService, child) {
                                final bool showReviews =
                                    prefsService.shouldScheduleReviews;
                                final List<dynamic> incompleteReviews =
                                    _getIncompleteReviews(plan);
                                if (showReviews &&
                                    incompleteReviews.isNotEmpty) {
                                  return IncompleteReviewsSection(
                                    plan: plan,
                                    planId: planId,
                                    incompleteReviews: incompleteReviews,
                                    firestoreService: firestoreService,
                                  );
                                }
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 48),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Iconsax.clipboard_tick,
                                          size: 60,
                                          color: Colors.grey
                                              .withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          showReviews
                                              ? 'No reviews to complete'
                                              : 'Revision schedule is off',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }

                      // Still memorising: no "Reviews to complete" — only shown when whole Quran memorisation is completed (Huffadh)
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PlanProgress(plan: plan),
                            plan['hifdhs']
                                    .where(
                                        (hifdh) => hifdh['completed'] == true)
                                    .isNotEmpty
                                ? Column(
                                    children: [
                                      PreviousMemorisation(plan: plan),
                                      Consumer<UserPreferencesService>(
                                        builder:
                                            (context, prefsService, child) {
                                          if (!prefsService
                                              .shouldScheduleReviews) {
                                            return SizedBox();
                                          }
                                          return PreviousReviews(plan: plan);
                                        },
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 30),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Iconsax.clipboard_close,
                                            size: 60,
                                            color: Colors.grey
                                                .withValues(alpha: 0.5),
                                          ),
                                          SizedBox(height: 16),
                                          Text(
                                            'No history found.',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                            SizedBox(height: 30),
                          ],
                        ),
                      );
                    }
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Iconsax.document_text,
                          size: 60,
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No plans found',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Plan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: firestoreService.getPlansStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.docs.isEmpty) {
                return const SizedBox(width: 40, height: 40);
              }

              Map<String, dynamic> plan =
                  snapshot.data!.docs[0].data() as Map<String, dynamic>;
              String id = snapshot.data!.docs[0].id;
              final bool isHuffadh = plan['planCompleted'] == true;

              // Huffadh: no edit-plan button (revision page only)
              if (isHuffadh) {
                return const SizedBox(width: 40, height: 40);
              }

              final editButton = IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPlanPage(
                        plan: plan,
                        id: id,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Iconsax.edit,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                tooltip: 'Edit plan',
                style: IconButton.styleFrom(
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(40, 40),
                ),
              );

              return SmartShowcase(
                tooltipId: 'edit_plan_button',
                title: 'Edit Your Plan',
                description:
                    'Tap here to modify your memorisation plan, change schedule, or update your progress.',
                globalKey: _editPlanKey,
                child: editButton,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Returns reviews that are due or overdue (date <= today, not completed), sorted by date ascending.
List<dynamic> _getIncompleteReviews(Map<String, dynamic> plan) {
  final List<dynamic> allReviews = (plan['reviews'] as List<dynamic>?) ?? [];
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final incomplete = allReviews.where((r) {
    try {
      final parts = (r['date'] as String).split('-');
      final reviewDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
      return !reviewDate.isAfter(today) && (r['completed'] != true);
    } catch (_) {
      return false;
    }
  }).toList();
  incomplete.sort((a, b) {
    final partsA = (a['date'] as String).split('-');
    final partsB = (b['date'] as String).split('-');
    final dateA = DateTime(
      int.parse(partsA[2]),
      int.parse(partsA[1]),
      int.parse(partsA[0]),
    );
    final dateB = DateTime(
      int.parse(partsB[2]),
      int.parse(partsB[1]),
      int.parse(partsB[0]),
    );
    return dateA.compareTo(dateB);
  });
  return incomplete;
}

class PlanProgress extends StatelessWidget {
  const PlanProgress({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    // Calculate percentage with safety check to avoid division by zero
    double percentage = plan['totalLines'] > 0
        ? (plan['completedLines'] / plan['totalLines'])
        : 0.0;
    // Ensure percentage doesn't exceed 1.0
    percentage = percentage > 1.0 ? 1.0 : percentage;

    final String title = 'Memorisation Progress';
    final String subtitle = 'Keep up your progress!';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 73, 121, 251),
            Color.fromARGB(255, 114, 152, 255),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 73, 121, 251).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: CircularPercentIndicator(
                radius: 45,
                lineWidth: 10,
                percent: percentage,
                progressColor: Colors.white,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                circularStrokeCap: CircularStrokeCap.round,
                center: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                animation: true,
                animationDuration: 1000,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reusable section wrapper for the Plan page. Use for Memorisation, Revision plans, etc.
class PlanPageSection extends StatelessWidget {
  const PlanPageSection({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  final String title;
  final IconData icon;
  final Color? iconColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        child,
      ],
    );
  }
}

/// Displays reviews that are due or overdue (incomplete) when mode is intensive.
/// Shown on the plan page for Huffadh users.
class IncompleteReviewsSection extends StatelessWidget {
  const IncompleteReviewsSection({
    super.key,
    required this.plan,
    required this.planId,
    required this.incompleteReviews,
    required this.firestoreService,
  });

  final Map<String, dynamic> plan;
  final String planId;
  final List<dynamic> incompleteReviews;
  final FirestoreService firestoreService;

  void _openReviewQuiz(
      BuildContext context, Map<String, dynamic> review, String id) async {
    final subscription =
        Provider.of<SubscriptionService>(context, listen: false);
    final allowed = await subscription.ensureCanStartQuiz(context);
    if (!allowed || !context.mounted) return;

    final isPro = subscription.isPro;
    final enableWhatNext = isPro &&
        Provider.of<UserPreferencesService>(context, listen: false)
            .enableWhatComesNext;

    final surahParts = (review['surah'] as String).split(' ');
    final endSurah = surahParts.length > 1 ? surahParts[1] : surahParts[0];
    final reviewTitle =
        '${surahParts[0]}  ${review['review'].toString().split('-')[0].split(':')[1]}-${surahParts[0] == endSurah ? '' : '$endSurah '}${review['review'].toString().split('-')[1].split(':')[1]}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          reviewTitle: reviewTitle.trim(),
          versesList: review['versesList'],
          review: review['review'],
          id: id,
          updateReview: firestoreService.updateReview,
          includeFillBlank: isPro,
          includeWhatNext: enableWhatNext,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.15),
            spreadRadius: 0,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4979FB).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.refresh_circle,
                  color: Color(0xFF4979FB),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviews to complete',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${incompleteReviews.length} review${incompleteReviews.length == 1 ? '' : 's'} due',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: incompleteReviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final review = incompleteReviews[index] as Map<String, dynamic>;
              final dateStr = review['date'] as String;
              final parts = dateStr.split('-');
              final day = parts[0];
              final month = parts[1];
              final sub = context.watch<SubscriptionService>();
              final prefs = context.watch<UserPreferencesService>();
              final includesWhatComesNext =
                  sub.isPro && prefs.enableWhatComesNext;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openReviewQuiz(context, review, planId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '${review['surah'].split(' ')[0]} ${review['review'].split('-')[0].split(':')[1]} - ${review['surah'].split(' ').length > 1 ? review['surah'].split(' ')[1] : review['surah'].split(' ')[0]} ${review['review'].split('-')[1].split(':')[1]}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .inversePrimary,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (includesWhatComesNext) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.shade700,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        'Beta',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                includesWhatComesNext
                                    ? 'Due today · $day/$month · What Comes Next'
                                    : 'Due today · $day/$month',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () => showQuizOptionsSheet(context),
                          color: Theme.of(context).colorScheme.inversePrimary,
                          iconSize: 22,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                        ),
                        Icon(
                          Iconsax.arrow_right_3,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PreviousMemorisation extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PreviousMemorisation({
    super.key,
    required this.plan,
  });

  String _convertToArabicNumbers(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  void _showMemorisationDetails(
      BuildContext context, Map<String, dynamic> hifdh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memorisation Details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),

              SizedBox(height: 20),

              // First verse container
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(0xFFE3EAFF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Iconsax.book_1,
                            color: Color(0xFF4979FB),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Surah ${hifdh['surah'].split(' ')[0]}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Verse ${hifdh['hifdh'].split('-')[0].split(':')[1]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Divider(
                      height: 1,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    SizedBox(height: 24),
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Text(
                        '${hifdh['startVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[0].split(':')[1]).replaceAll(' ', '')}﴾',
                        style: GoogleFonts.scheherazadeNew(
                          letterSpacing: 0,
                          fontSize: 20,
                          height: 1.5,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),
                  ],
                ),
              ),

              // Connection indicator
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_downward_rounded,
                      color: Theme.of(context).colorScheme.inversePrimary,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ],
              ),

              // Second verse container (if different from first)
              if (hifdh['endVerse'] != null &&
                  hifdh['endVerse'] != hifdh['startVerse'])
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Color(0xFFE3EAFF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Iconsax.book_1,
                              color: Color(0xFF4979FB),
                              size: 18,
                            ),
                          ),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Surah ${hifdh['surah'].split(' ')[1]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Verse ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Divider(
                        height: 1,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                      SizedBox(height: 24),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Text(
                          '${hifdh['endVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[1].split(':')[1]).replaceAll(' ', '')}﴾',
                          style: GoogleFonts.scheherazadeNew(
                            letterSpacing: 0,
                            fontSize: 20,
                            height: 1.5,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .tertiary
                        .withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.calendar,
                      color: Color.fromARGB(255, 100, 163, 119),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Completed on ${hifdh['date'].split('-')[0]}/${hifdh['date'].split('-')[1]}/${hifdh['date'].split('-')[2]}',
                      style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.inversePrimary),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> hifdhs = (plan['hifdhs'] as List?)
            ?.where((hifdh) => hifdh['completed'] == true)
            .toList() ??
        [];
    hifdhs = hifdhs.reversed.toList();

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.book_1,
                color: Color.fromARGB(255, 73, 121, 251),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Memorisation',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hifdhs.length > 2 ? 2 : hifdhs.length,
            itemBuilder: (context, index) {
              final hifdh = hifdhs[index];
              return Column(
                children: [
                  InkWell(
                    onTap: () => _showMemorisationDetails(context, hifdh),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.3),
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]} - ${hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Completed on ${hifdh['date'].split('-')[0]}/${hifdh['date'].split('-')[1]}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 106, 106, 106),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Iconsax.arrow_right_3,
                            color: Colors.grey,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class PreviousReviews extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PreviousReviews({
    super.key,
    required this.plan,
  });

  String _convertToArabicNumbers(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  void _showReviewDetails(BuildContext context, Map<String, dynamic> review) {
    Widget makeDissmissable({required Widget child}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return makeDissmissable(
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            maxChildSize: 0.9,
            builder: (context, scrollController) => Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Review Details',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // First verse container
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFE6F3EA),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Iconsax.refresh,
                                    color: Color(0xFF64A377),
                                    size: 18,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Surah ${review['surah'].split(' ')[0]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    Text(
                                      'Verse ${review['review'].split('-')[0].split(':')[1]}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                            SizedBox(height: 24),
                            Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                '${review['startVerse']} ﴿${_convertToArabicNumbers(review['review'].split('-')[0].split(':')[1]).replaceAll(' ', '')}﴾',
                                style: GoogleFonts.scheherazadeNew(
                                  letterSpacing: 0,
                                  fontSize: 20,
                                  height: 1.5,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Connection indicator
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                          Container(
                            margin: EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.tertiary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_downward_rounded,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),

                      // Second verse container (if different from first)
                      if (review['endVerse'] != null &&
                          review['endVerse'] != review['startVerse'])
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withValues(alpha: 0.1),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFE6F3EA),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Iconsax.refresh,
                                      color: Color(0xFF64A377),
                                      size: 18,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Surah ${review['surah'].split(' ')[1]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Text(
                                        'Verse ${review['review'].split('-')[1].split(':')[1]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              Divider(
                                height: 1,
                                color: Theme.of(context).colorScheme.tertiary,
                              ),
                              SizedBox(height: 24),
                              Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(
                                  '${review['endVerse']} ﴿${_convertToArabicNumbers(review['review'].split('-')[1].split(':')[1]).replaceAll(' ', '')}﴾',
                                  style: GoogleFonts.scheherazadeNew(
                                    letterSpacing: 0,
                                    fontSize: 20,
                                    height: 1.5,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .inversePrimary,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ],
                          ),
                        ),

                      SizedBox(height: 20),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .tertiary
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .tertiary
                                .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Iconsax.calendar,
                              color: Color(0xFF64A377),
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Next review on ${review['date'].split('-')[0]}/${review['date'].split('-')[1]}/${review['date'].split('-')[2]}',
                              style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Review Ratings:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 12),
                      review['ratings'].isEmpty
                          ? Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withValues(alpha: 0.1),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'No ratings yet',
                                  style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary),
                                ),
                              ),
                            )
                          : Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  for (var i = 0;
                                      i < review['ratings'].length;
                                      i++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8.0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "Review ${i + 1}:",
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade800,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          _buildRatingStars(
                                              review['ratings'][i]),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> reviews = plan['reviews'] ?? [];

    reviews.sort((a, b) {
      List<String> dateAParts = a['date'].split('-');
      List<String> dateBParts = b['date'].split('-');
      DateTime dateA = DateTime(int.parse(dateAParts[2]),
          int.parse(dateAParts[1]), int.parse(dateAParts[0]));
      DateTime dateB = DateTime(int.parse(dateBParts[2]),
          int.parse(dateBParts[1]), int.parse(dateBParts[0]));
      return dateB.compareTo(dateA); // Reversed for newest first
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.refresh,
                color: Color.fromARGB(255, 100, 163, 119),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Reviews',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          reviews.isEmpty
              ? Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No reviews scheduled yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length > 3 ? 3 : reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return InkWell(
                      onTap: () => _showReviewDetails(context, review),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .colorScheme
                                  .tertiary
                                  .withValues(alpha: 0.3),
                              spreadRadius: 1,
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${review['surah'].split(' ')[0]} ${review['review'].split('-')[0].split(':')[1]} - ${review['surah'].split(' ')[1]} ${review['review'].split('-')[1].split(':')[1]}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Next review on ${review['date'].split('-')[0]}/${review['date'].split('-')[1]}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Color.fromARGB(255, 106, 106, 106),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Iconsax.arrow_right_3,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
