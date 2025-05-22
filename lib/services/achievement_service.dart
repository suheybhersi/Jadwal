import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jadwal/services/firestore.dart';

class AchievementService {
  final FirebaseAuth auth;
  final String uid;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final FirestoreService _firestoreService;

  AchievementService({required this.auth, required this.uid}) {
    _firestoreService = FirestoreService(
      auth: auth,
      uid: uid,
    );
  }

  // Reference to the user document
  DocumentReference get userDocument => _firestore.collection('users').doc(uid);

  // Reference to the achievements collection
  CollectionReference get achievementsCollection =>
      userDocument.collection('achievements');

  // Reference to the user's achievements document
  DocumentReference get achievementDocument =>
      achievementsCollection.doc('user_achievements');

  // Ensure achievements document exists
  Future<void> ensureAchievementsDocExists() async {
    try {
      DocumentSnapshot docSnapshot = await achievementDocument.get();
      if (!docSnapshot.exists) {
        // Create the document with initial values
        await achievementDocument.set({
          'totalHifdhs': 0,
          'totalReviews': 0,
          'totalQuizzes': 0,
          'completedSurahs': 0,
          'planProgress': 0.0,
          'perfectReviews': 0,
          'perfectQuizzes': 0,
          'achievements': {},
          'lastActive': Timestamp.now(),
          'currentStreak': 0,
          'maxStreak': 0,
          'daysActive': 0,
        });
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  // Get the user's plan data
  Future<Map<String, dynamic>?> getPlanData() async {
    try {
      // Use the existing FirestoreService to get plans
      final plansSnapshot = await _firestoreService.getPlansStream().first;

      if (plansSnapshot.docs.isNotEmpty) {
        return plansSnapshot.docs.first.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      throw Exception(e);
    }
  }

  // Check all achievements and update them if the criteria are met
  Future<void> checkAndUpdateAchievements() async {
    try {
      // Ensure the achievements document exists before proceeding
      await ensureAchievementsDocExists();

      final userDoc = await userDocument.get();
      if (!userDoc.exists) {
        return;
      }

      final planData = await getPlanData();
      if (planData == null) {
        return;
      }

      // Get achievements document
      final achievementsDoc = await achievementDocument.get();
      if (!achievementsDoc.exists) {
        // Document should exist at this point, but check just in case
        await ensureAchievementsDocExists();
        return;
      }

      final achievementsData = achievementsDoc.data() as Map<String, dynamic>;

      // Initialize achievements map if it doesn't exist
      Map<String, dynamic> achievements =
          achievementsData['achievements'] as Map<String, dynamic>? ?? {};
      bool achievementsUpdated = false;

      // Get all the user stats we need for achievement checks
      final hifdhs = planData['hifdhs'] ?? [];
      final reviews = planData['reviews'] ?? [];

      // Get quiz history from the quiz history collection
      final quizHistorySnapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('quizHistory')
          .get();
      final quizzes =
          quizHistorySnapshot.docs.map((doc) => doc.data()).toList();

      final int totalHifdhs = hifdhs is List ? hifdhs.length : 0;
      final int totalReviews = reviews is List ? reviews.length : 0;
      final int totalQuizzes = quizzes.length;

      final int daysActive = achievementsData['daysActive'] ?? 0;

      // Calculate plan progress
      final double completedLines = planData['completedLines'] ?? 0;
      final double totalLines =
          planData['totalLines'] ?? 1; // Avoid division by zero
      final double planProgress =
          (completedLines / totalLines * 100).clamp(0, 100);

      // Count completed surahs
      final List<String> completedSurahs = _getCompletedSurahs(planData);

      // Count perfect scores
      final int perfectReviews = _countPerfectReviews(reviews);
      final int perfectQuizzes = _countPerfectQuizzes(quizzes);

      // Store all calculated values for UI use
      await achievementDocument.update({
        'totalHifdhs': totalHifdhs,
        'totalReviews': totalReviews,
        'totalQuizzes': totalQuizzes,
        'completedSurahs': completedSurahs.length,
        'planProgress': planProgress,
        'perfectReviews': perfectReviews,
        'perfectQuizzes': perfectQuizzes,
      });

      // Check and update achievement status

      // First verses achievement
      if (!(achievements['firstVerses'] == true) && totalHifdhs > 1) {
        achievements['firstVerses'] = true;
        achievementsUpdated = true;
      }

      // First review achievement
      if (!(achievements['firstReview'] == true) && totalReviews > 0) {
        achievements['firstReview'] = true;
        achievementsUpdated = true;
      }

      // First quiz achievement
      if (!(achievements['firstQuiz'] == true) && totalQuizzes > 0) {
        achievements['firstQuiz'] = true;
        achievementsUpdated = true;
      }

      // Days active achievements
      if (!(achievements['oneWeek'] == true) && daysActive >= 5) {
        achievements['oneWeek'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['oneMonth'] == true) && daysActive >= 10) {
        achievements['oneMonth'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['threeMonths'] == true) && daysActive >= 25) {
        achievements['threeMonths'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['oneYear'] == true) && daysActive >= 50) {
        achievements['oneYear'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['progress100'] == true) && daysActive >= 100) {
        achievements['progress100'] = true;
        achievementsUpdated = true;
      }

      // Perfect score achievements
      if (!(achievements['perfectScore'] == true) && perfectReviews > 0) {
        achievements['perfectScore'] = true;
        achievementsUpdated = true;
      }

      // Review count achievements
      if (!(achievements['tenReviews'] == true) && totalReviews >= 10) {
        achievements['tenReviews'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['fiftyReviews'] == true) && totalReviews >= 50) {
        achievements['fiftyReviews'] = true;
        achievementsUpdated = true;
      }

      // Quiz achievements
      if (!(achievements['quizMaster'] == true) && perfectQuizzes >= 3) {
        achievements['quizMaster'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['tenQuizzes'] == true) && totalQuizzes >= 10) {
        achievements['tenQuizzes'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['twentyFiveQuizzes'] == true) && totalQuizzes >= 25) {
        achievements['twentyFiveQuizzes'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['quizLegend'] == true) && perfectQuizzes >= 10) {
        achievements['quizLegend'] = true;
        achievementsUpdated = true;
      }

      // Progress achievements
      if (!(achievements['progress25'] == true) && planProgress >= 25) {
        achievements['progress25'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['progress50'] == true) && planProgress >= 50) {
        achievements['progress50'] = true;
        achievementsUpdated = true;
      }

      if (!(achievements['progress75'] == true) && planProgress >= 75) {
        achievements['progress75'] = true;
        achievementsUpdated = true;
      }

      // Update achievements in Firestore if any changes
      if (achievementsUpdated) {
        await achievementDocument.update({'achievements': achievements});
      }
    } catch (e) {
      throw Exception(e);
    }
  }

  // Helper method to count perfect review scores
  int _countPerfectReviews(dynamic reviews) {
    if (reviews is! List) return 0;

    int count = 0;
    for (final review in reviews) {
      if (review is Map<String, dynamic> && (review['ratings'].contains(5))) {
        count++;
      }
    }
    return count;
  }

  // Helper method to count perfect quiz scores
  int _countPerfectQuizzes(dynamic quizzes) {
    if (quizzes is! List) {
      return 0;
    }

    int count = 0;
    for (final quiz in quizzes) {
      if (quiz is Map<String, dynamic> &&
          quiz['score'] != null &&
          quiz['totalQuestions'] != null) {
        // Calculate percentage score
        final score = quiz['score'] as int;
        final totalQuestions = quiz['totalQuestions'] as int;
        final percentage = (score / totalQuestions) * 100;

        // Count as perfect if score is 100%
        if (percentage == 100) {
          count++;
        }
      }
    }
    return count;
  }

  // Helper method to get list of completed surahs
  List<String> _getCompletedSurahs(Map<String, dynamic> planData) {
    final completedSurahs = <String>{};
    final List<dynamic> hifdhs = planData['hifdhs'] ?? [];

    // Track which verses of each surah have been memorized
    final surahs = <String, Set<int>>{};

    for (final hifdh in hifdhs) {
      if (hifdh is Map<String, dynamic>) {
        final String? surahName = hifdh['surah'];
        final String? verseRange = hifdh['hifdh'];

        if (surahName != null && verseRange != null) {
          final surahParts = surahName.split(' ');
          if (surahParts.length < 2) continue;

          final String surah = surahParts[1]; // Extract the Surah number

          // Parse verse range (format: verse:1-verse:5)
          final parts = verseRange.split('-');
          if (parts.length != 2) continue;

          final startVerse = int.tryParse(parts[0].split(':').last);
          final endVerse = int.tryParse(parts[1].split(':').last);

          if (startVerse != null && endVerse != null) {
            if (!surahs.containsKey(surah)) {
              surahs[surah] = {};
            }

            // Add all verses in range
            for (int i = startVerse; i <= endVerse; i++) {
              surahs[surah]!.add(i);
            }
          }
        }
      }
    }

    // Check if the surah is complete (this is a simplified check)
    // In a real app, you'd compare with the total verses in each surah
    for (final entry in surahs.entries) {
      final verseCount = _getSurahVerseCount(entry.key);
      if (entry.value.length >= verseCount) {
        completedSurahs.add(entry.key);
      }
    }

    return completedSurahs.toList();
  }

  // Get the verse count for each surah (simplified)
  int _getSurahVerseCount(String surahNumber) {
    // This is a simplified implementation
    // In a real app, you'd have the actual verse counts for each surah
    final Map<String, int> surahVerseCounts = {
      '1': 7, // Al-Fatiha
      '2': 286, // Al-Baqarah
      '3': 200, // Ali 'Imran
      '4': 176, // An-Nisa
      '5': 120, // Al-Ma'idah
      // Add more surahs as needed
    };

    return surahVerseCounts[surahNumber] ?? 100; // Default to 100 if not found
  }

  // Method to update the user's active days and streak
  Future<void> updateUserActivity() async {
    try {
      // Ensure the achievements document exists
      await ensureAchievementsDocExists();

      final achievementsDoc = await achievementDocument.get();
      if (!achievementsDoc.exists) {
        // Document should exist at this point, but check just in case
        return;
      }

      final achievementsData = achievementsDoc.data() as Map<String, dynamic>;

      final Timestamp lastActive =
          achievementsData['lastActive'] ?? Timestamp.now();
      final int currentStreak = achievementsData['currentStreak'] ?? 0;
      final int maxStreak = achievementsData['maxStreak'] ?? 0;
      final int daysActive = achievementsData['daysActive'] ?? 0;

      final now = DateTime.now();
      final lastActiveDate = lastActive.toDate();
      final difference = now.difference(lastActiveDate).inDays;

      // Update data to track
      Map<String, dynamic> updateData = {
        'lastActive': Timestamp.now(),
      };

      // Check if it's a new day (more than 12 hours since last activity)
      if (difference >= 1) {
        // Increment days active
        updateData['daysActive'] = daysActive + 1;

        // Update streak
        if (difference == 1) {
          // Consecutive day
          updateData['currentStreak'] = currentStreak + 1;
          if (currentStreak + 1 > maxStreak) {
            updateData['maxStreak'] = currentStreak + 1;
          }
        } else {
          // Streak broken
          updateData['currentStreak'] = 1;
        }
      }

      await achievementDocument.update(updateData);
    } catch (e) {
      throw Exception(e);
    }
  }
}
