import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/services/spaced_repetition_service.dart';

void main() {
  group('SpacedRepetitionService Tests', () {
    late SpacedRepetitionService service;

    setUp(() {
      service = SpacedRepetitionService();
    });

    test('should return success after 3 consecutive good ratings', () {
      // Start with 2 consecutive correct
      var state = ReviewState(
        consecutiveCorrect: 2,
        easeFactor: 2.0,
        interval: 5,
        ratings: [4, 5],
      );

      // Third correct rating should result in success
      final result = service.calculateNextReview(
        rating: 4,
        currentState: state,
      );

      expect(result.status, ReviewStatus.success);
      expect(result.nextInterval, 0);
    });

    test('should return fail after 3 consecutive wrong ratings', () {
      // Start with 2 consecutive wrong
      var state = ReviewState(
        consecutiveCorrect: 0,
        easeFactor: 2.0,
        interval: 1,
        ratings: [1, 2],
      );

      // Third wrong rating should result in fail
      final result = service.calculateNextReview(
        rating: 2,
        currentState: state,
      );

      expect(result.status, ReviewStatus.fail);
      expect(result.nextInterval, 1);
    });

    test('should calculate correct new interval for good rating', () {
      // Setup: already has 1 correct review
      final state = ReviewState(
        consecutiveCorrect: 1,
        easeFactor: 2.0,
        interval: 3,
        ratings: [4],
      );

      // Second good rating
      final result = service.calculateNextReview(
        rating: 5,
        currentState: state,
      );

      expect(result.status, ReviewStatus.continue_);
      expect(result.newState.consecutiveCorrect, 2);
      expect(result.nextInterval, greaterThan(3)); // Should be 3 * EF
    });

    test('should reset interval for poor rating', () {
      // Setup: has 2 consecutive correct
      final state = ReviewState(
        consecutiveCorrect: 2,
        easeFactor: 2.0,
        interval: 6,
        ratings: [4, 5],
      );

      // Wrong rating should reset
      final result = service.calculateNextReview(
        rating: 2,
        currentState: state,
      );

      expect(result.status, ReviewStatus.continue_);
      expect(result.newState.consecutiveCorrect, 0);
      expect(result.nextInterval, 1); // Reset to 1 day
    });

    test('should set interval to 3 for first good review', () {
      // Initial state
      final state = ReviewState.initial();

      // First good review
      final result = service.calculateNextReview(
        rating: 4,
        currentState: state,
      );

      expect(result.status, ReviewStatus.continue_);
      expect(result.newState.consecutiveCorrect, 1);
      expect(result.nextInterval, 3); // First interval is 3 days
    });

    test('should enforce minimum ease factor of 1.3', () {
      final state = ReviewState(
        consecutiveCorrect: 0,
        easeFactor: 1.31,
        interval: 1,
        ratings: [0, 1, 1],
      );

      // Very low rating
      final result = service.calculateNextReview(
        rating: 0,
        currentState: state,
      );

      expect(result.newState.easeFactor, greaterThanOrEqualTo(1.3));
    });

    test('should calculate statistics correctly', () {
      final state = ReviewState(
        consecutiveCorrect: 1,
        easeFactor: 2.0,
        interval: 3,
        ratings: [4, 3, 5],
      );

      final result = service.calculateNextReview(
        rating: 4,
        currentState: state,
      );

      expect(result.statistics.totalReviews, 4);
      expect(result.statistics.totalCorrect, 4); // All ratings >= 3
      expect(result.statistics.successRate, 1.0);
      expect(result.statistics.consecutiveCorrect, 2);
    });

    test('should work with legacy array format', () {
      // Legacy format: [consecutiveCorrect, EF, interval]
      final legacyArray = [1, 2.0, 3];
      final state = ReviewState.fromLegacyArray(legacyArray);

      expect(state.consecutiveCorrect, 1);
      expect(state.easeFactor, 2.0);
      expect(state.interval, 3);

      // Convert back to legacy format
      final convertedBack = state.toLegacyArray();
      expect(convertedBack, [1, 2.0, 3]);
    });

    test('should calculate next review date correctly', () {
      final currentDate = DateTime(2024, 1, 1);
      final nextDate = service.calculateNextReviewDate(currentDate, 5);

      expect(nextDate, DateTime(2024, 1, 6));
    });

    test('should calculate review priority correctly', () {
      final scheduledDate = DateTime.now().subtract(const Duration(days: 5));
      final currentDate = DateTime.now();

      final priority = service.getReviewPriority(
        scheduledDate: scheduledDate,
        currentDate: currentDate,
        easeFactor: 1.5, // Hard item
        consecutiveCorrect: 0, // Not mastered
      );

      expect(priority, greaterThan(0));
      // Harder items (lower EF) should have higher priority
    });

    test('should detect mastered items', () {
      final masteredState = ReviewState(
        consecutiveCorrect: 3,
        easeFactor: 2.5,
        interval: 10,
        ratings: [4, 5, 4],
        statistics: ReviewStatistics.fromRatings([4, 5, 4]),
      );

      expect(service.isMastered(masteredState), true);
    });

    test('should return correct difficulty level', () {
      expect(service.getDifficultyLevel(2.8), 'Easy');
      expect(service.getDifficultyLevel(2.3), 'Medium');
      expect(service.getDifficultyLevel(1.8), 'Hard');
      expect(service.getDifficultyLevel(1.3), 'Very Hard');
    });

    test('should handle edge case: empty ratings', () {
      final state = ReviewState.initial();

      final result = service.calculateNextReview(
        rating: 4,
        currentState: state,
      );

      expect(result.statistics.totalReviews, 1);
      expect(result.statistics.successRate, 1.0);
    });

    test('should maintain backward compatibility with legacy format', () {
      // Simulate the old way of calling
      final legacyState = [0, 2.0, 1]; // [consecutiveCorrect, EF, interval]
      final state = ReviewState.fromLegacyArray(legacyState);

      // Add rating at index 0 (old way)
      final rating = 4;
      final result = service.calculateNextReview(
        rating: rating,
        currentState: state,
      );

      // Convert to legacy format
      final legacyResult = result.toLegacyFormat();

      // Should return array format
      if (result.status == ReviewStatus.continue_) {
        expect(legacyResult.length, 3);
        expect(legacyResult[0], isA<int>()); // consecutiveCorrect
        expect(legacyResult[1], isA<double>()); // EF
        expect(legacyResult[2], isA<int>()); // interval
      }
    });
  });
}
