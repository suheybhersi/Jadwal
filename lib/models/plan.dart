import 'package:hifdh_planner_app/models/hifdh.dart';
import 'package:hifdh_planner_app/models/review.dart';

class Plan {
  final String name;
  final String start;
  final String end;
  final int lines;
  final List<bool> hifdhDays;
  final int pages;
  final List<bool> dailyReadingDays;
  final bool active;
  final int totalAjza;
  final int completedAjza;
  final List<Hifdh> hifdhs;
  final int hifdhIn;
  final List<Review> reviews;

  Plan({
    required this.name,
    required this.start,
    required this.end,
    required this.lines,
    required this.hifdhDays,
    required this.pages,
    required this.dailyReadingDays,
    required this.active,
    required this.totalAjza,
    required this.completedAjza,
    required this.hifdhs,
    required this.hifdhIn,
    required this.reviews,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'start': start,
      'end': end,
      'lines': lines,
      'hifdhDays': hifdhDays,
      'pages': pages,
      'dailyReadingDays': dailyReadingDays,
      'active': active,
      'totalAjza': totalAjza,
      'completedAjza': completedAjza,
      'hifdhs': hifdhs,
      'hifdhIn': hifdhIn,
      'reviews': reviews,
    };
  }
}
