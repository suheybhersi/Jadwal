import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/firestore.dart';

class CreateWirdPage extends StatefulWidget {
  final FirestoreService firestoreService;

  const CreateWirdPage({
    super.key,
    required this.firestoreService,
  });

  @override
  State<CreateWirdPage> createState() => _CreateWirdPageState();
}

class _CreateWirdPageState extends State<CreateWirdPage> {
  int _pagesPerDay = 2;
  bool _customPages = false;
  final TextEditingController _customPagesController =
      TextEditingController(text: '2');
  int _startPage = 1;
  bool _customStart = false;
  final TextEditingController _customStartController =
      TextEditingController(text: '1');
  bool _isLoading = false;

  static const _primary = Color(0xFF4979FB);

  @override
  void dispose() {
    _customPagesController.dispose();
    _customStartController.dispose();
    super.dispose();
  }

  int get effectivePagesPerDay {
    if (_customPages) {
      final v = int.tryParse(_customPagesController.text);
      return (v ?? 1).clamp(1, FirestoreService.quranTotalPages);
    }
    return _pagesPerDay;
  }

  int get effectiveStartPage {
    if (_customStart) {
      final v = int.tryParse(_customStartController.text);
      return (v ?? 1).clamp(1, FirestoreService.quranTotalPages);
    }
    return _startPage;
  }

  Future<void> _create() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await widget.firestoreService.createWird(
        startPage: effectiveStartPage,
        pagesPerDay: effectivePagesPerDay,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.inversePrimary;

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Iconsax.arrow_left, color: onSurface),
        ),
        title: Text(
          'Create Wird',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Pages per day card
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.document_text_1,
                                  size: 20, color: _primary),
                              const SizedBox(width: 10),
                              Text(
                                'Pages per day',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [1, 2, 3, 5, 10].map((n) {
                              final selected =
                                  !_customPages && _pagesPerDay == n;
                              return _ChoiceChip(
                                label: '$n',
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    _customPages = false;
                                    _pagesPerDay = n;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          _ChoiceChip(
                            label: 'Custom',
                            selected: _customPages,
                            onTap: () => setState(() => _customPages = true),
                          ),
                          if (_customPages) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _customPagesController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText:
                                    '1–${FirestoreService.quranTotalPages}',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: _primary.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Where to start card
                    _SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Iconsax.flag, size: 20, color: _primary),
                              const SizedBox(width: 10),
                              Text(
                                'Where to start',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _OptionTile(
                            icon: Iconsax.book,
                            label: 'From beginning (Page 1)',
                            selected: !_customStart && _startPage == 1,
                            onTap: () => setState(() {
                              _customStart = false;
                              _startPage = 1;
                            }),
                          ),
                          const SizedBox(height: 10),
                          _OptionTile(
                            icon: Iconsax.edit_2,
                            label: 'Choose starting page',
                            selected: _customStart,
                            onTap: () => setState(() => _customStart = true),
                          ),
                          if (_customStart) ...[
                            const SizedBox(height: 14),
                            TextField(
                              controller: _customStartController,
                              keyboardType: TextInputType.number,
                              style: GoogleFonts.poppins(fontSize: 15),
                              decoration: InputDecoration(
                                hintText:
                                    'Page 1–${FirestoreService.quranTotalPages}',
                                hintStyle: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                                filled: true,
                                fillColor: surface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color: _primary.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: _primary, width: 1.5),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Create button fixed at bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _create,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Create Wird',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  static const _primary = Color(0xFF4979FB);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primary.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF4979FB);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.inversePrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _primary.withValues(alpha: 0.15)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? _primary : Colors.grey.shade300,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected ? _primary : onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const _primary = Color(0xFF4979FB);

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.inversePrimary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? _primary.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? _primary
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? _primary : Colors.grey.shade500,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: onSurface,
                  ),
                ),
              ),
              if (selected)
                const Icon(
                  Iconsax.tick_circle5,
                  size: 22,
                  color: _primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
