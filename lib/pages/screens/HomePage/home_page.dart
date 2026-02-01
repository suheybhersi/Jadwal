import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/HomePage/Week_days_section.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/pages/screens/HomePage/upcoming_section.dart';
import 'package:jadwal/pages/screens/HomePage/wird_section.dart';
import 'package:jadwal/pages/screens/MushafPage/mushaf_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/completion_feedback_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FirestoreService firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

  int hifdhIn = -1;

  final TextEditingController ratingController = TextEditingController();

  Map<String, dynamic> plan = {};

  bool reviewsMissedCalled = false;

  @override
  Widget build(BuildContext context) {
    bool hifdhMissedCalled = false;
    bool currentWeekCalled = false;
    bool updateHifdhCalled = false;
    String id = '';
    final userData = firestoreService.getUserProfile();
    return Scaffold(
      body: StreamBuilder(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
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
              final hifdhsList = plan['hifdhs'] as List<dynamic>?;
              final currentWeekList = plan['currentWeek'] as List<dynamic>?;
              if (hifdhsList != null &&
                  hifdhsList.isNotEmpty &&
                  currentWeekList != null &&
                  currentWeekList.isNotEmpty) {
                id = plansList[0].id;
                String weekStart = currentWeekList[0]['weekStart'];
                DateTime currWeekStartDT = DateTime.now().subtract(
                  Duration(days: DateTime.now().weekday - 1),
                );
                String currWeekStart =
                    '${currWeekStartDT.day}-${currWeekStartDT.month}-${currWeekStartDT.year}';

                if (currWeekStart != weekStart && !currentWeekCalled) {
                  currentWeekCalled = true;
                  firestoreService.updateCurrentWeek(id).then((_) {
                    currentWeekCalled = false;
                  });
                }

                if (!currentWeekCalled) {
                  DateTime todayDT = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    0,
                    0,
                  );

                  // Check each day of the week
                  bool needsUpdate = false;
                  List updatedWeek = List.from(currentWeekList);

                  for (int i = 0; i < currentWeekList.length; i++) {
                    dynamic day = currentWeekList[i];
                    List<String> weekStartString =
                        currentWeekList[0]['weekStart'].split('-');
                    DateTime weekStart = DateTime(
                      int.parse(weekStartString[2]),
                      int.parse(weekStartString[1]),
                      int.parse(weekStartString[0]),
                      0,
                      0,
                    );

                    DateTime dayDate = weekStart.add(Duration(days: i));

                    // If day is in the past and hasn't been marked as completed but has Hifdh assigned
                    if (dayDate.isBefore(todayDT) &&
                        !day['completed'] &&
                        plan['hifdhDays'][i] == true &&
                        !day['missed']) {
                      updatedWeek[i] = {...day, 'missed': true};
                      needsUpdate = true;
                    }
                  }

                  // Update Firestore if any days were marked as missed
                  if (needsUpdate) {
                    firestoreService
                        .updateDocument(id, {'currentWeek': updatedWeek});
                  }
                }

                bool completed = plan['hifdhs'].last['completed'];
                String hifdhDate = plan['hifdhs'].last['date'];
                String today =
                    '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}';

                DateTime hifdhDT = DateTime(
                  int.parse(hifdhDate.split('-')[2]),
                  int.parse(hifdhDate.split('-')[1]),
                  int.parse(hifdhDate.split('-')[0]),
                  0,
                  0,
                );
                DateTime todayDT = DateTime(
                  int.parse(today.split('-')[2]),
                  int.parse(today.split('-')[1]),
                  int.parse(today.split('-')[0]),
                  0,
                  0,
                );

                if (hifdhDT.difference(todayDT).inDays != plan['hifdhIn']) {
                  firestoreService.hifdhIn(id);
                }
                hifdhIn = plan['hifdhIn'];

                // Completed hifdh: always show the completed home page (not "No memorisation tasks")
                if (plan['planCompleted'] == true) {
                  return _buildCompletedHifdhHome(context, userData);
                }

                if ((hifdhDate == today || todayDT.isAfter(hifdhDT)) &&
                    completed) {
                  if (!updateHifdhCalled) {
                    updateHifdhCalled = true;
                    firestoreService.updateNextHifdh(id).then((_) {
                      updateHifdhCalled = false;
                    });
                  }
                  return Center(
                    child: CircularProgressIndicator(
                      color: Color.fromARGB(255, 73, 121, 251),
                    ),
                  );
                }

                if (todayDT.isAfter(hifdhDT) && !hifdhMissedCalled) {
                  hifdhMissedCalled = true;
                  firestoreService.hifdhMissed(id).then((_) {
                    hifdhMissedCalled = false;
                  });
                }

                if (!reviewsMissedCalled) {
                  reviewsMissedCalled = true;
                  firestoreService.reviewMissed(id).then((_) {
                    reviewsMissedCalled = false;
                  });
                }

                List<dynamic> reviews = plan['reviews']
                    .where((review) =>
                        review['date'] ==
                        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}')
                    .toList();

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header with name and settings
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 10, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Consumer<UserPreferencesService>(
                                      builder: (context, prefsService, child) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  'Welcome back',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: prefsService
                                                                .usageMode ==
                                                            UsageMode.flexible
                                                        ? const Color(
                                                                0xFF10B981)
                                                            .withValues(
                                                                alpha: 0.1)
                                                        : const Color(
                                                                0xFF4979FB)
                                                            .withValues(
                                                                alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                  ),
                                                  child: Text(
                                                    UserPreferencesService
                                                        .getModeName(
                                                            prefsService
                                                                .usageMode),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: prefsService
                                                                  .usageMode ==
                                                              UsageMode.flexible
                                                          ? const Color(
                                                              0xFF10B981)
                                                          : const Color(
                                                              0xFF4979FB),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            FutureBuilder<
                                                Map<String, dynamic>?>(
                                              future: userData,
                                              builder: (context, snapshot) {
                                                if (snapshot.hasData) {
                                                  return Text(
                                                    '${snapshot.data!['firstName']}',
                                                    style: GoogleFonts.poppins(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .inversePrimary,
                                                    ),
                                                  );
                                                }
                                                return const SizedBox.shrink();
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const SettingsPage(),
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Iconsax.setting_2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              WeekDaysSection(plan: plan),
                              UpcomingSection(
                                plan: plan,
                                hifdhIn: hifdhIn,
                                markHifdhAsComplete: markHifdhAsComplete,
                                markReviewAsComplete: markReviewAsComplete,
                                id: id,
                                reviews: reviews,
                              ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                      WirdSection(firestoreService: firestoreService),
                      const SizedBox(height: 8),
                    ],
                  ),
                );
              }

              // Plan exists but has no hifdhs yet — show completed home if they finished
              if (plan['planCompleted'] == true) {
                id = plansList[0].id;
                return _buildCompletedHifdhHome(context, userData);
              }
            }
          }
          return AlertDialog(
            content: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: Color.fromARGB(255, 73, 121, 251),
                ),
                SizedBox(height: 20),
                Text(
                  'Creating your plan',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompletedHifdhHome(
      BuildContext context, Future<Map<String, dynamic>?> userData) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 10, top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: userData,
                  builder: (context, snapshot) {
                    if (snapshot.hasData &&
                        snapshot.data!['firstName'] != null) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            '${snapshot.data!['firstName']}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ],
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.setting_2),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4979FB).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.tick_circle,
                          size: 56,
                          color: Color(0xFF4979FB),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'You\'ve completed the Quran',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Focus on revision and retention. Create quizzes, read the Quran, and keep your Hifdh strong.',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          WirdSection(firestoreService: firestoreService),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void markHifdhAsComplete(
      String key, BuildContext context, int lines, String id) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            content: isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text('Updating...'),
                    ],
                  )
                : const Text('Mark as completed?'),
            actions: isLoading
                ? [] // No actions while loading
                : [
                    MaterialButton(
                      onPressed: () async {
                        setState(() => isLoading = true); // Show loading

                        // Get plan data before creating hifdh to show stats
                        final planSnapshot = await firestoreService
                            .plansCollection
                            .doc(id)
                            .get();
                        final planData =
                            planSnapshot.data() as Map<String, dynamic>;
                        final currentStreak = planData['streak'] ?? 0;
                        final double totalLines =
                            (planData['totalLines'] as num?)?.toDouble() ?? 1;
                        final completedRaw =
                            (planData['completedLines'] as num?)?.toDouble();
                        final double completedLines = completedRaw != null
                            ? completedRaw.clamp(0.0, totalLines)
                            : 0;
                        final progress = totalLines > 0
                            ? (completedLines / totalLines).clamp(0.0, 1.0)
                            : 0.0;

                        // Parse key to get surah and verses
                        final keyParts = key.split(':');
                        String surah = '';
                        String verses = '';
                        if (keyParts.length >= 2) {
                          surah = keyParts[0];
                          final verseParts = keyParts[1].split('-');
                          if (verseParts.length >= 2) {
                            verses = '${verseParts[0]}-${verseParts[1]}';
                          }
                        }

                        await firestoreService.createNewHifdh(key, lines, id);
                        setState(() => isLoading = false); // Hide loading

                        // Close confirmation dialog
                        if (!context.mounted) return;
                        Navigator.pop(context);

                        // Show celebration
                        await CompletionFeedbackService
                            .showMemorizationCelebration(
                          context: context,
                          surah: surah,
                          verses: verses,
                          lines: lines,
                          streak: currentStreak + 1,
                          totalProgress: progress,
                        );
                      },
                      child: const Text('Yes'),
                    ),
                    MaterialButton(
                      onPressed: () =>
                          Navigator.pop(context), // Close the dialog
                      child: const Text('Cancel'),
                    ),
                  ],
          ),
        );
      },
    );
  }

  void markReviewAsComplete(
      BuildContext context, List<dynamic> reviews, String id) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuizPage(
          reviewTitle:
              '${reviews.first['surah'].split(' ')[0]}  ${reviews.first['review'].split('-')[0].split(':')[1]}-${reviews.first['surah'].split(' ')[0] == reviews.first['surah'].split(' ')[1] ? '' : reviews.first['surah'].split(' ')[1]} ${reviews.first['review'].split('-')[1].split(':')[1]}',
          versesList: reviews.first['versesList'],
          review: reviews.first['review'],
          id: id,
          updateReview: firestoreService.updateReview,
        ),
      ),
    );
  }
}
