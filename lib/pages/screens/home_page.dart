import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:jadwal/pages/screens/quiz_page.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  HomePage({super.key});

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

                        WeekDays(plan: plan),

                        // Today's Tasks Section
                        Upcoming(
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

class WeekDays extends StatelessWidget {
  const WeekDays({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final currentWeekday = today.weekday - 1; // 0-based index (0 = Monday)

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar_1,
                  color: Color.fromARGB(255, 73, 121, 251),
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'This Week',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              children: [
                // Progress bar showing week progress
                Row(
                  children: [
                    Expanded(
                      child: LinearPercentIndicator(
                        padding: EdgeInsets.zero,
                        lineHeight: 6,
                        percent: (currentWeekday + 1) / 7,
                        progressColor: Color.fromARGB(255, 73, 121, 251),
                        backgroundColor: Colors.grey.shade100,
                        barRadius: const Radius.circular(3),
                        animation: true,
                        animationDuration: 1000,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Day ${currentWeekday + 1}/7',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Days of the week with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    dynamic day = plan['currentWeek'][index];
                    List<String> weekStartString = day['weekStart'].split('-');
                    List<String> today =
                        '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}'
                            .split('-');
                    DateTime weekStart = DateTime(
                      int.parse(weekStartString[2]),
                      int.parse(weekStartString[1]),
                      int.parse(weekStartString[0]),
                      0,
                      0,
                    );

                    DateTime todayDT = DateTime(
                      int.parse(today[2]),
                      int.parse(today[1]),
                      int.parse(today[0]),
                      0,
                      0,
                    );

                    bool isToday =
                        weekStart.add(Duration(days: index)) == todayDT;
                    bool isPast =
                        weekStart.add(Duration(days: index)).isBefore(todayDT);
                    bool hasHifdh = plan['hifdhDays'][index] == true;
                    bool isCompleted = day['completed'] && (isToday || isPast);
                    bool isMissed = day['missed'] && (isToday || isPast);

                    // Determine status color
                    Color statusColor = Colors.transparent;
                    if (hasHifdh) {
                      if (isCompleted) {
                        statusColor = Color.fromARGB(255, 113, 233, 175);
                      } else if (isMissed) {
                        statusColor = Colors.red.shade300;
                      } else if (isToday) {
                        statusColor = Color.fromARGB(255, 73, 121, 251);
                      } else if (!isPast) {
                        statusColor = Color.fromARGB(255, 254, 189, 89);
                      }
                    }

                    return Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isToday
                                ? Color.fromARGB(255, 73, 121, 251)
                                : Colors.grey.shade50,
                            shape: BoxShape.circle,
                            boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: Color.fromARGB(255, 73, 121, 251)
                                          .withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              '${weekStart.add(Duration(days: index)).day}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isToday ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          day['day'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight:
                                isToday ? FontWeight.w600 : FontWeight.w500,
                            color: isToday
                                ? Color.fromARGB(255, 73, 121, 251)
                                : Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        // Status indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Upcoming extends StatelessWidget {
  const Upcoming({
    super.key,
    required this.plan,
    required this.hifdhIn,
    required this.id,
    required this.markHifdhAsComplete,
    required this.markReviewAsComplete,
    required this.reviews,
  });

  final Map<String, dynamic> plan;
  final int hifdhIn;
  final String id;
  final Function(String, BuildContext, int, String) markHifdhAsComplete;
  final Function(BuildContext, List<dynamic>, String) markReviewAsComplete;
  final List<dynamic> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.task_square,
                      color: Color.fromARGB(255, 73, 121, 251),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Today\'s Tasks',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      color: Color.fromARGB(255, 73, 121, 251),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 73, 121, 251),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // New Memorisation Card
              GestureDetector(
                onTap: () {
                  if (!plan['hifdhs'].last['completed']) {
                    newDraggableBottomSheet(context, plan['hifdhs'].last);
                  }
                },
                child: Container(
                  padding: EdgeInsets.all(20),
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
                        color:
                            Color.fromARGB(255, 73, 121, 251).withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: plan['hifdhs'] == null ||
                          plan['hifdhs'].isEmpty ||
                          hifdhIn == -1
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No memorisation tasks',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.book_1,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.book_1,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'New Memorisation',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    plan['hifdhs'].last['completed']
                                        ? 'Completed'
                                        : 'Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            // Add a future date indicator if the hifdh is completed and for a future date
                            plan['hifdhs'].last['completed']
                                ? Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 254, 189, 89)
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Color.fromARGB(255, 254, 189, 89),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Iconsax.calendar_1,
                                          color:
                                              Color.fromARGB(255, 254, 189, 89),
                                          size: 16,
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Upcoming task for ${_getNextHifdhDate(plan['hifdhDays'], plan['currentWeek'][0]['weekStart'])}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(),
                            SizedBox(
                                height:
                                    plan['hifdhs'].last['completed'] ? 16 : 0),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${plan['hifdhs'].last['surah'].split(' ')[0]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Verse ${plan['hifdhs'].last['hifdh'].split('-')[0].split(':')[1]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        plan['hifdhs'].last['length'] >= 0.6 &&
                                                plan['hifdhs']
                                                        .last['surah']
                                                        .split(' ')[0] !=
                                                    'Al-Fatiha'
                                            ? '...${plan['hifdhs'].last['startVerse'].substring(0, plan['hifdhs'].last['startVerse'].substring(0, 35).lastIndexOf(' '))}'
                                            : plan['hifdhs'].last['startVerse'],
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 22,
                                          height: 1.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    plan['hifdhs'].last['completed']
                                        ? Iconsax.calendar_1
                                        : Iconsax.arrow_right_3,
                                    color: Color.fromARGB(255, 73, 121, 251),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    plan['hifdhs'].last['completed']
                                        ? 'Next - ${_getNextHifdhDate(plan['hifdhDays'], plan['currentWeek'][0]['weekStart'])}'
                                        : 'Start Memorising',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 73, 121, 251),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Review Card
              reviews.isEmpty
                  ? SizedBox()
                  : Column(
                      children: [
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            markReviewAsComplete(context, reviews, id);
                          },
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color.fromARGB(255, 100, 163, 119),
                                  Color.fromARGB(255, 129, 186, 145),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 100, 163, 119)
                                      .withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Iconsax.refresh,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Review',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Quiz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${reviews.first['surah'].split(' ')[0]}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Verse ${reviews.first['review'].split('-')[0].split(':')[1]}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            reviews.first['length'] >= 0.6 &&
                                                    reviews.first['surah']
                                                            .split(' ')[0] !=
                                                        'Al-Fatiha'
                                                ? '...${reviews.first['startVerse'].substring(0, reviews.first['startVerse'].substring(0, 40).lastIndexOf(' '))}'
                                                : reviews.first['startVerse'],
                                            style: GoogleFonts.scheherazadeNew(
                                              fontSize: 22,
                                              height: 1.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.play,
                                        color:
                                            Color.fromARGB(255, 100, 163, 119),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Quiz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromARGB(
                                              255, 100, 163, 119),
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
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  void newDraggableBottomSheet(
      BuildContext context, Map<String, dynamic> hifdh) {
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
            initialChildSize: 0.7,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'New Memorisation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              // First verse section
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(255, 73, 121, 251),
                                      Color.fromARGB(255, 114, 152, 255),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromARGB(255, 73, 121, 251)
                                          .withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Iconsax.book_1,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Surah ${hifdh['surah'].split(' ')[0]}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Verse ${hifdh['hifdh'].split('-')[0].split(':')[1]}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          '${hifdh['startVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[0].split(':')[1]).replaceAll(' ', '')}﴾',
                                          style: GoogleFonts.scheherazadeNew(
                                            fontSize: 22,
                                            height: 1.8,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 24),
                              // Connection indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Color.fromARGB(255, 73, 121, 251),
                                      size: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.grey.shade200,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              // Second verse section
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color.fromARGB(255, 114, 152, 255),
                                      Color.fromARGB(255, 73, 121, 251),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color.fromARGB(255, 73, 121, 251)
                                          .withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Iconsax.book_1,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Surah ${hifdh['surah'].split(' ')[1]}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                            Text(
                                              'Verse ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: Text(
                                          '${hifdh['endVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[1].split(':')[1]).replaceAll(' ', '')}﴾',
                                          style: GoogleFonts.scheherazadeNew(
                                            fontSize: 22,
                                            height: 1.8,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40),
                              // Complete button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!hifdh['completed']) {
                                      markHifdhAsComplete(
                                        hifdh['nextKey'],
                                        context,
                                        plan['lines'],
                                        id,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Ink(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 73, 121, 251),
                                          Color.fromARGB(255, 114, 152, 255),
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      alignment: Alignment.center,
                                      child: Text(
                                        'Mark as Complete',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _convertToArabicNumbers(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  String _getNextHifdhDate(List<dynamic> hifdhDays, String weekStart) {
    // Parse the week start date
    List<String> dateParts = weekStart.split('-');
    DateTime weekStartDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    // Get today's date
    DateTime today = DateTime.now();

    // Find the next incomplete hifdh day
    for (int i = today.weekday - 1; i < 7; i++) {
      if (hifdhDays[i]) {
        DateTime nextDate = weekStartDate.add(Duration(days: i));
        if (nextDate.isAfter(today) && !plan['currentWeek'][i]['completed']) {
          return '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}';
        }
      }
    }

    // If no incomplete hifdh day found in current week, check next week
    bool foundFirst = false;
    for (int i = 0; i < today.weekday - 1; i++) {
      if (hifdhDays[i]) {
        DateTime nextDate = weekStartDate.add(Duration(days: i + 7));
        List<String> dateParts = plan['hifdhs'].last['date'].split('-');
        DateTime weekStartDateDT = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        if (!foundFirst &&
            (weekStartDateDT.isAfter(nextDate) ||
                weekStartDateDT == nextDate)) {
          foundFirst = true;
          continue;
        }

        return '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}';
      }
    }

    return '--/--'; // Fallback if no next date found
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
