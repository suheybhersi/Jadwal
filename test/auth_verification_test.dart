import 'package:flutter_test/flutter_test.dart';
import 'package:jadwal/utils/auth_verification.dart';

void main() {
  group('AuthVerification', () {
    test('grandfathers accounts created before the cutoff', () {
      expect(
        AuthVerification.createdRequiresVerification(
          DateTime.utc(2026, 8, 7),
        ),
        isFalse,
      );
      expect(
        AuthVerification.createdRequiresVerification(
          AuthVerification.requiredFrom.subtract(const Duration(seconds: 1)),
        ),
        isFalse,
      );
    });

    test('requires verification for accounts created on/after the cutoff', () {
      expect(
        AuthVerification.createdRequiresVerification(
          AuthVerification.requiredFrom,
        ),
        isTrue,
      );
      expect(
        AuthVerification.createdRequiresVerification(
          DateTime.utc(2026, 8, 9),
        ),
        isTrue,
      );
    });

    test('requires verification when creation time is unknown', () {
      expect(AuthVerification.createdRequiresVerification(null), isTrue);
    });
  });
}
