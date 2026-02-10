import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/notification_service.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';

/// One-time onboarding: ask new users if they want reminders and at what time.
class NotificationOnboardingPage extends StatefulWidget {
  final VoidCallback onComplete;

  const NotificationOnboardingPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<NotificationOnboardingPage> createState() =>
      _NotificationOnboardingPageState();
}

class _NotificationOnboardingPageState
    extends State<NotificationOnboardingPage> {
  bool _loading = true;
  bool _wantReminders = true;
  int _dailyHour = 8;
  int _dailyMinute = 0;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationService.instance.loadPreferences();
    if (!mounted) return;
    setState(() {
      _wantReminders = prefs.pushNotificationsEnabled &&
          prefs.taskReminderEnabled;
      _dailyHour = prefs.dailyNotificationHour;
      _dailyMinute = prefs.dailyNotificationMinute;
      _loading = false;
    });
  }

  String get _dailyTimeFormatted {
    final h = _dailyHour;
    final m = _dailyMinute;
    final padM = m.toString().padLeft(2, '0');
    if (h == 0) return '12:$padM AM';
    if (h < 12) return '$h:$padM AM';
    if (h == 12) return '12:$padM PM';
    return '${h - 12}:$padM PM';
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: _dailyHour.clamp(0, 23),
        minute: _dailyMinute.clamp(0, 59),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _dailyHour = picked.hour;
        _dailyMinute = picked.minute;
      });
    }
  }

  Future<void> _onContinue() async {
    if (_loading) return;

    final prefs = NotificationPreferences(
      pushNotificationsEnabled: _wantReminders,
      emailNotificationsEnabled: false,
      taskReminderEnabled: _wantReminders,
      eventAlertEnabled: _wantReminders,
      weeklySummaryEnabled: false,
      dailyNotificationHour: _dailyHour,
      dailyNotificationMinute: _dailyMinute,
      weeklySummaryWeekday: 1,
    );

    await NotificationService.instance.savePreferences(prefs);

    final prefsService =
        Provider.of<UserPreferencesService>(context, listen: false);
    await prefsService.completeNotificationOnboarding();

    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily reminders',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'We can remind you about your daily reading and memorisation.',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Do you want reminders?
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .tertiary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4979FB)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Iconsax.notification,
                                    size: 24,
                                    color: Color(0xFF4979FB),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Send me daily reminders',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Get a reminder at your chosen time',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _wantReminders,
                                  onChanged: (value) {
                                    setState(() => _wantReminders = value);
                                  },
                                  activeThumbColor: const Color(0xFF4979FB),
                                  inactiveThumbColor:
                                      Theme.of(context).colorScheme.tertiary,
                                ),
                              ],
                            ),
                          ),
                          if (_wantReminders) ...[
                            const SizedBox(height: 24),
                            Text(
                              'What time?',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Material(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .tertiary
                                            .withValues(alpha: 0.3),
                                        blurRadius: 12,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Iconsax.clock,
                                        size: 22,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        _dailyTimeFormatted,
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .inversePrimary,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Iconsax.arrow_right_3,
                                        size: 18,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4979FB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Continue',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            'You can change this anytime in Settings',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
