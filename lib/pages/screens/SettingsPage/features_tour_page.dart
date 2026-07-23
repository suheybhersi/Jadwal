import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

class FeaturesTourPage extends StatelessWidget {
  const FeaturesTourPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Features Tour',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.inversePrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4979FB).withValues(alpha: 0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Icon(
                      Iconsax.discover,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Discover Features',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Learn about all the features Jadwal has to offer',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Feature Cards
              _buildFeatureCard(
                context: context,
                icon: Iconsax.home,
                title: 'Home Dashboard',
                description:
                    'View your upcoming memorisation tasks, scheduled reviews, and weekly schedule. Tap any day to see detailed tasks.',
                color: const Color(0xFF4979FB),
                features: [
                  'Upcoming memorisation tasks',
                  'Scheduled reviews (Intensive mode)',
                  'Weekly calendar view',
                  'Quick access to daily tasks',
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.book_1,
                title: 'Digital Mushaf',
                description:
                    'Read and navigate through the complete Quran with authentic page layout. Perfect for memorisation and review.',
                color: const Color(0xFF10B981),
                features: [
                  'Complete Quran text',
                  'Authentic page layout',
                  'Easy navigation',
                  'Verse highlighting',
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.document_text,
                title: 'Interactive Quizzes',
                description:
                    'Test your memorisation with multiple question types. Create custom quizzes or take scheduled reviews.',
                color: const Color(0xFFEF4444),
                features: [
                  'Fill in the blank',
                  'Drag and drop',
                  'What comes next',
                  'Verse pairing',
                  'Build verse',
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.document_text,
                title: 'Plan Management',
                description:
                    'Create and manage your memorisation plan. Track progress, view completed memorisations, and edit your schedule.',
                color: const Color(0xFFF59E0B),
                features: [
                  'Custom start/end points',
                  'Flexible scheduling',
                  'Progress tracking',
                  'Plan editing',
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.profile_circle,
                title: 'Profile & Achievements',
                description:
                    'Track your progress, view achievements, and see detailed statistics about your memorisation journey.',
                color: const Color(0xFF8B5CF6),
                features: [
                  'Progress statistics',
                  'Achievement badges',
                  'Streak tracking',
                  'Performance insights',
                ],
              ),

              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                icon: Iconsax.setting,
                title: 'Customisation',
                description:
                    'Customise your experience with different memorisation modes, themes, and notification preferences.',
                color: const Color(0xFF6366F1),
                features: [
                  'Flexible or Intensive mode',
                  'Light/Dark theme',
                  'Notification settings',
                  'Profile management',
                ],
              ),

              const SizedBox(height: 30),

              // Quick Tips
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.info_circle,
                          color: const Color(0xFF4979FB),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Quick Tips',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4979FB),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTip(
                        'Tap on any day in "This Week" to see detailed tasks'),
                    _buildTip('Create custom quizzes from the Quiz page'),
                    _buildTip('Edit your plan anytime from the Plan page'),
                    _buildTip('View your achievements in the Profile page'),
                    _buildTip(
                        'Switch between Flexible and Intensive modes in Settings'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required List<String> features,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.tick_circle,
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF4979FB),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF4979FB),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
