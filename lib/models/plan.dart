import 'package:hifdh_planner_app/models/current_weekday.dart';
import 'package:hifdh_planner_app/models/daily_reading.dart';
import 'package:hifdh_planner_app/models/hifdh.dart';
import 'package:hifdh_planner_app/models/review.dart';

class Plan {
  final String name;
  final String start;
  final String end;
  final int lines;
  final List<bool> hifdhDays;
  final int pages;
  final int dailyReadingFrom;
  final int dailyReadingTo;
  final List<bool> dailyReadingDays;
  final List<DailyReading> dailyReadings;
  final bool active;
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
    required this.name,
    required this.start,
    required this.end,
    required this.lines,
    required this.hifdhDays,
    required this.pages,
    required this.dailyReadingFrom,
    required this.dailyReadingTo,
    required this.dailyReadingDays,
    required this.dailyReadings,
    required this.active,
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
      'name': name,
      'start': start,
      'end': end,
      'lines': lines,
      'hifdhDays': hifdhDays,
      'pages': pages,
      'dailyReadingFrom': dailyReadingFrom,
      'dailyReadingTo': dailyReadingTo,
      'dailyReadingDays': dailyReadingDays,
      'dailyReadings': dailyReadings,
      'active': active,
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
