import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/pages/plan_page.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:hifdh_planner_app/themes/theme_provider.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:popover/popover.dart';
import 'package:provider/provider.dart';

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
    // if (plan['active'] == true && firestoreService.plansCollection.count().get() != 0) {
    //   showDialog(
    //     context: context,
    //     builder: (context) =>
    //         const AlertDialog(title: Text('Choose a new active plan')),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlanPage(id: id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          border: plan['active']
              ? const Border()
              : Border.all(
                  width: 2,
                  color: Provider.of<ThemeProvider>(context).isDarkMode
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white),
          color:
              plan['active'] && Provider.of<ThemeProvider>(context).isDarkMode
                  ? Theme.of(context).colorScheme.primary
                  : plan['active']
                      ? Colors.white
                      : Colors.transparent,
        ),
        margin: const EdgeInsets.only(bottom: 20),
        child: Padding(
          padding: const EdgeInsets.only(left: 20, top: 15, bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan['name'],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              Row(
                children: [
                  MyProgressIndicator(plan: plan),
                  // Column(
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.only(left: 10.0),
                  //       child: Text(
                  //         '30%',
                  //         style: TextStyle(
                  //           fontSize: 20,
                  //           fontWeight: FontWeight.w600,
                  //           color: Theme.of(context).colorScheme.inversePrimary,
                  //         ),
                  //       ),
                  //     ),
                  //     SizedBox(
                  //       width: 60,
                  //       child: LinearPercentIndicator(
                  //         padding: const EdgeInsets.symmetric(
                  //           horizontal: 0,
                  //         ),
                  //         lineHeight: 10,
                  //         percent: 0.3,
                  //         progressColor: Colors.blue,
                  //         backgroundColor:
                  //             Theme.of(context).colorScheme.tertiary,
                  //         barRadius: const Radius.circular(20),
                  //       ),
                  //     ),
                  //   ],
                  // ),
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
                                      onPressed: () =>
                                          selectAsMainPlan(context),
                                      style: ButtonStyle(
                                          overlayColor:
                                              MaterialStateProperty.all(
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
                                          overlayColor:
                                              MaterialStateProperty.all(
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
                                          overlayColor:
                                              MaterialStateProperty.all(
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
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class MyProgressIndicator extends StatelessWidget {
  const MyProgressIndicator({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircularPercentIndicator(
          radius: 35,
          lineWidth: 12,
          percent: 0.4,
          progressColor: Colors.blue,
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          circularStrokeCap: CircularStrokeCap.round,
          center: Text(
            '40%',
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.inversePrimary,
                fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
