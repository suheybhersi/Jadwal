import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hifdh_planner_app/components/new_plan_form.dart';
import 'package:hifdh_planner_app/components/plan_tile.dart';
import 'package:hifdh_planner_app/services/firestore.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  final FirestoreService firestoreService = FirestoreService();

  List<bool> _selectedDays = List.generate(7, (index) => false);

  void _createNewPlan(BuildContext context) {
    _selectedDays = List.generate(7, (index) => false);
    showDialog(
      context: context,
      builder: (context) => NewPlanForm(selectedDays: _selectedDays),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool hifdhMissedCalled = false;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Plans',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
        ),
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
      floatingActionButton: TextButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
              Theme.of(context).colorScheme.tertiary),
        ),
        onPressed: () {
          _createNewPlan(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Icon(
            Icons.add,
            size: 30,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getPlansStream(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List plansList = snapshot.data!.docs;

              return plansList.isEmpty
                  ? Center(
                      child: Text(
                      'No plans...',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 24),
                    ))
                  : ListView.builder(
                      itemCount: plansList.length,
                      itemBuilder: (context, index) {
                        DocumentSnapshot document = plansList[index];
                        String docID = document.id;

                        Map<String, dynamic> plan =
                            document.data() as Map<String, dynamic>;

                        int hifdhIn = 0;
                        String verses = '';
                        if (plan['hifdhs'].isNotEmpty &&
                            plan['hifdhs'] != null) {
                          bool completed = plan['hifdhs'].last['completed'];

                          firestoreService.hifdhIn(docID);
                          hifdhIn = plan['hifdhIn'];
                          verses = plan['hifdhs'].last['hifdh'];
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

                          if (hifdhDate == today && completed) {
                            firestoreService.updateNextHifdh(docID);
                          } else if (todayDT.isAfter(hifdhDT) &&
                              !hifdhMissedCalled) {
                            hifdhMissedCalled = true;
                            firestoreService.hifdhMissed(docID).then((_) {
                              // Reset the flag after the method completes
                              hifdhMissedCalled = false;
                            });
                          }

                          String weekStart =
                              plan['currentWeek'][0]['weekStart'];

                          DateTime currWeekStartDT = DateTime.now().subtract(
                            Duration(days: DateTime.now().weekday - 1),
                          );

                          String currWeekStart =
                              '${currWeekStartDT.day}-${currWeekStartDT.month}-${currWeekStartDT.year}';

                          if ((currWeekStart.split('-')[0] !=
                                  weekStart.split('-')[0] ||
                              currWeekStart.split('-')[1] !=
                                  weekStart.split('-')[1] ||
                              currWeekStart.split('-')[2] !=
                                  weekStart.split('-')[2])) {
                            firestoreService.updateCurrentWeek(docID);
                          }
                        }

                        return PlanTile(
                          plan: plan,
                          id: docID,
                          hifdhIn: hifdhIn,
                          verses: verses,
                        );
                      },
                    );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}
