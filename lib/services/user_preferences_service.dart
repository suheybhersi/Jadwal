import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jadwal/services/firestore.dart';

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
  bool _hasCompletedNotificationOnboarding = false;
  
  FirestoreService? _firestoreService;
  bool _isLoading = false;
  bool _localLoadDone = false;
  bool _firestoreLoadDone = false;

  UserPreferencesService() {
    _loadPreferences();
    _initializeFirestore();
  }

  // Initialize Firestore service if user is logged in
  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService = FirestoreService(
        auth: FirebaseAuth.instance,
        uid: user.uid,
      );
      _loadFromFirestore();
    }
    
    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _firestoreService = FirestoreService(
          auth: FirebaseAuth.instance,
          uid: user.uid,
        );
        _loadFromFirestore();
      } else {
        _firestoreService = null;
        // Reset to defaults when logged out
        _hasCompletedModeSelection = false;
        _hasCompletedNotificationOnboarding = false;
        notifyListeners();
      }
    });
  }

  // Getters
  UsageMode get usageMode => _usageMode;
  bool get showStreaks => _showStreaks;
  bool get enableReviews => _enableReviews;
  bool get showMissedItems => _showMissedItems;
  bool get hasCompletedModeSelection => _hasCompletedModeSelection;
  bool get hasCompletedNotificationOnboarding =>
      _hasCompletedNotificationOnboarding;
  /// True after initial prefs (and Firestore for logged-in user) have been loaded; avoids flashing mode/tutorial screens.
  bool get initialLoadDone =>
      _localLoadDone && (_firestoreService == null || _firestoreLoadDone);

  // Derived properties based on mode
  bool get shouldScheduleReviews =>
      _usageMode != UsageMode.flexible && _enableReviews;
  bool get shouldShowPressureMetrics => _usageMode != UsageMode.flexible;

  // Load preferences from local storage (fallback/cache)
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
    
    // Note: hasCompletedModeSelection / hasCompletedNotificationOnboarding are now loaded from Firestore
    // This is just a fallback for offline scenarios
    _hasCompletedModeSelection =
        prefs.getBool('hasCompletedModeSelection') ?? false;
    _hasCompletedNotificationOnboarding =
        prefs.getBool('hasCompletedNotificationOnboarding') ?? false;

    // Override some settings based on mode
    _applyModeDefaults();

    _localLoadDone = true;
    notifyListeners();
  }

  // Load mode selection status from Firestore (per-user)
  Future<void> _loadFromFirestore() async {
    if (_firestoreService == null || _isLoading) return;
    
    try {
      _isLoading = true;
      final userProfile = await _firestoreService!.getUserProfile();
      
      if (userProfile != null) {
        // Load hasCompletedModeSelection from Firestore
        if (userProfile.containsKey('hasCompletedModeSelection')) {
          _hasCompletedModeSelection = userProfile['hasCompletedModeSelection'] as bool? ?? false;
        }
        
        // Load hasCompletedNotificationOnboarding from Firestore
        if (userProfile.containsKey('hasCompletedNotificationOnboarding')) {
          _hasCompletedNotificationOnboarding =
              userProfile['hasCompletedNotificationOnboarding'] as bool? ??
                  false;
        }
        
        // Load usage mode from Firestore if available
        if (userProfile.containsKey('usageMode')) {
          final modeString = userProfile['usageMode'] as String?;
          if (modeString != null) {
            final modeName = modeString.split('.').last;
            _usageMode = UsageMode.values.firstWhere(
              (mode) => mode.name == modeName,
              orElse: () => UsageMode.intensive,
            );
            
            // Migrate old "balanced" mode
            if (modeName == 'balanced') {
              _usageMode = UsageMode.intensive;
            }
          }
        }
        
        // Sync to local storage as cache
        await _savePreferences();
        _applyModeDefaults();
        notifyListeners();
      }
    } catch (e) {
      // If Firestore fails, use local storage values
      debugPrint('Error loading preferences from Firestore: $e');
    } finally {
      _isLoading = false;
      _firestoreLoadDone = true;
      notifyListeners();
    }
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('usageMode', _usageMode.toString());
    await prefs.setBool('showStreaks', _showStreaks);
    await prefs.setBool('enableReviews', _enableReviews);
    await prefs.setBool('showMissedItems', _showMissedItems);
    await prefs.setBool('hasCompletedModeSelection', _hasCompletedModeSelection);
     await prefs.setBool('hasCompletedNotificationOnboarding',
        _hasCompletedNotificationOnboarding);
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
    
    // Also save to Firestore if available
    if (_firestoreService != null) {
      try {
        await _firestoreService!.updateUserProfile({
          'usageMode': mode.toString(),
        });
      } catch (e) {
        debugPrint('Error saving usage mode to Firestore: $e');
      }
    }
    
    notifyListeners();
  }

  // Mark mode selection as completed
  Future<void> completeModeSelection() async {
    _hasCompletedModeSelection = true;
    await _savePreferences();
    
    // Save to Firestore (per-user storage)
    if (_firestoreService != null) {
      try {
        await _firestoreService!.updateUserProfile({
          'hasCompletedModeSelection': true,
          'usageMode': _usageMode.toString(),
        });
      } catch (e) {
        debugPrint('Error saving mode selection to Firestore: $e');
        // Still save locally as fallback
      }
    }
    
    notifyListeners();
  }

  // Mark notification onboarding as completed (per-user, synced via Firestore).
  Future<void> completeNotificationOnboarding() async {
    _hasCompletedNotificationOnboarding = true;
    await _savePreferences();

    if (_firestoreService != null) {
      try {
        await _firestoreService!.updateUserProfile({
          'hasCompletedNotificationOnboarding': true,
        });
      } catch (e) {
        debugPrint(
            'Error saving notification onboarding status to Firestore: $e');
      }
    }

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
