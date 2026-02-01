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
  });

  final FirestoreService firestoreService;

  @override
  State<WirdSection> createState() => _WirdSectionState();
}

class _WirdSectionState extends State<WirdSection> {
  bool _isExpanded = false;

  FirestoreService get firestoreService => widget.firestoreService;

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

  void _showAdjustSheet(BuildContext context, Map<String, dynamic> wird) {
    final current = (wird['currentPage'] as num?)?.toInt() ?? 1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Adjust Wird',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Did more or less than today\'s portion? Update where to continue from tomorrow.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              _AdjustTile(
                label: 'Did 1 more page',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(1);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              _AdjustTile(
                label: 'Did 2 more pages',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(2);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              _AdjustTile(
                label: 'Did 5 more pages',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(5);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              const Divider(height: 24),
              _AdjustTile(
                label: 'Did 1 less page',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(-1);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              _AdjustTile(
                label: 'Did 2 less pages',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(-2);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              _AdjustTile(
                label: 'Did 5 less pages',
                onTap: () async {
                  await firestoreService.adjustWirdByPages(-5);
                  if (context.mounted) Navigator.pop(ctx);
                },
              ),
              const Divider(height: 24),
              _AdjustTile(
                label: 'Set current page (where to continue)',
                onTap: () async {
                  Navigator.pop(ctx);
                  _showSetPageDialog(context, current);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetPageDialog(BuildContext context, int current) {
    final controller = TextEditingController(text: '$current');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Set current page',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Page (1–${FirestoreService.quranTotalPages})',
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
                await firestoreService.setWirdCurrentPage(v);
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Set'),
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
                        secondChild: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 14),
                            Text(
                              'Set a daily portion to read. We\'ll show today\'s pages and plan the next for tomorrow.',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () => _openCreateWird(context),
                                icon: const Icon(Iconsax.add,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  'Create Wird',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
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

        final currentPage = (data['currentPage'] as num?)?.toInt() ?? 1;
        final pagesPerDay = (data['pagesPerDay'] as num?)?.toInt() ?? 1;
        final endPage = (currentPage + pagesPerDay - 1)
            .clamp(1, FirestoreService.quranTotalPages);

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
                            'Pages $currentPage – $endPage',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _showAdjustSheet(context, data),
                          icon: Icon(
                            Iconsax.setting_2,
                            size: 20,
                            color: Colors.grey.shade600,
                          ),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            padding: EdgeInsets.zero,
                          ),
                          tooltip: 'Adjust',
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
                      secondChild: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => QuranViewer(
                                          initialPage: currentPage,
                                        ),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Iconsax.book, size: 18),
                                  label: Text(
                                    'Read',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF4979FB),
                                    side: const BorderSide(
                                        color: Color(0xFF4979FB)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await firestoreService.markWirdComplete();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Wird marked complete. Tomorrow\'s portion is set.'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Iconsax.tick_circle,
                                      size: 18, color: Colors.white),
                                  label: Text(
                                    'Mark complete',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF4979FB),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
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

class _AdjustTile extends StatelessWidget {
  const _AdjustTile({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      trailing: const Icon(Iconsax.arrow_right_3, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }
}
