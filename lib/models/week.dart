import 'package:jadwal/models/current_weekday.dart';

class Week {
  final String weekStart;
  final List<CurrentWeekDay> weekDays;

  Week({
    required this.weekStart,
    required this.weekDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'weekStart': weekStart,
      'weekdays': weekDays,
    };
  }
}
