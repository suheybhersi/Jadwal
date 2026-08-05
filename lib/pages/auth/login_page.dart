import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/components/my_textfield.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/services/firestore.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;

  void showErrorDialog(String message) {
    showAuthAlertDialog(
      context,
      title: 'Error',
      message: message,
    );
  }

  void showSuccessDialog(String message) {
    showAuthAlertDialog(
      context,
      title: 'Check your email',
      message: message,
      actionLabel: 'OK',
    );
  }

  Future<void> resetPassword() async {
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _ForgotPasswordDialog(
          initialEmail: emailController.text.trim(),
        );
      },
    );

    if (email == null || email.isEmpty || !mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(color: kAuthBrandBlue),
        );
      },
    );

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      Navigator.pop(context);
      showSuccessDialog(
        'If an account exists for $email, you\'ll receive a password reset link shortly.',
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      if (e.code == 'invalid-email') {
        showErrorDialog('Please enter a valid email address.');
      } else if (e.code == 'user-not-found') {
        showSuccessDialog(
          'If an account exists for $email, you\'ll receive a password reset link shortly.',
        );
      } else if (e.code == 'too-many-requests') {
        showErrorDialog('Too many attempts. Please try again later.');
      } else {
        showErrorDialog('Could not send reset email. Please try again.');
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pop(context);
      showErrorDialog('Could not send reset email. Please try again.');
    }
  }

  void signUserIn() async {
    if (_formKey.currentState?.validate() ?? false) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(color: kAuthBrandBlue),
          );
        },
      );

      try {
        final userCredential =
            await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );

        final user = userCredential.user;
        if (user != null) {
          final firestoreService = FirestoreService(
            uid: user.uid,
            auth: FirebaseAuth.instance,
          );
          await firestoreService.recordLoginActivity(method: 'email');
        }

        if (!mounted) return;
        Navigator.pop(context);
        Navigator.of(context).pop();
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        if (e.code == 'invalid-email' ||
            e.code == 'invalid-credential' ||
            e.code == 'wrong-password') {
          showErrorDialog('Incorrect email or password. Please try again.');
        } else {
          showErrorDialog('An unexpected error occurred. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          children: [
            const AuthHeader(
              title: 'Welcome back',
              subtitle: 'Log in to continue your memorisation journey.',
              logoHeight: 64,
            ),
            const SizedBox(height: 36),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  MyTextField(
                    controller: emailController,
                    hintText: 'Email',
                    prefixIcon: Icon(
                      Iconsax.direct_right,
                      color: Colors.grey.shade600,
                    ),
                    suffixIcon: null,
                    obscureText: false,
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      if (email.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                              r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                          .hasMatch(email)) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  MyTextField(
                    controller: passwordController,
                    hintText: 'Password',
                    prefixIcon: Icon(
                      Iconsax.password_check,
                      color: Colors.grey.shade600,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Iconsax.eye_slash : Iconsax.eye,
                        color: Colors.grey.shade600,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    obscureText: _obscurePassword,
                    validator: (value) {
                      final password = value ?? '';
                      if (password.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (password.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: resetPassword,
                      child: Text(
                        'Forgot password?',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kAuthBrandBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AuthPrimaryButton(
                    label: 'Log in',
                    onPressed: signUserIn,
                  ),
                  const SizedBox(height: 28),
                  AuthSwitchPrompt(
                    prompt: "Don't have an account?",
                    actionLabel: 'Sign up',
                    onTap: widget.onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _emailController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Forgot password',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your account email and we\'ll send you a link to reset your password.',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: GoogleFonts.poppins(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                prefixIcon: Icon(
                  Iconsax.direct_right,
                  color: Colors.grey.shade600,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kAuthBrandBlue),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                final email = value?.trim() ?? '';
                if (email.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                    .hasMatch(email)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.of(context).pop(_emailController.text.trim());
            }
          },
          child: Text(
            'Send link',
            style: GoogleFonts.poppins(
              color: kAuthBrandBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
