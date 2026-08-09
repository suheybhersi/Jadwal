import 'package:flutter/material.dart';
import 'package:jadwal/pages/auth/login_page.dart';
import 'package:jadwal/pages/auth/register_page.dart';

class LoginOrRegisterPage extends StatefulWidget {
  const LoginOrRegisterPage({
    super.key,
    this.startWithLogin = true,
  });

  /// When false, opens on Create account first.
  final bool startWithLogin;

  @override
  State<LoginOrRegisterPage> createState() => _LoginOrRegisterPageState();
}

class _LoginOrRegisterPageState extends State<LoginOrRegisterPage> {
  late bool showLoginPage;

  @override
  void initState() {
    super.initState();
    showLoginPage = widget.startWithLogin;
  }

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
