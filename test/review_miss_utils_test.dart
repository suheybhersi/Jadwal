import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/utils/review_miss_utils.dart';

void main() {
  group('ReviewMissUtils', () {
    test('applyMissPenaltyToSm2 resets streak and shortens interval', () {
      final next = ReviewMissUtils.applyMissPenaltyToSm2([2, 2.5, 10]);
      expect(next[0], 0);
      expect(next[1], closeTo(2.3, 0.001));
      expect(next[2], 1);
    });

    test('isNewHifdhBlocked at due threshold', () {
      final today = ReviewMissUtils.formatPlanDate(DateTime.now());
      final reviews = List.generate(
        5,
        (i) => {
          'date': today,
          'completed': false,
          'review': '1:$i-1:$i',
          'missCount': 0,
        },
      );
      expect(
        ReviewMissUtils.isNewHifdhBlocked({'reviews': reviews}),
        isTrue,
      );
      expect(
        ReviewMissUtils.isNewHifdhBlocked({
          'reviews': reviews.take(4).toList(),
        }),
        isFalse,
      );
    });

    test('isNewHifdhBlocked when one review missCount >= 3', () {
      final today = ReviewMissUtils.formatPlanDate(DateTime.now());
      final reviews = [
        {
          'date': today,
          'completed': false,
          'review': '2:1-2:5',
          'missCount': 3,
        },
      ];
      expect(
        ReviewMissUtils.isNewHifdhBlocked({'reviews': reviews}),
        isTrue,
      );
      expect(
        ReviewMissUtils.hasChronicallyMissedReview(reviews),
        isTrue,
      );
    });

    test('countBacklog ignores due today', () {
      final today = DateTime.now();
      final reviews = [
        {
          'date': ReviewMissUtils.formatPlanDate(today),
          'completed': false,
        },
        {
          'date': ReviewMissUtils.formatPlanDate(
            today.add(const Duration(days: 2)),
          ),
          'completed': false,
        },
      ];
      expect(ReviewMissUtils.countDueOrOverdue(reviews), 1);
      expect(ReviewMissUtils.countBacklog(reviews), 1);
    });
  });
}
