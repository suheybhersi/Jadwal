import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jadwal/components/my_textfield.dart';
import 'package:jadwal/components/square_tile.dart';
import 'package:iconsax/iconsax.dart';

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

  // Add state variable to track password visibility
  bool _obscurePassword = true;

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
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Close',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  void signUserIn() async {
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
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
        Navigator.of(context).pop(); // Navigate to next screen
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog
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

  // Add method to check if form is valid
  bool _isFormValid() {
    return emailController.text.isNotEmpty &&
        passwordController.text.isNotEmpty &&
        RegExp(r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
            .hasMatch(emailController.text) &&
        passwordController.text.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 24),
                    Image(
                        height: 150, image: AssetImage('assets/app_logo.png')),
                    SizedBox(height: 16),
                    Text(
                      'Welcome back',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Log in to your account',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        MyTextField(
                          controller: emailController,
                          hintText: 'Email',
                          prefixIcon: Icon(Iconsax.direct_right,
                              color: Colors.grey.shade600),
                          suffixIcon: null,
                          obscureText: false,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(
                                    r'^[a-zA-Z0-9._%-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                                .hasMatch(value)) {
                              return 'Enter a valid email address';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        MyTextField(
                          controller: passwordController,
                          hintText: 'Password',
                          prefixIcon: Icon(Iconsax.password_check,
                              color: Colors.grey.shade600),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Iconsax.eye_slash
                                  : Iconsax.eye,
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
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters long';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: true,
                                  onChanged: (value) {},
                                  checkColor: Colors.white,
                                  fillColor: WidgetStateProperty.all(
                                    Color.fromARGB(255, 49, 107, 253),
                                  ),
                                ),
                                Text('Remember me')
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ButtonStyle(
                              elevation: WidgetStateProperty.all(0),
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                  horizontal: 75,
                                  vertical: 16,
                                ),
                              ),
                              backgroundColor: WidgetStateProperty.all(
                                Color.fromARGB(255, 73, 121, 251),
                              ),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                              ),
                            ),
                            onPressed: _isFormValid() ? signUserIn : null,
                            child: Text(
                              'Login',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: ButtonStyle(
                              elevation: WidgetStateProperty.all(0),
                              side: WidgetStateProperty.all(
                                BorderSide(
                                  width: 1,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              padding: WidgetStateProperty.all(
                                EdgeInsets.symmetric(
                                  horizontal: 75,
                                  vertical: 16,
                                ),
                              ),
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.transparent),
                              shape: WidgetStateProperty.all(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.0),
                                ),
                              ),
                            ),
                            onPressed: widget.onTap,
                            child: Text(
                              'Create Account',
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                      'Or Sign in with',
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
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SquareTile(imagePath: 'assets/google.png'),
                    SquareTile(imagePath: 'assets/apple.png'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Add listeners to trigger rebuild when text changes
    emailController.addListener(() {
      setState(() {});
    });
    passwordController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}
