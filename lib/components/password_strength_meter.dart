import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/utils/password_validation.dart';

/// Live checklist + bar for password strength while typing.
class PasswordStrengthMeter extends StatelessWidget {
  const PasswordStrengthMeter({
    super.key,
    required this.password,
  });

  final String password;

  Color _barColor(int score) {
    switch (score) {
      case 0:
      case 1:
        return Colors.red.shade400;
      case 2:
        return Colors.orange.shade400;
      case 3:
        return const Color(0xFF4979FB);
      default:
        return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = PasswordValidation.strengthScore(password);
    final label = PasswordValidation.strengthLabel(score);
    final color = _barColor(score);
    final checks = <(String, bool)>[
      (
        'At least ${PasswordValidation.minLength} characters',
        PasswordValidation.hasMinLength(password),
      ),
      (
        'Upper & lowercase letters',
        PasswordValidation.hasUppercase(password) &&
            PasswordValidation.hasLowercase(password),
      ),
      ('A number', PasswordValidation.hasDigit(password)),
      ('A symbol (recommended)', PasswordValidation.hasSpecial(password)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: score / 4,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              password.isEmpty ? '' : label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: password.isEmpty ? Colors.transparent : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...checks.map((c) {
          final ok = c.$2;
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle : Icons.circle_outlined,
                  size: 14,
                  color: ok ? const Color(0xFF10B981) : Colors.grey.shade400,
                ),
                const SizedBox(width: 8),
                Text(
                  c.$1,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: ok ? Colors.grey.shade700 : Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
