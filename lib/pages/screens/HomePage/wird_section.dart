import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/screens/HomePage/create_wird_page.dart';
import 'package:jadwal/pages/screens/QuranViewer/quran_viewer.dart';
import 'package:jadwal/services/firestore.dart';

class WirdSection extends StatefulWidget {
  const WirdSection({
    super.key,
    required this.firestoreService,
    this.inline = false,
    this.onTapCreate,
    this.onEditEndPage,
    this.onTapReset,
  });

  final FirestoreService firestoreService;
  /// When true, content is shown directly (no expandable card). Use in dialogs.
  final bool inline;
  /// When set (e.g. in dialog), Create Wird triggers this instead of navigating.
  final VoidCallback? onTapCreate;
  /// When set (e.g. in dialog), Edit end page triggers this with current value instead of showing another dialog.
  final void Function(int currentEndPage)? onEditEndPage;
  /// When set (e.g. in dialog), Reset triggers this instead of showing another dialog.
  final VoidCallback? onTapReset;

  @override
  State<WirdSection> createState() => _WirdSectionState();
}

class _WirdSectionState extends State<WirdSection> {
  bool _isExpanded = false;

  FirestoreService get firestoreService => widget.firestoreService;

  Widget _buildMissedIndicator(String rescheduledFrom) {
    try {
      final parts = rescheduledFrom.split('-');
      if (parts.length != 3) return const SizedBox.shrink();
      final from = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final fromDate = DateTime(from.year, from.month, from.day);
      final daysMissed = today.difference(fromDate).inDays;
      if (daysMissed <= 0) return const SizedBox.shrink();
      return Row(
        children: [
          Icon(Iconsax.calendar_tick, size: 14, color: Colors.orange.shade700),
          const SizedBox(width: 6),
          Text(
            daysMissed == 1
                ? 'Rescheduled — 1 day missed'
                : 'Rescheduled — $daysMissed days missed',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.orange.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  void _openCreateWird(BuildContext context) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) =>
            CreateWirdPage(firestoreService: firestoreService),
      ),
    );
    if (created == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wird created. Your daily portion is ready.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showEditEndPageDialog(BuildContext context, int endPage) {
    final controller = TextEditingController(text: '$endPage');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit end page',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'End page (1–${FirestoreService.quranTotalPages})',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final v = int.tryParse(controller.text);
              if (v != null &&
                  v >= 1 &&
                  v <= FirestoreService.quranTotalPages) {
                await firestoreService.setWirdEndPage(v);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmResetWird(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Reset Wird',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'This will delete all wird data. You can create a new daily portion afterward.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await firestoreService.resetWird();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Wird reset. Create a new daily portion when ready.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: firestoreService.getWirdStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Center(
              child: SizedBox(
                height: 40,
                width: 40,
                child: CircularProgressIndicator(color: Color(0xFF4979FB)),
              ),
            ),
          );
        }

        final data = snapshot.data?.data() as Map<String, dynamic>?;
        final exists = snapshot.hasData && data != null;

        if (!exists) {
          final content = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set a daily portion to read. We\'ll show today\'s pages and plan the next for tomorrow.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.inline && widget.onTapCreate != null) {
                      widget.onTapCreate!();
                    } else {
                      _openCreateWird(context);
                    }
                  },
                  icon: const Icon(Iconsax.add,
                      size: 20, color: Colors.white),
                  label: Text(
                    'Create Wird',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4979FB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          );
          if (widget.inline) {
            return Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: content,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF4979FB).withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Iconsax.book_1,
                            color: const Color(0xFF4979FB),
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Daily reading',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Theme.of(context)
                                    .colorScheme
                                    .inversePrimary,
                              ),
                            ),
                          ),
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Iconsax.arrow_down_1,
                              size: 18,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: content,
                        ),
                        crossFadeState: _isExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final startPage = (data['startPage'] as num?)?.toInt() ?? 1;
        final endPage = (data['endPage'] as num?)?.toInt() ?? 1;
        final completedToday = data['completedAt'] != null;
        final isMissed = data['missed'] == true;
        final rescheduledFrom = data['rescheduledFrom'] as String?;
        final editEndPageDefault = endPage;

        final actionsContent = Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (completedToday)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'You’ve completed today’s portion. Tomorrow you’ll see the next pages.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.45,
                  ),
                ),
              )
            else if (isMissed) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Iconsax.info_circle, size: 20, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This day was missed. It cannot be completed. Set your device to the correct date.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.orange.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => QuranViewer(initialPage: startPage),
                      ),
                    );
                  },
                  icon: const Icon(Iconsax.book, size: 20),
                  label: Text(
                    'Read',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4979FB),
                    side: const BorderSide(color: Color(0xFF4979FB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ]
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => QuranViewer(
                              initialPage: startPage,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Iconsax.book, size: 20),
                      label: Text(
                        'Read',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4979FB),
                        side: const BorderSide(color: Color(0xFF4979FB)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await firestoreService.markWirdComplete();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Completed for today. See you tomorrow.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Iconsax.tick_circle,
                          size: 20, color: Colors.white),
                      label: Text(
                        'Complete',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4979FB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        );

        if (widget.inline) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Today\'s portion',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
                if (rescheduledFrom != null) ...[
                  const SizedBox(height: 6),
                  _buildMissedIndicator(rescheduledFrom),
                ],
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF4979FB).withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          completedToday
                              ? 'Completed for today'
                              : 'Pages $startPage – $endPage',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          if (widget.inline && widget.onEditEndPage != null) {
                            widget.onEditEndPage!(editEndPageDefault);
                          } else {
                            _showEditEndPageDialog(context, editEndPageDefault);
                          }
                        },
                        icon: Icon(
                          Iconsax.edit_2,
                          size: 18,
                          color: Colors.grey.shade600,
                        ),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(36, 36),
                          padding: EdgeInsets.zero,
                        ),
                        tooltip: 'Edit end page',
                      ),
                      TextButton(
                        onPressed: () {
                          if (widget.inline && widget.onTapReset != null) {
                            widget.onTapReset!();
                          } else {
                            _confirmResetWird(context);
                          }
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Reset',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                actionsContent,
              ],
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: 20, vertical: _isExpanded ? 12 : 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: _isExpanded ? 16 : 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4979FB).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Iconsax.book_1,
                          color: const Color(0xFF4979FB),
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            completedToday
                                ? 'Completed for today'
                                : 'Pages $startPage – $endPage',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              _showEditEndPageDialog(context, editEndPageDefault),
                          icon: Icon(
                            Iconsax.edit_2,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(40, 40),
                            padding: EdgeInsets.zero,
                          ),
                          tooltip: 'Edit end page',
                        ),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Iconsax.arrow_down_1,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: actionsContent,
                      ),
                      crossFadeState: _isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 200),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
