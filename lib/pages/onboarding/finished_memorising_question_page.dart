import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/onboarding_ui.dart';
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
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
            style: GoogleFonts.poppins(),
          ),
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
        child: _isLoading
            ? const _SetupLoadingView()
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const OnboardingStepHeader(
                      icon: Iconsax.book_1,
                      title: 'Have you finished memorising the Quran?',
                      subtitle:
                          'If you’ve completed your Hifdh, we’ll set you up for quizzes and revision. If you’re still memorising, we’ll help you create a plan.',
                    ),
                    const Spacer(),
                    OnboardingPrimaryButton(
                      label: 'Yes, I’ve completed the Quran',
                      onPressed: _onYes,
                    ),
                    const SizedBox(height: 10),
                    OnboardingSecondaryButton(
                      label: 'No, I’m still memorising',
                      onPressed: widget.onNo,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _SetupLoadingView extends StatelessWidget {
  const _SetupLoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: kOnboardingAccent),
            const SizedBox(height: 24),
            Text(
              'Setting things up…',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This might take a moment',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
