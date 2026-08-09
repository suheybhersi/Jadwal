import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/auth_page.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';

/// Shown after sign-up / sign-in until the user's email is verified.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key, required this.user});

  final User user;

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  bool _sending = false;
  bool _checking = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    // Fresh sign-ups already get a mail in register; still safe to offer resend.
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown([int seconds = 60]) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  Future<void> _resendEmail() async {
    if (_sending || _resendCooldown > 0) return;
    setState(() {
      _sending = true;
      _message = null;
    });
    try {
      await widget.user.sendEmailVerification();
      if (!mounted) return;
      _startCooldown();
      setState(() {
        _message = 'Verification email sent. Check your inbox and spam folder.';
        _messageIsError = false;
      });
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final message = e.code == 'too-many-requests'
          ? 'Too many attempts. Please wait a minute and try again.'
          : (e.message ?? 'Could not send verification email.');
      setState(() {
        _message = message;
        _messageIsError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not send verification email. Try again shortly.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      // Force token refresh so AuthPage's userChanges() stream rebuilds.
      await FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (!mounted) return;
      final refreshed = FirebaseAuth.instance.currentUser;
      if (refreshed != null && refreshed.emailVerified) {
        setState(() {
          _message = 'Email verified — continuing…';
          _messageIsError = false;
        });
      } else {
        setState(() {
          _message =
              'Not verified yet. Open the link in your email, then try again.';
          _messageIsError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _message = 'Could not check verification status. Try again.';
        _messageIsError = true;
      });
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _signOut() async {
    await AuthPage.signOutToOnboarding(context);
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? 'your email';

    return AuthGradientScaffold(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Verify your email',
              subtitle:
                  'We sent a link to confirm your address before you continue.',
              logoHeight: 56,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kAuthBrandBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: kAuthBrandBlue.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  const AuthIconTile(
                    icon: Iconsax.sms_tracking,
                    size: 56,
                    iconSize: 26,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    email,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the link in the email, then come back and continue.',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(
                _message!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _messageIsError
                      ? Colors.red.shade600
                      : const Color(0xFF10B981),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            AuthPrimaryButton(
              label: _checking ? 'Checking…' : "I've verified my email",
              enabled: !_checking,
              onPressed: _checking ? null : _checkVerified,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed:
                  (_sending || _resendCooldown > 0) ? null : _resendEmail,
              style: OutlinedButton.styleFrom(
                foregroundColor: kAuthBrandBlue,
                disabledForegroundColor: Colors.grey.shade400,
                side: BorderSide(
                  color: (_sending || _resendCooldown > 0)
                      ? Colors.grey.shade300
                      : kAuthBrandBlue,
                ),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                _resendCooldown > 0
                    ? 'Resend in ${_resendCooldown}s'
                    : (_sending ? 'Sending…' : 'Resend verification email'),
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _signOut,
              child: Text(
                'Use a different account',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
