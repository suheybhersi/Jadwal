import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/edit_daily_reading_form.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:shimmer/shimmer.dart';

class PlanPage extends StatelessWidget {
  final String id;
  final FirestoreService firestoreService = FirestoreService();

  PlanPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
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

            if (plan.isNotEmpty) {
              completed = plan['hifdhs'].last['completed'];
              Timestamp hifdhTimestamp = plan['hifdhs'].last['date'];
              DateTime hifdhDate = hifdhTimestamp.toDate();
              firestoreService.hifdhIn(id);
              hifdhIn = plan['hifdhIn'];
              verses = plan['hifdhs'].last['hifdh'];

              if (completed == false) {
                isLoading = false;
              }

              if (hifdhDate.day == DateTime.now().day && completed) {
                isLoading = true;
                firestoreService.updateNextHifdh(id);
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
                  _buildUpcomingReviews(context, plan, hifdhIn),
                  _buildDailyReading(context, plan, hifdhIn),
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
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
              IconButton(
                onPressed: () => editPlan(context, plan),
                icon: const Icon(Icons.edit),
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  padding: MaterialStateProperty.all(
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
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verses $verses',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        hifdhIn == 0
                            ? 'Today'
                            : hifdhIn == 1
                                ? 'Tomorrow'
                                : 'In $hifdhIn days',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {
                      if (!completed) {
                        markAsComplete(
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
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingReviews(
    BuildContext context,
    Map<String, dynamic> plan,
    int hifdhIn,
  ) {
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
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    plan['reviews'].isEmpty
                        ? 'No reviews'
                        : plan['reviews'].first['review'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    hifdhIn == 0
                        ? 'Today'
                        : hifdhIn == 1
                            ? 'Tomorrow'
                            : 'In $hifdhIn days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(
                    plan['reviews'].isEmpty
                        ? 'No reviews'
                        : plan['reviews'].first['review'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    hifdhIn == 0
                        ? 'Today'
                        : hifdhIn == 1
                            ? 'Tomorrow'
                            : 'In $hifdhIn days',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyReading(
      BuildContext context, Map<String, dynamic> plan, int hifdhIn) {
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
                  backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  padding: MaterialStateProperty.all(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verses ${plan['hifdhs'].last['hifdh']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        hifdhIn == 0
                            ? 'Today'
                            : hifdhIn == 1
                                ? 'Tomorrow'
                                : 'In $hifdhIn days',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
                        markAsComplete(
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
                  backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.secondary,
                  ),
                  padding: MaterialStateProperty.all(
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

  void markAsComplete(String key, BuildContext context, int lines) {
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
}
