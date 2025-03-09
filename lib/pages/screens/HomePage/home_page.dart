import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/HomePage/Week_days_section.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_page.dart';
import 'package:jadwal/pages/screens/HomePage/upcoming_section.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:iconsax/iconsax.dart';

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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome back',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
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
                                            color: Colors.black,
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
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
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade100,
                                blurRadius: 12,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    Icon(
                                      Iconsax.quote_up,
                                      color: Color.fromARGB(255, 73, 121, 251),
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Quote of the Day',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 20, right: 20, bottom: 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '"The best among you are those who learn the Quran and teach it."',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade800,
                                        height: 1.5,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      '- Prophet Muhammad (PBUH)',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade600,
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
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
                        await firestoreService.createNewHifdh(key, lines, id);
                        setState(() => isLoading = false); // Hide loading

                        // Close both dialogs

                        Navigator.pop(context);
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
