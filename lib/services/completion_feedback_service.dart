import 'package:flutter/material.dart';
import 'package:jadwal/components/celebration_widget.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';

/// Service to provide interactive feedback for completions
class CompletionFeedbackService {
  /// Show celebration for memorization completion
  static Future<void> showMemorizationCelebration({
    required BuildContext context,
    required String surah,
    required String verses,
    required int lines,
    required int streak,
    required double totalProgress,
  }) async {
    final prefsService =
        Provider.of<UserPreferencesService>(context, listen: false);

    // Build statistics list based on preferences
    final statistics = <StatisticItem>[
      StatisticItem(
        label: 'Lines Memorized',
        value: '$lines',
        icon: Iconsax.document,
      ),
      // Only show streak in Intensive mode
      if (prefsService.showStreaks)
        StatisticItem(
          label: 'Current Streak',
          value: '$streak days',
          icon: Iconsax.flash,
        ),
      StatisticItem(
        label: 'Total Progress',
        value: '${(totalProgress * 100).toStringAsFixed(1)}%',
        icon: Iconsax.chart,
      ),
    ];

    await showCelebrationDialog(
      context: context,
      title: 'Memorization Complete! 🎉',
      message: 'Great job! You\'ve memorized $surah $verses',
      subtitle: 'Keep up the excellent work!',
      icon: Iconsax.book_1,
      color: const Color(0xFF4979FB),
      statistics: statistics,
      continueText: 'Continue',
    );
  }

  /// Show celebration for review completion
  static Future<void> showReviewCelebration({
    required BuildContext context,
    required String status, // 'success', 'continue', or 'fail'
    required int nextInterval,
    required double successRate,
    required int consecutiveCorrect,
    String? surah,
  }) async {
    String title;
    String message;
    IconData icon;
    Color color;
    List<StatisticItem> statistics = [];

    if (status == 'success') {
      title = 'Review Mastered! 🌟';
      message = 'Excellent! This verse is now fully memorized.';
      icon = Iconsax.tick_circle;
      color = const Color(0xFF10B981); // Green
      statistics = [
        StatisticItem(
          label: 'Status',
          value: 'Mastered',
          icon: Iconsax.verify,
        ),
        StatisticItem(
          label: 'Success Rate',
          value: '${(successRate * 100).toStringAsFixed(0)}%',
          icon: Iconsax.chart_2,
        ),
      ];
    } else if (status == 'fail') {
      title = 'Keep Practicing 💪';
      message =
          'Don\'t worry! This verse has been rescheduled for more practice.';
      icon = Iconsax.refresh;
      color = const Color(0xFFF59E0B); // Orange
      statistics = [
        StatisticItem(
          label: 'Next Review',
          value: 'Rescheduled',
          icon: Iconsax.calendar,
        ),
        StatisticItem(
          label: 'Keep Going',
          value: 'You\'ve got this!',
          icon: Iconsax.heart,
        ),
      ];
    } else {
      title = 'Review Complete! ✅';
      message = 'Well done! Your next review is scheduled.';
      icon = Iconsax.refresh;
      color = const Color(0xFF4979FB); // Blue
      statistics = [
        StatisticItem(
          label: 'Next Review',
          value: nextInterval == 1 ? 'Tomorrow' : 'In $nextInterval days',
          icon: Iconsax.calendar_1,
        ),
        StatisticItem(
          label: 'Success Rate',
          value: '${(successRate * 100).toStringAsFixed(0)}%',
          icon: Iconsax.chart_2,
        ),
        StatisticItem(
          label: 'Consecutive Correct',
          value: '$consecutiveCorrect',
          icon: Iconsax.tick_circle,
        ),
      ];
    }

    await showCelebrationDialog(
      context: context,
      title: title,
      message: message,
      subtitle: surah != null ? 'Review: $surah' : null,
      icon: icon,
      color: color,
      statistics: statistics,
      continueText: 'Continue',
    );
  }

  /// Show celebration for quiz completion
  static Future<void> showQuizCelebration({
    required BuildContext context,
    required int score,
    required int totalQuestions,
    required double percentage,
    String? reviewTitle,
  }) async {
    String title;
    String message;
    IconData icon;
    Color color;

    if (percentage >= 90) {
      title = 'Outstanding! 🌟';
      message = 'Perfect score! You\'re doing amazing!';
      icon = Iconsax.star;
      color = const Color(0xFF10B981); // Green
    } else if (percentage >= 70) {
      title = 'Great Job! 🎉';
      message = 'Well done! Keep up the excellent work!';
      icon = Iconsax.tick_circle;
      color = const Color(0xFF4979FB); // Blue
    } else if (percentage >= 50) {
      title = 'Good Effort! 💪';
      message = 'Nice work! Keep practicing to improve!';
      icon = Iconsax.like;
      color = const Color(0xFFF59E0B); // Orange
    } else {
      title = 'Keep Practicing! 📚';
      message = 'Don\'t give up! Review and try again!';
      icon = Iconsax.refresh;
      color = const Color(0xFFEF4444); // Red
    }

    await showCelebrationDialog(
      context: context,
      title: title,
      message: message,
      subtitle: reviewTitle,
      icon: icon,
      color: color,
      statistics: [
        StatisticItem(
          label: 'Score',
          value: '$score / $totalQuestions',
          icon: Iconsax.document,
        ),
        StatisticItem(
          label: 'Percentage',
          value: '${percentage.toStringAsFixed(0)}%',
          icon: Iconsax.chart_2,
        ),
        StatisticItem(
          label: 'Performance',
          value: percentage >= 90
              ? 'Excellent'
              : percentage >= 70
                  ? 'Good'
                  : percentage >= 50
                      ? 'Fair'
                      : 'Needs Practice',
          icon: Iconsax.star,
        ),
      ],
      continueText: 'Continue',
    );
  }
}
