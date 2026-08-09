import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:jadwal/services/user_preferences_service.dart';
import 'package:provider/provider.dart';

enum _MemorisationAnswer { unset, completed, stillMemorising }

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
  _MemorisationAnswer _answer = _MemorisationAnswer.unset;

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

  Future<bool> _confirmCompletedChoice() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Are you sure?',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          content: Text(
            'We’ll set you up for quizzes and reading as a Huffadh.\n\n'
            'If you change your mind, you can reset your plan from Home and create a memorisation schedule anytime.',
            style: GoogleFonts.poppins(fontSize: 14, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'Go back',
                style: GoogleFonts.poppins(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Yes, I’m a Huffadh',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: kAuthBrandBlue,
                ),
              ),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  Future<void> _onContinue() async {
    if (_answer == _MemorisationAnswer.completed) {
      final confirmed = await _confirmCompletedChoice();
      if (!confirmed || !mounted) return;
      await _onYes();
    } else if (_answer == _MemorisationAnswer.stillMemorising) {
      widget.onNo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: _isLoading
          ? const _SetupLoadingView()
          : Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Have you finished memorising the Quran?',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.inversePrimary,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We’ll set things up for your path. You can change this later from settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _AnswerCard(
                        selected: _answer == _MemorisationAnswer.completed,
                        icon: Iconsax.cup,
                        title: 'Yes, I’ve completed the Quran',
                        subtitle:
                            'Quizzes and reading for revision — more Huffadh tools later.',
                        onTap: () => setState(
                          () => _answer = _MemorisationAnswer.completed,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AnswerCard(
                        selected:
                            _answer == _MemorisationAnswer.stillMemorising,
                        icon: Iconsax.book_1,
                        title: 'No, I’m still memorising',
                        subtitle:
                            'We’ll help you create a daily plan with reviews.',
                        onTap: () => setState(
                          () => _answer = _MemorisationAnswer.stillMemorising,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 24,
                  child: AuthPrimaryButton(
                    label: 'Continue',
                    enabled: _answer != _MemorisationAnswer.unset,
                    onPressed: _answer == _MemorisationAnswer.unset
                        ? null
                        : _onContinue,
                  ),
                ),
              ],
            ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: selected
                ? kAuthBrandBlue.withValues(alpha: 0.08)
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? kAuthBrandBlue
                  : Theme.of(context)
                      .colorScheme
                      .tertiary
                      .withValues(alpha: 0.4),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: kAuthBrandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: kAuthBrandBlue, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.inversePrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? kAuthBrandBlue : Colors.grey.shade400,
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
            const CircularProgressIndicator(color: kAuthBrandBlue),
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
