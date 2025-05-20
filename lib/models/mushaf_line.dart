class MushafLine {
  final int pageNumber;
  final int lineNumber;
  final String lineType;
  final bool isCentered;
  final String? firstWordId;
  final String? lastWordId;
  final String? surahNumber;

  MushafLine({
    required this.pageNumber,
    required this.lineNumber,
    required this.lineType,
    required this.isCentered,
    this.firstWordId,
    this.lastWordId,
    this.surahNumber,
  });

  factory MushafLine.fromMap(Map<String, dynamic> map) {
    return MushafLine(
      pageNumber: map['page_number'],
      lineNumber: map['line_number'],
      lineType: map['line_type'],
      isCentered: map['is_centered'] == 1,
      firstWordId: map['first_word_id']?.toString(),
      lastWordId: map['last_word_id']?.toString(),
      surahNumber: map['surah_number']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'page_number': pageNumber,
      'line_number': lineNumber,
      'line_type': lineType,
      'is_centered': isCentered ? 1 : 0,
      'first_word_id': firstWordId,
      'last_word_id': lastWordId,
      'surah_number': surahNumber,
    };
  }
}
