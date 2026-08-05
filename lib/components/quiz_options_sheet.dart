import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:jadwal/services/subscription_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';

/// Shows a modal bottom sheet with options for automatically generated quizzes
/// (e.g. review quizzes). Includes the "What comes next (Beta)" toggle.
void showQuizOptionsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Iconsax.setting_2,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  'Quiz options',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.inversePrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'For automatically generated review quizzes',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            Consumer2<UserPreferencesService, SubscriptionService>(
              builder: (context, prefs, sub, _) => Material(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  secondary: Icon(
                    Iconsax.arrow_right,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'What comes next',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).colorScheme.inversePrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: Colors.amber.shade700, width: 1),
                        ),
                        child: Text(
                          'Beta',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF4979FB).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF4979FB),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Pro',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF4979FB),
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      sub.isPro
                          ? 'Recitation-style questions. In testing — may be buggy.'
                          : 'Pro feature — upgrade to unlock speech quizzes.',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  value: sub.isPro && prefs.enableWhatComesNext,
                  onChanged: (value) async {
                    if (!sub.isPro) {
                      Navigator.pop(context);
                      await sub.openPaywall(context);
                      return;
                    }
                    await prefs.setEnableWhatComesNext(value);
                  },
                  activeThumbColor: const Color(0xFF4979FB),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
