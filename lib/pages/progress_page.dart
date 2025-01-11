import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressPage extends StatelessWidget {
  ProgressPage({super.key});

  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getSurahsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List surahsList = snapshot.data!.docs;

            if (surahsList.isNotEmpty) {
              // Sort surahsList by 'id'
              surahsList
                  .sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

              List<Map<String, dynamic>> surahData = surahsList
                  .map((doc) => doc.data() as Map<String, dynamic>)
                  .toList();

              // Add a title before the ListView
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 14,
                      top: 20.0,
                      bottom: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Iconsax.setting_2),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    // Ensure ListView takes available space
                    child: ListView.builder(
                      itemCount: surahData.length,
                      itemBuilder: (context, index) {
                        final surah = surahData[index];
                        final double progress =
                            surah['completedLines'] / surah['totalLines'];
                        return Container(
                          margin: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Color.fromARGB(255, 237, 242, 255),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 114, 152, 255),
                                    borderRadius: BorderRadius.circular(30)),
                                height: 40,
                                width: 40,
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      surah['surah'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    LinearPercentIndicator(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 0,
                                      ),
                                      lineHeight: 10,
                                      percent: progress > 1 ? 1 : progress,
                                      progressColor:
                                          Color.fromARGB(255, 113, 233, 175),
                                      backgroundColor:
                                          Color.fromARGB(255, 242, 243, 248),
                                      barRadius: const Radius.circular(20),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      '${(progress > 1 ? 1 : progress * 100).toStringAsFixed(0)}% Completed',
                                      style: GoogleFonts.poppins(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            }
          }
          return SizedBox();
        },
      ),
    );
  }
}
