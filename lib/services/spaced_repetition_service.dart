import 'dart:math';

/// Status of a review result
enum ReviewStatus {
  success, // Item is mastered (3 consecutive correct)
  fail, // Item needs more practice (3 consecutive wrong)
  continue_, // Continue with next interval
}

/// Statistics for a review item
class ReviewStatistics {
  final int totalReviews;
  final int totalCorrect;
  final int totalWrong;
  final double successRate;
  final double averageRating;
  final int consecutiveCorrect;
  final int consecutiveWrong;
  final DateTime? firstReviewed;
  final DateTime? lastReviewed;

  ReviewStatistics({
    required this.totalReviews,
    required this.totalCorrect,
    required this.totalWrong,
    required this.successRate,
    required this.averageRating,
    required this.consecutiveCorrect,
    required this.consecutiveWrong,
    this.firstReviewed,
    this.lastReviewed,
  });

  /// Create statistics from a list of ratings
  factory ReviewStatistics.fromRatings(
    List<int> ratings, {
    DateTime? firstReviewed,
    DateTime? lastReviewed,
  }) {
    if (ratings.isEmpty) {
      return ReviewStatistics(
        totalReviews: 0,
        totalCorrect: 0,
        totalWrong: 0,
        successRate: 0.0,
        averageRating: 0.0,
        consecutiveCorrect: 0,
        consecutiveWrong: 0,
        firstReviewed: firstReviewed,
        lastReviewed: lastReviewed,
      );
    }

    final totalCorrect = ratings.where((r) => r >= 3).length;
    final totalWrong = ratings.where((r) => r < 3).length;
    final successRate = ratings.isEmpty ? 0.0 : totalCorrect / ratings.length;
    final averageRating = ratings.isEmpty
        ? 0.0
        : ratings.reduce((a, b) => a + b) / ratings.length;

    // Calculate consecutive correct/wrong from the end
    int consecutiveCorrect = 0;
    int consecutiveWrong = 0;

    for (int i = ratings.length - 1; i >= 0; i--) {
      if (ratings[i] >= 3) {
        consecutiveCorrect++;
        if (consecutiveWrong > 0) break;
      } else {
        consecutiveWrong++;
        if (consecutiveCorrect > 0) break;
      }
    }

    return ReviewStatistics(
      totalReviews: ratings.length,
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      successRate: successRate,
      averageRating: averageRating,
      consecutiveCorrect: consecutiveCorrect,
      consecutiveWrong: consecutiveWrong,
      firstReviewed: firstReviewed,
      lastReviewed: lastReviewed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'successRate': successRate,
      'averageRating': averageRating,
      'consecutiveCorrect': consecutiveCorrect,
      'consecutiveWrong': consecutiveWrong,
      'firstReviewed': firstReviewed?.toIso8601String(),
      'lastReviewed': lastReviewed?.toIso8601String(),
    };
  }
}

/// State of a review item in the spaced repetition system
class ReviewState {
  final int consecutiveCorrect;
  final double easeFactor;
  final int interval; // in days
  final List<int> ratings;
  final ReviewStatistics? statistics;

  ReviewState({
    required this.consecutiveCorrect,
    required this.easeFactor,
    required this.interval,
    required this.ratings,
    this.statistics,
  });

  /// Create ReviewState from the legacy array format
  /// Format: [consecutiveCorrect, easeFactor, interval]
  factory ReviewState.fromLegacyArray(List<dynamic> arr, {List<int>? ratings}) {
    if (arr.length < 3) {
      throw ArgumentError('Array must have at least 3 elements');
    }

    return ReviewState(
      consecutiveCorrect: arr[0] as int,
      easeFactor: (arr[1] as num).toDouble(),
      interval: arr[2] as int,
      ratings: ratings ?? [],
    );
  }

  /// Convert to legacy array format for backward compatibility
  /// Format: [consecutiveCorrect, easeFactor, interval]
  List<dynamic> toLegacyArray() {
    return [consecutiveCorrect, easeFactor, interval];
  }

  /// Create initial state for a new review
  factory ReviewState.initial() {
    return ReviewState(
      consecutiveCorrect: 0,
      easeFactor: 2.5, // Standard SM-2 starting EF
      interval: 1, // First review after 1 day
      ratings: [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'consecutiveCorrect': consecutiveCorrect,
      'easeFactor': easeFactor,
      'interval': interval,
      'ratings': ratings,
      'statistics': statistics?.toMap(),
    };
  }
}

/// Result of calculating the next review
class ReviewResult {
  final ReviewStatus status;
  final ReviewState newState;
  final int nextInterval;
  final ReviewStatistics statistics;

  ReviewResult({
    required this.status,
    required this.newState,
    required this.nextInterval,
    required this.statistics,
  });

  /// Convert to legacy format for backward compatibility
  /// Returns ['success'], ['fail'], or [consecutiveCorrect, EF, interval]
  List<dynamic> toLegacyFormat() {
    switch (status) {
      case ReviewStatus.success:
        return ['success'];
      case ReviewStatus.fail:
        return ['fail'];
      case ReviewStatus.continue_:
        return [
          newState.consecutiveCorrect,
          newState.easeFactor,
          nextInterval,
        ];
    }
  }
}

/// Spaced Repetition Service implementing SM-2 algorithm
///
/// This is an improved version of the SuperMemo 2 algorithm with:
/// - Better structure and documentation
/// - Statistics tracking
/// - Type safety
/// - Testability
/// - Backward compatibility with existing data format
class SpacedRepetitionService {
  // SM-2 algorithm constants
  static const double _minEaseFactor = 1.3;
  static const int _successThreshold = 3; // Consecutive correct needed
  static const int _failThreshold = 3; // Consecutive wrong needed
  static const int _firstInterval = 1; // Days until first review
  static const int _secondInterval =
      3; // Days until second review (if first is correct)

  /// Calculate the next review state based on the current rating
  ///
  /// [rating] should be 0-5 where:
  /// - 0-2: Wrong/Incorrect
  /// - 3-5: Correct (3=hard, 4=good, 5=easy)
  ///
  /// Returns ReviewResult with the new state and next interval
  ReviewResult calculateNextReview({
    required int rating,
    required ReviewState currentState,
    DateTime? reviewDate,
  }) {
    // Validate rating
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }

    // Create updated ratings list
    final updatedRatings = List<int>.from(currentState.ratings)..add(rating);

    // Calculate statistics
    final statistics = ReviewStatistics.fromRatings(
      updatedRatings,
      lastReviewed: reviewDate ?? DateTime.now(),
    );

    // Check if rating is correct (>= 3) or wrong (< 3)
    final isCorrect = rating >= 3;

    int newConsecutiveCorrect;
    int newConsecutiveWrong;
    double newEaseFactor;
    int newInterval;

    if (isCorrect) {
      // Correct answer
      newConsecutiveCorrect = currentState.consecutiveCorrect + 1;
      newConsecutiveWrong = 0;

      // Check for success (3 consecutive correct)
      if (newConsecutiveCorrect >= _successThreshold) {
        return ReviewResult(
          status: ReviewStatus.success,
          newState: ReviewState(
            consecutiveCorrect: newConsecutiveCorrect,
            easeFactor: currentState.easeFactor,
            interval: currentState.interval,
            ratings: updatedRatings,
            statistics: statistics,
          ),
          nextInterval: 0, // No more reviews needed
          statistics: statistics,
        );
      }

      // Update ease factor based on rating
      // Formula: EF = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      // where q is the quality (rating)
      final qualityAdjustment =
          0.1 - (5 - rating) * (0.08 + (5 - rating) * 0.02);
      newEaseFactor = currentState.easeFactor + qualityAdjustment;

      // Ensure minimum ease factor
      if (newEaseFactor < _minEaseFactor) {
        newEaseFactor = _minEaseFactor;
      }

      // Calculate new interval
      if (newConsecutiveCorrect == 1) {
        // First correct review: use fixed interval
        newInterval = _secondInterval;
      } else {
        // Subsequent reviews: multiply interval by ease factor
        newInterval = (currentState.interval * newEaseFactor).round();
      }
    } else {
      // Wrong answer
      newConsecutiveCorrect = 0;
      newConsecutiveWrong = statistics.consecutiveWrong;

      // Check for fail (3 consecutive wrong)
      if (newConsecutiveWrong >= _failThreshold) {
        return ReviewResult(
          status: ReviewStatus.fail,
          newState: ReviewState(
            consecutiveCorrect: 0,
            easeFactor: currentState.easeFactor,
            interval: _firstInterval,
            ratings: updatedRatings,
            statistics: statistics,
          ),
          nextInterval: _firstInterval,
          statistics: statistics,
        );
      }

      // Reset ease factor and interval for wrong answer
      newEaseFactor = currentState.easeFactor;
      // Reduce ease factor slightly
      newEaseFactor = max(_minEaseFactor, newEaseFactor - 0.2);
      newInterval = _firstInterval; // Reset to 1 day
    }

    return ReviewResult(
      status: ReviewStatus.continue_,
      newState: ReviewState(
        consecutiveCorrect: newConsecutiveCorrect,
        easeFactor: newEaseFactor,
        interval: newInterval,
        ratings: updatedRatings,
        statistics: statistics,
      ),
      nextInterval: newInterval,
      statistics: statistics,
    );
  }

  /// Calculate next review date from current date and interval
  DateTime calculateNextReviewDate(DateTime currentDate, int intervalDays) {
    return currentDate.add(Duration(days: intervalDays));
  }

  /// Get review priority based on how overdue it is
  /// Returns a priority score (higher = more urgent)
  double getReviewPriority({
    required DateTime scheduledDate,
    required DateTime currentDate,
    required double easeFactor,
    required int consecutiveCorrect,
  }) {
    final daysOverdue = currentDate.difference(scheduledDate).inDays;

    // Base priority increases with days overdue
    double priority = daysOverdue.toDouble();

    // Items that are harder (lower EF) get higher priority
    priority += (2.5 - easeFactor) * 2;

    // Items with fewer consecutive correct get higher priority
    priority += (3 - consecutiveCorrect) * 0.5;

    return priority;
  }

  /// Check if an item is mastered (has been reviewed successfully enough times)
  bool isMastered(ReviewState state) {
    return state.consecutiveCorrect >= _successThreshold &&
        state.statistics!.totalCorrect >= 3;
  }

  /// Get difficulty level as a string
  String getDifficultyLevel(double easeFactor) {
    if (easeFactor >= 2.5) return 'Easy';
    if (easeFactor >= 2.0) return 'Medium';
    if (easeFactor >= 1.5) return 'Hard';
    return 'Very Hard';
  }
}
