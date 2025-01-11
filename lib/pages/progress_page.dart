import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hifdh_planner_app/services/firestore.dart';
import 'package:iconsax/iconsax.dart';

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
                      left: 10,
                      right: 4,
                      top: 20.0,
                      bottom: 15,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Iconsax.edit_2),
                        ),
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
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Memorisation',
                            style: GoogleFonts.poppins(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          LinearProgressIndicator(
                            value: 0,
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${(0 > 1 ? 1 : 0 * 100).toStringAsFixed(0)}% Completed',
                            style: GoogleFonts.poppins(fontSize: 16),
                          ),
                        ],
                      ),
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
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surah['surah'],
                                style: GoogleFonts.poppins(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 10),
                              LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                                backgroundColor: Colors.grey[300],
                                color: Colors.blue,
                              ),
                              SizedBox(height: 5),
                              Text(
                                '${(progress > 1 ? 1 : progress * 100).toStringAsFixed(0)}% Completed',
                                style: GoogleFonts.poppins(fontSize: 16),
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
