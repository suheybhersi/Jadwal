/// Shared password rules for register and change-password.
class PasswordValidation {
  PasswordValidation._();

  static const int minLength = 8;

  static bool hasMinLength(String password) => password.length >= minLength;

  static bool hasUppercase(String password) =>
      password.contains(RegExp(r'[A-Z]'));

  static bool hasLowercase(String password) =>
      password.contains(RegExp(r'[a-z]'));

  static bool hasDigit(String password) => password.contains(RegExp(r'[0-9]'));

  static bool hasSpecial(String password) =>
      password.contains(RegExp(r'''[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/`]'''));

  /// Required checks (special char is optional but boosts strength).
  static bool meetsRequirements(String password) =>
      hasMinLength(password) &&
      hasUppercase(password) &&
      hasLowercase(password) &&
      hasDigit(password);

  /// 0–4 score for the strength meter.
  static int strengthScore(String password) {
    if (password.isEmpty) return 0;
    var score = 0;
    if (hasMinLength(password)) score++;
    if (hasUppercase(password) && hasLowercase(password)) score++;
    if (hasDigit(password)) score++;
    if (hasSpecial(password)) score++;
    // Cap weak passwords that only hit length.
    if (password.length < minLength) {
      return score.clamp(0, 1);
    }
    return score.clamp(0, 4);
  }

  static String strengthLabel(int score) {
    switch (score) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      default:
        return 'Strong';
    }
  }

  /// Form validator — returns error message or null.
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!hasMinLength(value)) {
      return 'Use at least $minLength characters';
    }
    if (!hasUppercase(value)) {
      return 'Include at least one uppercase letter';
    }
    if (!hasLowercase(value)) {
      return 'Include at least one lowercase letter';
    }
    if (!hasDigit(value)) {
      return 'Include at least one number';
    }
    return null;
  }

  static String? validateConfirm(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
