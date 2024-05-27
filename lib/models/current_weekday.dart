class CurrentWeekDay {
  final String day;
  final bool isCompleted;
  final String weekStart;
  final String planId;

  CurrentWeekDay({
    required this.day,
    required this.isCompleted,
    required this.weekStart,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'day': day,
      'isCompleted': isCompleted,
      'weekStart': weekStart,
      'planId': planId,
    };
  }
}
