import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/components/my_textfield.dart';
import 'package:jadwal/pages/auth/widgets/auth_widgets.dart';
import 'package:jadwal/pages/screens/SettingsPage/privacy_policy_page.dart';
import 'package:jadwal/pages/screens/SettingsPage/terms_service_page.dart';
import 'package:jadwal/services/firestore.dart';

class RegisterPage extends StatefulWidget {
  final Function()? onTap;
  const RegisterPage({super.key, required this.onTap});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final userNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _agreedToTerms = false;

  void showErrorDialog(String message) {
    showAuthAlertDialog(
      context,
      title: 'Error',
      message: message,
    );
  }

  void signUserUp() async {
    if (_formKey.currentState!.validate()) {
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
        if (passwordController.text == confirmPasswordController.text) {
          UserCredential userCredential =
              await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );

          final user = userCredential.user;
          final firestoreService = FirestoreService(
            uid: user!.uid,
            auth: FirebaseAuth.instance,
          );
          await firestoreService.updateUserProfile({
            'firstName': firstNameController.text.trim(),
            'lastName': lastNameController.text.trim(),
            'username': userNameController.text.trim(),
            'email': emailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
          await firestoreService.recordLoginActivity(method: 'registration');

          if (!mounted) return;
          Navigator.pop(context);
          Navigator.of(context).pop();
        } else {
          Navigator.pop(context);
          showErrorDialog("Passwords don't match. Please try again.");
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        String errorMessage = 'An unexpected error occurred';

        if (e.code == 'email-already-in-use') {
          errorMessage = 'This email is already in use';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'Invalid email address';
        } else if (e.code == 'weak-password') {
          errorMessage = 'Password is too weak';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    userNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthGradientScaffold(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AuthHeader(
              title: 'Create your account',
              subtitle: 'Start planning your Quran memorisation today.',
              logoHeight: 56,
            ),
            const SizedBox(height: 28),
            Form(
              key: _formKey,
              child: RegisterForm(
                firstNameController: firstNameController,
                lastNameController: lastNameController,
                userNameController: userNameController,
                emailController: emailController,
                passwordController: passwordController,
                confirmPasswordController: confirmPasswordController,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreedToTerms,
                    onChanged: (value) {
                      setState(() {
                        _agreedToTerms = value ?? false;
                      });
                    },
                    checkColor: Colors.white,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return kAuthBrandBlue;
                      }
                      return Colors.transparent;
                    }),
                    side: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _agreedToTerms = !_agreedToTerms;
                      });
                    },
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'I agree to the ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kAuthBrandBlue,
                              decoration: TextDecoration.underline,
                              decorationColor: kAuthBrandBlue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyPage(),
                                  ),
                                );
                              },
                          ),
                          TextSpan(
                            text: ' and ',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          TextSpan(
                            text: 'Terms of Use',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kAuthBrandBlue,
                              decoration: TextDecoration.underline,
                              decorationColor: kAuthBrandBlue,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const TermsServicePage(),
                                  ),
                                );
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AuthPrimaryButton(
              label: 'Create account',
              enabled: _agreedToTerms,
              onPressed: _agreedToTerms
                  ? signUserUp
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please agree to the Privacy Policy and Terms of Use',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                          backgroundColor: Colors.red.shade400,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 28),
            AuthSwitchPrompt(
              prompt: 'Already have an account?',
              actionLabel: 'Log in',
              onTap: widget.onTap,
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    required this.firstNameController,
    required this.lastNameController,
    required this.userNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController userNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  InputDecoration _nameDecoration(BuildContext context, String hint) {
    return InputDecoration(
      hintText: hint,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.red),
        borderRadius: BorderRadius.circular(12),
      ),
      fillColor: Theme.of(context).colorScheme.surface,
      filled: true,
      prefixIcon: Icon(Iconsax.personalcard, color: Colors.grey.shade600),
      hintStyle: GoogleFonts.poppins(
        color: Theme.of(context).colorScheme.secondary,
        fontWeight: FontWeight.w500,
      ),
      errorStyle: GoogleFonts.poppins(
        color: Colors.red,
        fontSize: 12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.firstNameController,
                decoration: _nameDecoration(context, 'First name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: widget.lastNameController,
                decoration: _nameDecoration(context, 'Last name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MyTextField(
          controller: widget.userNameController,
          hintText: 'Username',
          obscureText: false,
          prefixIcon: Icon(Iconsax.user, color: Colors.grey.shade600),
          suffixIcon: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Username is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextField(
          controller: widget.emailController,
          hintText: 'Email',
          obscureText: false,
          prefixIcon: Icon(Iconsax.direct_right, color: Colors.grey.shade600),
          suffixIcon: null,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email is required';
            }
            if (!RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                .hasMatch(value)) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextField(
          controller: widget.passwordController,
          hintText: 'Password',
          obscureText: _obscurePassword,
          prefixIcon: Icon(Iconsax.password_check, color: Colors.grey.shade600),
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
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters long';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        MyTextField(
          controller: widget.confirmPasswordController,
          hintText: 'Confirm password',
          obscureText: _obscureConfirmPassword,
          prefixIcon: Icon(Iconsax.password_check, color: Colors.grey.shade600),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Iconsax.eye_slash : Iconsax.eye,
              color: Colors.grey.shade600,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Confirmation password is required';
            }
            if (value != widget.passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
