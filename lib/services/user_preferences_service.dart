import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Usage mode for the app
enum UsageMode {
  flexible, // Simple - no scheduled reviews, no pressure
  intensive, // Full functionality - SM-2 algorithm, reviews, statistics
}

/// Service to manage user preferences including usage mode
class UserPreferencesService with ChangeNotifier {
  UsageMode _usageMode = UsageMode.intensive;
  bool _showStreaks = true;
  bool _enableReviews = true;
  bool _showMissedItems = true;
  bool _hasCompletedModeSelection = false;

  UserPreferencesService() {
    _loadPreferences();
  }

  // Getters
  UsageMode get usageMode => _usageMode;
  bool get showStreaks => _showStreaks;
  bool get enableReviews => _enableReviews;
  bool get showMissedItems => _showMissedItems;
  bool get hasCompletedModeSelection => _hasCompletedModeSelection;

  // Derived properties based on mode
  bool get shouldScheduleReviews =>
      _usageMode != UsageMode.flexible && _enableReviews;
  bool get shouldShowPressureMetrics => _usageMode != UsageMode.flexible;

  // Load preferences from storage
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    // Load usage mode
    final modeString = prefs.getString('usageMode');
    
    if (modeString != null) {
      // Parse the mode string (format: "UsageMode.flexible")
      final modeName = modeString.split('.').last;
      _usageMode = UsageMode.values.firstWhere(
        (mode) => mode.name == modeName,
        orElse: () => UsageMode.intensive,
      );
      
      // Migrate old "balanced" mode to "intensive"
      if (modeName == 'balanced') {
        _usageMode = UsageMode.intensive;
      }
    }

    // Load other preferences
    _showStreaks = prefs.getBool('showStreaks') ?? true;
    _enableReviews = prefs.getBool('enableReviews') ?? true;
    _showMissedItems = prefs.getBool('showMissedItems') ?? true;
    _hasCompletedModeSelection =
        prefs.getBool('hasCompletedModeSelection') ?? false;

    // Override some settings based on mode
    _applyModeDefaults();

    notifyListeners();
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usageMode', _usageMode.toString());
    await prefs.setBool('showStreaks', _showStreaks);
    await prefs.setBool('enableReviews', _enableReviews);
    await prefs.setBool('showMissedItems', _showMissedItems);
    await prefs.setBool('hasCompletedModeSelection', _hasCompletedModeSelection);
  }

  // Apply default settings based on mode
  void _applyModeDefaults() {
    switch (_usageMode) {
      case UsageMode.flexible:
        _enableReviews = false;
        _showStreaks = false;
        _showMissedItems = false;
        break;
      case UsageMode.intensive:
        _enableReviews = true;
        _showStreaks = true;
        _showMissedItems = true;
        break;
    }
  }

  // Set usage mode
  Future<void> setUsageMode(UsageMode mode) async {
    _usageMode = mode;
    _applyModeDefaults();
    await _savePreferences();
    notifyListeners();
  }

  // Mark mode selection as completed
  Future<void> completeModeSelection() async {
    _hasCompletedModeSelection = true;
    await _savePreferences();
    notifyListeners();
  }

  // Toggle individual preferences (for advanced customization)
  Future<void> toggleStreaks() async {
    _showStreaks = !_showStreaks;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> toggleReviews() async {
    _enableReviews = !_enableReviews;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> toggleMissedItems() async {
    _showMissedItems = !_showMissedItems;
    await _savePreferences();
    notifyListeners();
  }

  // Get mode display name
  static String getModeName(UsageMode mode) {
    switch (mode) {
      case UsageMode.flexible:
        return 'Flexible';
      case UsageMode.intensive:
        return 'Intensive';
    }
  }

  // Get mode description
  static String getModeDescription(UsageMode mode) {
    switch (mode) {
      case UsageMode.flexible:
        return 'Just track your progress when you memorize';
      case UsageMode.intensive:
        return 'Full memorization system with reviews and statistics';
    }
  }

  // Get mode features
  static List<String> getModeFeatures(UsageMode mode) {
    switch (mode) {
      case UsageMode.flexible:
        return [
          'No scheduled reviews',
          'No pressure metrics',
          'Manual quizzes only',
          'Perfect for busy schedules',
        ];
      case UsageMode.intensive:
        return [
          'SM-2 spaced repetition',
          'Automatic review scheduling',
          'Progress tracking & statistics',
          'Streak counters & achievements',
        ];
    }
  }
}
