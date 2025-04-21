import 'package:flutter/material.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/services/firestore.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Streams for quiz history data
  late Stream<List<QueryDocumentSnapshot>> _customQuizStream;
  late Stream<List<QueryDocumentSnapshot>> _reviewQuizStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      // Initialize the streams using FirestoreService
      final firestoreService = Provider.of<FirestoreService>(context);
      _customQuizStream = firestoreService.getCustomQuizHistoryStream();
      _reviewQuizStream = firestoreService.getReviewQuizHistoryStream();
    } catch (e) {
      print('Error initializing quiz history streams: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTitleBar(context),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReviewQuizHistory(),
                _buildCustomQuizHistory(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Title bar with create quiz button
  Widget _buildTitleBar(BuildContext context) {
    return Padding(
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
            'Quizzes',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 22,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QuizCreationPage(),
                ),
              );
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Iconsax.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tab Bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Theme.of(context).colorScheme.primary,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Theme.of(context).colorScheme.inversePrimary,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        padding: EdgeInsets.zero,
        indicatorSize: TabBarIndicatorSize.tab,
        labelPadding: EdgeInsets.zero,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) {
            return states.contains(WidgetState.focused)
                ? null
                : Colors.transparent;
          },
        ),
        tabs: const [
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Review Quizzes'),
            ),
          ),
          Tab(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Text('Custom Quizzes'),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Quiz History
  Widget _buildCustomQuizHistory() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _customQuizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          print('Error in custom quiz stream: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading quiz history',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.clipboard_text,
                  size: 60,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No custom quizzes yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first quiz',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const QuizCreationPage(),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.add, color: Colors.white),
                  label: Text(
                    'Create Quiz',
                    style: GoogleFonts.poppins(),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Build list of quiz history items
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data![index];
            var quizData = doc.data() as Map<String, dynamic>;
            return _buildQuizHistoryCard(quizData);
          },
        );
      },
    );
  }

  // Review Quiz History
  Widget _buildReviewQuizHistory() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _reviewQuizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          print('Error in review quiz stream: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading review history',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.refresh,
                  size: 60,
                  color: Colors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No review quizzes yet',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Complete a review session to see your quizzes here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        // Build list of quiz history items
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data![index];
            var quizData = doc.data() as Map<String, dynamic>;
            return _buildQuizHistoryCard(quizData);
          },
        );
      },
    );
  }

  // Quiz history card widget
  Widget _buildQuizHistoryCard(Map<String, dynamic> quizData) {
    final score = quizData['score'] ?? 0;
    final totalQuestions = quizData['totalQuestions'] ?? 1;
    final percentage = (score / totalQuestions) * 100;
    final date = quizData['dateCompleted'] ?? 'Unknown date';

    // Determine color based on score percentage
    Color cardColor;
    IconData resultIcon;

    if (percentage >= 90) {
      cardColor = Colors.green.shade700;
      resultIcon = Icons.emoji_events;
    } else if (percentage >= 70) {
      cardColor = Colors.blue.shade700;
      resultIcon = Icons.thumb_up;
    } else if (percentage >= 50) {
      cardColor = Colors.amber.shade700;
      resultIcon = Icons.trending_up;
    } else {
      cardColor = Colors.red.shade700;
      resultIcon = Icons.refresh;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and score row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .inversePrimary
                          .withOpacity(0.7),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .inversePrimary
                            .withOpacity(0.7),
                      ),
                    ),
                  ],
                ),

                // Score
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        resultIcon,
                        size: 14,
                        color: cardColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$score/$totalQuestions',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cardColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress bar
            LinearProgressIndicator(
              value: score / totalQuestions,
              backgroundColor: Colors.grey.withOpacity(0.2),
              color: cardColor,
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),

            const SizedBox(height: 12),

            // Percentage
            Text(
              '${percentage.toInt()}% Correct',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),

            // Quiz type
            Text(
              quizData['isCustomQuiz'] ? 'Custom Quiz' : 'Review Quiz',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .inversePrimary
                    .withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
