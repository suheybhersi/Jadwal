import 'package:hifdh_planner_app/models/current_weekday.dart';
import 'package:hifdh_planner_app/models/hifdh.dart';
import 'package:hifdh_planner_app/models/review.dart';

class Plan {
  final bool backToFront;
  final String start;
  final String end;
  final int lines;
  final List<bool> hifdhDays;
  final double totalLines;
  final double completedLines;
  final List<Hifdh> hifdhs;
  final int hifdhIn;
  final List<Review> reviews;
  final int streak;
  final int missedReviews;
  final List<CurrentWeekDay> currentWeek;
  final bool planCompleted;

  Plan({
    required this.backToFront,
    required this.start,
    required this.end,
    required this.lines,
    required this.hifdhDays,
    required this.totalLines,
    required this.completedLines,
    required this.hifdhs,
    required this.hifdhIn,
    required this.reviews,
    required this.streak,
    required this.missedReviews,
    required this.currentWeek,
    required this.planCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'backToFront': backToFront,
      'start': start,
      'end': end,
      'lines': lines,
      'hifdhDays': hifdhDays,
      'totalLines': totalLines,
      'completedLines': completedLines,
      'hifdhs': hifdhs,
      'hifdhIn': hifdhIn,
      'reviews': reviews,
      'streak': streak,
      'missedReviews': missedReviews,
      'currentWeek': currentWeek,
      'planCompleted': planCompleted,
    };
  }
}
