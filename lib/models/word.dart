class Word {
  final int wordIndex;
  final String text;
  final bool isSpecial;
  final String? lineType; // 'surah_name', 'basmallah', or null for regular
  final bool isCentered;

  // Keep original fields for backward compatibility
  final String location;
  final int surah;
  final int ayah;
  final int wordPosition;

  Word({
    required this.wordIndex,
    required this.text,
    this.isSpecial = false,
    this.lineType,
    this.isCentered = false,
    this.location = '',
    this.surah = 0,
    this.ayah = 0,
    this.wordPosition = 0,
  });

  // Add this factory method for special lines
  factory Word.special({
    required String text,
    required String lineType,
    bool isCentered = true,
  }) {
    return Word(
      wordIndex: lineType == 'surah_name' ? -1 : -2,
      text: text,
      isSpecial: true,
      lineType: lineType,
      isCentered: isCentered,
    );
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    // Parse location string in format "surah:ayah:position"
    String locationStr = map['location'] as String;
    List<String> locationParts = locationStr.split(':');

    int surah = 0;
    int ayah = 0;
    int wordPosition = 0;

    if (locationParts.length >= 3) {
      surah = int.tryParse(locationParts[0]) ?? 0;
      ayah = int.tryParse(locationParts[1]) ?? 0;
      wordPosition = int.tryParse(locationParts[2]) ?? 0;
    }

    return Word(
      wordIndex: map['word_index'] as int,
      location: locationStr,
      surah: surah,
      ayah: ayah,
      wordPosition: wordPosition,
      text: map['text'] as String,
      isSpecial: false,
      isCentered: false,
    );
  }
}
