import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/HomePage/Week_days_section.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/pages/screens/HomePage/upcoming_section.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/completion_feedback_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

              if (plan['hifdhs'].isNotEmpty && plan['hifdhs'] != null) {
                id = plansList[0].id;
                String weekStart = plan['currentWeek'][0]['weekStart'];
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

                if (plan['currentWeek'] != null && !currentWeekCalled) {
                  DateTime todayDT = DateTime(
                    DateTime.now().year,
                    DateTime.now().month,
                    DateTime.now().day,
                    0,
                    0,
                  );

                  // Check each day of the week
                  bool needsUpdate = false;
                  List updatedWeek = List.from(plan['currentWeek']);

                  for (int i = 0; i < plan['currentWeek'].length; i++) {
                    dynamic day = plan['currentWeek'][i];
                    List<String> weekStartString =
                        plan['currentWeek'][0]['weekStart'].split('-');
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

                if ((hifdhDate == today || todayDT.isAfter(hifdhDT)) &&
                    completed) {
                  if (plan['planCompleted'] != true && !updateHifdhCalled) {
                    updateHifdhCalled = true;
                    firestoreService.updateNextHifdh(id).then((_) {
                      updateHifdhCalled = false;
                    });
                  } else if (plan['planCompleted'] == true) {
                    return Center(
                      child: Text(
                        'Plan Completed',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 30,
                        ),
                      ),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(255, 73, 121, 251),
                      ),
                    );
                  }
                } else if (todayDT.isAfter(hifdhDT) && !hifdhMissedCalled) {
                  hifdhMissedCalled = true;
                  firestoreService.hifdhMissed(id).then((_) {
                    hifdhMissedCalled = false;
                  });
                }

                // Call reviewMissed if there are reviews in the past not completed
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Consumer<UserPreferencesService>(
                                builder: (context, prefsService, child) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                          // Mode indicator badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: prefsService.usageMode == UsageMode.flexible
                                                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                                  : const Color(0xFF4979FB).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              UserPreferencesService.getModeName(prefsService.usageMode),
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: prefsService.usageMode == UsageMode.flexible
                                                    ? const Color(0xFF10B981)
                                                    : const Color(0xFF4979FB),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      FutureBuilder<Map<String, dynamic>?>(
                                        future: userData,
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Text(
                                              '${snapshot.data!['firstName']}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
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

                        // Today's Tasks Section
                        UpcomingSection(
                          plan: plan,
                          hifdhIn: hifdhIn,
                          markHifdhAsComplete: markHifdhAsComplete,
                          markReviewAsComplete: markReviewAsComplete,
                          id: id,
                          reviews: reviews,
                        ),

                        Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .tertiary
                                    .withValues(alpha: 0.3),
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: StreamBuilder<DocumentSnapshot>(
                            stream: firestoreService.getRandomVerseStream(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: CircularProgressIndicator(
                                      color: Color.fromARGB(255, 73, 121, 251),
                                    ),
                                  ),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data == null) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Text(
                                      'Verse not available',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final verseData = snapshot.data!.data()
                                  as Map<String, dynamic>?;
                              if (verseData == null) return SizedBox();

                              final verseText = verseData['text'] as String? ??
                                  'Verse not available';
                              final surah = verseData['surah'] as String? ?? '';
                              final key = verseData['key'] as String? ?? '';
                              final verseNumber = key.split(':').length > 1
                                  ? key.split(':')[1]
                                  : '';

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Iconsax.book_1,
                                              color: Color.fromARGB(
                                                  255, 73, 121, 251),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Verse of the Day',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 20, right: 20, bottom: 20),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          verseText,
                                          style: GoogleFonts.scheherazadeNew(
                                            letterSpacing: 0,
                                            fontSize: 24,
                                            height: 1.6,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary,
                                          ),
                                          textAlign: TextAlign.justify,
                                          textDirection: TextDirection.rtl,
                                        ),
                                        SizedBox(height: 12),
                                        Text(
                                          '$surah, Verse $verseNumber',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .inversePrimary
                                                .withValues(alpha: 0.7),
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
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
                        final planSnapshot = await firestoreService.plansCollection.doc(id).get();
                        final planData = planSnapshot.data() as Map<String, dynamic>;
                        final currentStreak = planData['streak'] ?? 0;
                        final totalLines = planData['totalLines'] ?? 1;
                        final completedLines = planData['completedLines'] ?? 0;
                        final progress = completedLines / totalLines;
                        
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
                        await CompletionFeedbackService.showMemorizationCelebration(
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
