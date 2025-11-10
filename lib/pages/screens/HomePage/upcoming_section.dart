import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/pages/screens/QuranViewer/quran_viewer.dart';
import 'package:jadwal/components/verse_picker.dart';

class UpcomingSection extends StatelessWidget {
  const UpcomingSection({
    super.key,
    required this.plan,
    required this.hifdhIn,
    required this.id,
    required this.markHifdhAsComplete,
    required this.markReviewAsComplete,
    required this.reviews,
  });

  final Map<String, dynamic> plan;
  final int hifdhIn;
  final String id;
  final Function(String, BuildContext, int, String) markHifdhAsComplete;
  final Function(BuildContext, List<dynamic>, String) markReviewAsComplete;
  final List<dynamic> reviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Iconsax.task_square,
                      color: Color.fromARGB(255, 73, 121, 251),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Today\'s Tasks',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 73, 121, 251).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.calendar_1,
                      color: Color.fromARGB(255, 73, 121, 251),
                      size: 14,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${DateTime.now().day} ${_getMonthName(DateTime.now().month)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color.fromARGB(255, 73, 121, 251),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // New Memorisation Card
              GestureDetector(
                onTap: () {
                  if (!plan['hifdhs'].last['completed']) {
                    newDraggableBottomSheet(context, plan['hifdhs'].last);
                  }
                },
                child: Container(
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
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Color.fromARGB(255, 73, 121, 251).withOpacity(0.2),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: plan['hifdhs'] == null ||
                          plan['hifdhs'].isEmpty ||
                          hifdhIn == -1
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'No memorisation tasks',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Iconsax.book_1,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Iconsax.book_1,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'New Memorisation',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    plan['hifdhs'].last['completed']
                                        ? 'Completed'
                                        : 'Pending',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '${plan['hifdhs'].last['surah'].contains(' ') ? plan['hifdhs'].last['surah'].split(' ').first : plan['hifdhs'].last['surah']}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Verse ${plan['hifdhs'].last['hifdh'].split('-')[0].split(':')[1]}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          color: Colors.white.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        plan['hifdhs'].last['length'] >= 0.6 &&
                                                plan['hifdhs']
                                                        .last['surah']
                                                        .split(' ')[0] !=
                                                    'Al-Fatiha'
                                            ? _buildStartVersePreview(
                                                plan['hifdhs'].last,
                                              )
                                            : plan['hifdhs'].last['startVerse'],
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 22,
                                          height: 1.8,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    plan['hifdhs'].last['completed']
                                        ? Iconsax.calendar_1
                                        : Iconsax.arrow_right_3,
                                    color: Color.fromARGB(255, 73, 121, 251),
                                    size: 18,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    plan['hifdhs'].last['completed']
                                        ? 'Next - ${_getNextHifdhDate(plan['hifdhDays'], plan['currentWeek'][0]['weekStart'])}'
                                        : 'Start Memorising',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color.fromARGB(255, 73, 121, 251),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Review Card
              reviews.isEmpty
                  ? SizedBox()
                  : Column(
                      children: [
                        SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            markReviewAsComplete(context, reviews, id);
                          },
                          child: Container(
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
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromARGB(255, 100, 163, 119)
                                      .withOpacity(0.2),
                                  blurRadius: 15,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.white.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Iconsax.refresh,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          'Review',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Quiz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${reviews.first['surah'].split(' ')[0]}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Verse ${reviews.first['review'].split('-')[0].split(':')[1]}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color:
                                                  Colors.white.withOpacity(0.9),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            reviews.first['length'] >= 0.6 &&
                                                    reviews.first['surah']
                                                            .split(' ')[0] !=
                                                        'Al-Fatiha'
                                                ? '...${reviews.first['startVerse'].substring(0, reviews.first['startVerse'].substring(0, 40).lastIndexOf(' '))}'
                                                : reviews.first['startVerse'],
                                            style: GoogleFonts.scheherazadeNew(
                                              fontSize: 22,
                                              height: 1.8,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Iconsax.play,
                                        color:
                                            Color.fromARGB(255, 100, 163, 119),
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Start Quiz',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color.fromARGB(
                                              255, 100, 163, 119),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
        SizedBox(height: 10),
      ],
    );
  }

  void newDraggableBottomSheet(
      BuildContext context, Map<String, dynamic> hifdh) {
    Widget makeDissmissable({required Widget child}) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: GestureDetector(
            onTap: () {},
            child: child,
          ),
        );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return makeDissmissable(
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.6,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    Container(
                      margin: EdgeInsets.only(
                        top: 12,
                      ),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        physics: BouncingScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'New Memorisation',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(
                                      Icons.close,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              // First verse section
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: Color(0xFFE3EAFF),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                Iconsax.book_1,
                                                color: Color(0xFF4979FB),
                                                size: 18,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Surah ${hifdh['surah'].split(' ')[0]}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                                Text(
                                                  'Verse ${hifdh['hifdh'].split('-')[0].split(':')[1]}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .inversePrimary
                                                        .withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            // Get the first verse key from hifdh
                                            final verseKey = hifdh['hifdh']
                                                .split('-')[0]
                                                .trim();
                                            // Get the end verse key from hifdh
                                            final endVerseKey = hifdh['hifdh']
                                                .split('-')[1]
                                                .trim();

                                            // Parse the start verse key to determine previous verse
                                            String prevVerseKey = '';
                                            try {
                                              final parts = verseKey.split(':');
                                              if (parts.length == 2) {
                                                int chapter =
                                                    int.parse(parts[0]);
                                                int verse = int.parse(parts[1]);
                                                // If this isn't the first verse of the surah, then previous is same surah, verse-1
                                                if (verse > 1) {
                                                  prevVerseKey =
                                                      '$chapter:${verse - 1}';
                                                } else {
                                                  // If it's the first verse, we need special handling
                                                  // For now we'll leave prevVerseKey empty which works for our case
                                                  // In a complete implementation, you'd need to handle surah boundaries
                                                }
                                              }
                                            } catch (e) {
                                              // If we can't parse, we'll just proceed without a previous verse key
                                              print(
                                                  'Error determining previous verse: $e');
                                            }

                                            try {
                                              // Show loading indicator
                                              showDialog(
                                                context: context,
                                                barrierDismissible: false,
                                                builder:
                                                    (BuildContext context) {
                                                  return const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  );
                                                },
                                              );

                                              // Get the FirestoreService
                                              final firestoreService =
                                                  FirestoreService(
                                                auth: FirebaseAuth.instance,
                                                uid: FirebaseAuth
                                                    .instance.currentUser!.uid,
                                              );

                                              // Get the page number for the start verse
                                              final startPageNumber =
                                                  await firestoreService
                                                      .getPageForVerseKey(
                                                          verseKey);

                                              // Get the page number for the end verse
                                              final endPageNumber =
                                                  await firestoreService
                                                      .getPageForVerseKey(
                                                          endVerseKey);

                                              // If we have a previous verse, try to get its page number
                                              // String prevVersePage = '';
                                              // if (prevVerseKey.isNotEmpty) {
                                              //   try {
                                              //     final prevPage =
                                              //         await firestoreService
                                              //             .getPageForVerseKey(
                                              //                 prevVerseKey);
                                              //     prevVersePage =
                                              //         prevPage.toString();
                                              //   } catch (e) {
                                              //     print(
                                              //         'Error getting previous verse page: $e');
                                              //   }
                                              // }

                                              // Close the loading dialog
                                              Navigator.pop(context);

                                              // Navigate to QuranViewer
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      QuranViewer(
                                                          initialPage:
                                                              startPageNumber,
                                                          verseToHighlight:
                                                              verseKey,
                                                          pageToHighlight:
                                                              startPageNumber
                                                                  .toString(),
                                                          endVerseToHighlight:
                                                              endVerseKey,
                                                          endPageToHighlight:
                                                              endPageNumber
                                                                  .toString(),
                                                          prevVerseKey:
                                                              prevVerseKey),
                                                ),
                                              );
                                            } catch (e) {
                                              // Close the loading dialog if there was an error
                                              Navigator.pop(context);

                                              // Show error message
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Error loading verse: $e')),
                                              );
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            backgroundColor: Color(0xFF4979FB),
                                            elevation: 0,
                                          ),
                                          child: Container(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Go',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        '${hifdh['startVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[0].split(':')[1]).replaceAll(' ', '')}﴾',
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 22,
                                          height: 1.8,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 20),
                              // Connection indicator
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                                  ),
                                  Container(
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 16),
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.arrow_downward_rounded,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .inversePrimary,
                                      size: 20,
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              // Second verse section
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .tertiary
                                        .withOpacity(0.1),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Color(0xFFE3EAFF),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Icon(
                                            Iconsax.book_1,
                                            color: Color(0xFF4979FB),
                                            size: 18,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Surah ${hifdh['surah'].substring(hifdh['surah'].indexOf(' ') + 1)}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                ),
                                              ),
                                              Text(
                                                'Verse ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 12,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .inversePrimary
                                                      .withOpacity(0.5),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _openEditEndPicker(context, hifdh);
                                          },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Color(0xFF4979FB),
                                          ),
                                          child: Text(
                                            'Edit',
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        '${hifdh['endVerse']} ﴿${_convertToArabicNumbers(hifdh['hifdh'].split('-')[1].split(':')[1]).replaceAll(' ', '')}﴾',
                                        style: GoogleFonts.scheherazadeNew(
                                          fontSize: 22,
                                          height: 1.8,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                        textAlign: TextAlign.justify,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40),

                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!hifdh['completed']) {
                                      markHifdhAsComplete(
                                        hifdh['nextKey'],
                                        context,
                                        plan['lines'],
                                        id,
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    backgroundColor: Color(0xFF4979FB),
                                    elevation: 0,
                                  ),
                                  child: Container(
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Mark as Complete',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openEditEndPicker(BuildContext context, Map<String, dynamic> hifdh) {
    final firestoreService = FirestoreService(
      auth: FirebaseAuth.instance,
      uid: FirebaseAuth.instance.currentUser!.uid,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Adjust End Verse',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder(
                      stream: firestoreService.getSurahsStream(),
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        final docs = snapshot.data!.docs;
                        final List<Map<String, dynamic>> surahData = docs
                            .map((d) => d.data() as Map<String, dynamic>)
                            .toList();

                        int parseSurahNumber(Map<String, dynamic> data) {
                          final dynamic raw = data['surahNumber'];
                          if (raw is int) return raw;
                          if (raw is String) {
                            return int.tryParse(raw) ?? 0;
                          }
                          return 0;
                        }

                        // Determine direction-aware allowed surah range
                        final endKey = hifdh['hifdh'].split('-')[1].trim();
                        final endSurahNumber = int.parse(endKey.split(':')[0]);
                        final initialVerse = int.parse(endKey.split(':')[1]);

                        final startKey = hifdh['hifdh'].split('-')[0].trim();
                        final startSurahNumber =
                            int.tryParse(startKey.split(':')[0]) ?? 0;
                        final bool isBackToFront =
                            (plan['backToFront'] ?? false) == true;

                        List<Map<String, dynamic>> allowedSurahs = surahData
                            .where((s) => isBackToFront
                                ? parseSurahNumber(s) <= startSurahNumber
                                : parseSurahNumber(s) >= startSurahNumber)
                            .toList();

                        if (allowedSurahs.isEmpty) {
                          allowedSurahs =
                              List<Map<String, dynamic>>.from(surahData);
                        }

                        if (allowedSurahs.isEmpty) {
                          return const Center(
                            child: Text('No surah data available.'),
                          );
                        }

                        allowedSurahs.sort((a, b) {
                          final aNum = parseSurahNumber(a);
                          final bNum = parseSurahNumber(b);
                          return isBackToFront
                              ? bNum.compareTo(aNum)
                              : aNum.compareTo(bNum);
                        });

                        final initialIndex = allowedSurahs.indexWhere(
                            (s) => parseSurahNumber(s) == endSurahNumber);
                        final resolvedInitialIndex =
                            initialIndex >= 0 ? initialIndex : 0;
                        final int initialPickerIndex =
                            allowedSurahs.isEmpty ? 0 : resolvedInitialIndex;

                        String? selectedSurahName;
                        int? selectedVerseNumber;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Column(
                            children: [
                              Expanded(
                                child: QuranVersePicker(
                                  surahData: allowedSurahs,
                                  initialSurahIndex: initialPickerIndex,
                                  initialVerseNumber: initialVerse,
                                  onVerseSelected:
                                      (String surahName, int verseNumber) {
                                    selectedSurahName = surahName;
                                    selectedVerseNumber = verseNumber;
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20.0, vertical: 16.0),
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // Resolve picked surah to its number
                                        final sel = selectedSurahName ??
                                            allowedSurahs[initialPickerIndex]
                                                ['surah'];
                                        final chosen = allowedSurahs.firstWhere(
                                            (s) => s['surah'] == sel,
                                            orElse: () => allowedSurahs[
                                                initialPickerIndex]);
                                        final surahNumber =
                                            parseSurahNumber(chosen);
                                        final verseNumber =
                                            selectedVerseNumber ?? initialVerse;
                                        final newEndKey =
                                            '$surahNumber:$verseNumber';

                                        final bool isInvalidSelection =
                                            (!isBackToFront &&
                                                    surahNumber <
                                                        startSurahNumber) ||
                                                (isBackToFront &&
                                                    surahNumber >
                                                        startSurahNumber);

                                        if (isInvalidSelection) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'You cannot select a previously memorised surah.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        // Show spinner
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );

                                        // Adjust on backend
                                        await firestoreService
                                            .adjustLastHifdhEnd(id, newEndKey);

                                        Navigator.of(context)
                                            .pop(); // close spinner
                                        Navigator.of(context)
                                            .pop(); // close sheet

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                              content: Text(
                                                  'End verse updated successfully')),
                                        );
                                      } catch (e) {
                                        Navigator.of(context)
                                            .pop(); // close spinner if open
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text('Failed to update: $e')),
                                        );
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      backgroundColor: Color(0xFF4979FB),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Save',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _buildStartVersePreview(dynamic lastHifdhData) {
    if (lastHifdhData is! Map) {
      return '';
    }

    final startVerse = lastHifdhData['startVerse'];
    if (startVerse is! String || startVerse.isEmpty) {
      return '';
    }

    const maxLength = 35;
    if (startVerse.length <= maxLength) {
      return startVerse;
    }

    final previewCandidate = startVerse.substring(0, maxLength);
    final lastSpace = previewCandidate.lastIndexOf(' ');

    if (lastSpace == -1) {
      return '...$previewCandidate';
    }

    return '...${previewCandidate.substring(0, lastSpace)}';
  }

  String _convertToArabicNumbers(String number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    for (int i = 0; i < english.length; i++) {
      number = number.replaceAll(english[i], arabic[i]);
    }
    return number;
  }

  String _getNextHifdhDate(List<dynamic> hifdhDays, String weekStart) {
    // Parse the week start date
    List<String> dateParts = weekStart.split('-');
    DateTime weekStartDate = DateTime(
      int.parse(dateParts[2]),
      int.parse(dateParts[1]),
      int.parse(dateParts[0]),
    );

    // Get today's date
    DateTime today = DateTime.now();

    // Find the next incomplete hifdh day
    for (int i = today.weekday - 1; i < 7; i++) {
      if (hifdhDays[i]) {
        DateTime nextDate = weekStartDate.add(Duration(days: i));
        if (nextDate.isAfter(today) && !plan['currentWeek'][i]['completed']) {
          return '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}';
        }
      }
    }

    // If no incomplete hifdh day found in current week, check next week
    bool foundFirst = false;
    for (int i = 0; i < today.weekday - 1; i++) {
      if (hifdhDays[i]) {
        DateTime nextDate = weekStartDate.add(Duration(days: i + 7));
        List<String> dateParts = plan['hifdhs'].last['date'].split('-');
        DateTime weekStartDateDT = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
        if (!foundFirst &&
            (weekStartDateDT.isAfter(nextDate) ||
                weekStartDateDT == nextDate)) {
          foundFirst = true;
          continue;
        }

        return '${nextDate.day.toString().padLeft(2, '0')}/${nextDate.month.toString().padLeft(2, '0')}';
      }
    }

    return '--/--'; // Fallback if no next date found
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }
}
