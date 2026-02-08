import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage tutorial and feature discovery state
class TutorialService with ChangeNotifier {
  bool _hasCompletedTutorial = false;
  bool _hasSeenFeatureTour = false;
  Map<String, bool> _tooltipSeen = {};
  bool _initialLoadDone = false;

  // Memorization tip IDs
  static const List<String> memorizationTipIds = [
    'go_to_memorization_button',
    'edit_end_verse_button',
    'mark_complete_button',
  ];

  TutorialService() {
    _loadPreferences();
  }

  // Getters
  bool get hasCompletedTutorial => _hasCompletedTutorial;
  bool get hasSeenFeatureTour => _hasSeenFeatureTour;
  /// True after preferences have been loaded from storage (avoids showing wrong screen on first frame).
  bool get initialLoadDone => _initialLoadDone;
  bool hasSeenTooltip(String tooltipId) => _tooltipSeen[tooltipId] ?? false;
  
  // Get count of seen memorization tips
  int get memorizationTipsSeen {
    return memorizationTipIds.where((id) => hasSeenTooltip(id)).length;
  }
  
  // Get total memorization tips
  int get totalMemorizationTips => memorizationTipIds.length;

  // Load preferences from storage
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _hasCompletedTutorial = prefs.getBool('hasCompletedTutorial') ?? false;
    _hasSeenFeatureTour = prefs.getBool('hasSeenFeatureTour') ?? false;
    
    // Load tooltip states
    final tooltipKeys = prefs.getKeys().where((key) => key.startsWith('tooltip_'));
    for (final key in tooltipKeys) {
      _tooltipSeen[key.replaceFirst('tooltip_', '')] = prefs.getBool(key) ?? false;
    }
    
    _initialLoadDone = true;
    notifyListeners();
  }

  // Save preferences to storage
  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCompletedTutorial', _hasCompletedTutorial);
    await prefs.setBool('hasSeenFeatureTour', _hasSeenFeatureTour);
    
    // Save tooltip states
    for (final entry in _tooltipSeen.entries) {
      await prefs.setBool('tooltip_${entry.key}', entry.value);
    }
  }

  // Mark tutorial as completed
  Future<void> completeTutorial() async {
    _hasCompletedTutorial = true;
    await _savePreferences();
    notifyListeners();
  }

  // Mark feature tour as seen
  Future<void> markFeatureTourSeen() async {
    _hasSeenFeatureTour = true;
    await _savePreferences();
    notifyListeners();
  }

  // Mark tooltip as seen
  Future<void> markTooltipSeen(String tooltipId) async {
    _tooltipSeen[tooltipId] = true;
    await _savePreferences();
    notifyListeners();
  }

  // Reset tutorial (for testing or re-onboarding)
  Future<void> resetTutorial() async {
    _hasCompletedTutorial = false;
    _hasSeenFeatureTour = false;
    _tooltipSeen.clear();
    await _savePreferences();
    notifyListeners();
  }
}
