class Surah {
  final int id;
  final int number;
  final String nameSimple;
  final String nameArabic;
  final String revelationPlace;
  final int versesCount;
  final int startPage; // You'll need to add this from your layout data

  Surah({
    required this.id,
    required this.number,
    required this.nameSimple,
    required this.nameArabic,
    required this.revelationPlace,
    required this.versesCount,
    required this.startPage,
  });

  factory Surah.fromJson(Map<String, dynamic> json, int startPage) {
    return Surah(
      id: json['id'],
      number: json['name'],
      nameSimple: json['name_simple'],
      nameArabic: json['name_arabic'],
      revelationPlace: json['revelation_place'],
      versesCount: json['verses_count'],
      startPage: startPage,
    );
  }
}
