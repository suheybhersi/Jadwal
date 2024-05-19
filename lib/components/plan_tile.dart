import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/pages/plan_page.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
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
        borderRadius: BorderRadius.circular(35),
        border: Border.all(
          color: plan['active']
              ? Colors.green
              : Theme.of(context).colorScheme.inversePrimary,
          width: plan['active'] ? 3 : 2,
        ),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.only(left: 25, right: 5, top: 20, bottom: 10),
            child: Row(
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
          ),
          Padding(
            padding: const EdgeInsets.only(
              top: 10.0,
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
          Text(
            '${plan['completedAjza']}/${plan['totalAjza']}',
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w600),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 300,
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
                  width: 300,
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
                                plan['reviews'] == null ||
                                        plan['reviews'].isEmpty
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
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 10.0, bottom: 20),
            child: TextButton(
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
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
