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
  final FirestoreService firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

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

            return Padding(
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: IconButton(
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
              ),
            );
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 10),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(),
                  ),
                );
              },
              icon: const Icon(Iconsax.setting_2),
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
                    PlanProgress(
                      plan: plan,
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

  void _showMemorisationDetails(
      BuildContext context, Map<String, dynamic> hifdh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Memorisation Details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Iconsax.book_1,
                    color: Color.fromARGB(255, 73, 121, 251),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]}-${hifdh['surah'].split(' ')[1] == hifdh['surah'].split(' ')[0] ? '' : hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 73, 121, 251),
                      Color.fromARGB(255, 114, 152, 255),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      hifdh['startVerse'] ?? 'Verse text not available',
                      style: GoogleFonts.scheherazadeNew(
                        letterSpacing: 0,
                        fontSize: 20,
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    if (hifdh['endVerse'] != null &&
                        hifdh['endVerse'] != hifdh['startVerse']) ...[
                      SizedBox(height: 12),
                      Divider(
                          color: Colors.white.withOpacity(0.3), thickness: 1),
                      SizedBox(height: 12),
                      Text(
                        hifdh['endVerse'],
                        style: GoogleFonts.scheherazadeNew(
                          letterSpacing: 0,
                          fontSize: 20,
                          height: 1.5,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                    SizedBox(height: 12),
                    Text(
                      '${hifdh['hifdh']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    color: Color.fromARGB(255, 100, 163, 119),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Completed on ${hifdh['date'].split('-')[0]}/${hifdh['date'].split('-')[1]}/${hifdh['date'].split('-')[2]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
              return InkWell(
                onTap: () => _showMemorisationDetails(context, hifdh),
                borderRadius: BorderRadius.circular(16),
                child: Container(
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
                        Iconsax.arrow_right_3,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
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

  void _showReviewDetails(BuildContext context, Map<String, dynamic> review) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review Details',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Iconsax.book_1,
                    color: Color.fromARGB(255, 100, 163, 119),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${review['surah'].split(' ')[0]} ${review['review'].split('-')[0].split(':')[1]}-${review['surah'].split(' ')[1] == review['surah'].split(' ')[0] ? '' : review['surah'].split(' ')[1]} ${review['review'].split('-')[1].split(':')[1]}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 100, 163, 119),
                      Color.fromARGB(255, 129, 186, 145),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                          Color.fromARGB(255, 100, 163, 119).withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      review['startVerse'] ?? 'Verse text not available',
                      style: GoogleFonts.scheherazadeNew(
                        letterSpacing: 0,
                        fontSize: 20,
                        height: 1.5,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.justify,
                      textDirection: TextDirection.rtl,
                    ),
                    if (review['endVerse'] != null &&
                        review['endVerse'] != review['startVerse']) ...[
                      SizedBox(height: 12),
                      Divider(
                          color: Colors.white.withOpacity(0.3), thickness: 1),
                      SizedBox(height: 12),
                      Text(
                        review['endVerse'],
                        style: GoogleFonts.scheherazadeNew(
                          letterSpacing: 0,
                          fontSize: 20,
                          height: 1.5,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.justify,
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                    SizedBox(height: 12),
                    Text(
                      '${review['review']}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Iconsax.calendar,
                    color: Color.fromARGB(255, 100, 163, 119),
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Next review on ${review['date'].split('-')[0]}/${review['date'].split('-')[1]}/${review['date'].split('-')[2]}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'Review Ratings:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              review['ratings'].isEmpty
                  ? Text(
                      'No ratings yet',
                      style:
                          GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < review['ratings'].length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Text(
                                  "Review ${i + 1}:",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 8),
                                _buildRatingStars(review['ratings'][i]),
                              ],
                            ),
                          ),
                      ],
                    ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatingStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: index < rating ? Colors.amber : Colors.grey,
          size: 18,
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> reviews = plan['reviews'] ?? [];

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
                    return InkWell(
                      onTap: () => _showReviewDetails(context, review),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
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
                            Icon(
                              Iconsax.arrow_right_3,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
