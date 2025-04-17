import 'package:flutter/material.dart';
import 'package:jadwal/themes/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  ThemeData _themeData = lightMode;
  bool _useSystemTheme = true;

  ThemeProvider() {
    _loadPreferences();
  }

  // Initialize by loading saved preferences
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _useSystemTheme = prefs.getBool('useSystemTheme') ?? true;

    if (!_useSystemTheme) {
      final isDark = prefs.getBool('isDarkMode') ?? false;
      _themeData = isDark ? darkMode : lightMode;
    }
    notifyListeners();
  }

  // Save current preferences
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('useSystemTheme', _useSystemTheme);
    await prefs.setBool('isDarkMode', isDarkMode);
  }

  ThemeData get themeData => _themeData;

  bool get isDarkMode => _themeData == darkMode;

  bool get useSystemTheme => _useSystemTheme;

  // Set whether to use system theme
  void setSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    _savePreferences();
    notifyListeners();
  }

  // Update theme based on system brightness
  void updateWithSystemTheme(Brightness systemBrightness) {
    // If we're using system theme, update the theme to match system
    if (_useSystemTheme) {
      final newTheme =
          systemBrightness == Brightness.dark ? darkMode : lightMode;

      // Only update if theme actually changed to avoid unnecessary rebuilds
      if (_themeData != newTheme) {
        _themeData = newTheme;
        notifyListeners();
      }
    }
  }

  // Manually set theme and disable system theme following
  void toggleTheme() {
    _useSystemTheme = false;
    // Set the theme directly based on what we want to change to
    _themeData = isDarkMode ? lightMode : darkMode;
    _savePreferences();
    notifyListeners();
  }
}
