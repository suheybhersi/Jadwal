class DailyReading {
  final String dailyReading;
  final String date;
  final bool completed;
  final int nextStart;
  final String planId;

  DailyReading({
    required this.dailyReading,
    required this.date,
    required this.completed,
    required this.nextStart,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'dailyReading': dailyReading,
      'date': date,
      'completed': completed,
      'nextStart': nextStart,
      'planId': planId,
    };
  }
}
