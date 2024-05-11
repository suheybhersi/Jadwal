class Hifdh {
  final String hifdh;
  DateTime date;
  final bool completed;
  final String nextKey;
  final String planId;

  Hifdh({
    required this.hifdh,
    required this.date,
    required this.completed,
    required this.nextKey,
    required this.planId,
  });

  Map<String, dynamic> toMap() {
    return {
      'hifdh': hifdh,
      'date': date,
      'completed': completed,
      'nextKey': nextKey,
      'planId': planId,
    };
  }
}
