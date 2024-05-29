class CurrentWeekDay {
  final String day;
  final bool completed;
  final bool missed;
  final String weekStart;
  final String planId;

  CurrentWeekDay({
    required this.day,
    required this.completed,
    required this.missed,
    required this.weekStart,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'completed': completed,
      'missed': missed,
      'weekStart': weekStart,
      'planId': planId,
    };
  }
}
