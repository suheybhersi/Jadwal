import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jadwal/services/achievement_service.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final AchievementService achievementService = AchievementService(
      auth: FirebaseAuth.instance,
      uid: user!.uid,
    );

    // Ensure achievements document exists and update achievements
    achievementService.ensureAchievementsDocExists().then((_) {
      achievementService.checkAndUpdateAchievements();
    });

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Achievements',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('achievements')
            .doc('user_achievements')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4979FB)));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading achievements'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            // Wait for the document to be created
            return const Center(
                child: CircularProgressIndicator(color: Color(0xFF4979FB)));
          }

          final achievementsData =
              snapshot.data!.data() as Map<String, dynamic>;
          final achievements =
              achievementsData['achievements'] as Map<String, dynamic>? ?? {};

          // Define all achievements with their details, ordered by likely progression
          final allAchievements = [
            // First-time/early achievements
            _createAchievementData(
              id: 'firstVerses',
              title: 'First Verses',
              description: 'Memorize your first verses',
              requirements: 'Add at least one hifdh entry',
              progressData: {
                'current': achievementsData['totalHifdhs'] ?? 0,
                'target': 1,
              },
              icon: Iconsax.book_1,
              color: const Color(0xFF4979FB),
              difficulty: 1,
              isUnlocked: achievements['firstVerses'] ?? false,
            ),
            _createAchievementData(
              id: 'firstReview',
              title: 'First Review',
              description: 'Complete your first review session',
              requirements: 'Complete one review session',
              progressData: {
                'current': achievementsData['totalReviews'] ?? 0,
                'target': 1,
              },
              icon: Iconsax.refresh,
              color: Colors.green,
              difficulty: 1,
              isUnlocked: achievements['firstReview'] ?? false,
            ),
            _createAchievementData(
              id: 'firstQuiz',
              title: 'First Quiz',
              description: 'Complete your first quiz',
              requirements: 'Complete one quiz session',
              progressData: {
                'current': achievementsData['totalQuizzes'] ?? 0,
                'target': 1,
              },
              icon: Iconsax.message_question,
              color: Colors.deepPurple,
              difficulty: 1,
              isUnlocked: achievements['firstQuiz'] ?? false,
            ),
            _createAchievementData(
              id: 'oneWeek',
              title: '5 Days',
              description: 'Use the app for 5 days',
              requirements:
                  'Use the app for 5 days (not necessarily consecutive)',
              progressData: {
                'current': achievementsData['daysActive'] ?? 0,
                'target': 5,
              },
              icon: Iconsax.calendar,
              color: Colors.purple,
              difficulty: 1,
              isUnlocked: achievements['oneWeek'] ?? false,
            ),
            _createAchievementData(
              id: 'perfectScore',
              title: 'Perfect Score',
              description: 'Get a perfect score in a review session',
              requirements: 'Complete a review with 100% correct answers',
              progressData: {
                'current': achievementsData['perfectReviews'] ?? 0,
                'target': 1,
              },
              icon: Iconsax.star,
              color: Colors.amber,
              difficulty: 2,
              isUnlocked: achievements['perfectScore'] ?? false,
            ),
            _createAchievementData(
              id: 'quizMaster',
              title: 'Quiz Master',
              description: 'Score 100% on 3 different quizzes',
              requirements: 'Complete 3 different quizzes with perfect scores',
              progressData: {
                'current': achievementsData['perfectQuizzes'] ?? 0,
                'target': 3,
              },
              icon: Iconsax.award,
              color: Colors.deepPurple,
              difficulty: 3,
              isUnlocked: achievements['quizMaster'] ?? false,
            ),
            _createAchievementData(
              id: 'tenReviews',
              title: '10 Reviews',
              description: 'Complete 10 review sessions',
              requirements: 'Finish 10 review sessions of any type',
              progressData: {
                'current': achievementsData['totalReviews'] ?? 0,
                'target': 10,
              },
              icon: Iconsax.refresh_circle,
              color: Colors.green,
              difficulty: 3,
              isUnlocked: achievements['tenReviews'] ?? false,
            ),
            _createAchievementData(
              id: 'oneMonth',
              title: '10 Days',
              description: 'Use the app for 10 days',
              requirements:
                  'Use the app for 10 days (not necessarily consecutive)',
              progressData: {
                'current': achievementsData['daysActive'] ?? 0,
                'target': 10,
              },
              icon: Iconsax.calendar,
              color: Colors.purple,
              difficulty: 2,
              isUnlocked: achievements['oneMonth'] ?? false,
            ),
            _createAchievementData(
              id: 'progress25',
              title: '25% Complete',
              description: 'Complete 25% of your memorization plan',
              requirements: 'Reach 25% completion of your memorization plan',
              progressData: {
                'current': achievementsData['planProgress'] ?? 0,
                'target': 25,
                'isPercentage': true,
              },
              icon: Iconsax.chart,
              color: Colors.teal,
              difficulty: 4,
              isUnlocked: achievements['progress25'] ?? false,
            ),
            _createAchievementData(
              id: 'tenQuizzes',
              title: '10 Quizzes',
              description: 'Complete 10 quizzes',
              requirements: 'Finish 10 quiz sessions of any type',
              progressData: {
                'current': achievementsData['totalQuizzes'] ?? 0,
                'target': 10,
              },
              icon: Iconsax.message_question,
              color: Colors.deepPurple,
              difficulty: 4,
              isUnlocked: achievements['tenQuizzes'] ?? false,
            ),
            _createAchievementData(
              id: 'fiftyReviews',
              title: '50 Reviews',
              description: 'Complete 50 review sessions',
              requirements: 'Finish 50 review sessions of any type',
              progressData: {
                'current': achievementsData['totalReviews'] ?? 0,
                'target': 50,
              },
              icon: Iconsax.refresh_right_square,
              color: Colors.green,
              difficulty: 5,
              isUnlocked: achievements['fiftyReviews'] ?? false,
            ),
            _createAchievementData(
              id: 'threeMonths',
              title: '25 Days',
              description: 'Use the app for 25 days',
              requirements:
                  'Use the app for 25 days (not necessarily consecutive)',
              progressData: {
                'current': achievementsData['daysActive'] ?? 0,
                'target': 25,
              },
              icon: Iconsax.calendar_1,
              color: Colors.purple,
              difficulty: 3,
              isUnlocked: achievements['threeMonths'] ?? false,
            ),
            _createAchievementData(
              id: 'progress50',
              title: '50% Complete',
              description: 'Complete 50% of your memorization plan',
              requirements: 'Reach 50% completion of your memorization plan',
              progressData: {
                'current': achievementsData['planProgress'] ?? 0,
                'target': 50,
                'isPercentage': true,
              },
              icon: Iconsax.chart_1,
              color: Colors.teal,
              difficulty: 5,
              isUnlocked: achievements['progress50'] ?? false,
            ),
            _createAchievementData(
              id: 'twentyFiveQuizzes',
              title: '25 Quizzes',
              description: 'Complete 25 quizzes',
              requirements: 'Finish 25 quiz sessions of any type',
              progressData: {
                'current': achievementsData['totalQuizzes'] ?? 0,
                'target': 25,
              },
              icon: Iconsax.teacher,
              color: Colors.deepPurple,
              difficulty: 6,
              isUnlocked: achievements['twentyFiveQuizzes'] ?? false,
            ),
            _createAchievementData(
              id: 'progress75',
              title: '75% Complete',
              description: 'Complete 75% of your memorization plan',
              requirements: 'Reach 75% completion of your memorization plan',
              progressData: {
                'current': achievementsData['planProgress'] ?? 0,
                'target': 75,
                'isPercentage': true,
              },
              icon: Iconsax.chart_2,
              color: Colors.teal,
              difficulty: 6,
              isUnlocked: achievements['progress75'] ?? false,
            ),
            _createAchievementData(
              id: 'quizLegend',
              title: 'Quiz Legend',
              description: 'Achieve a perfect score on 10 quizzes',
              requirements: 'Complete 10 different quizzes with perfect scores',
              progressData: {
                'current': achievementsData['perfectQuizzes'] ?? 0,
                'target': 10,
              },
              icon: Iconsax.crown,
              color: Colors.deepPurple,
              difficulty: 7,
              isUnlocked: achievements['quizLegend'] ?? false,
            ),
            _createAchievementData(
              id: 'oneYear',
              title: '50 Days',
              description: 'Use the app for 50 days',
              requirements:
                  'Use the app for 50 days (not necessarily consecutive)',
              progressData: {
                'current': achievementsData['daysActive'] ?? 0,
                'target': 50,
              },
              icon: Iconsax.calendar_circle,
              color: Colors.purple,
              difficulty: 4,
              isUnlocked: achievements['oneYear'] ?? false,
            ),
            _createAchievementData(
              id: 'progress100',
              title: '100 Days',
              description: 'Use the app for 100 days',
              requirements:
                  'Use the app for 100 days (not necessarily consecutive)',
              progressData: {
                'current': achievementsData['daysActive'] ?? 0,
                'target': 100,
              },
              icon: Iconsax.calendar_circle,
              color: Colors.purple,
              difficulty: 5,
              isUnlocked: achievements['progress100'] ?? false,
            ),
          ];

          // Count unlocked achievements
          final int unlocked =
              allAchievements.where((a) => a['isUnlocked'] == true).length;
          final double percentage = unlocked / allAchievements.length * 100;

          // Sort achievements - unlocked first, then by difficulty
          allAchievements.sort((a, b) {
            // First sort by unlocked status
            if (a['isUnlocked'] != b['isUnlocked']) {
              return a['isUnlocked'] ? -1 : 1;
            }
            // Then sort by difficulty
            return (a['difficulty'] as int).compareTo(b['difficulty'] as int);
          });

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Achievement stats
                  _buildAchievementStats(
                      unlocked, allAchievements.length, percentage, context),
                  const SizedBox(height: 24),

                  // Single achievements grid
                  _buildAchievementGrid(allAchievements, context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _createAchievementData({
    required String id,
    required String title,
    required String description,
    required String requirements,
    required Map<String, dynamic> progressData,
    required IconData icon,
    required Color color,
    required int difficulty,
    required bool isUnlocked,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'requirements': requirements,
      'progressData': progressData,
      'icon': icon,
      'color': color,
      'difficulty': difficulty,
      'isUnlocked': isUnlocked,
    };
  }

  Widget _buildAchievementStats(
      int unlocked, int total, double percentage, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements Progress',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4979FB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: Colors.grey.shade200,
              color: const Color(0xFF4979FB),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$unlocked/$total Unlocked',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Iconsax.medal_star,
                    size: 16,
                    color: Color(0xFF4979FB),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Keep it up!',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementGrid(
      List<Map<String, dynamic>> achievements, BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.9,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        return _buildAchievementIcon(
          achievement: achievement,
          context: context,
        );
      },
    );
  }

  Widget _buildAchievementIcon({
    required Map<String, dynamic> achievement,
    required BuildContext context,
  }) {
    final bool isUnlocked = achievement['isUnlocked'];
    final Color color = achievement['color'];
    final IconData icon = achievement['icon'];

    return GestureDetector(
      onTap: () => _showAchievementDialog(achievement, context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: isUnlocked
                  ? color.withValues(alpha: 0.1)
                  : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isUnlocked ? color : Colors.grey,
              size: 70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            achievement['title'],
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isUnlocked
                  ? Theme.of(context).colorScheme.inversePrimary
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            isUnlocked ? Iconsax.tick_circle : Iconsax.lock,
            color: isUnlocked ? Colors.green : Colors.grey,
            size: 16,
          ),
        ],
      ),
    );
  }

  void _showAchievementDialog(
      Map<String, dynamic> achievement, BuildContext context) {
    final bool isUnlocked = achievement['isUnlocked'];
    final Color color = achievement['color'];
    final IconData icon = achievement['icon'];
    final Map<String, dynamic> progressData = achievement['progressData'];

    // Calculate progress percentage
    double current = progressData['current'].toDouble();
    double target = progressData['target'].toDouble();
    double? maxReached = progressData['maxReached']?.toDouble();

    // Use max reached value for streaks if higher than current
    if (maxReached != null && maxReached > current) {
      current = maxReached;
    }

    // Cap at 100%
    if (current > target) current = target;

    final double progressPercentage = target > 0 ? current / target : 0;
    final String progressText = progressData['isPercentage'] == true
        ? '${current.toStringAsFixed(1)}%/$target%'
        : '$current/$target';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? color.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isUnlocked ? color : Colors.grey,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  achievement['title'],
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  achievement['description'],
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requirements:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement['requirements'],
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress:',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          Text(
                            progressText,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isUnlocked
                                  ? Colors.green
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progressPercentage,
                          backgroundColor: Colors.grey.shade200,
                          color: isUnlocked ? Colors.green : color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Iconsax.tick_circle : Iconsax.lock,
                      color: isUnlocked ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isUnlocked ? 'Unlocked' : 'Locked',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isUnlocked ? Colors.green : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF4979FB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 45),
                  ),
                  child: Text(
                    'Close',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
