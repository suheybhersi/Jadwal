import 'package:flutter_test/flutter_test.dart';

// A simplified version of the SM2 algorithm for testing
Future<List<dynamic>> sm2(
    Map<String, dynamic> review, List<dynamic> arr) async {
  List<dynamic> ratings = review['ratings'];

  int corrects = ratings.where((i) => i > 2).toList().length;
  int wrongs = ratings.where((i) => i < 3).toList().length;

  if (arr[0] >= 3) {
    corrects++;
    arr[1]++;
    if (corrects == 3) {
      return ['success'];
    }
    if (arr[1] == 1) {
      arr[3] = 3;
    } else {
      arr[3] = double.parse((arr[3] * arr[2]).toStringAsFixed(2));
    }
  } else {
    wrongs++;
    if (wrongs == 3) {
      return ['fail'];
    }
    arr[1] = 0;
    arr[3] = 1;
  }
  arr[2] =
      arr[2] + ((0.1 - (5 - arr[0]) * (0.08 + (5 - arr[0]) * 0.02)) * 0.75);
  if (arr[2] < 1.3) {
    arr[2] = 1.3;
  }
  return ([arr[1], arr[2], arr[3].truncate()]);
}

void main() {
  group('SM2 Algorithm Tests', () {
    test('should return success after 3 consecutive good ratings', () async {
      final review = {
        'ratings': [3, 4] // Already has 2 good ratings
      };
      // Input: [rating, consecutiveCorrect, EF, interval]
      final result = await sm2(review, [4, 2, 1.895, 3]);
      // Should return success when getting third consecutive good rating
      expect(result, ['success']);
    });

    test('should return fail after 3 poor ratings', () async {
      final review = {
        'ratings': [2, 1] // Already has 2 poor ratings
      };
      // Input: [rating, consecutiveCorrect, EF, interval]
      final result = await sm2(review, [2, 0, 1.895, 3]);
      expect(result, ['fail']);
    });

    test('should calculate correct new interval for good rating', () async {
      // Setup mock data
      final review = {
        'ratings': [3]
      };
      // Input: [rating, consecutiveCorrect, EF, interval]
      final result = await sm2(review, [5, 1, 1.895, 3]);
      // Expected: [consecutiveCorrect, EF, interval]
      expect(result[0], 2); // consecutiveCorrect increased
      expect(result[1], 1.97); // EF updated
      expect(result[2], 5); // New interval
    });

    test('should reset interval for poor rating', () async {
      final review = {
        'ratings': [3, 4]
      };
      // Input: [rating, consecutiveCorrect, EF, interval]
      final result = await sm2(review, [2, 2, 1.895, 5]);
      // Expected: [consecutiveCorrect, EF, interval]
      expect(result[0], 0); // consecutiveCorrect reset
      expect(result[1], 1.655); // EF reduced based on implementation
      expect(result[2], 1); // Interval reset to 1
    });

    test('should set interval to 3 for first good review', () async {
      final review = {'ratings': []};
      // Input: [rating, consecutiveCorrect, EF, interval]
      final result = await sm2(review, [4, 0, 2.0, 1]);
      // For first good review, interval should be set to 3 days
      expect(result[0], 1); // consecutiveCorrect becomes 1
      expect(result[1], 2.0); // EF based on implementation
      expect(result[2], 3); // Special case: first interval is 3
    });

    test('should enforce minimum EF of 1.3', () async {
      final review = {
        'ratings': [1, 1, 1]
      };
      // Input with very low rating to push EF below minimum
      final result = await sm2(review, [0, 0, 1.31, 1]);
      // EF should be capped at minimum value of 1.3
      expect(result[1], 1.3);
    });
  });
}
