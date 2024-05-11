import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/pages/plan_page.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:popover/popover.dart';

// ignore: must_be_immutable
class PlanTile extends StatelessWidget {
  Map<String, dynamic> plan;
  String id;
  int hifdhIn;
  String verses;
  PlanTile(
      {super.key,
      required this.plan,
      required this.id,
      required this.hifdhIn,
      required this.verses});
  final FirestoreService firestoreService = FirestoreService();
  void selectAsMainPlan(BuildContext context) {
    firestoreService.updateActivePlan(id);
    Navigator.pop(context);
  }

  void editPlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => EditPlanForm(
        plan: plan,
        id: id,
      ),
    );
  }

  void deletePlan(BuildContext context) {
    firestoreService.deletePlan(id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: plan['active']
              ? Colors.green
              : Theme.of(context).colorScheme.inversePrimary,
          width: plan['active'] ? 5 : 3,
        ),
      ),
      padding: const EdgeInsets.only(left: 25, right: 5, top: 20, bottom: 10),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'],
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              Builder(
                builder: (context) => IconButton(
                  onPressed: () => showPopover(
                      context: context,
                      bodyBuilder: (context) => Padding(
                            padding: const EdgeInsets.only(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextButton(
                                  onPressed: () => selectAsMainPlan(context),
                                  style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  child: SizedBox(
                                    width: 150,
                                    child: Text(
                                      'Select as main',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    editPlan(context);
                                  },
                                  style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  child: SizedBox(
                                    width: 150,
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => deletePlan(context),
                                  style: ButtonStyle(
                                      overlayColor: MaterialStateProperty.all(
                                          Theme.of(context)
                                              .colorScheme
                                              .primary)),
                                  child: SizedBox(
                                    width: 150,
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      width: 150,
                      height: 150,
                      backgroundColor:
                          Theme.of(context).colorScheme.background),
                  icon: const Icon(Icons.more_vert),
                ),
              )
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              right: 20,
            ),
            child: CircularPercentIndicator(
              radius: 110,
              lineWidth: 25,
              percent: 0.4,
              progressColor: Colors.blue,
              backgroundColor: Colors.blue.shade100,
              circularStrokeCap: CircularStrokeCap.round,
              center: const Text(
                '40%',
                style: TextStyle(fontSize: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              right: 20,
            ),
            child: Text(
              '${plan['completedAjza']}/${plan['totalAjza']}',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
              right: 20,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container(
                  width: 400,
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(30)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(
                            width: 140,
                            child: Text(
                              plan['hifdhs'] == null || plan['hifdhs'].isEmpty
                                  ? 'No hifdh'
                                  : verses,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        hifdhIn == 0
                            ? 'Today'
                            : hifdhIn == 1
                                ? 'Tomorrow'
                                : 'In $hifdhIn days',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                ),
                Container(
                  width: 400,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(top: 10, bottom: 10, left: 20),
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      borderRadius: BorderRadius.circular(30)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Review',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          plan['reviews'] == null || plan['reviews'].isEmpty
                              ? 'No review'
                              : plan['reviews'].first['review'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PlanPage(id: id),
                        ));
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  child: Text(
                    'See plan',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
