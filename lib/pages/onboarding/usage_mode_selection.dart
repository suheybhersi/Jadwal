import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/onboarding_ui.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';

class UsageModeSelectionPage extends StatefulWidget {
  final VoidCallback onComplete;

  const UsageModeSelectionPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<UsageModeSelectionPage> createState() =>
      _UsageModeSelectionPageState();
}

class _UsageModeSelectionPageState extends State<UsageModeSelectionPage> {
  UsageMode? _selectedMode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingStepHeader(
                      title: 'Choose your path',
                      subtitle:
                          'Everyone memorises differently. How would you like Jadwal to support you?',
                    ),
                    const SizedBox(height: 24),
                    _ModeOption(
                      mode: UsageMode.flexible,
                      icon: Iconsax.timer_pause,
                      color: const Color(0xFF10B981),
                      selected: _selectedMode == UsageMode.flexible,
                      onTap: () =>
                          setState(() => _selectedMode = UsageMode.flexible),
                    ),
                    const SizedBox(height: 10),
                    _ModeOption(
                      mode: UsageMode.intensive,
                      icon: Iconsax.flash_1,
                      color: kOnboardingAccent,
                      selected: _selectedMode == UsageMode.intensive,
                      isRecommended: true,
                      onTap: () =>
                          setState(() => _selectedMode = UsageMode.intensive),
                    ),
                  ],
                ),
              ),
            ),
            OnboardingBottomBar(
              helperText: 'You can change this anytime in Settings',
              child: OnboardingPrimaryButton(
                label: 'Continue',
                onPressed: _selectedMode == null
                    ? null
                    : () async {
                        final prefsService =
                            Provider.of<UserPreferencesService>(context,
                                listen: false);
                        await prefsService.setUsageMode(_selectedMode!);
                        await prefsService.completeModeSelection();
                        widget.onComplete();
                      },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  const _ModeOption({
    required this.mode,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    this.isRecommended = false,
  });

  final UsageMode mode;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final modeName = UserPreferencesService.getModeName(mode);
    final modeDescription = UserPreferencesService.getModeDescription(mode);
    final modeFeatures = UserPreferencesService.getModeFeatures(mode);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? color
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            modeName,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context)
                                  .colorScheme
                                  .inversePrimary,
                            ),
                          ),
                        ),
                        if (isRecommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Recommended',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF10B981),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    size: 20,
                    color: selected ? color : Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                modeDescription,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 10),
              ...modeFeatures.take(3).map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Iconsax.tick_circle, size: 14, color: color),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
