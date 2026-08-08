import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/services/distractor_service.dart';

List<String> _split(String verse) =>
    verse.split(' ').where((w) => w.trim().isNotEmpty).toList();

void main() {
  late DistractorService service;

  setUp(() {
    service = DistractorService(splitVerse: _split);
  });

  test('buildOptions always includes correct and caps at 6', () {
    final options = service.buildOptions(
      correctWord: 'يُوقِنُونَ',
      distractors: [
        'يَعْقِلُونَ',
        'يَتَفَكَّرُونَ',
        'يَعْلَمُونَ',
        'يَسْمَعُونَ',
        'يَنظُرُونَ',
        'extra1',
        'extra2',
      ],
    );

    expect(options.length, 6);
    expect(
      options.any((o) => DistractorService.normalize(o) ==
          DistractorService.normalize('يُوقِنُونَ')),
      isTrue,
    );
  });

  test('candidates come from neighbouring verses only', () {
    final verses = [
      'وَفِي خَلْقِكُمْ وَمَا يَبُثُّ',
      'وَاخْتِلَافِ ٱلَّيْلِ وَٱلنَّهَارِ لَءَايَتٌ لِّقَوْمٍ يَعْقِلُونَ',
      'تِلْكَ ءَايَتُ ٱللَّهِ نَتْلُوهَا',
    ];

    final candidates = service.buildCandidates(
      correctWord: 'يُوقِنُونَ',
      currentVerse: 'وَفِي خَلْقِكُمْ وَمَا يَبُثُّ مِن دَآبَّةٍ ءَايَتٌ لِّقَوْمٍ يُوقِنُونَ',
      verseIndex: 0,
      versesList: verses,
    );

    expect(candidates, isNotEmpty);
    expect(
      candidates.any((c) =>
          DistractorService.normalize(c) ==
          DistractorService.normalize('يُوقِنُونَ')),
      isFalse,
    );
    // Neighbour word should be available
    expect(
      candidates.any((c) =>
          DistractorService.normalize(c) ==
          DistractorService.normalize('يَعْقِلُونَ')),
      isTrue,
    );
  });
}
