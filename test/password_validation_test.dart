import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/utils/password_validation.dart';

void main() {
  group('PasswordValidation', () {
    test('rejects short or incomplete passwords', () {
      expect(PasswordValidation.validate(null), isNotNull);
      expect(PasswordValidation.validate(''), isNotNull);
      expect(PasswordValidation.validate('short1A'), isNotNull);
      expect(PasswordValidation.validate('alllowercase1'), isNotNull);
      expect(PasswordValidation.validate('ALLUPPERCASE1'), isNotNull);
      expect(PasswordValidation.validate('NoDigitsHere'), isNotNull);
    });

    test('accepts strong enough passwords', () {
      expect(PasswordValidation.validate('GoodPass1'), isNull);
      expect(PasswordValidation.validate('GoodPass1!'), isNull);
    });

    test('strength score increases with complexity', () {
      expect(PasswordValidation.strengthScore(''), 0);
      expect(PasswordValidation.strengthScore('abcdefg'), lessThan(2));
      expect(
        PasswordValidation.strengthScore('GoodPass1!'),
        greaterThan(PasswordValidation.strengthScore('GoodPass1')),
      );
      expect(PasswordValidation.strengthScore('GoodPass1!'), 4);
    });

    test('confirm matches', () {
      expect(PasswordValidation.validateConfirm('a', 'b'), isNotNull);
      expect(PasswordValidation.validateConfirm('a', 'a'), isNull);
    });
  });
}
