import 'package:flutter/material.dart';

ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  colorScheme: ColorScheme.light(
    background: Colors.grey.shade100,
    primary: Colors.grey.shade200,
    tertiary: Colors.grey.shade300,
    secondary: Colors.grey.shade400,
    inversePrimary: const Color.fromARGB(255, 32, 32, 32),
  ),
);

ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    background: const Color.fromARGB(255, 20, 20, 20),
    primary: const Color.fromARGB(255, 35, 35, 35),
    secondary: const Color.fromARGB(255, 60, 60, 60),
    tertiary: Colors.grey.shade700,
    inversePrimary: Colors.grey.shade300,
  ),
);
