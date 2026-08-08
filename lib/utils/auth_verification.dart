import 'package:firebase_auth/firebase_auth.dart';

/// Auth helpers for email verification gating.
class AuthVerification {
  AuthVerification._();

  /// Accounts created before this UTC time are not required to verify.
  /// New sign-ups on/after this release must verify.
  static final DateTime requiredFrom = DateTime.utc(2026, 8, 8, 5, 0);

  /// Whether an account created at [creationTime] must verify.
  static bool createdRequiresVerification(DateTime? creationTime) {
    if (creationTime == null) return true;
    return !creationTime.toUtc().isBefore(requiredFrom);
  }

  /// Whether this user must complete email verification before using the app.
  static bool requiresVerification(User user) {
    if (user.emailVerified) return false;
    return createdRequiresVerification(user.metadata.creationTime);
  }
}
