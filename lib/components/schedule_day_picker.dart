import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Weekday schedule picker with quick presets (Everyday / Weekdays / Weekends).
///
/// [selectedDays] is length 7, Monday-first.
class ScheduleDayPicker extends StatelessWidget {
  const ScheduleDayPicker({
    super.key,
    required this.selectedDays,
    required this.onChanged,
    this.compact = false,
  });

  final List<bool> selectedDays;
  final ValueChanged<List<bool>> onChanged;

  /// Tighter layout for constrained screens (e.g. Edit Plan).
  final bool compact;

  static const _dayLabels = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const _dayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _accent = Color.fromARGB(255, 73, 121, 251);

  int get _selectedCount => selectedDays.where((d) => d).length;

  bool get _isEveryday =>
      selectedDays.length == 7 && selectedDays.every((d) => d);

  bool get _isWeekdays =>
      selectedDays.length == 7 &&
      selectedDays[0] &&
      selectedDays[1] &&
      selectedDays[2] &&
      selectedDays[3] &&
      selectedDays[4] &&
      !selectedDays[5] &&
      !selectedDays[6];

  bool get _isWeekends =>
      selectedDays.length == 7 &&
      !selectedDays[0] &&
      !selectedDays[1] &&
      !selectedDays[2] &&
      !selectedDays[3] &&
      !selectedDays[4] &&
      selectedDays[5] &&
      selectedDays[6];

  void _applyPreset(List<bool> days) {
    onChanged(List<bool>.from(days));
  }

  void _toggleDay(int index) {
    final next = List<bool>.from(selectedDays);
    next[index] = !next[index];
    onChanged(next);
  }

  String get _summary {
    if (_selectedCount == 0) return 'Pick at least one day.';
    if (_isEveryday) return 'Every day';
    if (_isWeekdays) return 'Weekdays (Mon–Fri)';
    if (_isWeekends) return 'Weekends (Sat–Sun)';
    final names = <String>[];
    for (var i = 0; i < selectedDays.length; i++) {
      if (selectedDays[i]) names.add(_dayNames[i]);
    }
    return names.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final inverse = Theme.of(context).colorScheme.inversePrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Schedule',
          style: GoogleFonts.poppins(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: inverse,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Choose a preset or tap individual days.',
          style: GoogleFonts.poppins(
            fontSize: compact ? 11 : 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Row(
          children: [
            Expanded(
              child: _PresetChip(
                label: 'Everyday',
                selected: _isEveryday,
                onTap: () => _applyPreset(List.filled(7, true)),
                compact: compact,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _PresetChip(
                label: 'Weekdays',
                selected: _isWeekdays,
                onTap: () => _applyPreset(
                  [true, true, true, true, true, false, false],
                ),
                compact: compact,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _PresetChip(
                label: 'Weekends',
                selected: _isWeekends,
                onTap: () => _applyPreset(
                  [false, false, false, false, false, true, true],
                ),
                compact: compact,
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 10 : 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(7, (index) {
            final selected =
                index < selectedDays.length && selectedDays[index];
            return _DayToggle(
              label: _dayLabels[index],
              selected: selected,
              onTap: () => _toggleDay(index),
              compact: compact,
            );
          }),
        ),
        SizedBox(height: compact ? 8 : 10),
        Text(
          _summary,
          style: GoogleFonts.poppins(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
            color: _selectedCount == 0 ? Colors.red.shade700 : _accent,
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(vertical: compact ? 7 : 9),
          decoration: BoxDecoration(
            color: selected
                ? ScheduleDayPicker._accent.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? ScheduleDayPicker._accent
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.35),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? ScheduleDayPicker._accent
                  : Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DayToggle extends StatelessWidget {
  const _DayToggle({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 40.0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected
                ? ScheduleDayPicker._accent
                : Theme.of(context).colorScheme.surface,
            border: Border.all(
              color: selected
                  ? ScheduleDayPicker._accent
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: selected ? 0 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: selected
                  ? Colors.white
                  : Theme.of(context).colorScheme.inversePrimary,
            ),
          ),
        ),
      ),
    );
  }
}
