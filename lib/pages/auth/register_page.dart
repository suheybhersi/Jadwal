import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jadwal/components/my_textfield.dart';
import 'package:jadwal/components/square_tile.dart';
import 'package:iconsax/iconsax.dart';
import 'package:jadwal/services/firestore.dart';
import 'package:flutter/gestures.dart';

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

  // Add state variable for checkbox
  bool _agreedToTerms = false;

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: Text(
          message,
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Close',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void signUserUp() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        builder: (context) {
          return const Center(
            child: CircularProgressIndicator(),
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

          // Get the current user's UID
          final user = userCredential.user;
          // Use your FirestoreService to store user profile
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

          if (!mounted) return;
          Navigator.pop(context); // Close loading dialog
          Navigator.of(context).pop(); // Navigate to login or another screen
        } else {
          Navigator.pop(context); // Close loading dialog
          showErrorDialog("Passwords don't match. Please try again.");
        }
      } on FirebaseAuthException catch (e) {
        Navigator.pop(context); // Close loading dialog
        String errorMessage = 'An unexpected error occurred';

        if (e.code == 'email-already-in-use') {
          errorMessage = "This email is already in use";
        } else if (e.code == 'invalid-email') {
          errorMessage = "Invalid email address";
        } else if (e.code == 'weak-password') {
          errorMessage = "Password is too weak";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Text(
                  'Let\'s create an account for you!',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 32),
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
                            return Color.fromARGB(255, 73, 121, 251);
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
                    SizedBox(width: 8),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ).apply(
                                  decoration: TextDecoration.underline,
                                  color: Color.fromARGB(255, 73, 121, 251),
                                  decorationColor:
                                      Color.fromARGB(255, 73, 121, 251),
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Add privacy policy action here
                                    print('Privacy Policy tapped');
                                  },
                              ),
                              TextSpan(
                                text: ' and ',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              TextSpan(
                                text: 'Terms of Use',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                ).apply(
                                  decoration: TextDecoration.underline,
                                  color: Color.fromARGB(255, 73, 121, 251),
                                  decorationColor:
                                      Color.fromARGB(255, 73, 121, 251),
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // Add terms of use action here
                                    print('Terms of Use tapped');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: _agreedToTerms
                          ? Color.fromARGB(255, 73, 121, 251)
                          : Color.fromARGB(255, 73, 121, 251).withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    onPressed: _agreedToTerms
                        ? signUserUp
                        : () {
                            // Show error message if trying to sign up without agreeing
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Please agree to the Privacy Policy and Terms of Use',
                                  style: TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                                backgroundColor: Colors.red.shade400,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                margin: EdgeInsets.all(10),
                              ),
                            );
                          },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Divider(
                        color: Color.fromARGB(255, 200, 200, 200),
                        thickness: 0.5,
                        indent: 40,
                        endIndent: 10,
                      ),
                    ),
                    Text(
                      'Or Sign up with',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Flexible(
                      child: Divider(
                        color: const Color.fromARGB(255, 200, 200, 200),
                        thickness: 0.5,
                        indent: 10,
                        endIndent: 40,
                      ),
                    ),
                  ],
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(imagePath: 'assets/google.png'),
                    SizedBox(width: 10),
                    SquareTile(imagePath: 'assets/apple.png'),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: const Text(
                        'Login now',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
  // Add state variables to track password visibility
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.firstNameController,
                  decoration: InputDecoration(
                    hintText: 'First Name',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Iconsax.personalcard),
                    hintStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'First name is required';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: widget.lastNameController,
                  decoration: InputDecoration(
                    hintText: 'Last Name',
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade600),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    prefixIcon: Icon(Iconsax.personalcard),
                    hintStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Last name is required';
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
            prefixIcon:
                Icon(Iconsax.password_check, color: Colors.grey.shade600),
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
            hintText: 'Confirm Password',
            obscureText: _obscureConfirmPassword,
            prefixIcon:
                Icon(Iconsax.password_check, color: Colors.grey.shade600),
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
      ),
    );
  }
}
