import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shimmer/shimmer.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  int hifdhIn = -1;
  String verses = '';
  Map<String, dynamic> plan = {};

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 15),
                child: Text(
                  'Welcome Suheyb,',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        ),
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        backgroundColor: Colors.transparent,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: StreamBuilder(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const YourContentPlaceholder();
          }
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
              bool completed = plan['hifdhs'].last['completed'];
              Timestamp hifdhTimestamp = plan['hifdhs'].last['date'];
              DateTime hifdhDate = hifdhTimestamp.toDate();
              String id = activePlan
                  .id; // Assuming you need the ID for further operations
              firestoreService.hifdhIn(id);
              hifdhIn = plan['hifdhIn'];
              verses = plan['hifdhs'].last['hifdh'];

              if (hifdhDate.day == DateTime.now().day && completed) {
                firestoreService.updateNextHifdh(id);
              }
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const WeekDays(),
                    Upcoming(plan: plan, verses: verses, hifdhIn: hifdhIn),
                    Statistics(plan: plan)
                  ],
                ),
              );
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
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 3,
            color: Theme.of(context).colorScheme.tertiary,
          ),
          borderRadius: BorderRadius.circular(40),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 153, 250, 131),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: const Text(
                'M',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.background,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Text(
                'T',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 153, 250, 131),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              child: const Text(
                'W',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: const Color.fromARGB(255, 255, 162, 162),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: const Text(
                'T',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.background,
                border: Border.all(
                  width: 3,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: Text(
                'F',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.background,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Text(
                'S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.background,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              child: Text(
                'S',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.inversePrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Upcoming extends StatelessWidget {
  const Upcoming({
    super.key,
    required this.plan,
    required this.verses,
    required this.hifdhIn,
  });

  final Map<String, dynamic> plan;
  final String verses;
  final int hifdhIn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                'Upcoming',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 30,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 165,
                    height: 140,
                    child: Container(
                      padding:
                          const EdgeInsets.only(top: 25, left: 15, right: 15),
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 86, 173, 254),
                          borderRadius: BorderRadius.circular(30)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15,
                            ),
                            child: Container(
                              width: 85,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromARGB(255, 128, 193, 255),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Iconsax.note_text,
                                    color: Colors.grey.shade100,
                                    size: 20,
                                  ),
                                  Text(
                                    'New',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          plan['hifdhs'] == null ||
                                  plan['hifdhs'].isEmpty ||
                                  hifdhIn == -1
                              ? Text(
                                  'None',
                                  style: TextStyle(
                                      color: Colors.grey.shade100,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      verses,
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey.shade100,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      hifdhIn == 0
                                          ? 'Today'
                                          : hifdhIn == 1
                                              ? 'Tomorrow'
                                              : 'In $hifdhIn days',
                                      style: TextStyle(
                                        color: Colors.grey.shade100,
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 165,
                    height: 140,
                    child: Container(
                      padding:
                          const EdgeInsets.only(top: 25, left: 15, right: 15),
                      decoration: BoxDecoration(
                          color: Color.fromARGB(255, 60, 209, 107),
                          borderRadius: BorderRadius.circular(30)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: 15,
                            ),
                            child: Container(
                              width: 105,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Color.fromARGB(255, 124, 228, 157),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    color: Colors.grey.shade100,
                                    size: 20,
                                  ),
                                  Text(
                                    'Review',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          plan['reviews'] == null || plan['reviews'].isEmpty
                              ? Text(
                                  'None',
                                  style: TextStyle(
                                      color: Colors.grey.shade100,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['reviews'].first['review'],
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.grey.shade100,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      hifdhIn == 0
                                          ? 'Today'
                                          : hifdhIn == 1
                                              ? 'Tomorrow'
                                              : 'In $hifdhIn days',
                                      style: TextStyle(
                                        color: Colors.grey.shade100,
                                        fontSize: 20,
                                      ),
                                    )
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 164, 110, 245),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            bottom: 15,
                          ),
                          child: Container(
                            width: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: Color.fromARGB(255, 187, 144, 251),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Icon(
                                  Iconsax.book,
                                  color: Colors.grey.shade100,
                                  size: 20,
                                ),
                                Text(
                                  'Daily Reading',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade100,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        plan['reviews'] == null || plan['reviews'].isEmpty
                            ? Text(
                                'None',
                                style: TextStyle(
                                    color: Colors.grey.shade100,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    plan['reviews'].first['review'],
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.grey.shade100,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    hifdhIn == 0
                                        ? 'Today'
                                        : hifdhIn == 1
                                            ? 'Tomorrow'
                                            : 'In $hifdhIn days',
                                    style: TextStyle(
                                      color: Colors.grey.shade100,
                                      fontSize: 20,
                                    ),
                                  )
                                ],
                              ),
                      ],
                    ),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                'Statistics',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 170,
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Theme.of(context).colorScheme.tertiary,
                        width: 2),
                    borderRadius: BorderRadius.circular(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    Text(
                      '${plan['streak']} days',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.red.shade400, width: 2),
                    borderRadius: BorderRadius.circular(30)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    Text(
                      '${plan['missedReviews']} reviews',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
            decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.tertiary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(30)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: LinearPercentIndicator(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 0,
                    ),
                    lineHeight: 40,
                    percent: 0.4,
                    progressColor: Colors.blue,
                    backgroundColor: Colors.blue.shade100,
                    barRadius: const Radius.circular(20),
                    trailing: const Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: Text(
                        '30%',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class YourContentPlaceholder extends StatelessWidget {
  const YourContentPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Placeholder for WeekDays
          Shimmer.fromColors(
            period: const Duration(milliseconds: 1500),
            baseColor: Colors.grey.shade500,
            highlightColor: Colors.grey.shade200,
            child: const WeekDaysPlaceholder(),
          ),
          // Placeholder for Upcoming
          const UpcomingPlaceholder(),
          // Placeholder for Statistics
          const StatisticsPlaceholder(),
        ],
      ),
    );
  }
}

class WeekDaysPlaceholder extends StatelessWidget {
  const WeekDaysPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
      child: Container(
        width: double.infinity,
        height: 60, // Adjust height as needed
        decoration: BoxDecoration(
          color: Colors.grey[300], // Placeholder color
          borderRadius: BorderRadius.circular(40),
        ),
      ),
    );
  }
}

class UpcomingPlaceholder extends StatelessWidget {
  const UpcomingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0),
              child: Text(
                'Upcoming',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 30,
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 200,
                                height: 20,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 150,
                                height: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 200,
                                height: 20,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 150,
                                height: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 45,
                            height: 45,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 200,
                                height: 20,
                              ),
                              const SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.grey[300],
                                ),
                                width: 150,
                                height: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatisticsPlaceholder extends StatelessWidget {
  const StatisticsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  'Statistics',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 30,
                      color: Theme.of(context).colorScheme.inversePrimary),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Streak',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[300],
                        ),
                        width: 90,
                        height: 30,
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.tertiary, width: 2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Missed',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.tertiary),
                    ),
                    const SizedBox(height: 10),
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          color: Colors.grey[300],
                        ),
                        width: 110,
                        height: 30,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
            decoration: BoxDecoration(
              border: Border.all(
                  color: Theme.of(context).colorScheme.tertiary, width: 2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Goals',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Container(
                        width: 230,
                        height: 40, // Adjust height as needed
                        decoration: BoxDecoration(
                          color: Colors.grey[300], // Placeholder color
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Shimmer.fromColors(
                      period: const Duration(milliseconds: 1500),
                      baseColor: Colors.grey.shade500,
                      highlightColor: Colors.grey.shade200,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey[300],
                        ),
                        width: 40,
                        height: 40,
                        // Placeholder color
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '%',
                      style: TextStyle(fontSize: 20),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
