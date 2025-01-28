class Hifdh {
  final String hifdh;
  String date;
  final bool completed;
  final String nextKey;
  final String planId;
  final String surah;
  final String startVerse;
  final String endVerse;
  final double length;
  final List<dynamic> versesList;

  Hifdh({
    required this.hifdh,
    required this.date,
    required this.completed,
    required this.nextKey,
    required this.planId,
    required this.surah,
    required this.startVerse,
    required this.endVerse,
    required this.length,
    required this.versesList,
  });

  Map<String, dynamic> toMap() {
    return {
      'hifdh': hifdh,
      'date': date,
      'completed': completed,
      'nextKey': nextKey,
      'planId': planId,
      'surah': surah,
      'startVerse': startVerse,
      'endVerse': endVerse,
      'length': length,
      'versesList': versesList,
    };
  }
}
