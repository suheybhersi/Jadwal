import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    surface: Colors.white,
    primary: Color(0xFF4979FB), // changed for brand color usage
    tertiary: Colors.grey.shade300,
    secondary: Colors.grey.shade400,
    inversePrimary: const Color.fromARGB(255, 53, 53, 53),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    surface: const Color.fromARGB(255, 20, 20, 20),
    primary: Color(0xFF4979FB), // match or choose another for dark mode
    tertiary: const Color.fromARGB(255, 50, 50, 50),
    secondary: const Color.fromARGB(255, 60, 60, 60),
    inversePrimary: Colors.white,
  ),
);
