import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Helpers for missed-review scheduling and soft-gating new memorisation.
class ReviewMissUtils {
  ReviewMissUtils._();

  /// Max incomplete reviews that may sit on "today".
  static const int dueTodayCap = 4;

  /// Incomplete reviews due today or earlier that block new hifdh (Intensive).
  static const int hifdhBlockThreshold = 5;

  /// A single review with this many misses blocks new memorisation.
  static const int perReviewMissBlockThreshold = 3;

  static const double minEaseFactor = 1.3;
  static const double missEasePenalty = 0.2;
  static const int missIntervalDays = 1;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime? parsePlanDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split('-');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  static String formatPlanDate(DateTime d) =>
      '${d.day}-${d.month}-${d.year}';

  static bool isIncomplete(Map<String, dynamic> review) =>
      review['completed'] != true;

  static int missCountOf(Map<String, dynamic> review) =>
      (review['missCount'] as num?)?.toInt() ?? 0;

  /// True when this incomplete review was skipped at least once.
  static bool wasMissed(Map<String, dynamic> review) =>
      isIncomplete(review) && missCountOf(review) > 0;

  static bool anyWasMissed(Iterable<dynamic> reviews) {
    for (final raw in reviews) {
      if (raw is! Map) continue;
      if (wasMissed(Map<String, dynamic>.from(raw))) return true;
    }
    return false;
  }

  /// Incomplete reviews with date ≤ today.
  static List<Map<String, dynamic>> dueOrOverdue(
    List<dynamic> reviews, {
    DateTime? now,
  }) {
    final today = dateOnly(now ?? DateTime.now());
    final result = <Map<String, dynamic>>[];
    for (final raw in reviews) {
      if (raw is! Map) continue;
      final review = Map<String, dynamic>.from(raw);
      if (!isIncomplete(review)) continue;
      final date = parsePlanDate(review['date']?.toString());
      if (date == null) continue;
      if (!date.isAfter(today)) {
        result.add(review);
      }
    }
    return result;
  }

  static int countDueOrOverdue(List<dynamic> reviews, {DateTime? now}) =>
      dueOrOverdue(reviews, now: now).length;

  /// True if any incomplete review has been skipped enough times.
  static bool hasChronicallyMissedReview(List<dynamic> reviews) {
    for (final raw in reviews) {
      if (raw is! Map) continue;
      final review = Map<String, dynamic>.from(raw);
      if (!isIncomplete(review)) continue;
      if (missCountOf(review) >= perReviewMissBlockThreshold) return true;
    }
    return false;
  }

  static bool isNewHifdhBlocked(Map<String, dynamic> plan, {DateTime? now}) {
    final reviews = plan['reviews'];
    if (reviews is! List) return false;
    return countDueOrOverdue(reviews, now: now) >= hifdhBlockThreshold ||
        hasChronicallyMissedReview(reviews);
  }

  /// Prefer chronic-miss copy when that is the reason for the lock.
  static String hifdhBlockMessage(Map<String, dynamic> plan, {DateTime? now}) {
    final reviews = plan['reviews'];
    if (reviews is! List) {
      return 'Clear some reviews before adding more memorisation.';
    }
    if (hasChronicallyMissedReview(reviews)) {
      return 'A review has been skipped too many times. '
          'Complete your overdue reviews before memorising more.';
    }
    final due = countDueOrOverdue(reviews, now: now);
    return 'Clear some reviews before adding more memorisation. '
        '$due due right now.';
  }

  /// Incomplete reviews scheduled after today (backlog).
  static int countBacklog(List<dynamic> reviews, {DateTime? now}) {
    final today = dateOnly(now ?? DateTime.now());
    var count = 0;
    for (final raw in reviews) {
      if (raw is! Map) continue;
      final review = Map<String, dynamic>.from(raw);
      if (!isIncomplete(review)) continue;
      final date = parsePlanDate(review['date']?.toString());
      if (date == null) continue;
      if (date.isAfter(today)) count++;
    }
    return count;
  }

  /// Apply skip penalty to SM-2 state: `[consecutiveCorrect, EF, interval]`.
  static List<dynamic> applyMissPenaltyToSm2(List<dynamic>? sm2) {
    final next = List<dynamic>.from(sm2 ?? [0, 2.5, 1]);
    while (next.length < 3) {
      next.add(next.length == 1 ? 2.5 : 1);
    }
    next[0] = 0;
    final ef = (next[1] as num?)?.toDouble() ?? 2.5;
    next[1] = max(minEaseFactor, ef - missEasePenalty);
    next[2] = missIntervalDays;
    return next;
  }
}

/// Small pill for reviews that were skipped and rescheduled.
class MissedReviewTag extends StatelessWidget {
  const MissedReviewTag({super.key, this.onDark = false});

  /// Use on green Home cards where the background is already dark.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.orange.shade800.withValues(alpha: 0.9)
            : Colors.orange.shade100,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: onDark ? Colors.orange.shade200 : Colors.orange.shade700,
          width: 1,
        ),
      ),
      child: Text(
        'Missed',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: onDark ? Colors.white : Colors.orange.shade900,
        ),
      ),
    );
  }
}
