import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/pages/screens/SettingsPage/settings_page.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:iconsax/iconsax.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      resizeToAvoidBottomInset: true,
      body: ProgressContent(),
    );
  }
}

class ProgressContent extends StatefulWidget {
  const ProgressContent({super.key});

  @override
  State<ProgressContent> createState() => _ProgressContentState();
}

class _ProgressContentState extends State<ProgressContent> {
  final FirestoreService _firestoreService = FirestoreService(
    auth: FirebaseAuth.instance,
    uid: FirebaseAuth.instance.currentUser!.uid,
  );

  List<Map<String, dynamic>>? _cachedSurahData;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildTitleBar(context),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeaderBanner(),
                _buildSurahList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Title bar with settings button
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
            'Progress',
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
                  builder: (context) => const SettingsPage(),
                ),
              );
            },
            icon: const Icon(Iconsax.setting_2),
          ),
        ],
      ),
    );
  }

  // Header with gradient background
  SliverToBoxAdapter _buildHeaderBanner() {
    return SliverToBoxAdapter(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4979FB).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Iconsax.book_1, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Track Your Progress',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Keep track of how much you\'ve memorised for each surah',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surah List with StreamBuilder
  Widget _buildSurahList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getSurahProgressStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedSurahData == null) {
          return const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4979FB)),
            ),
          );
        }

        if (!snapshot.hasData && _cachedSurahData == null) {
          return _buildEmptyState(
            icon: Iconsax.information,
            message: 'No data available.',
          );
        }

        // Cache the data to prevent rebuilds
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final surahsList = snapshot.data!.docs;
          surahsList.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
          _cachedSurahData = surahsList
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        }

        final surahData = _cachedSurahData ?? [];

        return _buildSurahListItems(surahData);
      },
    );
  }

  // Empty state display
  SliverFillRemaining _buildEmptyState({
    required IconData icon,
    required String message,
  }) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey[400]),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Surah list items
  Widget _buildSurahListItems(List<Map<String, dynamic>> surahData) {
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final surah = surahData[index];
            return _SurahProgressCard(surah: surah);
          },
          childCount: surahData.length,
        ),
      ),
    );
  }
}

// Extracted widget for Surah progress card
class _SurahProgressCard extends StatelessWidget {
  final Map<String, dynamic> surah;

  const _SurahProgressCard({required this.surah});

  @override
  Widget build(BuildContext context) {
    final completedLines = surah['completedLines'].round();
    final totalLines = surah['totalLines'];
    final double progress = completedLines / totalLines;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.tertiary.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildSurahNumberBox(surah['surahNumber']),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surah['surah'],
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildProgressIndicator(progress, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Surah number box with gradient
  Widget _buildSurahNumberBox(dynamic surahNumber) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4979FB), Color(0xFF5C89FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      height: 40,
      width: 40,
      child: Center(
        child: Text(
          '$surahNumber',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // Progress indicator row
  Widget _buildProgressIndicator(double progress, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearPercentIndicator(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            lineHeight: 8,
            percent: progress > 1 ? 1 : progress,
            progressColor: const Color(0xFF4979FB),
            backgroundColor:
                Theme.of(context).colorScheme.inversePrimary.withOpacity(0.1),
            barRadius: const Radius.circular(20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0),
          child: Text(
            '${(progress > 1 ? 100 : progress * 100).toStringAsFixed(0)}%',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}
