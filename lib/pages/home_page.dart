import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

// ignore: must_be_immutable
class HomePage extends StatelessWidget {
  final FirestoreService firestoreService = FirestoreService();
  late int hifdhIn;
  late String verses;
  late Map<String, dynamic> plan;

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
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  const WeekDays(),
                  Upcoming(plan: plan, verses: verses, hifdhIn: hifdhIn),
                  Column(
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 170,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 25),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      width: 2),
                                  borderRadius: BorderRadius.circular(30)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Streak',
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                  Text(
                                    '8 days',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 25),
                              decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Colors.red.shade400, width: 2),
                                  borderRadius: BorderRadius.circular(30)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Missed',
                                    style: TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary),
                                  ),
                                  Text(
                                    '2 reviews',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 15, horizontal: 25),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .inversePrimary,
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
                  )
                ],
              ),
            );
          }
          return const SizedBox();
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                width: 3,
                color: Theme.of(context).colorScheme.secondary,
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
                    color: Colors.green,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'M',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.background,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
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
                    color: Colors.green,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  child: Text(
                    'W',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Colors.red.shade300,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
                  child: Text(
                    'T',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w500),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.background,
                    border: Border.all(
                      width: 3,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
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
        )
      ],
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
                    color: Theme.of(context).colorScheme.inversePrimary),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
                        const Icon(
                          Iconsax.note_text,
                          size: 50,
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['hifdhs'] == null || plan['hifdhs'].isEmpty
                                  ? 'No hifdh'
                                  : verses,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              hifdhIn == 0
                                  ? 'Today'
                                  : hifdhIn == 1
                                      ? 'Tomorrow'
                                      : 'In $hifdhIn days',
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            )
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
                        const Icon(
                          Icons.refresh,
                          size: 50,
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['reviews'] == null || plan['reviews'].isEmpty
                                  ? 'No review'
                                  : plan['reviews'].first['review'],
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.tertiary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
                        const Icon(
                          Iconsax.book,
                          size: 50,
                        ),
                        const SizedBox(
                          width: 30,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan['hifdhs'] == null || plan['hifdhs'].isEmpty
                                  ? 'No Daily Reading'
                                  : verses,
                              style: const TextStyle(
                                  fontSize: 24, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              hifdhIn == 0
                                  ? 'Today'
                                  : hifdhIn == 1
                                      ? 'Tomorrow'
                                      : 'In $hifdhIn days',
                              style: const TextStyle(
                                fontSize: 24,
                              ),
                            )
                          ],
                        )
                      ],
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
