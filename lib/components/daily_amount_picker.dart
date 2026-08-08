import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Unit-first daily memorisation amount (Lines or Pages).
class DailyAmountPicker extends StatefulWidget {
  const DailyAmountPicker({
    super.key,
    required this.unit,
    required this.amount,
    required this.onUnitChanged,
    required this.onAmountChanged,
    this.compact = false,
  });

  /// `'Lines'` or `'Pages'`.
  final String unit;
  final int amount;
  final ValueChanged<String> onUnitChanged;
  final ValueChanged<int> onAmountChanged;

  /// Tighter layout for constrained screens (e.g. Edit Plan).
  final bool compact;

  static const linesPerPage = 15;
  static const accent = Color.fromARGB(255, 73, 121, 251);

  @override
  State<DailyAmountPicker> createState() => _DailyAmountPickerState();
}

class _DailyAmountPickerState extends State<DailyAmountPicker> {
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _setAmount(int value) {
    widget.onAmountChanged(max(1, value));
  }

  void _selectUnit(String nextUnit) {
    if (nextUnit == widget.unit) return;

    final current = max(1, widget.amount);
    final converted = nextUnit == 'Pages'
        ? max(1, current ~/ DailyAmountPicker.linesPerPage)
        : max(
            DailyAmountPicker.linesPerPage,
            current * DailyAmountPicker.linesPerPage,
          );

    widget.onUnitChanged(nextUnit);
    widget.onAmountChanged(converted);
  }

  void _startHold(void Function() step) {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      step();
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    final inverse = Theme.of(context).colorScheme.inversePrimary;
    final tertiary = Theme.of(context).colorScheme.tertiary;
    final unitLabel = widget.unit == 'Pages' ? 'pages' : 'lines';
    final compact = widget.compact;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Daily Amount',
          style: GoogleFonts.poppins(
            fontSize: compact ? 15 : 16,
            fontWeight: FontWeight.w600,
            color: inverse,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Pick lines or pages, then how many per day.',
          style: GoogleFonts.poppins(
            fontSize: compact ? 11 : 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Container(
          height: compact ? 38 : 42,
          decoration: BoxDecoration(
            color: tertiary.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.all(3),
          child: Row(
            children: [
              Expanded(
                child: _UnitSegment(
                  label: 'Lines',
                  selected: widget.unit == 'Lines',
                  onTap: () => _selectUnit('Lines'),
                  compact: compact,
                ),
              ),
              Expanded(
                child: _UnitSegment(
                  label: 'Pages',
                  selected: widget.unit == 'Pages',
                  onTap: () => _selectUnit('Pages'),
                  compact: compact,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 4 : 6),
        Text(
          widget.unit == 'Pages'
              ? '1 page ≈ 15 lines'
              : 'A page is about 15 lines',
          style: GoogleFonts.poppins(
            fontSize: compact ? 10 : 11,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: compact ? 10 : 12),
        Container(
          height: compact ? 44 : 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tertiary.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTapDown: (_) => _startHold(() {
                  if (widget.amount > 1) _setAmount(widget.amount - 1);
                }),
                onTapUp: (_) => _stopHold(),
                onTapCancel: _stopHold,
                child: IconButton(
                  onPressed: () {
                    if (widget.amount > 1) _setAmount(widget.amount - 1);
                  },
                  icon: Icon(
                    Icons.remove,
                    color: Colors.grey.shade700,
                    size: compact ? 20 : 22,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                child: Text(
                  '${max(1, widget.amount)} $unitLabel / day',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: compact ? 14 : 15,
                    fontWeight: FontWeight.w600,
                    color: inverse,
                  ),
                ),
              ),
              GestureDetector(
                onTapDown: (_) => _startHold(() {
                  _setAmount(widget.amount + 1);
                }),
                onTapUp: (_) => _stopHold(),
                onTapCancel: _stopHold,
                child: IconButton(
                  onPressed: () => _setAmount(widget.amount + 1),
                  icon: Icon(
                    Icons.add,
                    color: Colors.grey.shade700,
                    size: compact ? 20 : 22,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UnitSegment extends StatelessWidget {
  const _UnitSegment({
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.surface
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: selected
                  ? DailyAmountPicker.accent
                  : Theme.of(context)
                      .colorScheme
                      .inversePrimary
                      .withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}
