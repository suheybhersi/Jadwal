import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: ProgressContent(),
    );
  }
}

class ProgressContent extends StatelessWidget {
  final FirestoreService firestoreService =
      FirestoreService(FirebaseAuth.instance);

  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  ProgressContent({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Only unfocus the TextField without causing a rebuild
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      behavior: HitTestBehavior
          .opaque, // Ensures taps outside the TextField are detected
      child: Column(
        children: [
          // Title and Settings
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              right: 10,
              top: 10,
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
              ],
            ),
          ),
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ValueListenableBuilder<String>(
              valueListenable: _searchQuery,
              builder: (context, query, child) {
                return TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (value) => _searchQuery.value = value,
                  decoration: InputDecoration(
                    filled: true, // Enables the background color
                    fillColor:
                        Colors.grey[200], // Sets the gray background color
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none, // Removes the border outline
                    ),
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    suffixIcon: query.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear(); // Clears the TextField
                              _searchQuery.value =
                                  ''; // Resets the ValueNotifier
                            },
                          )
                        : null,
                  ),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.black, // Text color inside the search bar
                  ),
                );
              },
            ),
          ),

          SizedBox(
            height: 10,
          ),
          // List of Surahs
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getSurahProgressStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No data available.',
                      style:
                          GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Fetch and sort data
                final surahsList = snapshot.data!.docs;
                surahsList
                    .sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));

                // Map Firestore data to a usable list
                final allData = surahsList
                    .map((doc) => doc.data() as Map<String, dynamic>)
                    .toList();

                return ValueListenableBuilder<String>(
                  valueListenable: _searchQuery,
                  builder: (context, query, child) {
                    // Filter data based on search query
                    final filteredData = query.isEmpty
                        ? allData
                        : allData
                            .where((surah) => surah['surah']
                                .toString()
                                .toLowerCase()
                                .contains(query.toLowerCase()))
                            .toList();

                    if (filteredData.isEmpty) {
                      return Center(
                        child: Text(
                          'No results found.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: filteredData.length,
                      itemBuilder: (context, index) {
                        final surah = filteredData[index];
                        // Calculate progress but round both to the nearest integer
                        final completedLines = surah['completedLines'].round();
                        final totalLines = surah['totalLines'];
                        final double progress = completedLines / totalLines;

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
                              // Surah Number
                              Container(
                                decoration: BoxDecoration(
                                    color: Color.fromARGB(255, 114, 152, 255),
                                    borderRadius: BorderRadius.circular(30)),
                                height: 40,
                                width: 40,
                                child: Center(
                                  child: Text(
                                    '${surah['surahNumber']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              // Surah Details
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
                                      trailing: Padding(
                                        padding:
                                            const EdgeInsets.only(left: 10.0),
                                        child: Text(
                                          '${(progress > 1 ? 100 : progress * 100).toStringAsFixed(0)}%',
                                          style:
                                              GoogleFonts.poppins(fontSize: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
