import 'package:flutter/material.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_creation_page.dart';
import 'package:jadwal/pages/screens/QuizPage/quiz_history_details_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/components/pro_upgrade_banner.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/subscription_service.dart';

class QuizHomePage extends StatefulWidget {
  const QuizHomePage({super.key});

  @override
  State<QuizHomePage> createState() => _QuizHomePageState();
}

class _QuizHomePageState extends State<QuizHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<QueryDocumentSnapshot>> _customQuizStream;
  late Stream<List<QueryDocumentSnapshot>> _reviewQuizStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _openCreateQuiz() async {
    final sub = Provider.of<SubscriptionService>(context, listen: false);
    final allowed = await sub.ensureHasQuizQuota(context);
    if (!allowed || !mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QuizCreationPage(),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    try {
      final firestoreService = Provider.of<FirestoreService>(context);
      _customQuizStream = firestoreService.getCustomQuizHistoryStream();
      _reviewQuizStream = firestoreService.getReviewQuizHistoryStream();
    } catch (e) {
      debugPrint('Error initializing quiz history streams: $e');
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
          const ProUpgradeBanner(
            compact: true,
            title: 'Go Pro for unlimited quizzes',
            margin: EdgeInsets.fromLTRB(20, 0, 20, 12),
          ),
          _buildTabBar(),
          const SizedBox(height: 8),
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

  Widget _buildTitleBar(BuildContext context) {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quizzes',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Consumer<SubscriptionService>(
                  builder: (context, sub, _) {
                    if (sub.isPro) {
                      return Text(
                        'Pro · unlimited',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: kAuthBrandBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    }
                    return GestureDetector(
                      onTap: () => sub.openPaywall(context),
                      child: Text(
                        '${sub.quizzesRemainingToday} of ${SubscriptionService.freeQuizzesPerDay} free left today · Upgrade',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Material(
            color: kAuthBrandBlue,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: _openCreateQuiz,
              borderRadius: BorderRadius.circular(14),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Iconsax.add, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: kAuthBrandBlue,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: textColor,
        labelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: const [
          Tab(
            height: 40,
            child: Text('Review'),
          ),
          Tab(
            height: 40,
            child: Text('Custom'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? action,
    String? actionLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: kAuthBrandBlue.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: kAuthBrandBlue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: 200,
                child: AuthPrimaryButton(
                  label: actionLabel,
                  onPressed: action,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomQuizHistory() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _customQuizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kAuthBrandBlue),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error in custom quiz stream: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading quiz history',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.clipboard_text,
            title: 'No custom quizzes yet',
            subtitle: 'Build a quiz on any verses whenever you want extra practice.',
            action: _openCreateQuiz,
            actionLabel: 'Create Quiz',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final quizData =
                snapshot.data![index].data() as Map<String, dynamic>;
            return _buildQuizHistoryCard(quizData);
          },
        );
      },
    );
  }

  Widget _buildReviewQuizHistory() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _reviewQuizStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: kAuthBrandBlue),
          );
        }

        if (snapshot.hasError) {
          debugPrint('Error in review quiz stream: ${snapshot.error}');
          return Center(
            child: Text(
              'Error loading review history',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(
            icon: Iconsax.refresh,
            title: 'No review quizzes yet',
            subtitle:
                'Complete a scheduled review and your quiz history will show up here.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final quizData =
                snapshot.data![index].data() as Map<String, dynamic>;
            return _buildQuizHistoryCard(quizData);
          },
        );
      },
    );
  }

  Widget _buildQuizHistoryCard(Map<String, dynamic> quizData) {
    final score = quizData['score'] ?? 0;
    final totalQuestions = quizData['totalQuestions'] ?? 1;
    final percentage = (score / totalQuestions) * 100;
    final date = quizData['dateCompleted'] ?? 'Unknown date';
    final questions = quizData['questions'] ?? [];
    final answeredQuestions = quizData['answeredQuestions'] ?? {};
    final quizId = quizData['quizId'] ?? '';
    final isCustomQuiz = quizData['isCustomQuiz'] ?? false;
    final quizContent = quizData['quizContent'] ?? '';

    final Color resultColor;
    if (percentage >= 90) {
      resultColor = const Color(0xFF10B981);
    } else if (percentage >= 70) {
      resultColor = kAuthBrandBlue;
    } else if (percentage >= 50) {
      resultColor = const Color(0xFFD97706);
    } else {
      resultColor = const Color(0xFFDC2626);
    }

    final displayTitle = quizContent.isNotEmpty
        ? quizContent
        : isCustomQuiz
            ? 'Custom Quiz'
            : 'Review Quiz';

    final textColor = Theme.of(context).colorScheme.inversePrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizHistoryDetailsPage(
                  score: score,
                  questions: List<Map<String, dynamic>>.from(questions),
                  quizId: quizId,
                  answeredQuestions: Map<int, Map<String, dynamic>>.from(
                    answeredQuestions.map(
                      (key, value) => MapEntry(
                        int.parse(key),
                        Map<String, dynamic>.from(value),
                      ),
                    ),
                  ),
                  isCustomQuiz: isCustomQuiz,
                  date: date,
                  quizContent: quizContent,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: resultColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$score/$totalQuestions',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: resultColor,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayTitle,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        date,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
