import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/ProfilePage/edit_profile_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';

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
        final displayName = '${userData['firstName'] ?? ''}'.trim();
        final username = userData['username'] ?? '';

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
          backgroundColor: Colors.white,
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
                                                  .withOpacity(0.7),
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
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.grey.shade100,
                                                  spreadRadius: 1,
                                                ),
                                              ],
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
                            _buildStatsOverview(plan),

                            const SizedBox(height: 24),

                            // Progress Overview section
                            _buildSectionHeader(
                                'Progress Overview', Iconsax.graph),
                            const SizedBox(height: 12),
                            _buildLearningStatsWidget(plan),

                            const SizedBox(height: 24),

                            // Achievements section
                            _buildSectionHeader(
                                'Achievements', Iconsax.medal_star),
                            const SizedBox(height: 12),
                            _buildAchievementsWidget(),

                            const SizedBox(height: 24),

                            // Recent Activity section
                            _buildSectionHeader(
                                'Recent Activity', Iconsax.activity),
                            const SizedBox(height: 12),
                            _buildRecentActivityWidget(plan),

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
              color: Colors.black87,
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

  Widget _buildSectionHeader(String title, IconData icon) {
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
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> plan) {
    // Calculate completion date
    final DateTime completionDate = _calculateDaysLeft(plan);
    final String formattedDate =
        "${completionDate.day}.${completionDate.month}.${completionDate.year.toString().substring(2)}";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
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
          ),
          _buildDivider(),
          _buildStatItem(
            value: '${plan['streak']}',
            label: 'Streak',
            icon: Iconsax.flash_1,
            color: Colors.orange,
          ),
          _buildDivider(),
          _buildStatItem(
            value:
                '${(plan['completedLines'] / plan['totalLines'] * 100).toStringAsFixed(1)}%',
            label: 'Completion Rate',
            icon: Iconsax.chart,
            color: Colors.blue,
          ),
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
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
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
            color: Colors.black87,
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

  Widget _buildDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.shade200,
    );
  }

  Widget _buildLearningStatsWidget(Map<String, dynamic> plan) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow(
            title: 'Completion Rate',
            value:
                '${(plan['completedLines'] / plan['totalLines'] * 100).toStringAsFixed(1)}%',
            icon: Iconsax.chart,
            color: const Color(0xFF4979FB),
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            title: 'Average Rating',
            value: '4.7/5',
            icon: Iconsax.star,
            color: Colors.amber,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            title: 'Completed Reviews',
            value: plan['reviews'] != null
                ? (plan['reviews'] is List
                    ? '${plan['reviews'].length}'
                    : '${plan['reviews']}')
                : '0',
            icon: Iconsax.clock,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementsWidget() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAchievementItem(
                title: '5 Day Streak',
                icon: Iconsax.flash_1,
                color: Colors.orange,
                isUnlocked: true,
              ),
              _buildAchievementItem(
                title: 'First Surah',
                icon: Iconsax.book_1,
                color: const Color(0xFF4979FB),
                isUnlocked: true,
              ),
              _buildAchievementItem(
                title: '1 Month',
                icon: Iconsax.calendar,
                color: Colors.purple,
                isUnlocked: false,
              ),
            ],
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () {
              // Navigate to full achievements page
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF4979FB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'View All Achievements',
              style: GoogleFonts.poppins(
                color: const Color(0xFF4979FB),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem({
    required String title,
    required IconData icon,
    required Color color,
    required bool isUnlocked,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUnlocked
                ? color.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
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
            color: isUnlocked ? Colors.black87 : Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentActivityWidget(Map<String, dynamic> plan) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 12,
          ),
        ],
      ),
      child: (plan['hifdhs'] != null && plan['hifdhs'].isNotEmpty)
          ? ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: plan['hifdhs'].length > 3 ? 3 : plan['hifdhs'].length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey.shade200,
              ),
              itemBuilder: (context, index) {
                final hifdh = plan['hifdhs'][plan['hifdhs'].length - 1 - index];
                return _buildActivityItem(
                  title: 'Memorized new verses',
                  subtitle:
                      '${hifdh['surah'].split(' ')[0]} ${hifdh['hifdh'].split('-')[0].split(':')[1]}-${hifdh['surah'].split(' ')[1] == hifdh['surah'].split(' ')[0] ? '' : hifdh['surah'].split(' ')[1]} ${hifdh['hifdh'].split('-')[1].split(':')[1]}',
                  icon: Iconsax.book_1,
                  color: const Color(0xFF4979FB),
                  date: hifdh['date'],
                );
              },
            )
          : Padding(
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
    );
  }

  Widget _buildActivityItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String date,
  }) {
    List<String> dateParts = date.split('-');
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
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
                    color: Colors.black87,
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
