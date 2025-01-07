import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/components/edit_plan_form.dart';
import 'package:hifdh_planner_app/components/my_stepper.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);
  void newPlanStepper() {
    showDialog(
      context: context,
      builder: (context) => const MyStepper(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List plansList = snapshot.data!.docs;

            if (plansList.isNotEmpty) {
              Map<String, dynamic> plan =
                  plansList[0].data() as Map<String, dynamic>;
              String id = plansList[0].id;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    PlanPageHeader(
                      onEditPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => EditPlanForm(
                            plan: plan,
                            id: id,
                          ),
                        );
                      },
                      onSettingsPressed: () {},
                    ),
                    PlanProgress(
                      plan: plan,
                    ),
                    PreviousMemorisation(
                      plan: plan,
                    ),
                    PreviousReviews(
                      plan: plan,
                    ),
                  ],
                ),
              );
            }
          }
          return Center(
            child: IconButton(
              onPressed: newPlanStepper,
              icon: const Icon(Iconsax.pen_add),
            ),
          );
        },
      ),
    );
  }
}

class PlanPageHeader extends StatelessWidget {
  final VoidCallback onEditPressed;
  final VoidCallback onSettingsPressed;

  const PlanPageHeader({
    super.key,
    required this.onEditPressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 10,
        right: 10,
        top: 20.0,
        bottom: 15,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onEditPressed,
            icon: const Icon(Iconsax.edit_2),
          ),
          Text(
            'Plan',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          IconButton(
            onPressed: onSettingsPressed,
            icon: const Icon(Iconsax.setting_2),
          ),
        ],
      ),
    );
  }
}

class PlanProgress extends StatelessWidget {
  const PlanProgress({
    super.key,
    required this.plan,
  });

  final Map<String, dynamic> plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 35),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          width: 2.0,
          color: Color.fromARGB(255, 114, 152, 255),
        ),
        image: DecorationImage(
          image: AssetImage(
            'assets/progressbg.png',
          ),
          fit: BoxFit.contain,
          // Adjust this to control how the image fits
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Memorisation',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Text(
                'Keep up your progress',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color.fromARGB(255, 106, 106, 106),
                ),
              ),
            ],
          ),
          CircularPercentIndicator(
            radius: 35,
            lineWidth: 8,
            percent: ((plan['completedLines'] / plan['totalLines'])),
            progressColor: Color.fromARGB(255, 73, 121, 251),
            backgroundColor: Color.fromARGB(255, 219, 228, 254),
            circularStrokeCap: CircularStrokeCap.round,
            center: Text(
              '${((((plan['completedLines'] / plan['totalLines']) > 1 ? 1 : (plan['completedLines'] / plan['totalLines'])) * 100)).toStringAsFixed(0)}%',
              style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.inversePrimary,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class PreviousMemorisation extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PreviousMemorisation({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> hifdhs = (plan['hifdhs'] as List?)
            ?.where((hifdh) => hifdh['completed'] == true)
            .toList() ??
        [];
    hifdhs = hifdhs.reversed.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Memorisation',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hifdhs.length > 3 ? 3 : hifdhs.length,
            itemBuilder: (context, index) {
              final hifdh = hifdhs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromARGB(255, 237, 242, 255),
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 240, 245, 255),
                              borderRadius: BorderRadius.circular(30)),
                          child: Image.asset(
                            'assets/newicon.png',
                            height: 24,
                            width: 24,
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]} - ${hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Completed on ${hifdh['date'].split('-')[0]}/${hifdh['date'].split('-')[1]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Color.fromARGB(255, 106, 106, 106),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class PreviousReviews extends StatelessWidget {
  final Map<String, dynamic> plan;

  const PreviousReviews({
    super.key,
    required this.plan,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> reviews = (plan['reviews'] as List?) ?? [];

    reviews.sort((a, b) {
      List<String> dateAParts = a['date'].split('-');
      List<String> dateBParts = b['date'].split('-');
      DateTime dateA = DateTime(int.parse(dateAParts[2]),
          int.parse(dateAParts[1]), int.parse(dateAParts[0]));
      DateTime dateB = DateTime(int.parse(dateBParts[2]),
          int.parse(dateBParts[1]), int.parse(dateBParts[0]));
      return dateA.compareTo(dateB);
    });
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reviews.length > 3 ? 3 : reviews.length,
            itemBuilder: (context, index) {
              final review = reviews[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromARGB(255, 237, 242, 255),
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 240, 255, 246),
                              borderRadius: BorderRadius.circular(30)),
                          child: Icon(
                            Iconsax.refresh,
                            color: const Color.fromARGB(255, 100, 163, 119),
                          ),
                        ),
                        SizedBox(
                          width: 20,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${review['surah'].split(' ')[0]} ${review['review'].split('-')[0].split(':')[1]} - ${review['surah'].split(' ')[1]} ${review['review'].split('-')[1].split(':')[1]}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'Next review on ${review['date'].split('-')[0]}/${review['date'].split('-')[1]}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Color.fromARGB(255, 106, 106, 106),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: Container(
                          // padding: EdgeInsets.all(11),
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 78, 174, 252),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                              child: Text(
                            '${review['ratings'].length}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          )),
                        )),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
