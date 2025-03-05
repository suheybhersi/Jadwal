import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/components/edit_plan_page.dart';
import 'package:jadwal/pages/screens/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Plan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
          ),
        ),
        leading: StreamBuilder<QuerySnapshot>(
          stream: firestoreService.getPlansStream(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return IconButton(
                onPressed: () {},
                icon: const Icon(Iconsax.edit, color: Colors.grey),
              );
            }

            Map<String, dynamic> plan =
                snapshot.data!.docs[0].data() as Map<String, dynamic>;
            String id = snapshot.data!.docs[0].id;

            return IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditPlanPage(
                      plan: plan,
                      id: id,
                    ),
                  ),
                );
              },
              icon: const Icon(Iconsax.edit),
              style: IconButton.styleFrom(
                padding: EdgeInsets.all(12),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Iconsax.setting_2),
            style: IconButton.styleFrom(
              padding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPlansStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 73, 121, 251),
              ),
            );
          }

          if (snapshot.hasData) {
            List plansList = snapshot.data!.docs;

            if (plansList.isNotEmpty) {
              Map<String, dynamic> plan =
                  plansList[0].data() as Map<String, dynamic>;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Your Progress',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    PlanProgress(
                      plan: plan,
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'History',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    plan['hifdhs']
                            .where((hifdh) => hifdh['completed'] == true)
                            .isNotEmpty
                        ? Column(
                            children: [
                              PreviousMemorisation(
                                plan: plan,
                              ),
                              PreviousReviews(
                                plan: plan,
                              ),
                            ],
                          )
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Column(
                                children: [
                                  Icon(
                                    Iconsax.clipboard_close,
                                    size: 60,
                                    color: Colors.grey.withOpacity(0.5),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No history found.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                    SizedBox(height: 30),
                  ],
                ),
              );
            }
          }
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.document_text,
                  size: 60,
                  color: Colors.grey.withOpacity(0.5),
                ),
                SizedBox(height: 16),
                Text(
                  'No plans found',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        },
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
    // Calculate percentage with safety check to avoid division by zero
    double percentage = plan['totalLines'] > 0
        ? (plan['completedLines'] / plan['totalLines'])
        : 0.0;
    // Ensure percentage doesn't exceed 1.0
    percentage = percentage > 1.0 ? 1.0 : percentage;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 73, 121, 251),
            Color.fromARGB(255, 114, 152, 255),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Memorisation Progress',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Keep up your progress!',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 2,
              child: CircularPercentIndicator(
                radius: 45,
                lineWidth: 10,
                percent: percentage,
                progressColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.3),
                circularStrokeCap: CircularStrokeCap.round,
                center: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${(percentage * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                animation: true,
                animationDuration: 1000,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.book_1,
                color: Color.fromARGB(255, 73, 121, 251),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Memorisation',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hifdhs.length > 2 ? 2 : hifdhs.length,
            itemBuilder: (context, index) {
              final hifdh = hifdhs[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      spreadRadius: 1,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]} - ${hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Completed on ${hifdh['date'].split('-')[0]}/${hifdh['date'].split('-')[1]}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Color.fromARGB(255, 106, 106, 106),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Iconsax.tick_circle,
                      color: Color.fromARGB(255, 73, 121, 251),
                      size: 20,
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
      return dateB.compareTo(dateA); // Reversed for newest first
    });

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.refresh,
                color: Color.fromARGB(255, 100, 163, 119),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Reviews',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          reviews.isEmpty
              ? Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'No reviews scheduled yet',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reviews.length > 3 ? 3 : reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade100,
                            spreadRadius: 1,
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${review['surah'].split(' ')[0]} ${review['review'].split('-')[0].split(':')[1]} - ${review['surah'].split(' ')[1]} ${review['review'].split('-')[1].split(':')[1]}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Next review on ${review['date'].split('-')[0]}/${review['date'].split('-')[1]}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Color.fromARGB(255, 106, 106, 106),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 114, 171, 255),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Center(
                              child: Text(
                                '${review['ratings'].length}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
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
