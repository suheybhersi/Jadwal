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
          content: Text('Something went wrong. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: Text(
          'Create Wird',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Iconsax.arrow_left),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How many pages per day?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [1, 2, 3, 5, 10].map((n) {
                final selected = !_customPages && _pagesPerDay == n;
                return FilterChip(
                  label: Text('$n'),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      _customPages = false;
                      _pagesPerDay = n;
                    });
                  },
                  selectedColor: const Color(0xFF4979FB).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF4979FB),
                );
              }).toList()
                ..add(
                  FilterChip(
                    label: const Text('Custom'),
                    selected: _customPages,
                    onSelected: (v) {
                      setState(() => _customPages = true);
                    },
                    selectedColor:
                        const Color(0xFF4979FB).withValues(alpha: 0.2),
                    checkmarkColor: const Color(0xFF4979FB),
                  ),
                ),
            ),
            if (_customPages) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customPagesController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText:
                      'Pages per day (1–${FirestoreService.quranTotalPages})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'Where to start?',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _OptionChip(
                    label: 'From beginning (Page 1)',
                    selected: !_customStart && _startPage == 1,
                    onTap: () => setState(() {
                      _customStart = false;
                      _startPage = 1;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _OptionChip(
                    label: 'Choose starting page',
                    selected: _customStart,
                    onTap: () => setState(() => _customStart = true),
                  ),
                ),
              ],
            ),
            if (_customStart) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customStartController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Page (1–${FirestoreService.quranTotalPages})',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _create,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4979FB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
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
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? const Color(0xFF4979FB).withValues(alpha: 0.12)
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF4979FB)
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Iconsax.tick_circle5 : Iconsax.tick_circle,
                size: 22,
                color: selected ? const Color(0xFF4979FB) : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.inversePrimary,
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
