import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  HomePage({super.key});

  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);
  int hifdhIn = -1;

  Map<String, dynamic> plan = {};

  void signUserOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    bool hifdhMissedCalled = false;
    bool currentWeekCalled = false;
    bool updateHifdhCalled = false;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Welcome Suheyb,',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                      onPressed: signUserOut,
                      icon: Icon(
                        Icons.logout,
                        color: Theme.of(context).colorScheme.primary,
                      )),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List plansList = snapshot.data!.docs;
            DocumentSnapshot? activePlan;

            // Find the active plan
            for (var plan in plansList) {
              if (plan.data()?['active'] == true) {
                activePlan = plan;
                break;
              }
            }

            if (activePlan != null) {
              // Extract data from the active plan
              plan = activePlan.data() as Map<String, dynamic>;

              if (plan['hifdhs'].isNotEmpty && plan['hifdhs'] != null) {
                String id = activePlan
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
                      WeekDays(plan: plan),
                      Upcoming(
                        plan: plan,
                        hifdhIn: hifdhIn,
                      ),
                      SizedBox(
                        height: 20,
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
}

class WeekDays extends StatelessWidget {
  const WeekDays({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: weekStart.add(Duration(days: index)) == todayDT
                        ? Border.all(
                            width: 2,
                            color: Theme.of(context).colorScheme.tertiary,
                          )
                        : const Border(),
                    color: day['completed'] &&
                            plan['hifdhDays'][index] ==
                                true //hifdh day marked as complete and is in plan
                        ? const Color.fromARGB(255, 60, 209, 107)
                        : day['missed'] //hifdh has been missed(not completed)
                            ? Colors.red.shade300
                            : Theme.of(context)
                                .colorScheme
                                .primary, //hifdh day not part of plan || hifdh day has not been reached
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal:
                          day['day'] == 'M' || day['day'] == 'W' ? 12 : 15,
                      vertical: 7),
                  child: Text(
                    day['day'],
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: plan['hifdhDays'][index] == true &&
                              (day['completed'] || day['missed'])
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ));
            })),
      ),
    );
  }
}

class Upcoming extends StatelessWidget {
  const Upcoming({
    super.key,
    required this.plan,
    required this.hifdhIn,
  });

  final Map<String, dynamic> plan;
  final int hifdhIn;

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
                  image: DecorationImage(
                    image: AssetImage(
                      plan['hifdhs'] == null ||
                              plan['hifdhs'].isEmpty ||
                              hifdhIn == -1
                          ? ''
                          : 'assets/newbg.png',
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
                                'Surah ${plan['hifdhs'].last['surah']}',
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
                                  plan['hifdhs'].last['length'] >= 0.7
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
                                        color: Color.fromARGB(255, 90, 92, 191),
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
                      ? DecorationImage(image: AssetImage(''))
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
                                'Surah ${reviews.first['surah']}',
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
                                  reviews.first['length'] >= 0.7
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
                      ? DecorationImage(image: AssetImage(''))
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
                                'Surah ${reviews.first['surah']}',
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
                                  reviews.first['length'] >= 0.7
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
                        '${(((plan['completedLines'] / plan['totalLines']) * 100)).toStringAsFixed(0)}% Progress',
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
                  percent: ((plan['completedLines'] / plan['totalLines'])),
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
