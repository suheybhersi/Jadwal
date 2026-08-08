import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/utils/quran_text_utils.dart';

void main() {
  test('Rub el Hizb and sajda are non-spoken', () {
    expect(QuranTextUtils.isNonSpokenToken('۞'), isTrue);
    expect(QuranTextUtils.isNonSpokenToken('۩'), isTrue);
    expect(QuranTextUtils.isNonSpokenToken('ۚ'), isTrue);
    expect(QuranTextUtils.isNonSpokenToken('يَعْقِلُونَ'), isFalse);
  });

  test('speakableWords drops structural symbols', () {
    final words = QuranTextUtils.speakableWords([
      '۞',
      'وَسَخَّرَ',
      'ٱلْبَحْرَ',
      '۩',
      'يَعْقِلُونَ',
    ]);
    expect(words, ['وَسَخَّرَ', 'ٱلْبَحْرَ', 'يَعْقِلُونَ']);
  });
}
