import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  HomePage({super.key}) {
    // Hide status bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);
  int hifdhIn = -1;
  final TextEditingController ratingController = TextEditingController();

  Map<String, dynamic> plan = {};

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    bool hifdhMissedCalled = false;
    bool currentWeekCalled = false;
    bool updateHifdhCalled = false;
    String id = '';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List plansList = snapshot.data!.docs;
            if (plansList.isNotEmpty) {
              Map<String, dynamic> plan =
                  plansList[0].data() as Map<String, dynamic>;

              if (plan['hifdhs'].isNotEmpty && plan['hifdhs'] != null) {
                id = plansList[0]
                    .id; // Assuming you need the ID for further operations

                String weekStart = plan['currentWeek'][0]['weekStart'];

                DateTime currWeekStartDT = DateTime.now().subtract(
                  Duration(days: DateTime.now().weekday - 1),
                );

                String currWeekStart =
                    '${currWeekStartDT.day}-${currWeekStartDT.month}-${currWeekStartDT.year}';

                if (currWeekStart != weekStart && !currentWeekCalled) {
                  currentWeekCalled = true;
                  firestoreService.updateCurrentWeek(id).then((_) {
                    // Reset the flag after the method completes
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
                  int.parse(today[0]),
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
                      // Reset the flag after the method completes
                      updateHifdhCalled = false;
                    });
                  } else {
                    return const Center(
                      child: Text(
                        'Plan Completed',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 30),
                      ),
                    );
                  }
                } else if (todayDT.isAfter(hifdhDT) && !hifdhMissedCalled) {
                  hifdhMissedCalled = true;
                  firestoreService.hifdhMissed(id).then((_) {
                    // Reset the flag after the method completes
                    hifdhMissedCalled = false;
                  });
                }

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20, right: 10, top: 20.0, bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello',
                                  style: GoogleFonts.poppins(
                                    color: Color.fromARGB(255, 106, 106, 106),
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  'Mohammed',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: signUserOut,
                              icon: Icon(
                                Iconsax.setting_2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          WeekDays(plan: plan),
                          SizedBox(
                            height: 10,
                          ),
                          Upcoming(
                            plan: plan,
                            hifdhIn: hifdhIn,
                            markHifdhAsComplete: markHifdhAsComplete,
                            markReviewAsComplete: markReviewAsComplete,
                            id: id,
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Statistics(plan: plan)
                    ],
                  ),
                );
              }
            }
          }
          return Center(
              child: Text(
            'No plans...',
            style: TextStyle(
                color: Theme.of(context).colorScheme.inversePrimary,
                fontSize: 24),
          ));
        },
      ),
    );
  }

  void markHifdhAsComplete(
      String key, BuildContext context, int lines, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Mark as completed?'),
        actions: [
          MaterialButton(
            onPressed: () {
              firestoreService.createNewHifdh(key, lines, id);
              Navigator.pop(context);
            },
            child: const Text('Yes'),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void markReviewAsComplete(BuildContext context, String review, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: TextFormField(
            controller: ratingController,
            decoration: const InputDecoration(
                hintText: 'Rating', border: OutlineInputBorder()),
          ),
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              firestoreService.updateReview(id, review, ratingController.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
          MaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
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
    final ScrollController scrollController = ScrollController();

    // Only scroll to end if it's Thursday-Sunday
    WidgetsBinding.instance.addPostFrameCallback((_) {
      int currentDay = DateTime.now().weekday;
      if (currentDay >= 4) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });

    return SingleChildScrollView(
      controller: scrollController, // Add the controller here
      scrollDirection: Axis.horizontal,

      child: Container(
        width: 575,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
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

            return Container(
              width: 65,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: weekStart.add(Duration(days: index)) == todayDT
                    ? const Border()
                    : Border.all(
                        width: 1,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                color: weekStart.add(Duration(days: index)) == todayDT
                    ? Color.fromARGB(255, 73, 121, 251)
                    : Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day['day'],
                    style: TextStyle(
                        fontSize: 16,
                        color: weekStart.add(Duration(days: index)) == todayDT
                            ? Colors.white
                            : Color.fromARGB(255, 106, 106, 106)),
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    '${weekStart.add(Duration(days: index)).day}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: weekStart.add(Duration(days: index)) == todayDT
                          ? Colors.white
                          : Color.fromARGB(255, 26, 26, 26),
                    ),
                  ),
                  SizedBox(
                    height: 2,
                  ),
                  if (plan['hifdhDays'][index] == true)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: day['completed'] &&
                                  (weekStart.add(Duration(days: index)) ==
                                          todayDT ||
                                      weekStart
                                          .add(Duration(days: index))
                                          .isBefore(todayDT))
                              ? const Color.fromARGB(255, 60, 209, 107)
                              : day['missed'] &&
                                      (weekStart.add(Duration(days: index)) ==
                                              todayDT ||
                                          weekStart
                                              .add(Duration(days: index))
                                              .isBefore(
                                                  todayDT)) //hifdh has been missed(not completed)
                                  ? Colors.red.shade300
                                  : Color.fromARGB(255, 254, 189, 89)),
                    )
                ],
              ),
            );
          }),
        ),
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
  });

  final Map<String, dynamic> plan;
  final int hifdhIn;
  final String id;
  final Function(String, BuildContext, int, String) markHifdhAsComplete;

  final Function(BuildContext, String, String) markReviewAsComplete;

  @override
  Widget build(BuildContext context) {
    List<dynamic> reviews = plan['reviews']
        .where((review) =>
            review['date'] ==
            '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}')
        .toList();

    // List<dynamic> dailyReadings = plan['dailyReadings']
    //     .where((dailyReading) =>
    //         dailyReading['date'] ==
    //         '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}')
    //     .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(
                  top: 15,
                  left: 15,
                  right: 15,
                  bottom: plan['hifdhs'] == null ||
                          plan['hifdhs'].isEmpty ||
                          hifdhIn == -1
                      ? 15
                      : 0,
                ),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 104, 107, 255),
                  borderRadius: BorderRadius.circular(30),
                  image: plan['hifdhs'] == null ||
                          plan['hifdhs'].isEmpty ||
                          hifdhIn == -1
                      ? null
                      : DecorationImage(
                          image: AssetImage(
                            'assets/newbg.png',
                          ),
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          // Adjust this to control how the image fits
                        ),
                ),
                child: plan['hifdhs'] == null ||
                        plan['hifdhs'].isEmpty ||
                        hifdhIn == -1
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'None',
                            style: TextStyle(
                                color: Colors.grey.shade100,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color.fromARGB(255, 134, 137, 255),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'New',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Surah ${plan['hifdhs'].last['surah'].split(' ')[0]}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                width: 60,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color:
                                      const Color.fromARGB(255, 134, 137, 255),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      'New',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Verse ${plan['hifdhs'].last['hifdh'].split('-')[0].split(':')[1]}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade100,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15,
                                  right: 1,
                                ),
                                child: Text(
                                  plan['hifdhs'].last['length'] >= 0.6
                                      ? '...${plan['hifdhs'].last['verse'].substring(0, plan['hifdhs'].last['verse'].substring(0, 40).lastIndexOf(' '))}'
                                      : plan['hifdhs'].last['verse'],
                                  style: GoogleFonts.scheherazadeNew(
                                    textStyle: TextStyle(
                                      fontSize: 24,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    if (!plan['hifdhs'].last['completed']) {
                                      markHifdhAsComplete(
                                        plan['hifdhs'].last['nextKey'],
                                        context,
                                        plan['lines'],
                                        id,
                                      );
                                    }
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Text(
                                      plan['hifdhs'].last['completed']
                                          ? 'Next - ${_getNextHifdhDate(plan['hifdhDays'], plan['currentWeek'][0]['weekStart'])}'
                                          : 'Complete',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 134, 137, 255),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: EdgeInsets.only(
                    top: 15,
                    left: 15,
                    right: 15,
                    bottom: reviews == [] || reviews.isEmpty ? 15 : 0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 98, 99, 150),
                  borderRadius: BorderRadius.circular(30),
                  image: reviews == [] || reviews.isEmpty
                      ? null
                      : DecorationImage(
                          image: AssetImage(
                              'assets/reviewbg.png'), // Replace with the correct path to your PNG file
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,
                          // Adjust this to control how the image fits
                        ),
                ),
                child: reviews == [] || reviews.isEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'None',
                            style: TextStyle(
                                color: Colors.grey.shade100,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          Container(
                            width: 80,
                            height: 20,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromARGB(255, 129, 130, 171)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Surah ${reviews.first['surah'].split(' ')[0]}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                width: 80,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Color.fromARGB(255, 129, 130, 171),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      'Review',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Verse ${reviews.first['review'].split('-')[0].split(':')[1]}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade100,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15,
                                  right: 1,
                                ),
                                child: Text(
                                  reviews.first['length'] >= 0.6
                                      ? '...${reviews.first['verse'].substring(0, reviews.first['verse'].substring(0, 40).lastIndexOf(' '))}'
                                      : reviews.first['verse'],
                                  style: GoogleFonts.scheherazadeNew(
                                    textStyle: TextStyle(
                                      fontSize: 24,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    markReviewAsComplete(
                                        context, reviews.first['review'], id);
                                  },
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Text(
                                      'Complete',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 98, 99, 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding: EdgeInsets.only(
                    top: 15,
                    left: 15,
                    right: 15,
                    bottom: reviews == [] || reviews.isEmpty ? 15 : 0),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 126, 169, 134),
                  borderRadius: BorderRadius.circular(30),
                  image: reviews == [] || reviews.isEmpty
                      ? null
                      : DecorationImage(
                          image: AssetImage(
                            'assets/dailybg.png',
                          ), // Replace with the correct path to your PNG file
                          fit: BoxFit.contain,
                          alignment: Alignment.bottomCenter,

                          // Adjust this to control how the image fits
                        ),
                ),
                child: reviews == [] || reviews.isEmpty
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'None',
                            style: TextStyle(
                                color: Colors.grey.shade100,
                                fontSize: 20,
                                fontWeight: FontWeight.w800),
                          ),
                          Container(
                            width: 80,
                            height: 20,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color.fromARGB(255, 173, 200, 177),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Surah ${reviews.first['surah'].split(' ')[0]}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                width: 110,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Color.fromARGB(255, 173, 200, 177),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      'Daily Reading',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontFamily: 'Poppins',
                                        color: Colors.white,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Verse ${reviews.first['review'].split('-')[0].split(':')[1]}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade100,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 15,
                                  right: 1,
                                ),
                                child: Text(
                                  reviews.first['length'] >= 0.6
                                      ? '...${reviews.first['verse'].substring(0, reviews.first['verse'].substring(0, 40).lastIndexOf(' '))}'
                                      : reviews.first['verse'],
                                  style: GoogleFonts.scheherazadeNew(
                                    textStyle: TextStyle(
                                      fontSize: 24,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  style: TextButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 4),
                                    child: Text(
                                      'Complete',
                                      style: TextStyle(
                                        color: const Color.fromARGB(
                                            255, 98, 99, 150),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
              ),
            ],
          ),
        )
      ],
    );
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
}

class Statistics extends StatelessWidget {
  const Statistics({
    super.key,
    required this.plan,
  });
  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Memorisation Progress',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 82, 95, 127)),
                      ),
                      Text(
                        '${((((plan['completedLines'] / plan['totalLines']) > 1 ? 1 : plan['completedLines'] / plan['totalLines']) * 100)).toStringAsFixed(0)}% Progress',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color.fromARGB(255, 152, 163, 199)),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Color.fromARGB(255, 251, 241, 227),
                        borderRadius: BorderRadius.circular(30)),
                    padding: EdgeInsets.all(12),
                    // height: 30,
                    // width: 30,
                    child: Image(
                      image: AssetImage(
                        'assets/trophy.png',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 25, bottom: 10),
                child: LinearPercentIndicator(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                  ),
                  lineHeight: 10,
                  percent: ((plan['completedLines'] / plan['totalLines']) > 1
                      ? 1
                      : (plan['completedLines'] / plan['totalLines'])),
                  progressColor: Color.fromARGB(255, 113, 233, 175),
                  backgroundColor: Color.fromARGB(255, 238, 240, 247),
                  barRadius: const Radius.circular(20),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
