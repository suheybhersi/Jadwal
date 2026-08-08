import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/onboarding_ui.dart';
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

  static const _presets = <({String label, String hint, int hour, int minute})>[
    (label: 'Morning', hint: '8:00 AM', hour: 8, minute: 0),
    (label: 'Afternoon', hint: '1:00 PM', hour: 13, minute: 0),
    (label: 'Evening', hint: '7:00 PM', hour: 19, minute: 0),
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await NotificationService.instance.loadPreferences();
    if (!mounted) return;
    setState(() {
      _wantReminders =
          prefs.pushNotificationsEnabled && prefs.taskReminderEnabled;
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

  bool _isPreset(int hour, int minute) =>
      _dailyHour == hour && _dailyMinute == minute;

  bool get _isCustomTime =>
      !_presets.any((p) => _isPreset(p.hour, p.minute));

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

    if (!mounted) return;
    final prefsService =
        Provider.of<UserPreferencesService>(context, listen: false);
    await prefsService.completeNotificationOnboarding();

    if (!mounted) return;
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final inverse = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: kOnboardingAccent),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const OnboardingStepHeader(
                            icon: Iconsax.notification,
                            title: 'Stay on track',
                            subtitle:
                                'A daily nudge helps keep your memorisation consistent. You can turn this off anytime.',
                          ),
                          const SizedBox(height: 28),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(
                                  () => _wantReminders = !_wantReminders),
                              borderRadius: BorderRadius.circular(14),
                              child: OnboardingSurfaceCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: kOnboardingAccent
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Iconsax.notification,
                                        size: 20,
                                        color: kOnboardingAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Send me daily reminders',
                                            style: GoogleFonts.poppins(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: inverse,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Get a nudge at your chosen time',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      _wantReminders
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 22,
                                      color: _wantReminders
                                          ? kOnboardingAccent
                                          : Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topCenter,
                            child: _wantReminders
                                ? _TimeSection(
                                    formattedTime: _dailyTimeFormatted,
                                    presets: _presets,
                                    isPreset: _isPreset,
                                    isCustom: _isCustomTime,
                                    onPresetTap: (hour, minute) {
                                      setState(() {
                                        _dailyHour = hour;
                                        _dailyMinute = minute;
                                      });
                                    },
                                    onCustomTap: _pickTime,
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  OnboardingBottomBar(
                    helperText: _wantReminders
                        ? 'We’ll notify you at $_dailyTimeFormatted'
                        : 'You can enable reminders later in Settings',
                    child: OnboardingPrimaryButton(
                      label: 'Continue',
                      onPressed: _onContinue,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimeSection extends StatelessWidget {
  const _TimeSection({
    required this.formattedTime,
    required this.presets,
    required this.isPreset,
    required this.isCustom,
    required this.onPresetTap,
    required this.onCustomTap,
  });

  final String formattedTime;
  final List<({String label, String hint, int hour, int minute})> presets;
  final bool Function(int hour, int minute) isPreset;
  final bool isCustom;
  final void Function(int hour, int minute) onPresetTap;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    final inverse = Theme.of(context).colorScheme.inversePrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Text(
          'When should we remind you?',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: inverse.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 10),
        OnboardingSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: kOnboardingAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Iconsax.clock,
                  size: 26,
                  color: kOnboardingAccent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                formattedTime,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: inverse,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Your daily reminder time',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < presets.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _TimeChip(
                  label: presets[i].label,
                  hint: presets[i].hint,
                  selected: isPreset(presets[i].hour, presets[i].minute),
                  onTap: () =>
                      onPresetTap(presets[i].hour, presets[i].minute),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onCustomTap,
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isCustom
                    ? kOnboardingAccent.withValues(alpha: 0.08)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCustom
                      ? kOnboardingAccent
                      : Theme.of(context)
                          .colorScheme
                          .tertiary
                          .withValues(alpha: 0.4),
                  width: isCustom ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.edit_2,
                    size: 18,
                    color: isCustom
                        ? kOnboardingAccent
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isCustom
                          ? 'Custom · $formattedTime'
                          : 'Pick a custom time',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isCustom ? kOnboardingAccent : inverse,
                      ),
                    ),
                  ),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? kOnboardingAccent.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? kOnboardingAccent
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? kOnboardingAccent
                      : Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
