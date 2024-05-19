import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.white,
    primary: Colors.grey.shade100,
    secondary: const Color.fromARGB(255, 233, 226, 226),
    tertiary: Colors.grey.shade400,
    inversePrimary: const Color.fromARGB(255, 32, 32, 32),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: const Color.fromARGB(255, 24, 24, 24),
    primary: const Color.fromARGB(255, 34, 34, 34),
    secondary: const Color.fromARGB(255, 49, 49, 49),
    tertiary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade300,
  ),
);
