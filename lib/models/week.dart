import 'package:jadwal/models/current_weekday.dart';

class Week {
  final String weekStart;
  final List<CurrentWeekDay> weekDays;
  final String planId;

  Week({
    required this.weekStart,
    required this.weekDays,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart,
      'weekdays': weekDays,
      'planId': planId,
    };
  }
}
