import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/ProfilePage/achievements_page.dart';
import 'package:jadwal/pages/screens/ProfilePage/edit_profile_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/achievement_service.dart';

class ProfilePage extends StatelessWidget {
  ProfilePage({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirestoreService(
        auth: FirebaseAuth.instance,
        uid: user!.uid,
      ).userDocument.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFF4979FB)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error fetching user data'));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('User data not found'));
        }

        // Retrieve user data from Firestore
        final userData = snapshot.data!.data() as Map<String, dynamic>;

        // Get date joined
        List<String> createdAt = (userData['createdAt']
                .toDate()
                .toString()
                .split(' ')[0]
                .split('-')
                .reversed)
            .toList();

        // Convert month number to name
        final months = [
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
        createdAt[1] = months[int.parse(createdAt[1]) - 1];
        createdAt[2] = createdAt[2].substring(2);

        final FirestoreService firestoreService = FirestoreService(
          auth: FirebaseAuth.instance,
          uid: FirebaseAuth.instance.currentUser?.uid ?? '',
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: StreamBuilder<QuerySnapshot>(
              stream: firestoreService.getPlansStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF4979FB)));
                }

                final plans = snapshot.data!.docs;
                final plan = plans.first.data() as Map<String, dynamic>;

                // Calculate progress percentage
                double progressPercentage = plan['totalLines'] > 0
                    ? plan['completedLines'] / plan['totalLines']
                    : 0.0;

                // Cap at 100%
                progressPercentage =
                    progressPercentage > 1.0 ? 1.0 : progressPercentage;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      // Top app bar with title and settings button
                      _buildTopBar(context),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: LinearGradient(
                                            colors: [
                                              Color.fromARGB(255, 73, 121, 251)
                                                  .withValues(alpha: 0.7),
                                              Color.fromARGB(255, 73, 121, 251),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                        ),
                                        child: Icon(
                                          Iconsax.user,
                                          size: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Positioned(
                                        right: 10,
                                        bottom: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    const EditProfilePage(),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Iconsax.edit,
                                              size: 20,
                                              color: Color.fromARGB(
                                                  255, 73, 121, 251),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    '@${userData['username']}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Stats Overview Section
                            _buildStatsOverview(plan, context),

                            const SizedBox(height: 24),

                            // Achievements section
                            _buildSectionHeader(
                                'Achievements', Iconsax.medal_star, context),
                            const SizedBox(height: 12),
                            _buildAchievementsWidget(context),

                            const SizedBox(height: 24),

                            // Recent Activity section
                            _buildSectionHeader(
                                'Recent Activity', Iconsax.activity, context),
                            const SizedBox(height: 12),
                            _buildRecentActivityWidget(plan, context),

                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 10, top: 16, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'My Profile',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, IconData icon, BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF4979FB),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> plan, BuildContext context) {
    // Calculate completion date
    final DateTime completionDate = _calculateDaysLeft(plan);
    final String formattedDate =
        "${completionDate.day}-${completionDate.month}-${completionDate.year.toString().substring(2)}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              value: formattedDate,
              label: 'Est. Completion',
              icon: Iconsax.timer_1,
              color: Colors.green,
              context: context),
          _buildDivider(context),
          _buildStatItem(
              value: '${plan['streak']}',
              label: 'Streak',
              icon: Iconsax.flash_1,
              color: Colors.orange,
              context: context),
          _buildDivider(context),
          _buildStatItem(
              value:
                  '${(plan['completedLines'] / plan['totalLines'] * 100).toStringAsFixed(1)}%',
              label: 'Completed',
              icon: Iconsax.chart,
              color: Colors.blue,
              context: context),
        ],
      ),
    );
  }

  DateTime _calculateDaysLeft(Map<String, dynamic> plan) {
    // Get the remaining lines
    double completed = plan['completedLines'];
    double total = plan['totalLines'];
    double remaining = total - completed;

    // Get the daily target/rate from plan details
    double dailyRate = plan['lines'] > 0 ? plan['lines'].toDouble() : 1.0;

    // Calculate raw days of practice needed
    int practiceSessionsLeft = (remaining / dailyRate).ceil();
    practiceSessionsLeft = practiceSessionsLeft < 0 ? 0 : practiceSessionsLeft;

    // Count active hifdh days per week
    int daysPerWeek = 0;
    if (plan['hifdhDays'] != null && plan['hifdhDays'] is List) {
      for (var isActive in plan['hifdhDays']) {
        if (isActive == true) daysPerWeek++;
      }
    }

    // Default to daily if no schedule is set
    daysPerWeek = daysPerWeek > 0 ? daysPerWeek : 7;

    // Calculate calendar weeks needed
    int weeksToComplete = (practiceSessionsLeft / daysPerWeek).ceil();

    // Calculate total calendar days until completion
    int calendarDaysLeft = weeksToComplete * 7;

    // Calculate and store completion date for use in UI if needed
    final DateTime today = DateTime.now();
    final DateTime completionDate = today.add(Duration(days: calendarDaysLeft));

    return completionDate;
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required BuildContext? context,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context!).colorScheme.inversePrimary,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
    );
  }

  Widget _buildAchievementsWidget(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('achievements')
            .doc('user_achievements')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4979FB)),
              ),
            );
          }

          // If no data exists, create the achievements document
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Create the document asynchronously
            AchievementService(
              auth: FirebaseAuth.instance,
              uid: user.uid,
            ).ensureAchievementsDocExists();

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color:
                        Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4979FB)),
              ),
            );
          }

          final achievementsData =
              snapshot.data!.data() as Map<String, dynamic>;
          final achievements =
              achievementsData['achievements'] as Map<String, dynamic>? ?? {};

          // Get all unlocked achievements
          final unlockedAchievements = achievements.entries
              .where((entry) => entry.value == true)
              .map((entry) => entry.key)
              .toList();

          // Get the last 3 unlocked achievements
          final lastThreeAchievements = unlockedAchievements.length > 3
              ? unlockedAchievements.sublist(unlockedAchievements.length - 3)
              : unlockedAchievements;

          // Map achievement IDs to their display data
          final achievementDisplayData = {
            'firstVerses': {
              'title': 'First Verses',
              'icon': Iconsax.book_1,
              'color': const Color(0xFF4979FB),
            },
            'firstReview': {
              'title': 'First Review',
              'icon': Iconsax.refresh,
              'color': Colors.green,
            },
            'firstQuiz': {
              'title': 'First Quiz',
              'icon': Iconsax.message_question,
              'color': Colors.deepPurple,
            },
            'oneWeek': {
              'title': '5 Days',
              'icon': Iconsax.calendar,
              'color': Colors.purple,
            },
            'perfectScore': {
              'title': 'Perfect Score',
              'icon': Iconsax.star,
              'color': Colors.amber,
            },
            'quizMaster': {
              'title': 'Quiz Master',
              'icon': Iconsax.award,
              'color': Colors.deepPurple,
            },
            'tenReviews': {
              'title': '10 Reviews',
              'icon': Iconsax.refresh_circle,
              'color': Colors.green,
            },
            'oneMonth': {
              'title': '10 Days',
              'icon': Iconsax.calendar,
              'color': Colors.purple,
            },
            'progress25': {
              'title': '25% Complete',
              'icon': Iconsax.chart,
              'color': Colors.teal,
            },
            'tenQuizzes': {
              'title': '10 Quizzes',
              'icon': Iconsax.message_question,
              'color': Colors.deepPurple,
            },
            'fiftyReviews': {
              'title': '50 Reviews',
              'icon': Iconsax.refresh_right_square,
              'color': Colors.green,
            },
            'threeMonths': {
              'title': '25 Days',
              'icon': Iconsax.calendar_1,
              'color': Colors.purple,
            },
            'progress50': {
              'title': '50% Complete',
              'icon': Iconsax.chart_1,
              'color': Colors.teal,
            },
            'twentyFiveQuizzes': {
              'title': '25 Quizzes',
              'icon': Iconsax.teacher,
              'color': Colors.deepPurple,
            },
            'progress75': {
              'title': '75% Complete',
              'icon': Iconsax.chart_2,
              'color': Colors.teal,
            },
            'quizLegend': {
              'title': 'Quiz Legend',
              'icon': Iconsax.crown,
              'color': Colors.deepPurple,
            },
            'oneYear': {
              'title': '50 Days',
              'icon': Iconsax.calendar_circle,
              'color': Colors.purple,
            },
            'progress100': {
              'title': '100 Days',
              'icon': Iconsax.calendar_circle,
              'color': Colors.purple,
            },
          };

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color:
                      Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                  spreadRadius: 1,
                  blurRadius: 12,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: lastThreeAchievements.map((achievementId) {
                    final displayData = achievementDisplayData[achievementId]!;
                    return _buildAchievementItem(
                      title: displayData['title'] as String,
                      icon: displayData['icon'] as IconData,
                      color: displayData['color'] as Color,
                      isUnlocked: true,
                      context: context,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AchievementsPage(),
                      ),
                    );
                  },
                  child: Text(
                    'View All Achievements',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4979FB),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildAchievementItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
    required BuildContext context,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isUnlocked ? color : Colors.grey,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isUnlocked
                ? Theme.of(context).colorScheme.inversePrimary
                : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivityWidget(
      Map<String, dynamic> plan, BuildContext context) {
    // Create a combined list of activities
    List<Map<String, dynamic>> activities = [];

    // Get today's date for comparison
    final today = DateTime.now();
    final todayString = '${today.day}-${today.month}-${today.year}';
    final todayTimestamp = _parseDate(todayString);

    // Add hifdhs to activities
    if (plan['hifdhs'] != null && plan['hifdhs'].isNotEmpty) {
      for (var hifdh in plan['hifdhs']) {
        if (hifdh['completed'] == true) {
          // Only add completed hifdhs
          final hifdhTimestamp = _parseDate(hifdh['date']);
          // Only add if the hifdh date is not in the future
          if (!hifdhTimestamp.isAfter(todayTimestamp)) {
            activities.add({
              'type': 'hifdh',
              'title': 'Memorised new verses',
              'subtitle':
                  '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]}-${hifdh['surah'].split(' ')[1] == hifdh['surah'].split(' ')[0] ? '' : hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
              'icon': Iconsax.book_1,
              'color': const Color(0xFF4979FB),
              'date': hifdh['date'],
              'timestamp': hifdhTimestamp,
            });
          }
        }
      }
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('quizHistory')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          // Add completed reviews from quiz history
          for (var doc in snapshot.data!.docs) {
            var quizData = doc.data() as Map<String, dynamic>;
            if (quizData['quizContent'] != null &&
                quizData['quizContent'].isNotEmpty) {
              final reviewTimestamp = _parseDate(quizData['dateCompleted']);
              // Only add if the review date is not in the future
              if (!reviewTimestamp.isAfter(todayTimestamp)) {
                activities.add({
                  'type': 'review',
                  'title': 'Completed review',
                  'subtitle': quizData['quizContent'],
                  'icon': Iconsax.refresh,
                  'color': Colors.green,
                  'date': quizData['dateCompleted'],
                  'timestamp': reviewTimestamp,
                });
              }
            }
          }
        }

        // Sort activities by timestamp (most recent first)
        activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                spreadRadius: 1,
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            children: [
              if (activities.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activities.length > 3 ? 3 : activities.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withValues(alpha: 0.4),
                  ),
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(
                      title: activity['title'],
                      subtitle: activity['subtitle'],
                      icon: activity['icon'],
                      color: activity['color'],
                      date: activity['date'],
                      context: context,
                    );
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No recent activity',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              if (activities.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AllActivitiesPage(activities: activities),
                        ),
                      );
                    },
                    child: Text(
                      'See All Activities',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF4979FB),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  DateTime _parseDate(String dateStr) {
    final parts = dateStr.split('-');
    return DateTime(
      int.parse(parts[2]), // year
      int.parse(parts[1]), // month
      int.parse(parts[0]), // day
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String date,
    required BuildContext context,
  }) {
    List<String> dateParts = date.split('-');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${dateParts[0]}/${dateParts[1]}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class AllActivitiesPage extends StatelessWidget {
  final List<Map<String, dynamic>> activities;

  const AllActivitiesPage({
    super.key,
    required this.activities,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_2),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'All Activities',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: activities.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4),
        ),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return _buildActivityItem(
            title: activity['title'],
            subtitle: activity['subtitle'],
            icon: activity['icon'],
            color: activity['color'],
            date: activity['date'],
            context: context,
          );
        },
      ),
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String date,
    required BuildContext context,
  }) {
    List<String> dateParts = date.split('-');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${dateParts[0]}/${dateParts[1]}',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
