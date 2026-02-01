import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';

class FinishedMemorisingQuestionPage extends StatefulWidget {
  final FirestoreService firestoreService;
  final VoidCallback onNo;

  const FinishedMemorisingQuestionPage({
    super.key,
    required this.firestoreService,
    required this.onNo,
  });

  @override
  State<FinishedMemorisingQuestionPage> createState() =>
      _FinishedMemorisingQuestionPageState();
}

class _FinishedMemorisingQuestionPageState
    extends State<FinishedMemorisingQuestionPage> {
  bool _isLoading = false;

  Future<void> _onYes() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      // Set mode and mark complete *before* adding the plan so that when
      // getHifdhsStream() emits, auth_page sees hasCompletedModeSelection and
      // skips the mode selection screen.
      if (!mounted) return;
      final prefsService =
          Provider.of<UserPreferencesService>(context, listen: false);
      await prefsService.setUsageMode(UsageMode.flexible);
      await prefsService.completeModeSelection();
      if (!mounted) return;
      await widget.firestoreService.addCompletedMemorisationPlan();
      // Stream will update and auth_page will show home
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4979FB).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Iconsax.book_1,
                    size: 64,
                    color: Color(0xFF4979FB),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Have you finished memorising the Quran?',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'If you have already completed your Hifdh, we\'ll set up your account so you can use quizzes and more. If you\'re still memorising, we\'ll help you create a plan.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF4979FB),
                      ),
                      SizedBox(height: 16),
                      Text('Setting up your account...'),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _onYes,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4979FB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Yes, I\'ve completed the Quran',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: widget.onNo,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color.fromARGB(255, 227, 234, 255),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      foregroundColor: const Color(0xFF4979FB),
                    ),
                    child: Text(
                      'No, I\'m still memorising',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
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
    );
  }
}
