import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/edit_daily_reading_form.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/components/review_tile.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';

class PlanPage extends StatelessWidget {
  final String id;
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  PlanPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    bool hifdhMissedCalled = false;
    bool currentWeekCalled = false;

    bool isLoading = false;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(5),
              child: Icon(
                Icons.person,
                color: Theme.of(context).colorScheme.primary,
                size: 30,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List plansList = snapshot.data!.docs;
            int documentIndex =
                plansList.indexWhere((element) => element.id == id);
            DocumentSnapshot document = plansList[documentIndex];
            Map<String, dynamic> plan = document.data() as Map<String, dynamic>;
            bool completed = false;
            int hifdhIn = 0;
            String verses = '';

            if (plan.isNotEmpty && plan['hifdhs'].isNotEmpty) {
              completed = plan['hifdhs'].last['completed'];
              firestoreService.hifdhIn(id);
              hifdhIn = plan['hifdhIn'];
              verses = plan['hifdhs'].last['hifdh'];

              if (completed == false) {
                isLoading = false;
              }

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

              if ((hifdhDate == today || todayDT.isAfter(hifdhDT)) &&
                  completed) {
                isLoading = true;
                if (plan['planCompleted'] != true) {
                  firestoreService.updateNextHifdh(id);
                } else {
                  isLoading = false;
                  return const Center(
                    child: Text(
                      'Plan Completed',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 30),
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

              String weekStart = plan['currentWeek'][0]['weekStart'];

              DateTime currWeekStartDT = DateTime.now().subtract(
                Duration(days: DateTime.now().weekday - 1),
              );

              String currWeekStart =
                  '${currWeekStartDT.day}-${currWeekStartDT.month}-${currWeekStartDT.year}';

              if ((currWeekStart.split('-')[0] != weekStart.split('-')[0] ||
                      currWeekStart.split('-')[1] != weekStart.split('-')[1] ||
                      currWeekStart.split('-')[2] != weekStart.split('-')[2]) &&
                  !currentWeekCalled) {
                currentWeekCalled = true;
                firestoreService.updateCurrentWeek(id).then((_) {
                  // Reset the flag after the method completes
                  currentWeekCalled = false;
                });
              }

              if (isLoading) {
                return Column(
                  children: [
                    _buildPlanDetails(context, plan),
                    _buildNextHifdhShimmer(context, completed, plan),
                    _buildUpcomingReviewsShimmer(context),
                    _buildDailyReadingShimmer(context, plan),
                  ],
                );
              }
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  _buildPlanDetails(context, plan),
                  _buildNextHifdh(context, plan, hifdhIn, completed, verses),
                  _buildUpcomingReviews(context, plan, hifdhIn, completed),
                  _buildDailyReading(context, plan, hifdhIn, completed, verses),
                ],
              ),
            );
          }
          return const SizedBox(); // Placeholder for when data is loading
        },
      ),
    );
  }

  Widget _buildPlanDetails(BuildContext context, Map<String, dynamic> plan) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'],
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              IconButton(
                onPressed: () => editPlan(context, plan),
                icon: const Icon(Icons.edit),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  ),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextHifdh(
    BuildContext context,
    Map<String, dynamic> plan,
    int hifdhIn,
    bool completed,
    String verses,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        padding:
            const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 86, 173, 254),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                bottom: 15,
              ),
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 128, 193, 255),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Next Hifdh',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                IconButton(
                  onPressed: () {
                    if (!completed) {
                      markHifdhAsComplete(
                        plan['hifdhs'].last['nextKey'],
                        context,
                        plan['lines'],
                      );
                    }
                  },
                  icon: completed
                      ? Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const ImageIcon(
                            AssetImage('assets/checked.png'),
                            color: Color.fromARGB(255, 60, 209, 107),
                            size: 35,
                          ),
                        )
                      : ImageIcon(
                          const AssetImage('assets/unchecked.png'),
                          size: 35,
                          color: Colors.grey.shade100,
                        ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingReviews(
    BuildContext context,
    Map<String, dynamic> plan,
    int hifdhIn,
    bool completed,
  ) {
    List<dynamic> reviews = plan['reviews']
        .where((review) =>
            review['date'] ==
            '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}')
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        width: 350,
        padding:
            const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 15),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 113, 100, 250),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: Container(
                width: 175,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 144, 135, 253),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Today's Reviews",
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
            reviews == [] || reviews.isEmpty
                ? Text(
                    'None',
                    style: TextStyle(
                        color: Colors.grey.shade100,
                        fontSize: 24,
                        fontWeight: FontWeight.w800),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: reviews.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> review = reviews[index];
                        return ReviewTile(review: review, id: id);
                      },
                    ),
                  )
          ],
        ),
      ),
    );
  }

  Widget _buildDailyReading(BuildContext context, Map<String, dynamic> plan,
      int hifdhIn, bool completed, String verses) {
    List<dynamic> dailyReadings = plan['dailyReadings']
        .where((dailyReading) =>
            dailyReading['date'] ==
            '${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}')
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Reading',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              IconButton(
                onPressed: () => editDailyReading(context, plan),
                icon: const Icon(Icons.edit),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.tertiary,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
          child: Container(
            padding:
                const EdgeInsets.only(top: 20, left: 15, right: 15, bottom: 15),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                dailyReadings == [] ||
                        dailyReadings.isEmpty ||
                        dailyReadings.last['completed'] == true
                    ? Text(
                        'None',
                        style: TextStyle(
                            color: Provider.of<ThemeProvider>(context)
                                    .isDarkMode
                                ? Colors.grey.shade100
                                : Theme.of(context).colorScheme.inversePrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pages ${dailyReadings.last['dailyReading']}',
                            style: TextStyle(
                              fontSize: 20,
                              color:
                                  Provider.of<ThemeProvider>(context).isDarkMode
                                      ? Colors.grey.shade100
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'Today',
                            style: TextStyle(
                              color:
                                  Provider.of<ThemeProvider>(context).isDarkMode
                                      ? Colors.grey.shade100
                                      : Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                dailyReadings == [] ||
                        dailyReadings.isEmpty ||
                        dailyReadings.last['completed'] == true
                    ? const SizedBox()
                    : IconButton(
                        onPressed: () {
                          markDailyReadingAsComplete(
                            plan['dailyReadings'].last['nextStart'],
                            context,
                          );
                        },
                        icon: ImageIcon(
                          const AssetImage('assets/unchecked.png'),
                          size: 35,
                          color: Colors.grey.shade100,
                        ),
                      )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildNextHifdhShimmer(
      BuildContext context, bool completed, Map<String, dynamic> plan) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 5.0,
        bottom: 10,
        left: 20,
        right: 20,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: Colors.blue,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Next Hifdh',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    period: const Duration(milliseconds: 5000),
                    baseColor: Colors.grey.shade500,
                    highlightColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 150,
                          height: 20,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 100,
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (!completed) {
                        markHifdhAsComplete(
                          plan['hifdhs'].last['nextKey'],
                          context,
                          plan['lines'],
                        );
                      }
                    },
                    icon: completed
                        ? const ImageIcon(
                            AssetImage('assets/checked.png'),
                            color: Colors.green,
                            size: 30,
                          )
                        : const ImageIcon(
                            AssetImage('assets/unchecked.png'),
                            size: 30,
                          ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingReviewsShimmer(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 5.0,
        bottom: 10,
        left: 20,
        right: 20,
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: Colors.green,
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upcoming Reviews',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  Shimmer.fromColors(
                    period: const Duration(milliseconds: 5000),
                    baseColor: Colors.grey.shade500,
                    highlightColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 150,
                          height: 20,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 100,
                          height: 20,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReadingShimmer(
      BuildContext context, Map<String, dynamic> plan) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20.0,
            vertical: 10,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily Reading',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              IconButton(
                onPressed: () => editDailyReading(context, plan),
                icon: const Icon(Icons.edit),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(
            top: 5.0,
            bottom: 10,
            left: 20,
            right: 20,
          ),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(
                  width: 2,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                borderRadius: BorderRadius.circular(25)),
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    period: const Duration(milliseconds: 5000),
                    baseColor: Colors.grey.shade500,
                    highlightColor: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 150,
                          height: 20,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.grey[300],
                          ),
                          width: 100,
                          height: 20,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void editPlan(BuildContext context, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => EditPlanForm(
        plan: plan,
        id: id,
      ),
    );
  }

  void editDailyReading(BuildContext context, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => EditDailyReadingForm(
        plan: plan,
        id: id,
      ),
    );
  }

  void markHifdhAsComplete(String key, BuildContext context, int lines) {
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

  void markDailyReadingAsComplete(int nextStart, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('Mark as completed?'),
        actions: [
          MaterialButton(
            onPressed: () {
              firestoreService.createNewDailyReading(id, nextStart);
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
}
